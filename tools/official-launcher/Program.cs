using System.Diagnostics;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;

namespace EternalEmerald.Launcher;

internal static class Program
{
    [STAThread]
    static int Main(string[] args)
    {
        if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
        {
            var d = AppContext.BaseDirectory;
            return File.Exists(Path.Combine(d, "Game.exe")) && File.Exists(Path.Combine(d, "launchers", "Start-Eternal-Emerald-MMO.ps1")) ? 0 : 2;
        }

        using var mutex = new Mutex(true, "EternalEmeraldOfficialLauncher", out bool first);
        if (!first) return 0;

        ApplicationConfiguration.Initialize();
        Application.ThreadException += (_, e) => CrashLog.Write(e.Exception);
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
            CrashLog.Write(e.ExceptionObject as Exception ?? new Exception(e.ExceptionObject?.ToString()));
        try
        {
            Application.Run(new LauncherForm(args.Contains("--guest", StringComparer.OrdinalIgnoreCase)));
            return 0;
        }
        catch (Exception ex)
        {
            CrashLog.Write(ex);
            MessageBox.Show("Le launcher a rencontré une erreur. Un rapport a été créé dans .runtime\\launcher-crash.log.",
                "Eternal Emerald", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}

internal static class CrashLog
{
    public static void Write(Exception ex)
    {
        try
        {
            string dir = Path.Combine(AppContext.BaseDirectory, ".runtime");
            Directory.CreateDirectory(dir);
            File.AppendAllText(Path.Combine(dir, "launcher-crash.log"), $"[{DateTime.Now:O}] {ex}\r\n\r\n");
        }
        catch { }
    }
}

internal static class Prefs
{
    static string file = Path.Combine(AppContext.BaseDirectory, ".runtime", "launcher.ini");
    static readonly Dictionary<string, string> d = new();

    public static void Load(string root)
    {
        file = Path.Combine(root, ".runtime", "launcher.ini");
        try
        {
            if (File.Exists(file))
                foreach (var l in File.ReadAllLines(file)) { var i = l.IndexOf('='); if (i > 0) d[l[..i]] = l[(i + 1)..]; }
        }
        catch { }
    }
    public static bool Get(string k, bool def) => d.TryGetValue(k, out var v) ? v == "1" : def;
    public static void Set(string k, bool v)
    {
        d[k] = v ? "1" : "0";
        try { Directory.CreateDirectory(Path.GetDirectoryName(file)!); File.WriteAllLines(file, d.Select(x => $"{x.Key}={x.Value}")); } catch { }
    }
}

internal sealed class UpdateFile
{
    public string path { get; set; } = "";
    public string url { get; set; } = "";
    public string sha256 { get; set; } = "";
    public long bytes { get; set; }
}

internal sealed class UpdateManifest
{
    public string version { get; set; } = "";
    public bool mandatory { get; set; } = true;
    public List<UpdateFile> files { get; set; } = new();
}

internal sealed class UpdateService
{
    const string DefaultManifest = "https://raw.githubusercontent.com/NISMOR33/POKEMON-ONLINE/main/update-manifest.json";
    readonly string root;
    readonly HttpClient http = new() { Timeout = TimeSpan.FromMinutes(15) };
    public UpdateService(string gameRoot){root=gameRoot;http.DefaultRequestHeaders.UserAgent.ParseAdd("Eternal-Emerald-Launcher/3.1");}

    public async Task<(UpdateManifest? manifest,List<UpdateFile> changed)> Check(CancellationToken token=default)
    {
        string endpoint=DefaultManifest,overrideFile=Path.Combine(root,"launcher-update-url.txt");
        if(File.Exists(overrideFile)){var custom=File.ReadAllText(overrideFile).Trim();if(Uri.TryCreate(custom,UriKind.Absolute,out _))endpoint=custom;}
        string json=await http.GetStringAsync(endpoint,token);
        var manifest=JsonSerializer.Deserialize<UpdateManifest>(json,new JsonSerializerOptions{PropertyNameCaseInsensitive=true})??throw new InvalidDataException("Le manifeste de mise à jour est invalide.");
        var changed=new List<UpdateFile>();
        foreach(var f in manifest.files)
        {
            string target=SafeTarget(f.path);if(!File.Exists(target)||!string.Equals(await Hash(target,token),f.sha256,StringComparison.OrdinalIgnoreCase))changed.Add(f);
        }
        return(manifest,changed);
    }

    public async Task DownloadAndApply(UpdateManifest manifest,List<UpdateFile> files,Action<int,string> progress,int launcherPid)
    {
        string stageRoot=Path.Combine(root,".runtime","update",manifest.version);Directory.CreateDirectory(stageRoot);
        var plan=new List<object>();long total=Math.Max(1,files.Sum(f=>Math.Max(1,f.bytes))),done=0;
        foreach(var f in files)
        {
            string target=SafeTarget(f.path),stage=Path.Combine(stageRoot,Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(f.path)))+".download");
            using var response=await http.GetAsync(f.url,HttpCompletionOption.ResponseHeadersRead);response.EnsureSuccessStatusCode();
            await using(var input=await response.Content.ReadAsStreamAsync())await using(var output=new FileStream(stage,FileMode.Create,FileAccess.Write,FileShare.None))
            {var buffer=new byte[1024*128];int read;while((read=await input.ReadAsync(buffer))>0){await output.WriteAsync(buffer.AsMemory(0,read));done+=read;progress((int)Math.Clamp(done*100/total,0,100),Path.GetFileName(f.path));}}
            if(!string.Equals(await Hash(stage),f.sha256,StringComparison.OrdinalIgnoreCase)){File.Delete(stage);throw new InvalidDataException($"La vérification de {f.path} a échoué.");}
            plan.Add(new{stage,target,sha256=f.sha256});
        }
        string planFile=Path.Combine(stageRoot,"plan.json");File.WriteAllText(planFile,JsonSerializer.Serialize(plan));
        string helper=Path.Combine(root,"launchers","Apply-Eternal-Emerald-Update.ps1");if(!File.Exists(helper))throw new FileNotFoundException("Le programme d'installation de mise à jour est introuvable.",helper);
        Process.Start(new ProcessStartInfo("powershell.exe",$"-NoProfile -ExecutionPolicy Bypass -File \"{helper}\" -Plan \"{planFile}\" -LauncherPid {launcherPid}"){WorkingDirectory=root,UseShellExecute=false,CreateNoWindow=true});
    }

    string SafeTarget(string relative)
    {
        if(string.IsNullOrWhiteSpace(relative)||Path.IsPathRooted(relative))throw new InvalidDataException("Chemin de mise à jour interdit.");
        string full=Path.GetFullPath(Path.Combine(root,relative.Replace('/',Path.DirectorySeparatorChar)));string prefix=root.TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar;
        if(!full.StartsWith(prefix,StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("Chemin de mise à jour interdit.");return full;
    }
    static async Task<string> Hash(string path,CancellationToken token=default){await using var s=File.OpenRead(path);using var h=SHA256.Create();return Convert.ToHexString(await h.ComputeHashAsync(s,token)).ToLowerInvariant();}
}

// ───────────────────────── THEME ─────────────────────────
internal static class Theme
{
    public static readonly Color Night = Color.FromArgb(5, 15, 16);
    public static readonly Color Emerald = Color.FromArgb(39, 184, 119);
    public static readonly Color Mint = Color.FromArgb(118, 236, 174);
    public static readonly Color Cream = Color.FromArgb(242, 238, 211);
    public static readonly Color Muted = Color.FromArgb(128, 158, 147);
    public static readonly Color Gold = Color.FromArgb(239, 198, 86);
    public static readonly Color Danger = Color.FromArgb(240, 104, 92);

    public static Font Ui(float pt, FontStyle st = FontStyle.Regular) => new("Segoe UI", pt, st);
    public static Font Glyph(float pt) => new("Segoe MDL2 Assets", pt);

    public static GraphicsPath Round(RectangleF r, float radius)
    {
        float d = Math.Max(1, radius * 2);
        var p = new GraphicsPath();
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    public static Bitmap? LoadImage(string path)
    {
        if (!File.Exists(path)) return null;
        using var tmp = Image.FromFile(path);
        return new Bitmap(tmp);
    }
}

// ───────────────────────── CONTROLS ─────────────────────────
internal abstract class FlatControl : Control
{
    protected bool Hover, Pressed;
    protected FlatControl()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.ResizeRedraw | ControlStyles.SupportsTransparentBackColor, true);
        SetStyle(ControlStyles.Selectable, false);
        BackColor = Color.Transparent;
        Cursor = Cursors.Hand;
    }
    protected override void OnMouseEnter(EventArgs e) { Hover = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { Hover = Pressed = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e) { Pressed = true; Invalidate(); base.OnMouseDown(e); }
    protected override void OnMouseUp(MouseEventArgs e) { Pressed = false; Invalidate(); base.OnMouseUp(e); }
    protected override void OnEnabledChanged(EventArgs e) { Invalidate(); base.OnEnabledChanged(e); }
}

internal sealed class RoundButton : FlatControl
{
    bool primary;
    float shine = -0.4f;
    readonly System.Windows.Forms.Timer shineTimer = new() { Interval = 30 };
    public bool Primary
    {
        get => primary;
        set { primary = value; if (value) shineTimer.Start(); else shineTimer.Stop(); }
    }
    public RoundButton()
    {
        Font = Theme.Ui(11, FontStyle.Bold);
        shineTimer.Tick += (_, _) =>
        {
            shine += 0.022f;
            if (shine > 2.4f) shine = -0.4f;
            if (Enabled && IsHandleCreated && shine < 1.4f) Invalidate();
        };
    }
    protected override void Dispose(bool disposing) { if (disposing) shineTimer.Dispose(); base.Dispose(disposing); }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        var r = new RectangleF(5, 5, Width - 10, Height - 10);
        if (Pressed && Enabled) r.Offset(0, 1);

        if (Primary && Enabled)
        {
            if (Hover)
                for (int i = 1; i <= 4; i++)
                {
                    using var gp = Theme.Round(RectangleF.Inflate(r, i * 2, i * 2), 16 + i * 2);
                    using var pen = new Pen(Color.FromArgb(34 - i * 7, Theme.Mint), 2);
                    g.DrawPath(pen, gp);
                }
            using var path = Theme.Round(r, 16);
            using var br = new LinearGradientBrush(r,
                Hover ? Color.FromArgb(70, 226, 152) : Color.FromArgb(48, 206, 134), Color.FromArgb(20, 140, 94), 90f);
            g.FillPath(br, path);
            if (shine > -0.3f && shine < 1.3f)
            {
                float sx = r.X + shine * r.Width;
                var state = g.Save();
                g.SetClip(path);
                var band = new RectangleF(sx - 70, r.Y, 140, r.Height);
                using var sb = new LinearGradientBrush(band, Color.White, Color.White, 0f)
                {
                    InterpolationColors = new ColorBlend
                    {
                        Colors = new[] { Color.FromArgb(0, 255, 255, 255), Color.FromArgb(75, 255, 255, 255), Color.FromArgb(0, 255, 255, 255) },
                        Positions = new[] { 0f, 0.5f, 1f }
                    }
                };
                g.FillRectangle(sb, band);
                g.Restore(state);
            }
            using var hi = new Pen(Color.FromArgb(70, 255, 255, 255), 1);
            g.DrawPath(hi, path);
        }
        else
        {
            using var path = Theme.Round(r, 16);
            using var fill = new SolidBrush(Color.FromArgb(Enabled ? (Hover ? 34 : 16) : 10, 255, 255, 255));
            using var pen = new Pen(Color.FromArgb(Hover ? 90 : 45, 255, 255, 255), 1);
            g.FillPath(fill, path);
            g.DrawPath(pen, path);
        }

        var fg = !Enabled ? Theme.Muted : Primary ? Color.White : Theme.Cream;
        using var tb = new SolidBrush(fg);
        using var sf = new StringFormat { LineAlignment = StringAlignment.Center, Alignment = StringAlignment.Center };
        if (Primary)
        {
            float tw = g.MeasureString(Text, Font, PointF.Empty, StringFormat.GenericTypographic).Width;
            float x0 = (Width - (tw + 30)) / 2f, cy = r.Y + r.Height / 2f;
            g.FillPolygon(tb, new[] { new PointF(x0, cy - 7), new PointF(x0 + 12, cy), new PointF(x0, cy + 7) });
            sf.Alignment = StringAlignment.Near;
            g.DrawString(Text, Font, tb, new RectangleF(x0 + 28, r.Y, r.Width, r.Height), sf);
        }
        else g.DrawString(Text, Font, tb, r, sf);
    }
}

internal sealed class GlyphButton : FlatControl
{
    public string Glyph { get; set; } = "";
    public bool Active { get; set; }
    public float Radius { get; set; } = 14;
    public Color HoverFill { get; set; } = Color.FromArgb(32, 255, 255, 255);
    readonly Font font = Theme.Glyph(12);

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAlias;
        var r = new RectangleF(0, 0, Width - 1, Height - 1);
        using var path = Theme.Round(r, Radius);
        if (Active)
        {
            using var br = new LinearGradientBrush(r, Color.FromArgb(52, 211, 140), Color.FromArgb(22, 150, 100), 90f);
            g.FillPath(br, path);
        }
        else if (Hover)
        {
            using var br = new SolidBrush(HoverFill);
            g.FillPath(br, path);
        }
        using var tb = new SolidBrush(Active ? Color.White : Hover ? Theme.Cream : Theme.Muted);
        using var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(Glyph, font, tb, r, sf);
    }
}

internal sealed class NavTab : FlatControl
{
    public bool Active { get; set; }
    public NavTab() { Font = Theme.Ui(9, FontStyle.Bold); }
    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        using var tb = new SolidBrush(Active ? Theme.Cream : Hover ? Theme.Cream : Theme.Muted);
        using var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(Text, Font, tb, new RectangleF(0, 0, Width, Height - 4), sf);
        if (Active)
        {
            using var u = new SolidBrush(Theme.Mint);
            g.FillRectangle(u, Width / 2f - 14, Height - 5, 28, 3);
        }
    }
}

