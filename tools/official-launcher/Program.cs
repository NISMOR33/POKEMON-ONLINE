using System.Diagnostics;
using System.Drawing.Drawing2D;
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
                "Pokémon Online", MessageBoxButtons.OK, MessageBoxIcon.Error);
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

internal sealed class UpdateFile { public string path { get; set; }=""; public string url { get; set; }=""; public string sha256 { get; set; }=""; public long bytes { get; set; } }
internal sealed class UpdateManifest { public string version { get; set; }=""; public bool mandatory { get; set; }=true; public List<UpdateFile> files { get; set; }=new(); }
internal sealed class UpdateService
{
    const string DefaultManifest="https://raw.githubusercontent.com/NISMOR33/POKEMON-ONLINE/main/update-manifest.json";
    readonly string root;readonly HttpClient http=new(){Timeout=TimeSpan.FromMinutes(15)};
    public UpdateService(string gameRoot){root=gameRoot;http.DefaultRequestHeaders.UserAgent.ParseAdd("Eternal-Emerald-Launcher/3.1.1");}
    public async Task<(UpdateManifest? manifest,List<UpdateFile> changed)> Check()
    {
        string endpoint=DefaultManifest,customFile=Path.Combine(root,"launcher-update-url.txt");if(File.Exists(customFile)){var custom=File.ReadAllText(customFile).Trim();if(Uri.TryCreate(custom,UriKind.Absolute,out _))endpoint=custom;}
        var manifest=JsonSerializer.Deserialize<UpdateManifest>(await http.GetStringAsync(endpoint),new JsonSerializerOptions{PropertyNameCaseInsensitive=true})??throw new InvalidDataException("Le manifeste de mise à jour est invalide.");var changed=new List<UpdateFile>();
        foreach(var f in manifest.files){string target=SafeTarget(f.path);if(!File.Exists(target)||!string.Equals(await Hash(target),f.sha256,StringComparison.OrdinalIgnoreCase))changed.Add(f);}return(manifest,changed);
    }
    public async Task DownloadAndApply(UpdateManifest manifest,List<UpdateFile> files,Action<int,string> progress,int launcherPid)
    {
        string stageRoot=Path.Combine(root,".runtime","update",manifest.version);Directory.CreateDirectory(stageRoot);var plan=new List<object>();long total=Math.Max(1,files.Sum(f=>Math.Max(1,f.bytes))),done=0;
        foreach(var f in files){string target=SafeTarget(f.path),stage=Path.Combine(stageRoot,Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(f.path)))+".download");using var response=await http.GetAsync(f.url,HttpCompletionOption.ResponseHeadersRead);response.EnsureSuccessStatusCode();await using(var input=await response.Content.ReadAsStreamAsync())await using(var output=new FileStream(stage,FileMode.Create,FileAccess.Write,FileShare.None)){var buffer=new byte[131072];int read;while((read=await input.ReadAsync(buffer))>0){await output.WriteAsync(buffer.AsMemory(0,read));done+=read;progress((int)Math.Clamp(done*100/total,0,100),Path.GetFileName(f.path));}}if(!string.Equals(await Hash(stage),f.sha256,StringComparison.OrdinalIgnoreCase)){File.Delete(stage);throw new InvalidDataException($"La vérification de {f.path} a échoué.");}plan.Add(new{stage,target,sha256=f.sha256});}
        string planFile=Path.Combine(stageRoot,"plan.json");File.WriteAllText(planFile,JsonSerializer.Serialize(plan));string helper=Path.Combine(root,"launchers","Apply-Eternal-Emerald-Update.ps1");if(!File.Exists(helper))throw new FileNotFoundException("Le programme d'installation de mise à jour est introuvable.",helper);Process.Start(new ProcessStartInfo("powershell.exe",$"-NoProfile -ExecutionPolicy Bypass -File \"{helper}\" -Plan \"{planFile}\" -LauncherPid {launcherPid}"){WorkingDirectory=root,UseShellExecute=false,CreateNoWindow=true});
    }
    string SafeTarget(string relative){if(string.IsNullOrWhiteSpace(relative)||Path.IsPathRooted(relative))throw new InvalidDataException("Chemin de mise à jour interdit.");string full=Path.GetFullPath(Path.Combine(root,relative.Replace('/',Path.DirectorySeparatorChar))),prefix=root.TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar;if(!full.StartsWith(prefix,StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("Chemin de mise à jour interdit.");return full;}
    static async Task<string> Hash(string path){await using var s=File.OpenRead(path);using var h=SHA256.Create();return Convert.ToHexString(await h.ComputeHashAsync(s)).ToLowerInvariant();}
}

internal sealed class Zone
{
    public Rectangle R;
    public string Label = "";
    public Action Click = () => { };
    public bool Enabled = true;
    public int Radius = 14;
}

internal sealed class LauncherForm : Form
{
    // The whole UI is drawn in "design space" (the 1672x940 reference artwork) and scaled to the window.
    const int W = 1280, H = 720, IW = 1672, IH = 940;
    const float S = W / (float)IW;
    const int OX = 500, OY = 64, OW = 650, OH = 640; // overlay panel (news / settings)

    static readonly Color Cream = Color.FromArgb(242, 238, 211), Mint = Color.FromArgb(150, 245, 170),
        Muted = Color.FromArgb(160, 192, 176), Gold = Color.FromArgb(239, 198, 86), Danger = Color.FromArgb(240, 104, 92),
        Leaf = Color.FromArgb(88, 190, 90);
    static readonly Rectangle[] UiRects =
    {
        new(30, 30, 740, 330), new(40, 388, 428, 258), new(40, 690, 560, 190), new(1172, 335, 478, 325),
        new(1450, 12, 210, 62), new(1384, 854, 270, 60)
    };
    static readonly (string key, string title, string sub, bool def)[] Opts =
    {
        ("autoclose", "Fermer après le lancement", "Le launcher se ferme quand le jeu démarre", true),
        ("fx", "Effets animés", "Particules et reflets sur l'écran d'accueil", true),
        ("guest", "Mode invité", "Lancer le jeu avec une instance invitée", false)
    };

    static Font Px(string fam, float px, FontStyle st = FontStyle.Regular) => new(fam, px, st, GraphicsUnit.Pixel);
    readonly Font fMenu = Px("Segoe UI Semibold", 30), fTitle = Px("Segoe UI Black", 40), fBody = Px("Segoe UI Semibold", 27),
        fSub = Px("Segoe UI", 19), fTag = Px("Segoe UI Black", 15), fBtn = Px("Segoe UI Black", 22), fStatus = Px("Segoe UI Semibold", 26),
        fSrv = Px("Segoe UI Semibold", 21), fSrvS = Px("Segoe UI", 15), fGlyph = Px("Segoe MDL2 Assets", 32), fGlyphS = Px("Segoe MDL2 Assets", 20);

    readonly string root;
    bool guest;
    Bitmap? bg;
    string page = "home";
    float ovT, progCur, progTarget;
    int tick;
    readonly List<Zone> baseZones = new();
    List<Zone> zones = new();
    Zone playZone = new();
    Zone? hot, down;
    string statusText = "Vérification…", serverText = "Connexion…";
    Color serverTint = Gold;
    bool playEnabled = true, launching, online, diagBusy, updateBlocking;
    int ms = -1;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 33 };
    readonly (float x, float y, float vx, float vy, float sz, float ph)[] dust = new (float, float, float, float, float, float)[42];

    public LauncherForm(bool isGuest)
    {
        root = FindRoot();
        Prefs.Load(root);
        guest = isGuest || Prefs.Get("guest", false);
        Text = "Pokémon Online";
        FormBorderStyle = FormBorderStyle.None;
        AutoScaleMode = AutoScaleMode.None;
        ClientSize = new Size(W, H);
        MinimumSize = MaximumSize = Size;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(10, 30, 20);
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        if (File.Exists(Path.Combine(root, "Game.ico"))) Icon = new Icon(Path.Combine(root, "Game.ico"));

        LoadBackground();
        BuildZones();
        SetPage("home");
        var rnd = new Random(11);
        for (int i = 0; i < dust.Length; i++)
            dust[i] = (rnd.Next(IW), rnd.Next(IH), 0.25f + (float)rnd.NextDouble() * 0.5f, 0.2f + (float)rnd.NextDouble() * 0.7f, 2f + (float)rnd.NextDouble() * 4f, (float)rnd.NextDouble() * 6f);
        timer.Tick += OnTick;
        timer.Start();

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

    void LoadBackground()
    {
        foreach (var name in new[] { "launcher-bg.png", "launcher-bg.jpg" })
        {
            var path = Path.Combine(root, "Graphics", "Pictures", name);
            if (!File.Exists(path)) continue;
            using var img = Image.FromFile(path);
            bg = new Bitmap(W, H);
            using var g = Graphics.FromImage(bg);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.DrawImage(img, 0, 0, W, H);
            return;
        }
    }

    // ───────── zones (hit areas in design space) ─────────
    void BuildZones()
    {
        Zone Add(int x, int y, int w, int h, string label, Action a, int rad = 14)
        {
            var z = new Zone { R = new Rectangle(x, y, w, h), Label = label, Click = a, Radius = rad };
            baseZones.Add(z);
            return z;
        }
        Add(58, 411, 388, 70, "Accueil", () => SetPage("home"));
        Add(58, 485, 388, 70, "Actualités", () => SetPage("news"));
        Add(58, 560, 388, 70, "Paramètres", () => SetPage("settings"));
        playZone = Add(60, 705, 520, 125, "JOUER", () => { _ = Launch(); }, 20);
        Add(1190, 413, 440, 120, "News 1", () => SetPage("news"));
        Add(1190, 535, 440, 115, "News 2", () => SetPage("news"));
        Add(1456, 18, 50, 50, "⚙", () => SetPage("settings"), 10);
        Add(1530, 18, 50, 50, "—", () => WindowState = FormWindowState.Minimized, 10);
        Add(1603, 18, 52, 50, "×", Close, 10);
    }

    void SetPage(string p)
    {
        page = p;
        hot = down = null;
        zones = new List<Zone>(baseZones);
        if (p == "home") return;
        zones.Add(new Zone { R = new Rectangle(OX + OW - 70, OY + 16, 48, 48), Label = "×", Radius = 8, Click = () => SetPage("home") });
        if (p != "settings") return;
        for (int i = 0; i < Opts.Length; i++)
        {
            var o = Opts[i];
            zones.Add(new Zone
            {
                R = new Rectangle(OX + 24, OY + 110 + i * 118, OW - 48, 100), Radius = 12,
                Click = () =>
                {
                    bool v = !OptValue(o.key, o.def);
                    if (o.key == "guest") guest = v;
                    Prefs.Set(o.key, v);
                }
            });
        }
        void Btn(int i, string t, Action a) =>
            zones.Add(new Zone { R = new Rectangle(OX + 24 + i * 206, 560, 190, 64), Label = t, Radius = 10, Click = a });
        Btn(0, "DOSSIER DU JEU", () => Process.Start(new ProcessStartInfo("explorer.exe", root) { UseShellExecute = true }));
        Btn(1, "JOURNAUX", OpenLogs);
        Btn(2, "RÉPARER", () => { _ = RunDiagnostic(true); });
    }

    bool OptValue(string key, bool def) => key == "guest" ? guest : Prefs.Get(key, def);

    // ───────── input ─────────
    protected override void OnMouseMove(MouseEventArgs e)
    {
        float x = e.X / S, y = e.Y / S;
        hot = zones.LastOrDefault(z => z.R.Contains((int)x, (int)y));
        Cursor = hot != null && hot.Enabled ? Cursors.Hand : Cursors.Default;
        base.OnMouseMove(e);
    }
    protected override void OnMouseLeave(EventArgs e) { hot = null; base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left)
        {
            if (hot != null) down = hot;
            else { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); }
        }
        base.OnMouseDown(e);
    }
    protected override void OnMouseUp(MouseEventArgs e)
    {
        var z = down; down = null;
        if (z != null && z == hot && z.Enabled) z.Click();
        base.OnMouseUp(e);
    }
    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (keyData == Keys.Enter && playEnabled && !launching) { _ = Launch(); return true; }
        if (keyData == Keys.F1) { _ = RunDiagnostic(); return true; }
        if (keyData == Keys.Escape) { if (page != "home") SetPage("home"); else Close(); return true; }
        return base.ProcessCmdKey(ref msg, keyData);
    }
    [DllImport("user32.dll")] static extern bool ReleaseCapture();
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, int m, int w, int l);

    void OnTick(object? s, EventArgs e)
    {
        if (WindowState == FormWindowState.Minimized) return;
        tick++;
        progCur += (progTarget - progCur) * 0.14f;
        if (Math.Abs(progTarget - progCur) < 0.2f) progCur = progTarget;
        float tgt = page == "home" ? 0 : 1;
        ovT += (tgt - ovT) * 0.22f;
        if (Math.Abs(tgt - ovT) < 0.01f) ovT = tgt;
        if (Prefs.Get("fx", true))
            for (int i = 0; i < dust.Length; i++)
            {
                var d = dust[i];
                d.y -= d.vy; d.x += d.vx + (float)Math.Sin(tick * 0.02 + d.ph) * 0.4f;
                if (d.y < -10) { d.y = IH + 10; d.x = (d.x * 3 + 97) % IW; }
                if (d.x > IW + 10) d.x = -10;
                dust[i] = d;
            }
        Invalidate();
    }

    // ───────── painting ─────────
    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        if (bg != null) g.DrawImageUnscaled(bg, 0, 0);
        else
        {
            using var b = new LinearGradientBrush(ClientRectangle, Color.FromArgb(30, 100, 50), Color.FromArgb(6, 25, 18), 60f);
            g.FillRectangle(b, ClientRectangle);
        }
        g.ScaleTransform(S, S);
        if (bg == null) FallbackUi(g);
        DrawDust(g);
        if (page != "home")
        {
            MenuRow(g, 0, "Accueil", "\uE80F", false);
            if (page == "news") MenuRow(g, 1, "Actualités", "\uE789", true);
            if (page == "settings") MenuRow(g, 2, "Paramètres", "\uE713", true);
        }
        DrawPlay(g);
        DrawStatus(g);
        DrawServer(g);
        if (ovT > 0.02f) DrawOverlay(g);
        DrawHover(g);
    }

    static void Txt(Graphics g, string t, Font f, Color c, RectangleF r, float a = 1f, StringAlignment ha = StringAlignment.Near,
        StringAlignment va = StringAlignment.Center, bool shadow = false)
    {
        using var sf = new StringFormat { Alignment = ha, LineAlignment = va, Trimming = StringTrimming.EllipsisWord };
        if (shadow)
        {
            using var sb = new SolidBrush(Color.FromArgb((int)(150 * a), 0, 20, 10));
            g.DrawString(t, f, sb, new RectangleF(r.X + 2, r.Y + 2, r.Width, r.Height), sf);
        }
        using var b = new SolidBrush(Color.FromArgb(Math.Clamp((int)(c.A * a), 0, 255), c));
        g.DrawString(t, f, b, r, sf);
    }

    static GraphicsPath Round(RectangleF r, float radius)
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

    void FallbackUi(Graphics g)
    {
        Txt(g, "Image introuvable : Graphics\\Pictures\\launcher-bg.png", fBody, Cream, new RectangleF(60, 40, 1200, 50));
        foreach (var z in baseZones)
        {
            using var pen = new Pen(Color.FromArgb(120, 255, 255, 255), 2);
            g.DrawRectangle(pen, z.R);
            Txt(g, z.Label, fMenu, Cream, z.R, 1f, StringAlignment.Center);
        }
    }

    void DrawDust(Graphics g)
    {
        if (!Prefs.Get("fx", true)) return;
        using var reg = new Region(new RectangleF(0, 0, IW, IH));
        foreach (var r in UiRects) reg.Exclude(r);
        g.Clip = reg;
        foreach (var d in dust)
        {
            int a = (int)(110 + 80 * Math.Sin(tick * 0.07 + d.ph));
            using var glow = new SolidBrush(Color.FromArgb(Math.Clamp(a / 4, 0, 255), 255, 250, 190));
            using var core = new SolidBrush(Color.FromArgb(Math.Clamp(a, 0, 255), 255, 252, 215));
            g.FillEllipse(glow, d.x - d.sz, d.y - d.sz, d.sz * 2, d.sz * 2);
            g.FillEllipse(core, d.x - d.sz / 2, d.y - d.sz / 2, d.sz, d.sz);
        }
        g.ResetClip();
    }

    void MenuRow(Graphics g, int idx, string text, string glyph, bool active)
    {
        var r = new RectangleF(58, 411 + idx * 74.5f, 388, 70);
        using var path = Round(r, 12);
        if (active)
        {
            using var br = new LinearGradientBrush(r, Color.FromArgb(104, 206, 72), Color.FromArgb(46, 138, 50), 90f);
            using var pen = new Pen(Color.FromArgb(200, 248, 150), 3);
            g.FillPath(br, path);
            g.DrawPath(pen, path);
        }
        else
        {
            using var br = new SolidBrush(Color.FromArgb(14, 48, 37));
            g.FillPath(br, path);
        }
        var fg = active ? Color.White : Color.FromArgb(205, 225, 200);
        Txt(g, glyph, fGlyph, fg, new RectangleF(r.X + 22, r.Y, 56, r.Height), 1f, StringAlignment.Center);
        Txt(g, text, fMenu, fg, new RectangleF(r.X + 100, r.Y, 240, r.Height));
        Txt(g, "\uE76C", fGlyphS, fg, new RectangleF(r.Right - 56, r.Y, 36, r.Height), 1f, StringAlignment.Center);
    }

    void DrawPlay(Graphics g)
    {
        var r = playZone.R;
        using var path = Round(r, 20);
        if (playEnabled && !launching && Prefs.Get("fx", true))
        {
            float t = (tick % 130) / 130f, pos = r.X + (t * 1.7f - 0.35f) * r.Width;
            var band = new RectangleF(pos - 60, r.Y, 120, r.Height);
            g.SetClip(path);
            using var sb = new LinearGradientBrush(band, Color.White, Color.White, 0f)
            {
                InterpolationColors = new ColorBlend
                {
                    Colors = new[] { Color.FromArgb(0, 255, 255, 255), Color.FromArgb(80, 255, 255, 255), Color.FromArgb(0, 255, 255, 255) },
                    Positions = new[] { 0f, 0.5f, 1f }
                }
            };
            g.FillRectangle(sb, band);
            g.ResetClip();
        }
        if (!playEnabled || launching)
        {
            using var dim = new SolidBrush(Color.FromArgb(120, 0, 15, 8));
            g.FillPath(dim, path);
        }
    }

    void DrawStatus(Graphics g)
    {
        var r = new RectangleF(150, 836, 340, 42);
        using (var path = Round(r, 10))
        using (var fill = new SolidBrush(Color.FromArgb(242, 8, 30, 22)))
        using (var pen = new Pen(Leaf, 2))
        {
            g.FillPath(fill, path);
            g.DrawPath(pen, path);
        }
        Txt(g, statusText, fStatus, Cream, new RectangleF(r.X, r.Y - 2, r.Width, r.Height - (launching ? 6 : 0)), 1f, StringAlignment.Center);
        if (launching)
        {
            using var track = new SolidBrush(Color.FromArgb(60, 255, 255, 255));
            g.FillRectangle(track, 166, 868, 308, 5);
            float w = 308 * progCur / 100f;
            if (w > 1)
            {
                using var br = new LinearGradientBrush(new RectangleF(166, 868, Math.Max(w, 2), 5), Color.FromArgb(60, 170, 70), Mint, 0f);
                g.FillRectangle(br, 166, 868, w, 5);
            }
        }
    }

    void DrawServer(Graphics g)
    {
        var r = new RectangleF(1386, 856, 264, 54);
        using (var path = Round(r, 10))
        using (var fill = new SolidBrush(Color.FromArgb(244, 8, 30, 22)))
        using (var pen = new Pen(Leaf, 2))
        {
            g.FillPath(fill, path);
            g.DrawPath(pen, path);
        }
        float pulse = (float)(Math.Sin(tick * 0.12) + 1) / 2f, rr = 9 + pulse * 7;
        using (var ring = new SolidBrush(Color.FromArgb((int)(100 * (1 - pulse)), serverTint))) g.FillEllipse(ring, 1416 - rr, 883 - rr, rr * 2, rr * 2);
        using (var dot = new SolidBrush(serverTint)) g.FillEllipse(dot, 1407, 874, 18, 18);
        Txt(g, serverText, fSrv, Cream, new RectangleF(1438, 861, 170, 28));
        Txt(g, online ? $"Latence {ms} ms" : "Aucune connexion", fSrvS, Muted, new RectangleF(1438, 886, 170, 20));
        int lit = !online ? 0 : ms < 40 ? 3 : ms < 100 ? 2 : 1;
        for (int i = 0; i < 3; i++)
        {
            int h = 12 + i * 8;
            using var b = new SolidBrush(i < lit ? serverTint : Color.FromArgb(70, 255, 255, 255));
            g.FillRectangle(b, 1612 + i * 12, 892 - h, 8, h);
        }
    }

    void PixButton(Graphics g, RectangleF r, string text, float a)
    {
        using var path = Round(r, 10);
        using var br = new LinearGradientBrush(r, Color.FromArgb((int)(255 * a), 96, 200, 74), Color.FromArgb((int)(255 * a), 40, 125, 46), 90f);
        using var pen = new Pen(Color.FromArgb((int)(255 * a), 6, 40, 22), 3);
        using var hi = new Pen(Color.FromArgb((int)(120 * a), 220, 255, 170), 2);
        g.FillPath(br, path);
        g.DrawPath(pen, path);
        g.DrawLine(hi, r.X + 12, r.Y + 6, r.Right - 12, r.Y + 6);
        Txt(g, text, fBtn, Color.White, r, a, StringAlignment.Center, StringAlignment.Center, true);
    }

    void DrawOverlay(Graphics g)
    {
        float a = ovT;
        var st = g.Save();
        g.TranslateTransform(0, (1 - a) * 22);

        var panel = new RectangleF(OX, OY, OW, OH);
        using (var path = Round(panel, 12))
        {
            using var fill = new SolidBrush(Color.FromArgb((int)(240 * a), 9, 34, 26));
            using var outer = new Pen(Color.FromArgb((int)(255 * a), 4, 18, 14), 9);
            g.FillPath(fill, path);
            g.DrawPath(outer, path);
        }
        using (var inner = new Pen(Color.FromArgb((int)(255 * a), 92, 200, 94), 3))
        using (var path2 = Round(RectangleF.Inflate(panel, -5, -5), 9)) g.DrawPath(inner, path2);
        using (var line = new Pen(Color.FromArgb((int)(70 * a), 190, 245, 150), 2))
        {
            g.DrawLine(line, OX + 28, OY + 88, OX + OW - 28, OY + 88);
        }

        Txt(g, page == "news" ? "ACTUALITÉS" : "PARAMÈTRES", fTitle, Color.FromArgb(205, 252, 170), new RectangleF(OX + 32, OY + 18, 480, 64), a, StringAlignment.Near, StringAlignment.Center, true);
        PixButton(g, new RectangleF(OX + OW - 70, OY + 16, 48, 48), "×", a);

        if (page == "news")
        {
            int i = 0;
            foreach (var (tag, title, desc) in ReadNews().Take(4))
            {
                var row = new RectangleF(OX + 24, OY + 110 + i * 124, OW - 48, 116);
                var tc = tag == "NOUVEAU" ? Gold : tag == "ONLINE" ? Mint : Color.FromArgb(140, 205, 255);
                using (var path = Round(row, 12))
                using (var fill = new SolidBrush(Color.FromArgb((int)(230 * a), 18, 58, 44)))
                using (var pen = new Pen(Color.FromArgb((int)(190 * a), 60, 140, 80), 2))
                {
                    g.FillPath(fill, path);
                    g.DrawPath(pen, path);
                }
                var ic = new RectangleF(row.X + 18, row.Y + 22, 72, 72);
                using (var path = Round(ic, 10))
                using (var fill = new SolidBrush(Color.FromArgb((int)(60 * a), tc)))
                using (var pen = new Pen(Color.FromArgb((int)(200 * a), tc), 2))
                {
                    g.FillPath(fill, path);
                    g.DrawPath(pen, path);
                }
                Txt(g, tag == "NOUVEAU" ? "\uE734" : tag == "ONLINE" ? "\uE774" : "\uE946", fGlyph, tc, ic, a, StringAlignment.Center);
                Txt(g, tag, fTag, tc, new RectangleF(row.X + 110, row.Y + 10, 440, 20), a);
                Txt(g, title, fBody, Cream, new RectangleF(row.X + 110, row.Y + 28, 460, 34), a);
                Txt(g, desc, fSub, Muted, new RectangleF(row.X + 110, row.Y + 62, 464, 50), a, StringAlignment.Near, StringAlignment.Near);
                i++;
            }
        }
        else
        {
            for (int i = 0; i < Opts.Length; i++)
            {
                var o = Opts[i];
                var row = new RectangleF(OX + 24, OY + 110 + i * 118, OW - 48, 100);
                using (var path = Round(row, 12))
                using (var fill = new SolidBrush(Color.FromArgb((int)(230 * a), 18, 58, 44)))
                using (var pen = new Pen(Color.FromArgb((int)(190 * a), 60, 140, 80), 2))
                {
                    g.FillPath(fill, path);
                    g.DrawPath(pen, path);
                }
                Txt(g, o.title, fBody, Cream, new RectangleF(row.X + 24, row.Y + 14, 420, 38), a);
                Txt(g, o.sub, fSub, Muted, new RectangleF(row.X + 24, row.Y + 52, 440, 34), a);
                bool on = OptValue(o.key, o.def);
                var t = new RectangleF(row.Right - 116, row.Y + 28, 92, 44);
                using (var path = Round(t, 8))
                using (var fill = new SolidBrush(Color.FromArgb((int)(255 * a), on ? Color.FromArgb(70, 180, 70) : Color.FromArgb(40, 62, 54))))
                using (var pen = new Pen(Color.FromArgb((int)(255 * a), on ? Color.FromArgb(190, 245, 140) : Color.FromArgb(90, 112, 100)), 3))
                {
                    g.FillPath(fill, path);
                    g.DrawPath(pen, path);
                }
                using var knob = new SolidBrush(Color.FromArgb((int)(255 * a), on ? Color.White : Color.FromArgb(150, 165, 155)));
                g.FillRectangle(knob, on ? t.Right - 40 : t.X + 6, t.Y + 6, 34, 32);
            }
            Txt(g, "OUTILS", fTag, Muted, new RectangleF(OX + 28, 526, 200, 24), a);
            string[] names = { "DOSSIER DU JEU", "JOURNAUX", "RÉPARER" };
            for (int i = 0; i < 3; i++) PixButton(g, new RectangleF(OX + 24 + i * 206, 560, 190, 64), names[i], a);
        }
        g.Restore(st);
    }

    void DrawHover(Graphics g)
    {
        if (hot == null || !hot.Enabled) return;
        bool pressed = down == hot;
        using var path = Round(hot.R, hot.Radius);
        using (var glow = new Pen(Color.FromArgb(pressed ? 20 : 45, 255, 255, 220), 12)) g.DrawPath(glow, path);
        using (var fill = new SolidBrush(Color.FromArgb(pressed ? 8 : 26, pressed ? 0 : 255, pressed ? 0 : 255, pressed ? 0 : 255))) g.FillPath(fill, path);
        using (var pen = new Pen(Color.FromArgb(190, 255, 255, 235), 3)) g.DrawPath(pen, path);
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
            list.Add(("NOUVEAU", "Bienvenue dans Pokémon Online", "Un nouveau launcher, un monde partagé et une aventure à vivre à plusieurs."));
            list.Add(("ONLINE", "Explorez Hoenn avec vos amis", "Croisez d'autres Dresseurs, combattez et échangez pendant votre voyage."));
            list.Add(("CONSEIL", "Sauvegarde automatique", "Votre progression est protégée à chaque étape de l'aventure."));
        }
        return list;
    }

    // ───────── logic ─────────
    void SetServer(string text, Color tint) { serverText = text; serverTint = tint; }

    async Task<bool> CheckUpdates()
    {
        playEnabled=playZone.Enabled=false;statusText="Recherche des mises à jour…";SetServer("Connexion à GitHub…",Gold);progTarget=4;
        try{var service=new UpdateService(root);var result=await service.Check();if(result.manifest==null||result.changed.Count==0){statusText="Jeu à jour";SetServer(result.manifest==null?"Aucun manifeste":$"Version {result.manifest.version}",Mint);progTarget=100;return false;}updateBlocking=result.manifest.mandatory;statusText=$"Mise à jour {result.manifest.version}";SetServer("Mise à jour obligatoire",Gold);await service.DownloadAndApply(result.manifest,result.changed,(pct,name)=>{progTarget=pct;statusText=$"Téléchargement… {pct} % — {name}";Invalidate();},Environment.ProcessId);statusText="Installation et redémarrage…";await Task.Delay(700);Close();return true;}
        catch(HttpRequestException ex){CrashLog.Write(ex);statusText="GitHub temporairement indisponible";SetServer("Version installée utilisable",Gold);progTarget=100;return false;}
        catch(Exception ex){CrashLog.Write(ex);updateBlocking=true;statusText="Mise à jour impossible";SetServer("Mise à jour obligatoire",Danger);progTarget=0;MessageBox.Show(this,"La mise à jour obligatoire n'a pas pu être installée.\n\n"+ex.Message,"Pokémon Online — mise à jour",MessageBoxButtons.OK,MessageBoxIcon.Error);return false;}
    }

    async Task Inspect()
    {
        bool files = new[] { "Game.exe", "Game.rxdata", "mkxp.json", "launchers" }.All(x => File.Exists(Path.Combine(root, x)) || Directory.Exists(Path.Combine(root, x)));
        ms = await Ping();
        online = ms >= 0;
        SetServer(online ? "Serveur en ligne" : "Prêt au démarrage", online ? Mint : Gold);
        bool running = Process.GetProcessesByName("Game").Length > 0;
        statusText = !files ? "Installation incomplète" : running ? "Le jeu est déjà lancé" : "Prêt à jouer";
        playEnabled = playZone.Enabled = files && !running && !updateBlocking;
    }

    async Task Launch()
    {
        if(updateBlocking){Info("La mise à jour obligatoire doit être installée avant de lancer le jeu.");return;}
        if (launching || !playEnabled) return;
        launching = true; playEnabled = playZone.Enabled = false; progTarget = 8;
        try
        {
            statusText = "Préparation de Hoenn…";
            if (!await Port())
            {
                SetServer("Démarrage…", Gold);
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
                progTarget = 34;
                await p.WaitForExitAsync();
                string output = (await o) + Environment.NewLine + (await er);
                Directory.CreateDirectory(Path.Combine(root, ".runtime"));
                File.WriteAllText(Path.Combine(root, ".runtime", "launcher.log"), output);
                if (p.ExitCode != 0)
                    throw new InvalidOperationException(output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries).LastOrDefault() ?? "Le serveur n'a pas pu démarrer.");
            }
            progTarget = 82;
            ms = await Ping(); online = ms >= 0;
            SetServer("Serveur en ligne", Mint);
            statusText = "Ouverture du jeu…";
            var info = new ProcessStartInfo(Path.Combine(root, "Game.exe")) { WorkingDirectory = root, UseShellExecute = false };
            if (guest) info.Environment["PEMK_INSTANCE"] = "guest";
            Process.Start(info);
            progTarget = 100; statusText = "Bonne aventure !";
            await Task.Delay(1300);
            if (Prefs.Get("autoclose", true)) Close();
            else { launching = false; progTarget = 0; await Inspect(); }
        }
        catch (Exception ex)
        {
            progTarget = 0; statusText = "Le lancement a échoué";
            SetServer("Service indisponible", Danger);
            MessageBox.Show(this, ex.Message + "\n\nOuvrez les journaux pour obtenir le détail.", "Pokémon Online", MessageBoxButtons.OK, MessageBoxIcon.Error);
            launching = false; playEnabled = playZone.Enabled = true;
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

    async Task RunDiagnostic(bool repair = false)
    {
        if (diagBusy) return;
        string script = Path.Combine(root, "launchers", "Repair-Eternal-Emerald.ps1");
        if (!File.Exists(script)) { Info("L'outil de diagnostic est introuvable."); return; }
        diagBusy = true;
        string before = statusText;
        statusText = repair ? "Réparation en cours…" : "Diagnostic en cours…";
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
            diagBusy = false;
            if (p.ExitCode == 0)
            {
                statusText = "Installation vérifiée";
                MessageBox.Show(this, report, "Diagnostic — installation prête", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else if (!repair && MessageBox.Show(this, report + "\n\nVoulez-vous tenter la réparation automatique ?", "Diagnostic", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                await RunDiagnostic(true);
            else
            {
                statusText = "Réparation nécessaire";
                MessageBox.Show(this, report, "Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        catch (Exception ex)
        {
            diagBusy = false;
            statusText = before;
            MessageBox.Show(this, ex.Message, "Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally { diagBusy = false; }
        await Inspect();
    }

    void OpenLogs()
    {
        string d = Path.Combine(root, ".runtime");
        Directory.CreateDirectory(d);
        Process.Start(new ProcessStartInfo("explorer.exe", d) { UseShellExecute = true });
    }

    void Info(string t) => MessageBox.Show(this, t, "Pokémon Online", MessageBoxButtons.OK, MessageBoxIcon.Information);

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            timer.Dispose(); bg?.Dispose();
            foreach (var f in new[] { fMenu, fTitle, fBody, fSub, fTag, fBtn, fStatus, fSrv, fSrvS, fGlyph, fGlyphS }) f.Dispose();
        }
        base.Dispose(disposing);
    }
}
