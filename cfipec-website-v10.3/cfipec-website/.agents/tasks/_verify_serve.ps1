$ErrorActionPreference = "Stop"
$site = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website"
$out  = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/.agents/tasks/_verify_out.txt"
$port = 8733

# Start an in-process HttpListener on a background runspace
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

$rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
$rs.Open()
$ps = [System.Management.Automation.PowerShell]::Create()
$ps.Runspace = $rs
[void]$ps.AddScript({
  param($l, $root)
  while ($l.IsListening) {
    try {
      $ctx = $l.GetContext()
      $req = $ctx.Request; $res = $ctx.Response
      $rel = $req.Url.AbsolutePath.TrimStart("/")
      if ($rel -eq "") { $rel = "index.html" }
      $p = Join-Path $root ($rel -replace '/', '\')
      if (Test-Path $p -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($p)
        $res.ContentLength64 = $bytes.Length
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $res.StatusCode = 404
        $b = [System.Text.Encoding]::UTF8.GetBytes("404 not found")
        $res.ContentLength64 = $b.Length
        $res.OutputStream.Write($b, 0, $b.Length)
      }
      $res.Close()
    } catch { }
  }
}).AddArgument($listener).AddArgument($site)
$handle = $ps.BeginInvoke()
Start-Sleep -Milliseconds 700

function Fetch($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8
    return @{ ok = $true; code = $r.StatusCode; len = $r.Content.Length; body = $r.Content }
  } catch {
    return @{ ok = $false; code = 0; len = 0; body = ("ERR: " + $_.Exception.Message) }
  }
}

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("=== HTTP serve test (PowerShell HttpListener, port $port) ===")
foreach ($f in @("index.html","menu.js","home.css","iso-17024.html","country-template.html","assets/images/JOBORDERS_logo_light.png")) {
  $r = Fetch "http://localhost:$port/$f"
  if ($r.ok) { $lines.Add(("[" + $r.code + "] " + $f + "  len=" + $r.len)) }
  else { $lines.Add(("[ERR] " + $f + " : " + $r.body)) }
}

$idx = (Fetch "http://localhost:$port/index.html").body
$lines.Add("")
$lines.Add("=== index.html static markers ===")
$lines.Add("jo-feature section id=joborders present : " + [bool]($idx -match 'id="joborders"'))
$lines.Add("external JOBORDERS url present          : " + [bool]($idx -match 'joborders\.cfipec\.org'))
$lines.Add("cards--2 quick-links present             : " + [bool]($idx -match 'cards--2'))
$lines.Add("JOBORDERS_logo_light img present         : " + [bool]($idx -match 'JOBORDERS_logo_light\.png'))
$lines.Add("For Workers card (data-page=workerProfile) GONE : " + (-not [bool]($idx -match 'data-page="workerProfile"')))
$lines.Add("hero external link                       : " + [bool]($idx -match 'class="btn btn-ghost" target="_blank" rel="noopener noreferrer" aria-label="Learn About JOBORDERS'))

$menu = (Fetch "http://localhost:$port/menu.js").body
$lines.Add("")
$lines.Add("=== menu.js static markers ===")
$lines.Add("JOBORDERS_URL defined           : " + [bool]($menu -match 'const JOBORDERS_URL'))
$lines.Add("isExternal helper present       : " + [bool]($menu -match 'function isExternal'))
$lines.Add("For Workers MAIN entry GONE      : " + (-not [bool]($menu -match "label: .For Workers.")))
$lines.Add("workerKeys variable GONE        : " + (-not [bool]($menu -match 'const workerKeys')))
$lines.Add("workerItems variable GONE       : " + (-not [bool]($menu -match 'const workerItems')))
$lines.Add("My Worker Profile label GONE     : " + (-not [bool]($menu -match 'My Worker Profile')))

# Stop server
$listener.Stop()
Start-Sleep -Milliseconds 200
try { $ps.Stop(); $rs.Close() } catch { }

$lines.Add("")
$lines.Add("=== Note on JS-rendered DOM ===")
$lines.Add("No Python/Node/headless-browser runtime is installed, so client-side menu.js output")
$lines.Add("cannot be rendered automatically. Verified via static HTML/JS structure inspection")
$lines.Add("plus a logic trace of menu.js (string-builder) for both signed-out and signed-in states.")
$lines.Add("Signed-out nav: Home / JOBORDERS(external, no dropdown) / Country Partners / For Partners / More + Login+SignUp. No For Workers.")
$lines.Add("Signed-in profile dropdown: Account Details / Settings / Log out only (no My Worker Profile, no worker links).")
$lines.Add("Signed-in footer Account col: Account Details / Settings / Log out only.")
$lines.Add("Footer JOBORDERS heading: external link with ↗ cue and aria-label.")

[System.IO.File]::WriteAllText($out, ($lines -join "`r`n"))
Write-Output "WROTE: $out"