internal sealed class GlassCard : Control
{
    public string Glyph { get; set; } = "";
    public string Title { get; set; } = "";
    public string Sub { get; set; } = "";
    readonly Font gf = Theme.Glyph(15), tf = Theme.Ui(10, FontStyle.Bold), sf2 = Theme.Ui(9);
    public bool Clickable { get; set; }
    public bool ShowSwitch { get; set; }
    public bool On { get; set; }
    public event Action<bool>? Toggled;
    bool hot;
    protected override void OnMouseEnter(EventArgs e) { if (Clickable || ShowSwitch) { hot = true; Cursor = Cursors.Hand; Invalidate(); } base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hot = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnClick(EventArgs e)
    {
        if (ShowSwitch) { On = !On; Toggled?.Invoke(On); Invalidate(); }
        base.OnClick(e);
    }

    public GlassCard()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        var r = new RectangleF(0, 0, Width - 1, Height - 1);
        using (var path = Theme.Round(r, 16))
        using (var fill = new LinearGradientBrush(r, Color.FromArgb(hot ? 46 : 26, 255, 255, 255), Color.FromArgb(hot ? 20 : 8, 255, 255, 255), 90f))
        using (var pen = new Pen(Color.FromArgb(34, 255, 255, 255), 1))
        {
            g.FillPath(fill, path);
            g.DrawPath(pen, path);
        }
        var ic = new RectangleF(18, (Height - 46) / 2f, 46, 46);
        using (var b = new SolidBrush(Color.FromArgb(44, Theme.Emerald))) g.FillEllipse(b, ic);
        using (var p = new Pen(Color.FromArgb(120, Theme.Mint), 1)) g.DrawEllipse(p, ic);
        using var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        using (var mb = new SolidBrush(Theme.Mint)) g.DrawString(Glyph, gf, mb, ic, sf);
        using (var cb = new SolidBrush(Theme.Cream)) g.DrawString(Title, tf, cb, 78, Height / 2f - 23);
        using (var mb = new SolidBrush(Theme.Muted)) g.DrawString(Sub, sf2, mb, 78, Height / 2f + 2);
        if (ShowSwitch)
        {
            var t = new RectangleF(Width - 80, Height / 2f - 13, 52, 26);
            using var tp = Theme.Round(t, 13);
            using (var track = new SolidBrush(On ? Theme.Emerald : Color.FromArgb(60, 255, 255, 255))) g.FillPath(track, tp);
            using var knob = new SolidBrush(Color.White);
            g.FillEllipse(knob, On ? t.Right - 23 : t.X + 3, t.Y + 3, 20, 20);
        }
    }
}

