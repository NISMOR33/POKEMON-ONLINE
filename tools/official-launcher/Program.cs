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
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [STAThread]
    static int Main(string[] args)
    {
        if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
        {
            var d = AppContext.BaseDirectory;
            return File.Exists(Path.Combine(d, "Game.exe")) && File.Exists(Path.Combine(d, "launchers", "Start-Eternal-Emerald-MMO.ps1")) ? 0 : 2;
        }

        using var mutex = new Mutex(true, "EternalEmeraldOfficialLauncher", out bool first);
        if (!first)
        {
            var self = Process.GetCurrentProcess();
            var other = Process.GetProcessesByName(self.ProcessName)
                .FirstOrDefault(p => p.Id != self.Id && p.MainWindowHandle != IntPtr.Zero);
            if (other != null)
            {
                ShowWindow(other.MainWindowHandle, 9);
                SetForegroundWindow(other.MainWindowHandle);
            }
            return 0;
        }

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

internal static class WindowsShell
{
    public static string Exe
    {
        get
        {
            string winDir = Environment.GetEnvironmentVariable("WINDIR")
                ?? Environment.GetEnvironmentVariable("SystemRoot")
                ?? Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            if (string.IsNullOrWhiteSpace(winDir)) winDir = @"C:\Windows";

            string[] candidates = new[]
            {
                Path.Combine(winDir, "System32", "WindowsPowerShell", "v1.0", "powershell.exe"),
                Path.Combine(winDir, "SysWOW64", "WindowsPowerShell", "v1.0", "powershell.exe"),
                Path.Combine(winDir, "System32", "powershell.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.SystemX86), "WindowsPowerShell", "v1.0", "powershell.exe")
            };

            foreach (var candidate in candidates)
            {
                if (!string.IsNullOrWhiteSpace(candidate) && File.Exists(candidate))
                    return candidate;
            }

            string? pathEnv = Environment.GetEnvironmentVariable("PATH");
            if (!string.IsNullOrEmpty(pathEnv))
            {
                foreach (string p in pathEnv.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
                {
                    try
                    {
                        string full = Path.Combine(p.Trim(), "powershell.exe");
                        if (File.Exists(full)) return full;
                        string pwsh = Path.Combine(p.Trim(), "pwsh.exe");
                        if (File.Exists(pwsh)) return pwsh;
                    }
                    catch { }
                }
            }

            return "powershell.exe";
        }
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

// ───────────────────────── mise à jour GitHub (inchangé) ─────────────────────────
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
        string planFile=Path.Combine(stageRoot,"plan.json");File.WriteAllText(planFile,JsonSerializer.Serialize(plan));string helper=Path.Combine(root,"launchers","Apply-Eternal-Emerald-Update.ps1");if(!File.Exists(helper))throw new FileNotFoundException("Le programme d'installation de mise à jour est introuvable.",helper);Process.Start(new ProcessStartInfo(WindowsShell.Exe,$"-NoProfile -ExecutionPolicy Bypass -File \"{helper}\" -Plan \"{planFile}\" -LauncherPid {launcherPid}"){WorkingDirectory=root,UseShellExecute=false,CreateNoWindow=true});
    }
    string SafeTarget(string relative){if(string.IsNullOrWhiteSpace(relative)||Path.IsPathRooted(relative))throw new InvalidDataException("Chemin de mise à jour interdit.");string full=Path.GetFullPath(Path.Combine(root,relative.Replace('/',Path.DirectorySeparatorChar))),prefix=root.TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar;if(!full.StartsWith(prefix,StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("Chemin de mise à jour interdit.");return full;}
    static async Task<string> Hash(string path){await using var s=File.OpenRead(path);using var h=SHA256.Create();return Convert.ToHexString(await h.ComputeHashAsync(s)).ToLowerInvariant();}
}

internal sealed class ServerInfo
{
    public string Name = "", Host = "127.0.0.1";
    public int Port = 9998, Ms = -1;
    public bool On;
}

// Police pixel 5x7 intégrée (aucune police ni image nécessaire).
internal static class PixFont
{
    static readonly Dictionary<char, byte[]> G = Build();
    static Dictionary<char, byte[]> Build()
    {
        const string data =
            "A 0E 11 11 1F 11 11 11|B 1E 11 11 1E 11 11 1E|C 0E 11 10 10 10 11 0E|D 1E 11 11 11 11 11 1E|E 1F 10 10 1E 10 10 1F|F 1F 10 10 1E 10 10 10|" +
            "G 0E 11 10 17 11 11 0E|H 11 11 11 1F 11 11 11|I 0E 04 04 04 04 04 0E|J 07 02 02 02 02 12 0C|K 11 12 14 18 14 12 11|L 10 10 10 10 10 10 1F|" +
            "M 11 1B 15 15 11 11 11|N 11 19 15 13 11 11 11|O 0E 11 11 11 11 11 0E|P 1E 11 11 1E 10 10 10|Q 0E 11 11 11 15 12 0D|R 1E 11 11 1E 14 12 11|" +
            "S 0F 10 10 0E 01 01 1E|T 1F 04 04 04 04 04 04|U 11 11 11 11 11 11 0E|V 11 11 11 11 11 0A 04|W 11 11 11 15 15 15 0A|X 11 11 0A 04 0A 11 11|" +
            "Y 11 11 0A 04 04 04 04|Z 1F 01 02 04 08 10 1F|0 0E 11 13 15 19 11 0E|1 04 0C 04 04 04 04 0E|2 0E 11 01 02 04 08 1F|3 1F 02 04 02 01 11 0E|" +
            "4 02 06 0A 12 1F 02 02|5 1F 10 1E 01 01 11 0E|6 06 08 10 1E 11 11 0E|7 1F 01 02 04 08 08 08|8 0E 11 11 0E 11 11 0E|9 0E 11 11 0F 01 02 0C|" +
            ". 00 00 00 00 00 0C 0C|, 00 00 00 00 0C 04 08|: 00 0C 0C 00 0C 0C 00|- 00 00 00 1F 00 00 00|( 02 04 08 08 08 04 02|) 08 04 02 02 02 04 08|" +
            "/ 01 01 02 04 08 10 10|[ 0E 08 08 08 08 08 0E|] 0E 02 02 02 02 02 0E|% 19 19 02 04 08 13 13|! 04 04 04 04 04 00 04|? 0E 11 01 02 04 00 04|" +
            "+ 00 04 04 1F 04 04 00|> 08 04 02 01 02 04 08|< 02 04 08 10 08 04 02|' 04 04 08 00 00 00 00|_ 00 00 00 00 00 00 1F|= 00 00 1F 00 1F 00 00|* 00 04 0E 1F 0E 04 00";
        var d = new Dictionary<char, byte[]>();
        foreach (var e in data.Split('|'))
            d[e[0]] = e[2..].Split(' ').Select(h => Convert.ToByte(h, 16)).ToArray();
        return d;
    }

    static (char, int) Split(char c) => c switch
    {
        'É' => ('E', 1), 'È' => ('E', 2), 'Ê' => ('E', 3), 'Ë' => ('E', 4), 'À' => ('A', 2), 'Â' => ('A', 3), 'Ç' => ('C', 5),
        'Î' => ('I', 3), 'Ï' => ('I', 4), 'Ô' => ('O', 3), 'Û' => ('U', 3), 'Ù' => ('U', 2), 'Ü' => ('U', 4), _ => (c, 0)
    };

    public static int Width(string t) => Math.Max(0, t.Length * 6 - 1);

    public static void Draw(string text, Action<int, int> plot)
    {
        int x = 0;
        foreach (var raw in text.ToUpperInvariant())
        {
            var (c, acc) = Split(raw);
            if (G.TryGetValue(c, out var rows))
                for (int y = 0; y < 7; y++)
                    for (int b = 0; b < 5; b++)
                        if (((rows[y] >> (4 - b)) & 1) != 0) plot(x + b, y);
            switch (acc)
            {
                case 1: plot(x + 3, -2); plot(x + 2, -1); break;
                case 2: plot(x + 1, -2); plot(x + 2, -1); break;
                case 3: plot(x + 2, -2); plot(x + 1, -1); plot(x + 3, -1); break;
                case 4: plot(x + 1, -1); plot(x + 3, -1); break;
                case 5: plot(x + 2, 7); plot(x + 1, 8); break;
            }
            x += 6;
        }
    }
}

internal sealed class LauncherForm : Form
{
    // La fenêtre tient sur un écran 1366x768 ; la cartouche entre depuis le bord supérieur.
    const int W = 1100, CH = 740, TOP = 0, H = CH;
    const int BX = 110, BY = 160, BW = 880, BH = 530;
    const int LX = 216, LY = 218, LS = 3, LW = 222, LH = 96;
    static readonly Color[] Pal = { Color.FromArgb(203, 222, 163), Color.FromArgb(160, 188, 122), Color.FromArgb(76, 106, 68), Color.FromArgb(20, 38, 24) };
    static readonly Color Mint = Color.FromArgb(90, 255, 100), Gold = Color.FromArgb(255, 190, 50), Danger = Color.FromArgb(255, 70, 55);
    static readonly string[] Ids = { "up", "down", "left", "right", "A", "B", "START", "SELECT" };
    static readonly string[] HomeFr = { "JOUER", "COMMUNAUTÉ", "MISES À JOUR", "PARAMÈTRES", "QUITTER" };

    // Icônes pixel-art de l'écran ('#' = teinte sombre)
    static readonly string[] IcoComm =
    {
        "..###.....###..",
        ".#####...#####.",
        ".#####...#####.",
        "..###.....###..",
        "...............",
        ".#####...#####.",
        "#######.#######",
        "#######.#######",
        "#######.#######",
    };
    static readonly string[] IcoUpd =
    {
        "......##......",
        "......##......",
        "......##......",
        "......##......",
        "....######....",
        ".....####.....",
        "......##......",
        "..............",
        "#............#",
        "#............#",
        "##############",
    };
    static readonly string[] IcoQuit =
    {
        "#######.......",
        "#######.......",
        "##............",
        "##.......#....",
        "##.......##...",
        "##..########..",
        "##..########..",
        "##.......##...",
        "##.......#....",
        "##............",
        "#######.......",
        "#######.......",
    };

    readonly string root;
    bool guest;
    Bitmap? shell, overlay, cartImg;
    RectangleF cartSrc;
    readonly Bitmap lcdBmp = new(LW, LH, PixelFormat.Format32bppArgb);
    readonly byte[] fb = new byte[LW * LH], prev = new byte[LW * LH], snap = new byte[LW * LH];
    readonly int[] pix = new int[LW * LH];
    readonly System.Windows.Forms.Timer timer = new() { Interval = 16 };
    readonly Stopwatch clock = Stopwatch.StartNew();
    readonly Random rnd = new();
    readonly float[] press = new float[8], selR = new float[4];
    readonly bool[] held = new bool[8];
    readonly List<ServerInfo> servers = new();

    double bootStart, lastT, bootT, impactTime;
    float introA, cartY = -200, cartVel, cartTarget = 90, amp, ledOn, lcdPower, wipe = 1, progCur, progTarget;
    bool cartLive, impacted, booted, closing, launching, updating, updateBlocking, playEnabled = true, online, diagBusy;
    int tick, homeSel, listSel, ms = -1, hoverIdx = -1;
    string page = "home", statusText = "Initialisation…", updShort = "--", updVersion = "--";
    string? downId;
    Color serverTint = Gold;
    Font fTb = new("Segoe UI", 12, FontStyle.Regular, GraphicsUnit.Pixel), fLbl = new("Segoe UI", 11, FontStyle.Bold, GraphicsUnit.Pixel),
        fBrand = new("Segoe UI", 25, FontStyle.Bold | FontStyle.Italic, GraphicsUnit.Pixel), fAb = new("Segoe UI", 18, FontStyle.Bold | FontStyle.Italic, GraphicsUnit.Pixel);

    // Position "cartouche enfoncée" selon la vraie image (ou la cartouche dessinée en secours).
    float Seat => 18f;
    float Deep => Seat + 26f;

    public LauncherForm(bool isGuest)
    {
        root = FindRoot();
        Prefs.Load(root);
        guest = isGuest || Prefs.Get("guest", false);
        Text = "Pokémon Online Launcher";
        FormBorderStyle = FormBorderStyle.None;
        AutoScaleMode = AutoScaleMode.None;
        ClientSize = new Size(W, H);
        MinimumSize = MaximumSize = Size;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(40, 26, 16);
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        if (File.Exists(Path.Combine(root, "Game.ico"))) Icon = new Icon(Path.Combine(root, "Game.ico"));

        LoadCartImage();
        cartTarget = Seat;
        shell = BuildShell(); overlay = BuildOverlay();
        LoadServers();
        timer.Tick += OnTick;
        Shown += (_, _) =>
        {
            bootStart = lastT = clock.Elapsed.TotalSeconds;
            if (!Prefs.Get("fx", true)) SkipBoot();
            timer.Start();
            _ = RefreshServers();
        };
    }

    static string FindRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir != null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "Game.exe")) ||
                File.Exists(Path.Combine(dir.FullName, "launchers", "Start-Eternal-Emerald-MMO.ps1")) ||
                File.Exists(Path.Combine(dir.FullName, "launchers", "Apply-Eternal-Emerald-Update.ps1")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }
        return AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
    }

    // L'image fournie sert d'autocollant sur l'étiquette Émeraude.
    void LoadCartImage()
    {
        try
        {
            string[] names = { "cartouche-rogne", "cartouche", "cartridge", "emerald", "emeraude", "pokemon-emerald" };
            string[] dirs = { root, Path.Combine(root, "launchers"), Path.Combine(root, "tools", "official-launcher"), AppContext.BaseDirectory };
            string[] exts = { ".png", ".jpg", ".jpeg", ".bmp", ".gif" };
            var hit = names.SelectMany(n => dirs.SelectMany(d => exts.Select(e => Path.Combine(d, n + e))))
                           .FirstOrDefault(File.Exists);
            if (string.IsNullOrEmpty(hit)) return;
            using var raw = Image.FromFile(hit);
            cartImg = new Bitmap(raw);
            float iw = cartImg.Width, ih = cartImg.Height;
            const float labelAspect = (300f - 64f) / 108f;
            if (iw / ih > labelAspect)
            {
                float cw = ih * labelAspect;
                cartSrc = new RectangleF((iw - cw) / 2f, 0, cw, ih);
            }
            else
            {
                float ch = iw / labelAspect;
                cartSrc = new RectangleF(0, (ih - ch) / 2f, iw, ch);
            }
        }
        catch { cartImg?.Dispose(); cartImg = null; }
    }

    // ───────────────────────── décor statique (dessiné une seule fois) ─────────────────────────
    static GraphicsPath Round(RectangleF r, float radius)
    {
        float d = Math.Max(1, radius * 2);
        var p = new GraphicsPath();
        p.AddArc(r.X, r.Y, d, d, 180, 90); p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90); p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    static void PixText(Graphics g, string t, float x, float y, int sc, Color c)
    {
        using var b = new SolidBrush(c);
        PixFont.Draw(t, (px, py) => g.FillRectangle(b, x + px * sc, y + py * sc, sc, sc));
    }

    static void Ctr(Graphics g, string t, Font f, Color c, float cx, float cy)
    {
        using var b = new SolidBrush(c);
        using var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(t, f, b, cx, cy, sf);
    }

    Bitmap BuildShell()
    {
        var bmp = new Bitmap(W, CH, PixelFormat.Format32bppArgb);
        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;

        // ombre portée
        using (var small = new Bitmap(W / 8, CH / 8))
        {
            using (var sg = Graphics.FromImage(small))
            {
                sg.SmoothingMode = SmoothingMode.AntiAlias;
                using var sp = Round(new RectangleF((BX + 10) / 8f, (BY + 26) / 8f, BW / 8f, BH / 8f), 5);
                using var sb = new SolidBrush(Color.FromArgb(200, 0, 0, 0));
                sg.FillPath(sb, sp);
            }
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.DrawImage(small, new Rectangle(0, 0, W, CH));
        }

        var body = new RectangleF(BX, BY, BW, BH);
        using (var path = Round(body, 40))
        using (var br = new LinearGradientBrush(body, Color.FromArgb(224, 224, 218), Color.FromArgb(164, 164, 158), 90f))
        using (var edge = new Pen(Color.FromArgb(130, 60, 60, 56), 3))
        using (var hi = new Pen(Color.FromArgb(150, 255, 255, 255), 2))
        using (var ip = Round(RectangleF.Inflate(body, -4, -4), 37))
        {
            g.FillPath(br, path); g.DrawPath(edge, path); g.DrawPath(hi, ip);
        }
        // fente de la cartouche
        using (var slot = Round(new RectangleF(390, BY - 3, 320, 12), 5))
        using (var sb = new LinearGradientBrush(new RectangleF(390, BY - 3, 320, 12), Color.FromArgb(20, 20, 24), Color.FromArgb(70, 70, 76), 90f)) g.FillPath(sb, slot);

        // en-tête : titre + voyant serveur
        string title = "POKÉMON ONLINE LAUNCHER";
        float tx = (W - PixFont.Width(title) * 3) / 2f;
        PixText(g, title, tx + 1, BY + 15, 3, Color.FromArgb(130, 255, 255, 255));
        PixText(g, title, tx, BY + 14, 3, Color.FromArgb(24, 24, 28));
        Ctr(g, "ONLINE", fLbl, Color.FromArgb(50, 50, 52), 893, 185);

        // lunette de l'écran
        var bez = new RectangleF(146, 206, 814, 318);
        using (var bp = Round(bez, 26))
        using (var bb = new LinearGradientBrush(bez, Color.FromArgb(96, 96, 108), Color.FromArgb(62, 62, 74), 90f))
        using (var bo = new Pen(Color.FromArgb(40, 40, 48), 3)) { g.FillPath(bb, bp); g.DrawPath(bo, bp); }
        Ctr(g, "POWER", fLbl, Color.FromArgb(200, 120, 120), 178, 314);
        Ctr(g, "D O T   M A T R I X   W I T H   S T E R E O   S O U N D", fLbl, Color.FromArgb(150, 150, 168), 553, 515);

        // marque
        Ctr(g, "ETERNAL BOY", fBrand, Color.FromArgb(34, 40, 112), 550, 552);

        // alvéole allongée derrière A / B (inclinée comme sur une vraie console)
        var st = g.Save();
        g.TranslateTransform(772, 589); g.RotateTransform(-33.7f);
        var pr = new RectangleF(-100, -50, 200, 100);
        using (var gp = Round(pr, 50))
        using (var gb = new LinearGradientBrush(pr, Color.FromArgb(150, 150, 144), Color.FromArgb(206, 206, 200), 90f))
        using (var go = new Pen(Color.FromArgb(120, 90, 90, 86), 2)) { g.FillPath(gb, gp); g.DrawPath(go, gp); }
        g.Restore(st);

        // grille de haut-parleur
        using (var sp = new Pen(Color.FromArgb(104, 104, 100), 8) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        using (var sh = new Pen(Color.FromArgb(120, 255, 255, 255), 2) { StartCap = LineCap.Round, EndCap = LineCap.Round })
            for (int i = 0; i < 6; i++)
            {
                g.DrawLine(sh, 882 + i * 14 + 5, 674 - i * 2, 902 + i * 14 + 5, 614 - i * 2);
                g.DrawLine(sp, 882 + i * 14, 672 - i * 2, 902 + i * 14, 612 - i * 2);
            }

        Ctr(g, "SELECT", fLbl, Color.FromArgb(34, 40, 112), 508, 662);
        Ctr(g, "START", fLbl, Color.FromArgb(34, 40, 112), 582, 662);
        Ctr(g, "B", fAb, Color.FromArgb(34, 40, 112), 752, 662);
        Ctr(g, "A", fAb, Color.FromArgb(34, 40, 112), 846, 606);
        return bmp;
    }

    static Bitmap BuildOverlay()
    {
        var bmp = new Bitmap(LW * LS, LH * LS, PixelFormat.Format32bppArgb);
        using var g = Graphics.FromImage(bmp);
        using (var pen = new Pen(Color.FromArgb(34, 10, 24, 10), 1))
        {
            for (int x = LS - 1; x < bmp.Width; x += LS) g.DrawLine(pen, x, 0, x, bmp.Height);
            for (int y = LS - 1; y < bmp.Height; y += LS) g.DrawLine(pen, 0, y, bmp.Width, y);
        }
        int e = 18;
        using (var t = new LinearGradientBrush(new Rectangle(0, 0, bmp.Width, e + 1), Color.FromArgb(80, 0, 0, 0), Color.FromArgb(0, 0, 0, 0), 90f)) g.FillRectangle(t, 0, 0, bmp.Width, e);
        using (var b = new LinearGradientBrush(new Rectangle(0, bmp.Height - e - 1, bmp.Width, e + 1), Color.FromArgb(0, 0, 0, 0), Color.FromArgb(80, 0, 0, 0), 90f)) g.FillRectangle(b, 0, bmp.Height - e, bmp.Width, e);
        using (var l = new LinearGradientBrush(new Rectangle(0, 0, e + 1, bmp.Height), Color.FromArgb(80, 0, 0, 0), Color.FromArgb(0, 0, 0, 0), 0f)) g.FillRectangle(l, 0, 0, e, bmp.Height);
        using (var rr = new LinearGradientBrush(new Rectangle(bmp.Width - e - 1, 0, e + 1, bmp.Height), Color.FromArgb(0, 0, 0, 0), Color.FromArgb(80, 0, 0, 0), 0f)) g.FillRectangle(rr, bmp.Width - e, 0, e, bmp.Height);
        using (var gl = new SolidBrush(Color.FromArgb(16, 255, 255, 255)))
            g.FillPolygon(gl, new[] { new Point(0, 0), new Point(bmp.Width * 6 / 10, 0), new Point(0, bmp.Height * 6 / 10) });
        return bmp;
    }

    // ───────────────────────── animation ─────────────────────────
    static float Ease(float t) => 1 - (float)Math.Pow(1 - Math.Clamp(t, 0, 1), 3);

    void SkipBoot()
    {
        cartLive = impacted = true; cartY = cartTarget; cartVel = 0; impactTime = bootT - 3; bootStart -= 5;
    }

    void OnTick(object? s, EventArgs e)
    {
        if (WindowState == FormWindowState.Minimized) return;
        double now = clock.Elapsed.TotalSeconds;
        float dt = Math.Min(0.05f, (float)(now - lastT));
        lastT = now; bootT = now - bootStart; tick++;
        introA = Ease((float)bootT / 0.6f);
        if (bootT >= 0.6) cartLive = true;
        if (cartLive)
        {
            cartVel += ((cartTarget - cartY) * 90f - cartVel * 11f) * dt;
            cartY += cartVel * dt;
            if (!impacted && cartY >= cartTarget) { impacted = true; impactTime = bootT; amp = Math.Clamp(cartVel / 50f, 3f, 10f); }
        }
        amp *= (float)Math.Pow(0.02, dt);
        progCur += (progTarget - progCur) * Math.Min(1, dt * 8f);
        if (Math.Abs(progTarget - progCur) < 0.3f) progCur = progTarget;
        for (int i = 0; i < 8; i++) if (!held[i]) press[i] = Math.Max(0, press[i] - dt * 5f);
        double lt = bootT - impactTime - 0.35;
        if (!closing)
        {
            ledOn = impacted && bootT > impactTime + 0.15 ? Math.Min(1, ledOn + dt * 4) : 0;
            lcdPower = !impacted || lt < 0 ? 0 : Math.Min(1, (float)lt / 0.25f);
        }
        else ledOn = Math.Max(0, ledOn - dt * 3);
        wipe = Math.Min(1, wipe + dt / 0.28f);
        var tr = SelTarget();
        for (int k = 0; k < 4; k++) selR[k] += (tr[k] - selR[k]) * Math.Min(1, dt * 18f);
        RenderLcd();
        Present();
    }

    float[] SelTarget()
    {
        if (page == "home") return homeSel == 0 ? new float[] { 3, 15, 108, 25 } : new float[] { 116, 14 + (homeSel - 1) * 18, 104, 18 };
        int rh = Rows().Count > 5 ? 9 : 11;
        return new float[] { 2, 28 + listSel * rh - 1, LW - 4, rh - 1 };
    }

    // ───────────────────────── rendu de l'écran LCD (4 teintes) ─────────────────────────
    void P(int x, int y, byte c) { if ((uint)x < LW && (uint)y < LH) fb[y * LW + x] = c; }
    void R(int x, int y, int w, int h, byte c)
    {
        for (int j = Math.Max(0, y); j < Math.Min(LH, y + h); j++)
            for (int i = Math.Max(0, x); i < Math.Min(LW, x + w); i++) fb[j * LW + i] = c;
    }
    void Box(int x, int y, int w, int h, byte c, int th = 1) { R(x, y, w, th, c); R(x, y + h - th, w, th, c); R(x, y, th, h, c); R(x + w - th, y, th, h, c); }
    void T(string s, int x, int y, byte c, int sc = 1, bool bold = false) =>
        PixFont.Draw(s, (px, py) => { for (int j = 0; j < sc; j++) for (int i = 0; i < sc; i++) { P(x + px * sc + i, y + py * sc + j, c); if (bold) P(x + px * sc + i + 1, y + py * sc + j, c); } });
    static int TW(string s, int sc = 1) => PixFont.Width(s) * sc;
    void Disc(int cx, int cy, int r, byte c) { for (int y = -r; y <= r; y++) for (int x = -r; x <= r; x++) if (x * x + y * y <= r * r + r) P(cx + x, cy + y, c); }
    void Bmp(string[] rows, int x, int y, byte c = 3)
    {
        for (int j = 0; j < rows.Length; j++)
            for (int i = 0; i < rows[j].Length; i++)
                if (rows[j][i] == '#') P(x + i, y + j, c);
    }

    // Pokéball pixel-art
    void Ball(int cx, int cy, int r)
    {
        for (int y = -r; y <= r; y++)
            for (int x = -r; x <= r; x++)
            {
                int d = x * x + y * y;
                if (d > r * r + r) continue;
                byte c;
                if (d > (r - 1) * (r - 1)) c = 3;                   // contour
                else if (d <= 11) c = d <= 4 ? (byte)0 : (byte)3;   // bouton central
                else if (y == 0) c = 3;                             // bande
                else c = y < 0 ? (byte)2 : (byte)0;                 // haut sombre / bas clair
                P(cx + x, cy + y, c);
            }
    }

    void DrawMenuIcon(int i, int x, int y)
    {
        switch (i)
        {
            case 1: Bmp(IcoComm, x, y + 2); break;
            case 2: Bmp(IcoUpd, x, y + 1); break;
            case 3: // engrenage
                Disc(x + 6, y + 6, 4, 3);
                R(x + 5, y, 3, 3, 3); R(x + 5, y + 10, 3, 3, 3); R(x, y + 5, 3, 3, 3); R(x + 10, y + 5, 3, 3, 3);
                R(x + 2, y + 2, 2, 2, 3); R(x + 9, y + 2, 2, 2, 3); R(x + 2, y + 9, 2, 2, 3); R(x + 9, y + 9, 2, 2, 3);
                Disc(x + 6, y + 6, 1, 0);
                break;
            case 4: Bmp(IcoQuit, x, y); break;
        }
    }

    void Header()
    {
        Box(3, 2, 13, 7, 3); R(16, 4, 1, 3, 3);
        for (int i = 0; i < 4; i++) R(5 + i * 3, 4, 2, 3, 3);
        T("FULL", 21, 2, 3);
        string clock = DateTime.Now.ToString("HH:mm");
        if (tick % 60 > 30) clock = clock.Replace(':', ' ');
        string st = online ? "ONLINE" : "OFFLINE";
        int cx = LW - 4 - TW(clock), sx = cx - 6 - TW(st);
        T(clock, cx, 2, 3); T(st, sx, 2, 3);
        Box(sx - 10, 2, 7, 7, 3); R(sx - 7, 3, 1, 3, 3); R(sx - 7, 5, 2, 1, 3);
        R(0, 11, LW, 1, 3);
    }

    void DrawSel(int th)
    {
        int x = (int)Math.Round(selR[0]), y = (int)Math.Round(selR[1]), w = (int)Math.Round(selR[2]), h = (int)Math.Round(selR[3]);
        R(x, y, w, h, 1); Box(x, y, w, h, 3, th);
    }

    void RenderLcd()
    {
        Array.Copy(fb, prev, fb.Length);
        Array.Clear(fb);
        double lt = bootT - impactTime - 0.35;
        if (!booted)
        {
            if (lt < 0) return;
            if (lt < 0.12) { Array.Fill(fb, (byte)1); return; }
            float u = (float)(lt - 0.12);
            int y = (int)(-26 + Ease(u / 0.9f) * 50);
            T("POKÉMON", (LW - TW("POKÉMON", 3)) / 2, y, 3, 3);
            if (u > 0.5f) T("ONLINE", (LW - TW("ONLINE", 2)) / 2, y + 29, 3, 2, true);
            if (u > 1.0f) T("(C) 2026 ETERNAL EMERALD", (LW - TW("(C) 2026 ETERNAL EMERALD", 1)) / 2, 84, 2);
            if (lt >= 1.9) { booted = true; Array.Copy(fb, snap, fb.Length); wipe = 0; _ = StartupAsync(); }
            return;
        }
        if (page == "home") RenderHome(); else RenderList();
        if (wipe < 1)
        {
            int cut = (int)(wipe * LW);
            for (int y = 0; y < LH; y++) for (int x = cut; x < LW; x++) fb[y * LW + x] = snap[y * LW + x];
            R(cut, 0, 2, LH, 3);
        }
    }

    void RenderHome()
    {
        Header();
        DrawSel(2);
        bool dim = !playEnabled && !launching;
        Ball(15, 27, 7);
        if (launching)
        {
            T("CHARGEMENT" + new string('.', tick / 15 % 4), 27, 19, 3, 1, true);
            R(27, 30, 76, 6, 2); R(28, 31, (int)(74 * progCur / 100f), 4, 3);
        }
        else
        {
            T("JOUER", 27, 18, dim ? (byte)2 : (byte)3, 2, true);
            if (homeSel == 0 && playEnabled) T(">", 100 + (tick / 20 % 2), 24, 3, 1, true);
        }
        var s0 = servers[0];
        string sn = s0.Name.Length > 9 ? s0.Name[..9] : s0.Name;
        T("SERVEUR " + sn, 4, 42, 3);
        T("SERVEURS ACTIFS", 4, 52, 3, 1, true);
        for (int i = 0; i < Math.Min(3, servers.Count); i++)
        {
            var s = servers[i];
            string n = s.Name.Length > 6 ? s.Name[..6] : s.Name;
            T($"{i + 1}. {n} [{(s.On ? "ON" : "OFF")}]" + (s.On ? $" {s.Ms}MS" : ""), 4, 61 + i * 8, 3);
        }
        for (int i = 1; i < 5; i++)
        {
            int y = 14 + (i - 1) * 18;
            DrawMenuIcon(i, 118, y + 3);
            T(HomeFr[i], 134, y + 2, 3, 1, true);
        }
        R(0, 86, LW, 1, 2);
        if (launching || updating) R(0, 86, (int)(LW * progCur / 100f), 1, 3);
        string st = statusText.Length > 36 ? statusText[..36] : statusText;
        T(st, 4, 88, 3);
    }

    List<(string l, string v)> Rows() => page switch
    {
        "comm" => new() { ("DISCORD", ""), ("SITE OFFICIEL", ""), ("SIGNALER UN BUG", "") },
        "upd" => new() { ("RECHERCHER LES MAJ", ">"), ("VERSION", updVersion), ("ETAT", updShort) },
        _ => new()
        {
            ("FERMER APRES LANCEMENT", Prefs.Get("autoclose", true) ? "[ON]" : "[OFF]"),
            ("EFFETS ANIMES", Prefs.Get("fx", true) ? "[ON]" : "[OFF]"),
            ("MODE INVITE", guest ? "[ON]" : "[OFF]"),
            ("DOSSIER DU JEU", ">"), ("JOURNAUX", ">"), ("REPARER L'INSTALL.", ">")
        }
    };

    void RenderList()
    {
        Header();
        string title = page == "comm" ? "COMMUNAUTÉ" : page == "upd" ? "MISES À JOUR" : "PARAMÈTRES";
        T(title, 4, 16, 3, 1, true);
        R(0, 26, LW, 1, 2);
        var rows = Rows();
        int rh = rows.Count > 5 ? 9 : 11;
        DrawSel(1);
        for (int i = 0; i < rows.Count; i++)
        {
            int y = 28 + i * rh;
            T(rows[i].l, 6, y + 1, 3);
            if (rows[i].v.Length > 0) T(rows[i].v, LW - 6 - TW(rows[i].v), y + 1, 3, 1, true);
        }
        if (updating) { R(0, 86, LW, 1, 2); R(0, 86, (int)(LW * progCur / 100f), 1, 3); T(statusText.Length > 36 ? statusText[..36] : statusText, 4, 88, 3); }
        else { T("B: RETOUR", 4, 88, 2); T("A: OK", LW - 4 - TW("A: OK"), 88, 2); }
    }

    // ───────────────────────── dessin ─────────────────────────
    protected override void OnPaint(PaintEventArgs e) { }
    protected override void OnPaintBackground(PaintEventArgs e) { }
    protected override CreateParams CreateParams { get { var cp = base.CreateParams; cp.ExStyle |= 0x80000; return cp; } }

    // Fenêtre transparente (alpha par pixel) : seule la console et la cartouche sont visibles.
    [StructLayout(LayoutKind.Sequential)] struct PT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] struct SZ { public int cx, cy; }
    [StructLayout(LayoutKind.Sequential)] struct BLEND { public byte Op, Flags, Alpha, Format; }
    [StructLayout(LayoutKind.Sequential)] struct BMI { public int biSize, biWidth, biHeight; public short biPlanes, biBitCount; public int biCompression, biSizeImage, biXPels, biYPels, biClrUsed, biClrImportant; }
    [DllImport("user32.dll")] static extern bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, IntPtr pptDst, ref SZ psize, IntPtr hdcSrc, ref PT pptSrc, int crKey, ref BLEND pblend, int dwFlags);
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr h);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr h, IntPtr dc);
    [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleDC(IntPtr dc);
    [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr dc);
    [DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr dc, IntPtr obj);
    [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr obj);
    [DllImport("gdi32.dll")] static extern IntPtr CreateDIBSection(IntPtr hdc, ref BMI bmi, uint usage, out IntPtr bits, IntPtr section, uint offset);

    IntPtr memDc, hDib;
    Bitmap? frame;
    Graphics? fg;
    float fade = 1;

    void Present()
    {
        if (!IsHandleCreated) return;
        IntPtr scr = GetDC(IntPtr.Zero);
        if (frame == null)
        {
            var bmi = new BMI { biSize = 40, biWidth = W, biHeight = -H, biPlanes = 1, biBitCount = 32 };
            memDc = CreateCompatibleDC(scr);
            hDib = CreateDIBSection(scr, ref bmi, 0, out var bits, IntPtr.Zero, 0);
            SelectObject(memDc, hDib);
            frame = new Bitmap(W, H, W * 4, PixelFormat.Format32bppPArgb, bits);
            fg = Graphics.FromImage(frame);
        }
        fg!.Clear(Color.Transparent);
        PaintScene(fg);
        var size = new SZ { cx = W, cy = H }; var src = new PT();
        var bl = new BLEND { Alpha = (byte)(255 * Math.Clamp(fade, 0f, 1f)), Format = 1 };
        UpdateLayeredWindow(Handle, scr, IntPtr.Zero, ref size, memDc, ref src, 0, ref bl, 2);
        ReleaseDC(IntPtr.Zero, scr);
    }

    void PaintScene(Graphics g)
    {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        g.TranslateTransform(0, TOP);   // tout le dessin est en "coordonnées console"
        DrawCart(g);

        float a = introA;
        if (shell != null)
        {
            var st = g.Save();
            float sx = amp > 0.05f ? (float)Math.Sin(clock.Elapsed.TotalSeconds * 70) * amp : 0, sy = amp > 0.05f ? (float)Math.Cos(clock.Elapsed.TotalSeconds * 53) * amp * 0.6f : 0;
            g.TranslateTransform(sx, sy + (1 - a) * 40);
            if (a < 0.99f)
            {
                using var ia = new ImageAttributes();
                ia.SetColorMatrix(new ColorMatrix { Matrix33 = Math.Clamp(a, 0, 1) });
                g.DrawImage(shell, new Rectangle(0, 0, W, CH), 0, 0, W, CH, GraphicsUnit.Pixel, ia);
            }
            else
            {
                g.DrawImageUnscaled(shell, 0, 0);
                DrawLcd(g);
                DrawLeds(g);
                DrawDpad(g);
                float glow = 0.5f + 0.5f * (float)Math.Sin(tick * 0.08);
                float aGlow = launching ? 1f : booted ? glow * 0.7f : 0f;
                Color c1 = Color.FromArgb(214, 66, 112), c2 = Color.FromArgb(118, 16, 54);
                Btn(g, 736, 613, 36, c1, c2, press[5], 0, Color.Transparent);
                Btn(g, 808, 565, 36, c1, c2, press[4], aGlow, Color.FromArgb(255, 120, 170));
                Pill(g, 478, 620, press[7]);
                Pill(g, 552, 620, press[6]);
            }
            g.Restore(st);
        }
        DrawDots(g);
    }

    void DrawCart(Graphics g)
    {
        float x = 400, y = cartY, w = 300, h = 190f;
        if (y < -TOP - h) return;

        var state = g.Save();
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;

        // 1. Ombre portée sous la cartouche
        float shadowAlpha = Math.Clamp(130f * (1f - Math.Abs(y - Seat) / 200f), 30f, 130f);
        using (var shadowPath = Round(new RectangleF(x + 4, y + 8, w - 8, h - 4), 12))
        using (var sb = new SolidBrush(Color.FromArgb((int)shadowAlpha, 0, 0, 0)))
        {
            g.FillPath(sb, shadowPath);
        }

        // 2. Silhouette 3D authentique d'une cartouche Game Boy Advance
        using var bodyPath = new GraphicsPath();
        float r = 10f;
        bodyPath.AddArc(x, y + 4, r * 2, r * 2, 180, 90);
        bodyPath.AddLine(x + r, y + 4, x + 70, y + 4);
        bodyPath.AddBezier(x + 70, y + 4, x + 90, y + 12, x + w - 90, y + 12, x + w - 70, y + 4);
        bodyPath.AddLine(x + w - 70, y + 4, x + w - r, y + 4);
        bodyPath.AddArc(x + w - r * 2, y + 4, r * 2, r * 2, 270, 90);
        bodyPath.AddLine(x + w, y + 4 + r, x + w, y + 45);
        bodyPath.AddLine(x + w, y + 45, x + w - 6, y + 52);
        bodyPath.AddLine(x + w - 6, y + 52, x + w - 6, y + h - 16);
        bodyPath.AddLine(x + w - 6, y + h - 16, x + w - 16, y + h);
        bodyPath.AddLine(x + w - 16, y + h, x + 16, y + h);
        bodyPath.AddLine(x + 16, y + h, x + 6, y + h - 16);
        bodyPath.AddLine(x + 6, y + h - 16, x + 6, y + 52);
        bodyPath.AddLine(x + 6, y + 52, x, y + 45);
        bodyPath.CloseFigure();

        // 3. Plastique Vert Émeraude Translucide avec relief
        using (var bodyBr = new LinearGradientBrush(new RectangleF(x, y, w, h), Color.Transparent, Color.Transparent, 85f))
        {
            var cb = new ColorBlend
            {
                Colors = new[]
                {
                    Color.FromArgb(240, 16, 155, 88),
                    Color.FromArgb(220, 9, 110, 60),
                    Color.FromArgb(245, 4, 65, 36)
                },
                Positions = new[] { 0f, 0.45f, 1f }
            };
            bodyBr.InterpolationColors = cb;
            g.FillPath(bodyBr, bodyPath);
        }

        using (var outerPen = new Pen(Color.FromArgb(190, 2, 50, 26), 2.5f))
        {
            g.DrawPath(outerPen, bodyPath);
        }

        // 4. Composants internes vus à travers le plastique (PCB, Puces, Pins)
        var pcbRect = new RectangleF(x + 18, y + 32, w - 36, h - 42);
        using (var pcbBr = new SolidBrush(Color.FromArgb(50, 0, 80, 40)))
        {
            g.FillRectangle(pcbBr, pcbRect);
        }

        using (var chipBr = new SolidBrush(Color.FromArgb(70, 20, 25, 22)))
        using (var chipPen = new Pen(Color.FromArgb(40, 150, 255, 180), 1))
        {
            var chipRect = new RectangleF(x + w / 2f - 40, y + 48, 80, 45);
            g.FillRectangle(chipBr, chipRect);
            g.DrawRectangle(chipPen, chipRect.X, chipRect.Y, chipRect.Width, chipRect.Height);
        }

        using (var goldBr = new SolidBrush(Color.FromArgb(70, 220, 180, 60)))
        {
            for (int p = 0; p < 28; p++)
            {
                g.FillRectangle(goldBr, x + 28 + p * 8.6f, y + h - 18, 5, 14);
            }
        }

        using (var tracePen = new Pen(Color.FromArgb(40, 140, 240, 160), 1f))
        {
            g.DrawLine(tracePen, x + 30, y + 40, x + 90, y + 40);
            g.DrawLine(tracePen, x + 90, y + 40, x + 110, y + 60);
            g.DrawLine(tracePen, x + w - 30, y + 40, x + w - 90, y + 40);
            g.DrawLine(tracePen, x + w - 90, y + 40, x + w - 110, y + 60);
        }

        // 5. Ligne de relief et stries de préhension
        using (var innerHighlight = new Pen(Color.FromArgb(80, 180, 255, 210), 1.5f))
        {
            g.DrawLine(innerHighlight, x + 12, y + 14, x + w - 12, y + 14);
            g.DrawLine(innerHighlight, x + 12, y + 14, x + 12, y + h - 16);
        }

        using (var ribDark = new Pen(Color.FromArgb(80, 2, 45, 22), 1.5f))
        using (var ribLight = new Pen(Color.FromArgb(50, 160, 255, 190), 1.5f))
        {
            for (int i = 0; i < 18; i++)
            {
                float rx = x + 44 + i * 12f;
                g.DrawLine(ribDark, rx, y + h - 28, rx, y + h - 10);
                g.DrawLine(ribLight, rx + 1f, y + h - 28, rx + 1f, y + h - 10);
            }
        }

        // 6. LOGO "GAME BOY ADVANCE" MOULÉ / GRAVÉ (3D Embossed)
        string gbaText = "GAME BOY ADVANCE";
        float gbaW = PixFont.Width(gbaText);
        float gbaX = x + (w - gbaW) / 2f;
        float gbaY = y + 16f;

        PixText(g, gbaText, gbaX - 0.5f, gbaY - 0.5f, 1, Color.FromArgb(140, 2, 40, 20));
        PixText(g, gbaText, gbaX, gbaY - 1f, 1, Color.FromArgb(120, 4, 55, 28));
        PixText(g, gbaText, gbaX + 1f, gbaY + 1f, 1, Color.FromArgb(110, 170, 255, 200));
        PixText(g, gbaText, gbaX, gbaY, 1, Color.FromArgb(180, 8, 85, 45));

        // 7. ÉTIQUETTE ÉMERAUDE AVEC REFLET METALLIQUE HOLOGRAPHIQUE
        var labelRect = new RectangleF(x + 32, y + 36, w - 64, 108);

        using (var recessPath = Round(RectangleF.Inflate(labelRect, 3, 3), 8))
        {
            using (var recessBr = new SolidBrush(Color.FromArgb(70, 30, 40, 35))) g.FillPath(recessBr, recessPath);
            using (var recessPen = new Pen(Color.FromArgb(90, 2, 45, 22), 1.5f)) g.DrawPath(recessPen, recessPath);
        }

        using var labelPath = Round(labelRect, 6);
        var labelState = g.Save();
        g.SetClip(labelPath, CombineMode.Replace);

        if (cartImg != null)
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(cartImg, labelRect, cartSrc, GraphicsUnit.Pixel);
        }
        else
        {
            using var labelBg = new LinearGradientBrush(labelRect, Color.FromArgb(10, 110, 75), Color.FromArgb(4, 55, 38), 45f);
            g.FillRectangle(labelBg, labelRect);
            PixText(g, "POKÉMON", labelRect.X + 20, labelRect.Y + 15, 2, Color.FromArgb(255, 215, 0));
            PixText(g, "EMERALD VERSION", labelRect.X + 15, labelRect.Y + 45, 1, Color.FromArgb(255, 255, 255));
        }

        float cycle = (tick % 180) / 180f;
        float foilX = labelRect.X - 100 + cycle * (labelRect.Width + 200);
        using (var foilBr = new LinearGradientBrush(
            new PointF(foilX - 40, labelRect.Y),
            new PointF(foilX + 40, labelRect.Bottom),
            Color.Transparent, Color.Transparent))
        {
            var foilBlend = new ColorBlend
            {
                Colors = new[]
                {
                    Color.FromArgb(0, 255, 255, 255),
                    Color.FromArgb(70, 160, 255, 220),
                    Color.FromArgb(110, 255, 255, 255),
                    Color.FromArgb(70, 200, 255, 180),
                    Color.FromArgb(0, 255, 255, 255)
                },
                Positions = new[] { 0f, 0.35f, 0.5f, 0.65f, 1f }
            };
            foilBr.InterpolationColors = foilBlend;
            g.FillRectangle(foilBr, labelRect);
        }

        g.Restore(labelState);

        using (var labelBorder = new Pen(Color.FromArgb(140, 20, 25, 25), 1.5f))
        {
            g.DrawPath(labelBorder, labelPath);
        }

        // 8. VIS ET REFLET SUR LE PLASTIQUE
        using (var screwDark = new SolidBrush(Color.FromArgb(140, 5, 45, 22)))
        using (var screwMetal = new LinearGradientBrush(new RectangleF(0, 0, 10, 10), Color.FromArgb(200, 190, 200, 195), Color.FromArgb(220, 90, 100, 95), 45f))
        using (var screwPen = new Pen(Color.FromArgb(100, 30, 35, 30), 1))
        {
            foreach (float sx in new[] { x + 22, x + w - 22 })
            {
                float sy = y + 88;
                g.FillEllipse(screwDark, sx - 5, sy - 5, 10, 10);
                var smState = g.Save();
                g.TranslateTransform(sx - 4, sy - 4);
                g.FillEllipse(screwMetal, 0, 0, 8, 8);
                g.DrawEllipse(screwPen, 0, 0, 8, 8);
                g.DrawLine(screwPen, 2, 4, 6, 4);
                g.DrawLine(screwPen, 4, 2, 4, 6);
                g.Restore(smState);
            }
        }

        using (var glassReflect = new LinearGradientBrush(new RectangleF(x, y, w / 2f, h), Color.FromArgb(45, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), 30f))
        {
            g.FillPolygon(glassReflect, new[]
            {
                new PointF(x + 15, y + 6),
                new PointF(x + 110, y + 6),
                new PointF(x + 60, y + h - 20),
                new PointF(x + 15, y + h - 20)
            });
        }

        g.Restore(state);
    }

    void DrawLcd(Graphics g)
    {
        var rect = new RectangleF(LX, LY, LW * LS, LH * LS);
        using (var dark = new SolidBrush(Color.FromArgb(30, 38, 30))) g.FillRectangle(dark, rect);
        if (lcdPower <= 0.001f) { if (overlay != null) g.DrawImageUnscaled(overlay, LX, LY); return; }

        int[] pal = Pal.Select(c => c.ToArgb()).ToArray();
        for (int i = 0; i < pix.Length; i++)
        {
            int c = pal[fb[i]];
            if (fb[i] != prev[i])
            {
                int o = pal[prev[i]];
                c = (255 << 24) | ((((c >> 16 & 255) * 7 + (o >> 16 & 255) * 3) / 10) << 16) | ((((c >> 8 & 255) * 7 + (o >> 8 & 255) * 3) / 10) << 8) | (((c & 255) * 7 + (o & 255) * 3) / 10);
            }
            pix[i] = c;
        }
        var bd = lcdBmp.LockBits(new Rectangle(0, 0, LW, LH), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(pix, 0, bd.Scan0, pix.Length);
        lcdBmp.UnlockBits(bd);

        float p = lcdPower, vy = Math.Clamp(p * 3f, 0.02f, 1f), hx = p > 0.3f ? 1f : Math.Clamp(p / 0.3f, 0.04f, 1f);
        var dst = new RectangleF(rect.X + rect.Width * (1 - hx) / 2, rect.Y + rect.Height * (1 - vy) / 2, rect.Width * hx, rect.Height * vy);
        var oldI = g.InterpolationMode; var oldP = g.PixelOffsetMode;
        g.InterpolationMode = InterpolationMode.NearestNeighbor; g.PixelOffsetMode = PixelOffsetMode.Half;
        g.DrawImage(lcdBmp, dst, new RectangleF(0, 0, LW, LH), GraphicsUnit.Pixel);
        g.InterpolationMode = oldI; g.PixelOffsetMode = oldP;

        if (p < 1)
            using (var fl = new SolidBrush(Color.FromArgb((int)(200 * (1 - p)), 230, 255, 200))) g.FillRectangle(fl, dst);
        else if (booted)
        {
            var clip = g.Clip;
            g.SetClip(rect);
            float pulse = 0.55f + 0.45f * (float)Math.Sin(tick * 0.1);
            var sr = new RectangleF(LX + selR[0] * LS, LY + selR[1] * LS, selR[2] * LS, selR[3] * LS);
            for (int k = 1; k <= 5; k++)
                using (var pen = new Pen(Color.FromArgb((int)(pulse * (60 - k * 9)), 170, 255, 90), 3))
                using (var gp = Round(RectangleF.Inflate(sr, k * 3, k * 3), 4 + k)) g.DrawPath(pen, gp);
            g.Clip = clip;
        }
        if (overlay != null && p >= 1) g.DrawImageUnscaled(overlay, LX, LY);
        if (p >= 1 && rnd.Next(5) == 0) using (var fk = new SolidBrush(Color.FromArgb(rnd.Next(2, 9), 0, 0, 0))) g.FillRectangle(fk, rect);
    }

    void DrawLeds(Graphics g)
    {
        Led(g, 178, 288, 6, Color.FromArgb(255, 40, 40), ledOn);
        var c = serverTint == Mint ? Color.FromArgb(90, 255, 90) : serverTint == Danger ? Color.FromArgb(255, 70, 60) : Color.FromArgb(255, 190, 50);
        Led(g, 928, 185, 6, c, ledOn * (0.75f + 0.25f * (float)Math.Sin(tick * 0.1)));
    }

    static void Led(Graphics g, float cx, float cy, float r, Color c, float on)
    {
        for (int k = 4; k >= 1; k--)
            using (var b = new SolidBrush(Color.FromArgb((int)(on * 26), c))) g.FillEllipse(b, cx - r - k * 3, cy - r - k * 3, (r + k * 3) * 2, (r + k * 3) * 2);
        using var off = new SolidBrush(Color.FromArgb(70, 20, 20)); g.FillEllipse(off, cx - r, cy - r, r * 2, r * 2);
        using var lit = new SolidBrush(Color.FromArgb((int)(255 * on), c)); g.FillEllipse(lit, cx - r, cy - r, r * 2, r * 2);
        using var hi = new SolidBrush(Color.FromArgb((int)(150 * on), 255, 255, 255)); g.FillEllipse(hi, cx - r * 0.5f, cy - r * 0.6f, r * 0.7f, r * 0.5f);
    }

    // ───────────────────────── boutons réalistes ─────────────────────────
    static GraphicsPath CrossPath(float cx, float cy, float L, float T, float rad)
    {
        var p = new GraphicsPath { FillMode = FillMode.Winding };
        using (var a = Round(new RectangleF(cx - T, cy - L, T * 2, L * 2), rad)) p.AddPath(a, false);
        using (var b = Round(new RectangleF(cx - L, cy - T, L * 2, T * 2), rad)) p.AddPath(b, false);
        return p;
    }

    void DrawDpad(Graphics g)
    {
        float cx = 250, cy = 601, L = 54, T = 21;

        // alvéole creusée
        var well = new RectangleF(cx - 82, cy - 82, 164, 164);
        using (var wb = new LinearGradientBrush(well, Color.FromArgb(125, 70, 70, 66), Color.FromArgb(170, 255, 255, 255), 90f)) g.FillEllipse(wb, well);
        using (var wp = new Pen(Color.FromArgb(110, 60, 60, 56), 2)) g.DrawEllipse(wp, well);
        using (var wl = new Pen(Color.FromArgb(60, 255, 255, 255), 1.5f)) g.DrawEllipse(wl, RectangleF.Inflate(well, -6, -6));

        // ombre + liseré noir + corps dégradé
        using (var sh = CrossPath(cx, cy + 5, L + 2, T + 2, 9))
        using (var sb = new SolidBrush(Color.FromArgb(105, 0, 0, 0))) g.FillPath(sb, sh);
        using (var rim = CrossPath(cx, cy, L + 2, T + 2, 9))
        using (var rb = new SolidBrush(Color.FromArgb(14, 14, 18))) g.FillPath(rb, rim);

        using (var body = CrossPath(cx, cy, L, T, 8))
        {
            using (var bb = new LinearGradientBrush(new RectangleF(cx - L, cy - L, L * 2, L * 2), Color.FromArgb(92, 92, 100), Color.FromArgb(32, 32, 38), 90f))
                g.FillPath(bb, body);
            using (var top = CrossPath(cx, cy - 1, L - 4, T - 4, 6))
            using (var tb = new LinearGradientBrush(new RectangleF(cx - L, cy - L, L * 2, L * 2), Color.FromArgb(60, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), 90f))
                g.FillPath(tb, top);

            // direction enfoncée
            var st = g.Save();
            g.SetClip(body, CombineMode.Replace);
            var arms = new[] { new RectangleF(cx - T, cy - L, T * 2, L), new RectangleF(cx - T, cy, T * 2, L), new RectangleF(cx - L, cy - T, L, T * 2), new RectangleF(cx, cy - T, L, T * 2) };
            for (int i = 0; i < 4; i++)
                if (press[i] > 0.02f) using (var pb = new SolidBrush(Color.FromArgb((int)(150 * press[i]), 0, 0, 0))) g.FillRectangle(pb, arms[i]);
            g.Restore(st);
        }

        // flèches gravées
        using (var tb = new SolidBrush(Color.FromArgb(150, 168, 168, 178)))
        {
            g.FillPolygon(tb, new[] { new PointF(cx, cy - 44), new PointF(cx - 8, cy - 32), new PointF(cx + 8, cy - 32) });
            g.FillPolygon(tb, new[] { new PointF(cx, cy + 44), new PointF(cx - 8, cy + 32), new PointF(cx + 8, cy + 32) });
            g.FillPolygon(tb, new[] { new PointF(cx - 44, cy), new PointF(cx - 32, cy - 8), new PointF(cx - 32, cy + 8) });
            g.FillPolygon(tb, new[] { new PointF(cx + 44, cy), new PointF(cx + 32, cy - 8), new PointF(cx + 32, cy + 8) });
        }
        // cuvette centrale
        var dish = new RectangleF(cx - 14, cy - 14, 28, 28);
        using (var db = new LinearGradientBrush(dish, Color.FromArgb(18, 18, 22), Color.FromArgb(78, 78, 86), 90f)) g.FillEllipse(db, dish);
    }

    // Bouton rond bombé (A / B) avec alvéole, ombre, tranche, dégradé radial et reflet.
    static void Btn(Graphics g, float cx, float cy, float r, Color c1, Color c2, float pr, float glow, Color gc)
    {
        // alvéole creusée
        var wr = new RectangleF(cx - r - 9, cy - r - 9, (r + 9) * 2, (r + 9) * 2);
        using (var wb = new LinearGradientBrush(wr, Color.FromArgb(150, 70, 70, 66), Color.FromArgb(165, 255, 255, 255), 90f)) g.FillEllipse(wb, wr);
        using (var wp = new Pen(Color.FromArgb(110, 60, 60, 56), 1.5f)) g.DrawEllipse(wp, wr);

        if (glow > 0)
            for (int k = 1; k <= 5; k++)
                using (var gp = new Pen(Color.FromArgb((int)(glow * (38 - k * 6)), gc), 5)) g.DrawEllipse(gp, cx - r - 9 - k * 4, cy - r - 9 - k * 4, (r + 9 + k * 4) * 2, (r + 9 + k * 4) * 2);

        float rr = r - pr * 1.5f;                 // le bouton s'écrase un peu
        float top = cy - 4 + pr * 4;              // 4 px de relief au repos
        float depth = 4 - pr * 3;                 // épaisseur de la tranche visible

        using (var sb = new SolidBrush(Color.FromArgb((int)(110 - pr * 50), 0, 0, 0)))
            g.FillEllipse(sb, cx - rr + 1, top - rr + depth + 3, rr * 2, rr * 2);
        using (var side = new SolidBrush(Color.FromArgb(c2.R * 55 / 100, c2.G * 55 / 100, c2.B * 55 / 100)))
            g.FillEllipse(side, cx - rr, top - rr + depth, rr * 2, rr * 2);

        using (var path = new GraphicsPath())
        {
            path.AddEllipse(cx - rr, top - rr, rr * 2, rr * 2);
            using (var pg = new PathGradientBrush(path)
            {
                CenterPoint = new PointF(cx - rr * 0.3f, top - rr * 0.35f),
                CenterColor = c1,
                SurroundColors = new[] { c2 }
            }) g.FillPath(pg, path);
            using (var edge = new Pen(Color.FromArgb(120, c2.R / 2, c2.G / 2, c2.B / 2), 1.5f)) g.DrawPath(edge, path);
        }
        var spec = new RectangleF(cx - rr * 0.62f, top - rr * 0.88f, rr * 1.0f, rr * 0.62f);
        using (var gl = new LinearGradientBrush(spec, Color.FromArgb((int)(150 - pr * 90), 255, 255, 255), Color.FromArgb(0, 255, 255, 255), 90f))
            g.FillEllipse(gl, spec);
    }

    // Select / Start : pastilles en caoutchouc inclinées dans leur rainure.
    static void Pill(Graphics g, float x, float y, float pr)
    {
        float cx = x + 30, cy = y + 11;
        var st = g.Save();
        g.TranslateTransform(cx, cy); g.RotateTransform(-25f);

        var groove = new RectangleF(-36, -12, 72, 24);
        using (var gp = Round(groove, 12))
        using (var gb = new LinearGradientBrush(groove, Color.FromArgb(130, 80, 80, 76), Color.FromArgb(165, 255, 255, 255), 90f))
        using (var go = new Pen(Color.FromArgb(110, 60, 60, 56), 1.5f)) { g.FillPath(gb, gp); g.DrawPath(go, gp); }

        float d = pr * 2.5f;
        var btn = new RectangleF(-30, -9 + d, 60, 17);
        using (var sp = Round(new RectangleF(btn.X, btn.Y + 3 - pr * 2, btn.Width, btn.Height), 8))
        using (var sb = new SolidBrush(Color.FromArgb(120, 0, 0, 0))) g.FillPath(sb, sp);
        using (var bp = Round(btn, 8))
        using (var bb = new LinearGradientBrush(btn, Color.FromArgb(118, 118, 128), Color.FromArgb(44, 44, 54), 90f))
        using (var bo = new Pen(Color.FromArgb(24, 24, 30), 1.5f)) { g.FillPath(bb, bp); g.DrawPath(bo, bp); }
        var gloss = new RectangleF(btn.X + 6, btn.Y + 1.5f, btn.Width - 12, 6);
        using (var gl = new LinearGradientBrush(gloss, Color.FromArgb((int)(120 - pr * 80), 255, 255, 255), Color.FromArgb(0, 255, 255, 255), 90f))
            g.FillEllipse(gl, gloss);
        g.Restore(st);
    }

    void DrawDots(Graphics g)
    {
        Color[] cs = { Color.FromArgb(255, 95, 86), Color.FromArgb(255, 189, 46), Color.FromArgb(39, 201, 63) };
        for (int i = 0; i < 3; i++)
        {
            using var b = new SolidBrush(cs[i]); using var o = new Pen(Color.FromArgb(110, 50, 40, 40), 1.5f);
            g.FillEllipse(b, 214 + i * 20 - 7, 178, 14, 14); g.DrawEllipse(o, 214 + i * 20 - 7, 178, 14, 14);
        }
    }

    // ───────────────────────── entrées ─────────────────────────
    // Toutes les coordonnées de Hit / LcdIndex sont en "coordonnées console" (souris - TOP).
    static double Dist(int x, int y, int cx, int cy) => Math.Sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));

    string? Hit(int x, int y)
    {
        if (Dist(x, y, 214, 185) <= 9) return "close";
        if (Dist(x, y, 234, 185) <= 9) return "min";
        if (Dist(x, y, 254, 185) <= 9) return "opt";
        if (Dist(x, y, 808, 565) <= 38) return "A";
        if (Dist(x, y, 736, 613) <= 38) return "B";
        if (new Rectangle(478, 620, 60, 22).Contains(x, y)) return "SELECT";
        if (new Rectangle(552, 620, 60, 22).Contains(x, y)) return "START";
        if (new Rectangle(229, 547, 42, 55).Contains(x, y)) return "up";
        if (new Rectangle(229, 601, 42, 55).Contains(x, y)) return "down";
        if (new Rectangle(196, 580, 55, 42).Contains(x, y)) return "left";
        if (new Rectangle(250, 580, 55, 42).Contains(x, y)) return "right";
        if (booted && new Rectangle(LX, LY, LW * LS, LH * LS).Contains(x, y)) return "lcd";
        if (new Rectangle(400, (int)cartY, 300, Math.Max(0, BY - (int)cartY)).Contains(x, y)) return "cart";
        return null;
    }

    int LcdIndex(int x, int y)
    {
        int bx = (x - LX) / LS, by = (y - LY) / LS;
        if (page == "home")
        {
            for (int i = 0; i < 5; i++)
            {
                var t = i == 0 ? new[] { 3, 15, 108, 25 } : new[] { 116, 14 + (i - 1) * 18, 104, 18 };
                if (bx >= t[0] && bx < t[0] + t[2] && by >= t[1] && by < t[1] + t[3]) return i;
            }
            return -1;
        }
        var rows = Rows(); int rh = rows.Count > 5 ? 9 : 11, idx = (by - 27) / rh;
        return by >= 27 && idx >= 0 && idx < rows.Count ? idx : -1;
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        int my = e.Y - TOP;
        var id = closing ? null : Hit(e.X, my);
        Cursor = id != null ? Cursors.Hand : Cursors.Default;
        hoverIdx = id == "lcd" ? LcdIndex(e.X, my) : -1;
        if (hoverIdx >= 0) SetSel(hoverIdx);
        base.OnMouseMove(e);
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left || closing) return;
        downId = Hit(e.X, e.Y - TOP);
        int i = downId == null ? -1 : Array.IndexOf(Ids, downId);
        if (i >= 0) { held[i] = true; press[i] = 1; }
        if (downId == null) { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); }
        base.OnMouseDown(e);
    }

    protected override void OnMouseUp(MouseEventArgs e)
    {
        Array.Clear(held);
        int my = e.Y - TOP;
        var id = Hit(e.X, my);
        if (id != null && id == downId) DoPress(id, e.X, my);
        downId = null;
        base.OnMouseUp(e);
    }

    protected override bool ProcessCmdKey(ref Message msg, Keys k)
    {
        switch (k)
        {
            case Keys.Up: DoPress("up", 0, 0); return true;
            case Keys.Down: DoPress("down", 0, 0); return true;
            case Keys.Left: DoPress("left", 0, 0); return true;
            case Keys.Right: DoPress("right", 0, 0); return true;
            case Keys.Enter: DoPress("A", 0, 0); return true;
            case Keys.Space: DoPress("START", 0, 0); return true;
            case Keys.Escape: case Keys.Back: DoPress("B", 0, 0); return true;
            case Keys.F1: _ = RunDiagnostic(); return true;
        }
        return base.ProcessCmdKey(ref msg, k);
    }

    [DllImport("user32.dll")] static extern bool ReleaseCapture();
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, int m, int w, int l);

    void DoPress(string id, int mx, int my)
    {
        if (closing) return;
        int pi = Array.IndexOf(Ids, id);
        if (pi >= 0) press[pi] = 1;
        if (id == "close") { _ = PowerOff(); return; }
        if (id == "min") { WindowState = FormWindowState.Minimized; return; }
        if (!booted && id != "cart") { if (pi >= 0 || id == "lcd") SkipBoot(); return; }
        switch (id)
        {
            case "opt": GoPage("set"); break;
            case "up": Nav(-1); break;
            case "down": Nav(1); break;
            case "left": if (page == "home") SetSel(0); break;
            case "right": if (page == "home" && homeSel == 0) SetSel(1); break;
            case "A": ActivateSelection(); break;
            case "B": Back(); break;
            case "START": _ = Launch(); break;
            case "SELECT": GoPage("upd"); break;
            case "cart": _ = Reinsert(); break;
            case "lcd": { int i = LcdIndex(mx, my); if (i >= 0) { SetSel(i); ActivateSelection(); } break; }
        }
    }

    void SetSel(int i) { if (page == "home") homeSel = i; else listSel = i; }

    void Nav(int d)
    {
        int n = page == "home" ? 5 : Rows().Count, cur = page == "home" ? homeSel : listSel;
        SetSel((cur + d + n) % n);
    }

    void GoPage(string p)
    {
        if (p == page) return;
        Array.Copy(fb, snap, fb.Length);
        wipe = 0; page = p; listSel = 0;
        var t = SelTarget(); for (int k = 0; k < 4; k++) selR[k] = t[k];
    }

    void Back() { if (page != "home") GoPage("home"); else _ = PowerOff(); }

    void ActivateSelection()
    {
        if (page == "home")
        {
            switch (homeSel)
            {
                case 0: _ = Launch(); break;
                case 1: GoPage("comm"); break;
                case 2: GoPage("upd"); break;
                case 3: GoPage("set"); break;
                case 4: _ = PowerOff(); break;
            }
        }
        else if (page == "comm") OpenLink(new[] { "discord", "site", "bug" }[listSel]);
        else if (page == "upd") { if (listSel == 0 && !updating && !launching) _ = ManualUpdate(); }
        else switch (listSel)
        {
            case 0: Prefs.Set("autoclose", !Prefs.Get("autoclose", true)); break;
            case 1: Prefs.Set("fx", !Prefs.Get("fx", true)); break;
            case 2: guest = !guest; Prefs.Set("guest", guest); break;
            case 3: Process.Start(new ProcessStartInfo("explorer.exe", root) { UseShellExecute = true }); break;
            case 4: OpenLogs(); break;
            case 5: _ = RunDiagnostic(true); break;
        }
    }

    // Éjecte un peu la cartouche puis la remet.
    async Task Reinsert() { cartTarget = Seat - 60; await Task.Delay(520); cartTarget = launching ? Deep : Seat; }

    async Task PowerOff()
    {
        if (closing) return;
        closing = true; cartTarget = -235;
        for (int i = 0; i <= 18; i++) { lcdPower = 1 - i / 18f; await Task.Delay(16); }
        lcdPower = 0;
        for (double o = 1; o > 0; o -= 0.1) { fade = (float)Math.Max(0, o); await Task.Delay(15); }
        Close();
    }

    // ───────────────────────── logique ─────────────────────────
    void SetServer(string text, Color tint) { serverTint = tint; }

    void LoadServers()
    {
        try
        {
            var f = Path.Combine(root, "launchers", "servers.txt");
            if (File.Exists(f))
                foreach (var l in File.ReadAllLines(f))
                {
                    var p = l.Split('|');
                    if (p.Length >= 3 && int.TryParse(p[2].Trim(), out var port)) servers.Add(new ServerInfo { Name = p[0].Trim(), Host = p[1].Trim(), Port = port });
                }
        }
        catch { }
        if (servers.Count == 0) servers.Add(new ServerInfo { Name = "HOENN" });
    }

    async Task RefreshServers()
    {
        while (!IsDisposed && !closing)
        {
            foreach (var s in servers.ToList())
            {
                var sw = Stopwatch.StartNew();
                try { using var c = new TcpClient(); using var t = new CancellationTokenSource(700); await c.ConnectAsync(s.Host, s.Port, t.Token); s.On = true; s.Ms = (int)Math.Max(1, sw.ElapsedMilliseconds); }
                catch { s.On = false; s.Ms = -1; }
            }
            if (!launching && !updating) { online = servers[0].On; ms = servers[0].Ms; SetServer("", online ? Mint : Gold); }
            await Task.Delay(8000);
        }
    }

    async Task StartupAsync() { if (!await CheckUpdates()) await Inspect(); }
    async Task ManualUpdate() { if (!await CheckUpdates()) await Inspect(); }

    async Task<bool> CheckUpdates()
    {
        playEnabled = false; updating = true; statusText = "Recherche des mises à jour…"; SetServer("", Gold); progTarget = 4;
        try
        {
            var service = new UpdateService(root);
            var result = await service.Check();
            updVersion = result.manifest?.version ?? "--";
            if (result.manifest == null || result.changed.Count == 0)
            {
                statusText = "Jeu à jour"; updShort = "A JOUR"; SetServer("", Mint); progTarget = 0; updating = false; return false;
            }
            updateBlocking = result.manifest.mandatory; updShort = $"{result.changed.Count} FICHIER(S)";
            statusText = $"Mise à jour {result.manifest.version}"; SetServer("", Gold);
            await service.DownloadAndApply(result.manifest, result.changed, (pct, name) => { progTarget = pct; statusText = $"Téléchargement… {pct} % — {name}"; }, Environment.ProcessId);
            statusText = "Installation et redémarrage…";
            await Task.Delay(700);
            Close();
            return true;
        }
        catch (HttpRequestException ex)
        {
            CrashLog.Write(ex); statusText = "GitHub temporairement indisponible"; updShort = "HORS LIGNE"; SetServer("", Gold); progTarget = 0; updating = false; return false;
        }
        catch (Exception ex)
        {
            CrashLog.Write(ex); updateBlocking = true; statusText = "Mise à jour impossible"; updShort = "ERREUR"; SetServer("", Danger); progTarget = 0; updating = false;
            MessageBox.Show(this, "La mise à jour obligatoire n'a pas pu être installée.\n\n" + ex.Message, "Pokémon Online — mise à jour", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return false;
        }
    }

    async Task Inspect()
    {
        updating = false;
        bool files = new[] { "Game.exe", "Game.rxdata", "mkxp.json", "launchers" }.All(x => File.Exists(Path.Combine(root, x)) || Directory.Exists(Path.Combine(root, x)));
        ms = await Ping(); online = ms >= 0;
        SetServer("", online ? Mint : Gold);
        bool running = Process.GetProcessesByName("Game").Length > 0;
        statusText = !files ? "Installation incomplète" : running ? "Le jeu est déjà lancé" : online ? $"Serveur {servers[0].Name} connecté" : "Prêt à jouer";
        playEnabled = files && !running && !updateBlocking;
        progTarget = 0;
    }

    async Task Launch()
    {
        if (!booted || closing) return;
        if (updateBlocking) { Info("La mise à jour obligatoire doit être installée avant de lancer le jeu."); return; }
        if (launching || updating || !playEnabled) return;
        launching = true; playEnabled = false; progTarget = 8; cartTarget = Deep;
        try
        {
            statusText = "Préparation de Hoenn…";
            if (!await Port())
            {
                SetServer("", Gold);
                string script = Path.Combine(root, "launchers", "Start-Eternal-Emerald-MMO.ps1");
                if (!File.Exists(script)) throw new FileNotFoundException("Le service de jeu est introuvable.");
                var arg = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" -NoGame" + (guest ? " -Guest" : "");
                var psi = new ProcessStartInfo(WindowsShell.Exe, arg)
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
            SetServer("", Mint);
            statusText = "Ouverture du jeu…";
            var info = new ProcessStartInfo(Path.Combine(root, "Game.exe")) { WorkingDirectory = root, UseShellExecute = false };
            if (guest) info.Environment["PEMK_INSTANCE"] = "guest";
            Process.Start(info);
            progTarget = 100; statusText = "Bonne aventure !";
            await Task.Delay(1300);
            if (Prefs.Get("autoclose", true)) { await PowerOff(); return; }
            launching = false; progTarget = 0; cartTarget = Seat; await Inspect();
        }
        catch (Exception ex)
        {
            progTarget = 0; statusText = "Le lancement a échoué"; SetServer("", Danger); cartTarget = Seat;
            MessageBox.Show(this, ex.Message + "\n\nOuvrez les journaux pour obtenir le détail.", "Pokémon Online", MessageBoxButtons.OK, MessageBoxIcon.Error);
            launching = false; playEnabled = true;
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
            var psi = new ProcessStartInfo(WindowsShell.Exe, args)
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
            diagBusy = false; statusText = before;
            MessageBox.Show(this, ex.Message, "Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally { diagBusy = false; }
        await Inspect();
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
            timer.Dispose(); fg?.Dispose(); frame?.Dispose(); if (hDib != IntPtr.Zero) DeleteObject(hDib); if (memDc != IntPtr.Zero) DeleteDC(memDc); shell?.Dispose(); overlay?.Dispose(); cartImg?.Dispose(); lcdBmp.Dispose();
            fTb.Dispose(); fLbl.Dispose(); fBrand.Dispose(); fAb.Dispose();
        }
        base.Dispose(disposing);
    }
}