internal sealed class StatusPill : Control
{
    string text = "CONNEXION…";
    Color tint = Theme.Gold;
    float phase;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 40 };
    readonly Font font = Theme.Ui(8.5f, FontStyle.Bold);

    public StatusPill()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
        timer.Tick += (_, _) => { phase += 0.12f; Invalidate(); };
        timer.Start();
    }

    public void SetState(string t, Color c) { text = t; tint = c; Invalidate(); }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        var r = new RectangleF(1, 1, Width - 3, Height - 3);
        using (var path = Theme.Round(r, Height / 2f))
        using (var fill = new SolidBrush(Color.FromArgb(30, tint)))
        using (var pen = new Pen(Color.FromArgb(95, tint), 1))
        {
            g.FillPath(fill, path);
            g.DrawPath(pen, path);
        }
        float cy = Height / 2f, pulse = (float)(Math.Sin(phase) + 1) / 2f, rr = 4 + pulse * 6;
        using (var ring = new SolidBrush(Color.FromArgb((int)(110 * (1 - pulse)), tint))) g.FillEllipse(ring, 19 - rr, cy - rr, rr * 2, rr * 2);
        using (var dot = new SolidBrush(tint)) g.FillEllipse(dot, 15, cy - 4, 8, 8);
        using var tb = new SolidBrush(tint);
        using var sf = new StringFormat { LineAlignment = StringAlignment.Center };
        g.DrawString(text, font, tb, new RectangleF(34, 0, Width - 34, Height), sf);
    }

    protected override void Dispose(bool disposing) { if (disposing) timer.Dispose(); base.Dispose(disposing); }
}

internal sealed class SlimProgress : Control
{
    float current, target;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 16 };

    public SlimProgress()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
        timer.Tick += (_, _) =>
        {
            current += (target - current) * 0.14f;
            if (Math.Abs(target - current) < 0.2f) { current = target; timer.Stop(); }
            Invalidate();
        };
    }

    public int Value { get => (int)target; set { target = Math.Clamp(value, 0, 100); timer.Start(); } }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        var track = new RectangleF(0, 0, Width, Height);
        using (var tb = new SolidBrush(Color.FromArgb(26, 255, 255, 255))) g.FillRectangle(tb, track);
        float w = Width * current / 100f;
        if (w < 2) return;
        var fill = new RectangleF(0, 0, w, Height);
        using var br = new LinearGradientBrush(new RectangleF(0, 0, Math.Max(w, 2), Height), Theme.Emerald, Theme.Mint, 0f);
        g.FillRectangle(br, fill);
    }

    protected override void Dispose(bool disposing) { if (disposing) timer.Dispose(); base.Dispose(disposing); }
}

internal sealed class TitleControl : Control
{
    public TitleControl()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.TextRenderingHint = TextRenderingHint.AntiAlias;
        using var f = Theme.Ui(40, FontStyle.Bold);
        g.DrawString("ETERNAL", f, Brushes.White, 0, 0);
        using var br = new LinearGradientBrush(new RectangleF(0, 60, 380, 70), Theme.Mint, Theme.Emerald, 0f);
        g.DrawString("EMERALD", f, br, 0, 58);
    }
}

// Animated hero stage: glow circle, rotating ring, dust, Rayquaza sprite and trainer cut-out.
internal sealed class Stage : Control
{
    readonly Func<Bitmap?> background;
    readonly Bitmap? sprite, hero;
    readonly int frameSize;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 33 };
    readonly (float x, float y, float speed, float size, int alpha)[] dust = new (float, float, float, float, int)[38];
    int tick, frame;
    PointF par;

    public Stage(Func<Bitmap?> bg, string spritePath, string heroPath)
    {
        background = bg;
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        sprite = Theme.LoadImage(spritePath);
        frameSize = Math.Max(1, sprite?.Height ?? 1);
        if (File.Exists(heroPath)) hero = LoadCutout(heroPath);

        var rnd = new Random(7);
        for (int i = 0; i < dust.Length; i++)
            dust[i] = (rnd.Next(0, 500), rnd.Next(0, 380), 0.25f + (float)rnd.NextDouble() * 0.9f, 1.5f + (float)rnd.NextDouble() * 3f, rnd.Next(40, 150));

        timer.Tick += (_, _) =>
        {
            tick++;
            if (!Prefs.Get("fx", true) || FindForm()?.WindowState == FormWindowState.Minimized) return;
            var m = PointToClient(Cursor.Position);
            float tx = Math.Clamp((m.X - Width / 2f) / Width, -1f, 1f), ty = Math.Clamp((m.Y - Height / 2f) / Height, -1f, 1f);
            par = new PointF(par.X + (tx - par.X) * 0.08f, par.Y + (ty - par.Y) * 0.08f);
            if (tick % 2 == 0 && sprite != null) frame = (frame + 1) % Math.Max(1, sprite.Width / frameSize);
            for (int i = 0; i < dust.Length; i++)
            {
                dust[i].y -= dust[i].speed;
                if (dust[i].y < -6) { dust[i].y = Height + 6; dust[i].x = (dust[i].x * 7 + 13) % Math.Max(1, Width); }
            }
            Invalidate();
        };
        timer.Start();
    }

    static Bitmap LoadCutout(string path)
    {
        using var src = new Bitmap(path);
        var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
        var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(data.Stride) * bmp.Height;
        var buf = new byte[bytes];
        Marshal.Copy(data.Scan0, buf, 0, bytes);
        for (int i = 0; i < bytes; i += 4)
        {
            int light = Math.Min(buf[i + 2], Math.Min(buf[i + 1], buf[i]));
            int alpha = light > 248 ? 0 : light > 225 ? 255 - (light - 225) * 11 : 255;
            buf[i + 3] = (byte)Math.Min((int)buf[i + 3], Math.Clamp(alpha, 0, 255));
        }
        Marshal.Copy(buf, 0, data.Scan0, bytes);
        bmp.UnlockBits(data);
        return bmp;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        var bg = background();
        if (bg != null) g.DrawImage(bg, new Rectangle(0, 0, Width, Height), new Rectangle(Left, Top, Width, Height), GraphicsUnit.Pixel);
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var c = new RectangleF(100 + par.X * 6, 40 + par.Y * 6, 330, 330);
        using (var b = new LinearGradientBrush(c, Color.FromArgb(235, 31, 184, 119), Color.FromArgb(120, 8, 66, 48), 45f)) g.FillEllipse(b, c);
        using (var p = new Pen(Color.FromArgb(90, 118, 236, 174), 2)) g.DrawEllipse(p, RectangleF.Inflate(c, -14, -14));

        var st = g.Save();
        g.TranslateTransform(265 + par.X * 6, 205 + par.Y * 6);
        g.RotateTransform(tick * 0.5f);
        using (var ring = new Pen(Color.FromArgb(120, 118, 236, 174), 1.5f) { DashStyle = DashStyle.Dash }) g.DrawEllipse(ring, -192, -192, 384, 384);
        using (var dot = new SolidBrush(Theme.Mint)) g.FillEllipse(dot, -6, -198, 12, 12);
        g.Restore(st);

        foreach (var d in dust)
        {
            int a = (int)(d.alpha * (0.6 + 0.4 * Math.Sin(tick * 0.08 + d.x)));
            using var db = new SolidBrush(Color.FromArgb(Math.Clamp(a, 0, 255), Theme.Mint));
            g.FillEllipse(db, d.x, d.y, d.size, d.size);
        }

        for (int i = 0; i < 5; i++)
        {
            double ang = tick * (0.012 + i * 0.004) + i * 1.3;
            float rad = 175 + i * 9, sz = 6 + i % 3 * 2;
            float sx = 265 + par.X * 20 + (float)Math.Cos(ang) * rad, sy = 205 + par.Y * 20 + (float)Math.Sin(ang) * rad * 0.9f;
            using var shard = new SolidBrush(Color.FromArgb(150, Theme.Mint));
            g.FillPolygon(shard, new[] { new PointF(sx, sy - sz), new PointF(sx + sz * .7f, sy), new PointF(sx, sy + sz), new PointF(sx - sz * .7f, sy) });
        }
        using (var sh = new SolidBrush(Color.FromArgb(70, 0, 0, 0))) g.FillEllipse(sh, 90 + par.X * 10, 368, 210, 20);

        if (sprite != null)
        {
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            int bob = (int)Math.Round(Math.Sin(tick * 0.09) * 7);
            g.DrawImage(sprite, new Rectangle((int)(165 - par.X * 14 + Math.Sin(tick * 0.045) * 10), (int)(-25 + bob - par.Y * 10), 320, 320), new Rectangle(frame * frameSize, 0, frameSize, frameSize), GraphicsUnit.Pixel);
        }
        if (hero != null)
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.Default;
            float s = Math.Min(285f / hero.Width, 285f / hero.Height), w = hero.Width * s, h = hero.Height * s;
            int bob = (int)Math.Round(Math.Sin(tick * 0.07 + 1) * 3);
            g.DrawImage(hero, 190 - w / 2f + par.X * 10, 100 + (285 - h) + bob + par.Y * 6, w, h);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) { timer.Dispose(); sprite?.Dispose(); hero?.Dispose(); }
        base.Dispose(disposing);
    }
}

// ───────────────────────── MAIN FORM ─────────────────────────
internal sealed class LauncherForm : Form
{
    const int W = 1100, H = 660;
    readonly string root;
    bool guest;
    readonly Bitmap bg;
    readonly StatusPill pill = new();
    readonly Label status = new(), detail = new();
    readonly SlimProgress progress = new();
    RoundButton play = new(), diag = new();
    bool launching, updateBlocking;
    static readonly string[] PageKeys = { "ACCUEIL", "ACTUALITÉS", "COMMUNAUTÉ", "PARAMÈTRES" };
    readonly Dictionary<string, List<Control>> pages = new();
    readonly Dictionary<string, NavTab> tabControls = new();
    readonly List<GlyphButton> side = new();

    public LauncherForm(bool isGuest)
    {
        root = FindRoot();
        Prefs.Load(root);
        guest = isGuest || Prefs.Get("guest", false);
        Text = "Pokémon Eternal Emerald";
        FormBorderStyle = FormBorderStyle.None;
        AutoScaleMode = AutoScaleMode.None;
        ClientSize = new Size(W, H);
        MinimumSize = MaximumSize = new Size(W, H);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Theme.Night;
        DoubleBuffered = true;
        if (File.Exists(Path.Combine(root, "Game.ico"))) Icon = new Icon(Path.Combine(root, "Game.ico"));

        using (var p = Theme.Round(new RectangleF(0, 0, W, H), 20)) Region = new Region(p);
        bg = BuildBackground();
        MouseDown += Drag;
        Build();
        Opacity = 0;
        Shown += async (_, _) =>
        {
            for (double o = 0; o < 1; o += 0.09) { Opacity = o; await Task.Delay(14); }
            Opacity = 1;
            if (!await CheckUpdates()) await Inspect();
        };
    }

    static string FindRoot()
    {
        var d = AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
        if (File.Exists(Path.Combine(d, "Game.exe"))) return d;
        var p = Directory.GetParent(d)?.FullName;
        return p != null && File.Exists(Path.Combine(p, "Game.exe")) ? p : d;
    }

    // Static background rendered once; transparent children and the Stage reuse it.
    static Bitmap BuildBackground()
    {
        var bmp = new Bitmap(W, H);
        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        using (var b = new LinearGradientBrush(new Rectangle(0, 0, W, H), Color.FromArgb(5, 15, 16), Color.FromArgb(11, 38, 32), 35f))
            g.FillRectangle(b, 0, 0, W, H);
        Glow(g, 810, 260, 430, Color.FromArgb(78, 31, 184, 119));
        Glow(g, 180, 620, 380, Color.FromArgb(34, 20, 150, 150));

        using (var sb = new SolidBrush(Color.FromArgb(130, 3, 9, 10))) g.FillRectangle(sb, 0, 0, 76, H);
        using (var line = new Pen(Color.FromArgb(22, 255, 255, 255))) { g.DrawLine(line, 76, 0, 76, H); g.DrawLine(line, 76, 64, W, 64); }

        // emerald gem logo
        var gem = new[] { new PointF(38, 14), new PointF(56, 34), new PointF(38, 56), new PointF(20, 34) };
        using (var gb = new LinearGradientBrush(new RectangleF(20, 14, 36, 42), Theme.Mint, Color.FromArgb(18, 130, 88), 90f)) g.FillPolygon(gb, gem);
        using (var fb = new SolidBrush(Color.FromArgb(70, 255, 255, 255))) g.FillPolygon(fb, new[] { new PointF(38, 14), new PointF(56, 34), new PointF(38, 34) });
        using (var fp = new Pen(Color.FromArgb(120, 5, 40, 30), 1)) { g.DrawPolygon(fp, gem); g.DrawLine(fp, 20, 34, 56, 34); g.DrawLine(fp, 38, 14, 38, 56); }

        using var path = Theme.Round(new RectangleF(.5f, .5f, W - 1, H - 1), 20);
        using var border = new Pen(Color.FromArgb(60, 118, 236, 174), 1);
        g.DrawPath(border, path);
        return bmp;
    }

    static void Glow(Graphics g, float cx, float cy, float radius, Color color)
    {
        using var path = new GraphicsPath();
        path.AddEllipse(cx - radius, cy - radius, radius * 2, radius * 2);
        using var pg = new PathGradientBrush(path) { CenterColor = color, SurroundColors = new[] { Color.FromArgb(0, color) } };
        g.FillPath(pg, path);
    }

    protected override void OnPaintBackground(PaintEventArgs e) => e.Graphics.DrawImageUnscaled(bg, 0, 0);

    static Label Lbl(string t, int x, int y, int w, int h, float pt, Color c, FontStyle st = FontStyle.Regular, ContentAlignment a = ContentAlignment.TopLeft) =>
        new() { Text = t, Bounds = new Rectangle(x, y, w, h), Font = Theme.Ui(pt, st), ForeColor = c, BackColor = Color.Transparent, TextAlign = a };

    void Build()
    {
        // sidebar
        string[] glyphs = { "\uE80F", "\uE789", "\uE716", "\uE713" };
        string[] infos = { "", "Actualités Eternal Emerald", "Profil du Dresseur", "Paramètres" };
        for (int i = 0; i < glyphs.Length; i++)
        {
            int idx = i;
            var b = new GlyphButton { Glyph = glyphs[i], Active = i == 0, Bounds = new Rectangle(16, 100 + i * 58, 44, 44), Radius = 14 };
            b.Click += (_, _) => ShowPage(PageKeys[idx]);
            side.Add(b);
            Controls.Add(b);
        }
        var help = new GlyphButton { Glyph = "\uE897", Bounds = new Rectangle(16, H - 74, 44, 44), Radius = 14 };
        help.Click += (_, _) => OpenLogs();
        Controls.Add(help);

        // top bar
        Controls.Add(Lbl("ETERNAL EMERALD", 100, 20, 200, 24, 11, Theme.Mint, FontStyle.Bold));
        string[] tabs = { "ACCUEIL", "ACTUALITÉS", "COMMUNAUTÉ", "PARAMÈTRES" };
        int tx = 330;
        foreach (var t in tabs)
        {
            var tab = new NavTab { Text = t, Active = t == "ACCUEIL", Bounds = new Rectangle(tx, 14, 112, 46) };
            tabControls[t] = tab;
            tab.Click += (_, _) => ShowPage(t);
            Controls.Add(tab);
            tx += 118;
        }
        Controls.Add(Lbl("V3.0  •  STABLE", 800, 22, 150, 22, 8.5f, Theme.Muted, FontStyle.Bold, ContentAlignment.MiddleRight));
        var min = new GlyphButton { Glyph = "\uE921", Bounds = new Rectangle(W - 98, 14, 36, 36), Radius = 18 };
        min.Click += (_, _) => WindowState = FormWindowState.Minimized;
        var close = new GlyphButton { Glyph = "\uE8BB", Bounds = new Rectangle(W - 56, 14, 36, 36), Radius = 18, HoverFill = Color.FromArgb(210, 214, 69, 62) };
        close.Click += (_, _) => Close();
        Controls.Add(min); Controls.Add(close);

        int homeStart = Controls.Count;
        // hero (left)
        pill.Bounds = new Rectangle(118, 100, 340, 30);
        Controls.Add(pill);
        Controls.Add(new TitleControl { Bounds = new Rectangle(114, 142, 470, 140) });
        Controls.Add(Lbl("Une aventure connectée au cœur de Hoenn. Explorez, combattez et partagez votre histoire avec les autres Dresseurs.",
            120, 290, 440, 60, 11, Color.FromArgb(190, 200, 196)));

        play = new RoundButton { Text = "JOUER MAINTENANT", Primary = true, Bounds = new Rectangle(110, 362, 300, 66) };
        play.Click += async (_, _) => await Launch();
        diag = new RoundButton { Text = "DIAGNOSTIC", Bounds = new Rectangle(416, 362, 150, 66), Font = Theme.Ui(9.5f, FontStyle.Bold) };
        diag.Click += async (_, _) => await RunDiagnostic();
        Controls.Add(play); Controls.Add(diag);

        // stage (right)
        var stage = new Stage(() => bg,
            Path.Combine(root, "Graphics", "Pokemon", "Front", "RAYQUAZA.png"),
            Path.Combine(root, "Graphics", "Pictures", "launcher-brendan-v4.png"))
        { Bounds = new Rectangle(570, 70, 500, 390) };
        stage.MouseDown += Drag;
        Controls.Add(stage);

        // feature cards
        Controls.Add(new GlassCard { Glyph = "\uE774", Title = "MONDE EN LIGNE", Sub = "Explorez Hoenn ensemble", Bounds = new Rectangle(118, 472, 302, 86) });
        Controls.Add(new GlassCard { Glyph = "\uE74E", Title = "SAUVEGARDE AUTO", Sub = "Progression protégée", Bounds = new Rectangle(436, 472, 302, 86) });
        Controls.Add(new GlassCard { Glyph = "\uE765", Title = "CLAVIER AZERTY", Sub = "Commandes adaptées", Bounds = new Rectangle(754, 472, 302, 86) });

        pages["ACCUEIL"] = Controls.Cast<Control>().Skip(homeStart).ToList();
        BuildPages();
        // status bar
        status.SetBounds(118, 578, 520, 24); status.Font = Theme.Ui(11, FontStyle.Bold); status.ForeColor = Theme.Cream; status.BackColor = Color.Transparent; status.Text = "Vérification…";
        detail.SetBounds(118, 602, 520, 20); detail.Font = Theme.Ui(9); detail.ForeColor = Theme.Muted; detail.BackColor = Color.Transparent;
        progress.Bounds = new Rectangle(118, 638, 940, 4);
        Controls.Add(status); Controls.Add(detail); Controls.Add(progress);
        Controls.Add(Lbl("ENTRÉE  Jouer     •     F1  Diagnostic     •     ÉCHAP  Quitter", 640, 590, 418, 22, 8, Theme.Muted, FontStyle.Regular, ContentAlignment.MiddleRight));
    }

    // ───────── pages ─────────
    void ShowPage(string key)
    {
        foreach (var kv in pages) foreach (var c in kv.Value) c.Visible = kv.Key == key;
        foreach (var kv in tabControls) { kv.Value.Active = kv.Key == key; kv.Value.Invalidate(); }
        for (int i = 0; i < side.Count; i++) { side[i].Active = PageKeys[i] == key; side[i].Invalidate(); }
        Invalidate();
    }

    void BuildPages()
    {
        void Add(List<Control> l, Control c) { c.Visible = false; l.Add(c); Controls.Add(c); }
        List<Control> Page(string key, string title, string sub)
        {
            var l = new List<Control>();
            pages[key] = l;
            Add(l, Lbl(title, 118, 84, 600, 42, 22, Theme.Cream, FontStyle.Bold));
            Add(l, Lbl(sub, 120, 128, 800, 24, 10.5f, Theme.Muted));
            return l;
        }

        // Actualités (lit launchers\news.txt : TAG|Titre|Description)
        var news = Page("ACTUALITÉS", "ACTUALITÉS", "Les dernières nouvelles d'Eternal Emerald");
        int y = 172;
        foreach (var (tag, title, desc) in ReadNews().Take(4))
        {
            Add(news, new GlassCard
            {
                Glyph = tag == "NOUVEAU" ? "\uE734" : tag == "ONLINE" ? "\uE774" : "\uE946",
                Title = $"[{tag}]  {title}", Sub = desc, Bounds = new Rectangle(118, y, 940, 86)
            });
            y += 98;
        }

        // Communauté (lit launcher-links.txt : discord=…, site=…, bug=…)
        var com = Page("COMMUNAUTÉ", "COMMUNAUTÉ", "Rejoignez les autres Dresseurs de Hoenn");
        void Card(int i, string glyph, string title, string sub, string key)
        {
            var c = new GlassCard { Glyph = glyph, Title = title, Sub = sub, Clickable = true, Bounds = new Rectangle(118 + i * 319, 172, 302, 86) };
            c.Click += (_, _) => OpenLink(key);
            Add(com, c);
        }
        Card(0, "\uE8F2", "DISCORD", "Discuter avec la communauté", "discord");
        Card(1, "\uE774", "SITE OFFICIEL", "Actualités et guides", "site");
        Card(2, "\uE7BA", "SIGNALER UN BUG", "Aidez-nous à améliorer le jeu", "bug");
        Add(com, Lbl("Astuce : ajoutez vos liens dans launcher-links.txt  (discord=https://…   site=https://…   bug=https://…)", 120, 276, 940, 24, 9.5f, Theme.Muted));

        // Paramètres
        var set = Page("PARAMÈTRES", "PARAMÈTRES", "Personnalisez votre launcher");
        void Row(int i, string glyph, string title, string sub, string key, bool def, Action<bool>? after = null)
        {
            var r = new GlassCard { Glyph = glyph, Title = title, Sub = sub, ShowSwitch = true, On = Prefs.Get(key, def), Bounds = new Rectangle(118, 172 + i * 98, 940, 86) };
            r.Toggled += v => { Prefs.Set(key, v); after?.Invoke(v); };
            Add(set, r);
        }
        Row(0, "\uE7E8", "FERMER APRÈS LE LANCEMENT", "Le launcher se ferme quand le jeu démarre", "autoclose", true);
        Row(1, "\uE713", "EFFETS ANIMÉS", "Animations et parallaxe de la scène d'accueil", "fx", true);
        Row(2, "\uE77B", "MODE INVITÉ", "Lancer le jeu avec une instance invitée", "guest", guest, v => guest = v);
        void Btn(int i, string t, Action a)
        {
            var b = new RoundButton { Text = t, Font = Theme.Ui(9.5f, FontStyle.Bold), Bounds = new Rectangle(112 + i * 319, 474, 314, 64) };
            b.Click += (_, _) => a();
            Add(set, b);
        }
        Btn(0, "DOSSIER DU JEU", () => Process.Start(new ProcessStartInfo("explorer.exe", root) { UseShellExecute = true }));
        Btn(1, "JOURNAUX", OpenLogs);
        Btn(2, "RÉPARER L'INSTALLATION", () => { _ = RunDiagnostic(true); });
    }

    List<(string, string, string)> ReadNews()
    {
        var list = new List<(string, string, string)>();
        try
        {
            var f = Path.Combine(root, "launchers", "news.txt");
            if (File.Exists(f))
                foreach (var l in File.ReadAllLines(f))
                {
                    var p = l.Split('|');
                    if (p.Length >= 3) list.Add((p[0].Trim().ToUpperInvariant(), p[1].Trim(), p[2].Trim()));
                }
        }
        catch { }
        if (list.Count == 0)
        {
            list.Add(("NOUVEAU", "Nouveau launcher Eternal Emerald", "Interface repensée, diagnostic intégré et démarrage automatique du serveur."));
            list.Add(("ONLINE", "Le monde de Hoenn en ligne", "Croisez d'autres Dresseurs pendant votre aventure."));
            list.Add(("CONSEIL", "Sauvegarde automatique", "Votre progression est protégée à chaque étape."));
        }
        return list;
    }

    void OpenLink(string key)
    {
        var links = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        try
        {
            var f = Path.Combine(root, "launcher-links.txt");
            if (File.Exists(f))
                foreach (var l in File.ReadAllLines(f)) { var i = l.IndexOf('='); if (i > 0) links[l[..i].Trim()] = l[(i + 1)..].Trim(); }
        }
        catch { }
        if (links.TryGetValue(key, out var url) && (url.StartsWith("https://") || url.StartsWith("http://")))
            Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
        else Info("Lien non configuré. Ajoutez une ligne « " + key + "=https://… » dans launcher-links.txt, à côté de Game.exe.");
    }

    // ───────── logic ─────────
    async Task<bool> CheckUpdates()
    {
        play.Enabled=false;diag.Enabled=false;status.Text="Recherche des mises à jour…";detail.Text="Connexion sécurisée à GitHub";progress.Value=4;
        try
        {
            var service=new UpdateService(root);var result=await service.Check();
            if(result.manifest==null||result.changed.Count==0){status.Text="Jeu à jour";detail.Text=result.manifest==null?"Aucun manifeste disponible":$"Version {result.manifest.version}";progress.Value=100;diag.Enabled=true;return false;}
            updateBlocking=result.manifest.mandatory;status.Text=$"Mise à jour {result.manifest.version} disponible";detail.Text=$"Téléchargement de {result.changed.Count} fichier(s) requis";pill.SetState("MISE À JOUR OBLIGATOIRE",Theme.Gold);
            await service.DownloadAndApply(result.manifest,result.changed,(pct,name)=>{progress.Value=pct;status.Text=$"Mise à jour en cours… {pct} %";detail.Text=name;},Environment.ProcessId);
            status.Text="Installation de la mise à jour…";detail.Text="Le launcher va redémarrer automatiquement";await Task.Delay(700);Close();return true;
        }
        catch(HttpRequestException ex){CrashLog.Write(ex);status.Text="Vérification GitHub indisponible";detail.Text="Le jeu peut être lancé avec la version installée";progress.Value=100;diag.Enabled=true;return false;}
        catch(Exception ex){CrashLog.Write(ex);updateBlocking=true;status.Text="Mise à jour impossible";detail.Text=ex.Message;progress.Value=0;diag.Enabled=true;MessageBox.Show(this,"La mise à jour obligatoire n'a pas pu être installée.\n\n"+ex.Message+"\n\nLe bouton Jouer reste bloqué pour éviter une version incompatible.","Eternal Emerald — mise à jour",MessageBoxButtons.OK,MessageBoxIcon.Error);return false;}
    }

    async Task Inspect()
    {
        bool files = new[] { "Game.exe", "Game.rxdata", "mkxp.json", "launchers" }.All(x => File.Exists(Path.Combine(root, x)) || Directory.Exists(Path.Combine(root, x)));
        int ms = await Ping();
        bool online = ms >= 0;
        pill.SetState(online ? $"TOUS LES SERVICES ACTIFS  •  {ms} ms" : "PRÊT AU DÉMARRAGE", online ? Theme.Mint : Theme.Gold);
        bool running = Process.GetProcessesByName("Game").Length > 0;
        status.Text = !files ? "Installation incomplète" : running ? "Le jeu est déjà lancé" : "Vous êtes prêt à jouer";
        detail.Text = online ? "Serveur connecté • version 1.0" : "Le serveur démarrera automatiquement";
        progress.Value = files ? 100 : 12;
        play.Text = running ? "JEU EN COURS" : "JOUER MAINTENANT";
        play.Enabled = files && !running && !updateBlocking;
        play.Invalidate();
    }

    async Task Launch()
    {
        if(updateBlocking){Info("La mise à jour obligatoire doit être installée avant de lancer le jeu.");return;}
        if (launching) return;
        launching = true; play.Enabled = diag.Enabled = false; progress.Value = 8;
        try
        {
            status.Text = "Préparation de Hoenn…"; detail.Text = "Vérification des services locaux";
            if (!await Port())
            {
                pill.SetState("DÉMARRAGE DU SERVEUR…", Theme.Gold);
                string script = Path.Combine(root, "launchers", "Start-Eternal-Emerald-MMO.ps1");
                if (!File.Exists(script)) throw new FileNotFoundException("Le service de jeu est introuvable.");
                var arg = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" -NoGame" + (guest ? " -Guest" : "");
                var psi = new ProcessStartInfo("powershell.exe", arg)
                {
                    WorkingDirectory = root, UseShellExecute = false, CreateNoWindow = true,
                    RedirectStandardOutput = true, RedirectStandardError = true
                };
                using var p = Process.Start(psi) ?? throw new InvalidOperationException("Le service n'a pas pu démarrer.");
                var o = p.StandardOutput.ReadToEndAsync();
                var er = p.StandardError.ReadToEndAsync();
                progress.Value = 34;
                await p.WaitForExitAsync();
                string output = (await o) + Environment.NewLine + (await er);
                Directory.CreateDirectory(Path.Combine(root, ".runtime"));
                File.WriteAllText(Path.Combine(root, ".runtime", "launcher.log"), output);
                if (p.ExitCode != 0)
                    throw new InvalidOperationException(output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries).LastOrDefault() ?? "Le serveur n'a pas pu démarrer.");
            }
            progress.Value = 82;
            pill.SetState("TOUS LES SERVICES ACTIFS", Theme.Mint);
            status.Text = "Ouverture du jeu…";
            var info = new ProcessStartInfo(Path.Combine(root, "Game.exe")) { WorkingDirectory = root, UseShellExecute = false };
            if (guest) info.Environment["PEMK_INSTANCE"] = "guest";
            Process.Start(info);
            progress.Value = 100; status.Text = "Bonne aventure !"; detail.Text = "Bienvenue à Hoenn";
            await Task.Delay(1300);
            if (Prefs.Get("autoclose", true)) Close();
            else { launching = false; await Inspect(); }
        }
        catch (Exception ex)
        {
            progress.Value = 0; status.Text = "Le lancement a échoué"; detail.Text = ex.Message;
            pill.SetState("SERVICE INDISPONIBLE", Theme.Danger);
            MessageBox.Show(this, ex.Message + "\n\nOuvrez les journaux pour obtenir le détail.", "Eternal Emerald", MessageBoxButtons.OK, MessageBoxIcon.Error);
            play.Enabled = diag.Enabled = true; launching = false;
        }
    }

    static async Task<int> Ping()
    {
        var sw = Stopwatch.StartNew();
        return await Port() ? (int)Math.Max(1, sw.ElapsedMilliseconds) : -1;
    }

    static async Task<bool> Port()
    {
        using var c = new TcpClient();
        using var t = new CancellationTokenSource(350);
        try { await c.ConnectAsync("127.0.0.1", 9998, t.Token); return true; } catch { return false; }
    }

    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (keyData == Keys.Enter && play.Enabled && !launching) { _ = Launch(); return true; }
        if (keyData == Keys.F1) { _ = RunDiagnostic(); return true; }
        if (keyData == Keys.Escape) { Close(); return true; }
        return base.ProcessCmdKey(ref msg, keyData);
    }

    async Task RunDiagnostic(bool repair = false)
    {
        string script = Path.Combine(root, "launchers", "Repair-Eternal-Emerald.ps1");
        if (!File.Exists(script)) { Info("L'outil de diagnostic est introuvable."); return; }
        diag.Enabled = false;
        status.Text = repair ? "Réparation en cours…" : "Diagnostic en cours…";
        try
        {
            var args = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\"" + (repair ? " -Repair" : "");
            var psi = new ProcessStartInfo("powershell.exe", args)
            {
                WorkingDirectory = root, UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true
            };
            using var p = Process.Start(psi) ?? throw new InvalidOperationException("Le diagnostic n'a pas pu démarrer.");
            var output = p.StandardOutput.ReadToEndAsync();
            var error = p.StandardError.ReadToEndAsync();
            await p.WaitForExitAsync();
            string rp = Path.Combine(root, ".runtime", "diagnostic.txt");
            string report = File.Exists(rp) ? File.ReadAllText(rp) : (await output) + Environment.NewLine + (await error);
            if (p.ExitCode == 0)
            {
                status.Text = "Installation vérifiée";
                MessageBox.Show(this, report, "Diagnostic — installation prête", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else if (!repair && MessageBox.Show(this, report + "\n\nVoulez-vous tenter la réparation automatique ?", "Diagnostic", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                await RunDiagnostic(true);
            else
            {
                status.Text = "Réparation nécessaire";
                MessageBox.Show(this, report, "Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        catch (Exception ex)
        {
            status.Text = "Diagnostic impossible";
            MessageBox.Show(this, ex.Message, "Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally { diag.Enabled = true; }
    }

    void OpenLogs()
    {
        string d = Path.Combine(root, ".runtime");
        Directory.CreateDirectory(d);
        Process.Start(new ProcessStartInfo("explorer.exe", d) { UseShellExecute = true });
    }

    void Info(string t) => MessageBox.Show(this, t, "Eternal Emerald", MessageBoxButtons.OK, MessageBoxIcon.Information);

    void Drag(object? s, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); }
    }
    [DllImport("user32.dll")] static extern bool ReleaseCapture();
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, int m, int w, int l);

    protected override void Dispose(bool disposing)
    {
        if (disposing) bg.Dispose();
        base.Dispose(disposing);
    }
}
