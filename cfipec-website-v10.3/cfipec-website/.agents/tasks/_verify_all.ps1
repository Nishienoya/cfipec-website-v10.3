$ErrorActionPreference = "Continue"
$site = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website"
$out  = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/.agents/tasks/_verify_out.txt"
$port = 8737

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("START " + (Get-Date -Format "o"))

# --- Background job that owns its own listener ---
$job = Start-Job -ScriptBlock {
  param($root,$port)
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$port/")
  $listener.Start()
  while ($listener.IsListening) {
    try {
      $ctx = $listener.GetContext()
      $res = $ctx.Response
      $rel = $ctx.Request.Url.AbsolutePath.TrimStart("/")
      if ($rel -eq "") { $rel = "index.html" }
      $p = Join-Path $root ($rel -replace '/','\')
      if (Test-Path $p -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($p)
        $res.ContentLength64 = $bytes.Length
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
      } else {
        $res.StatusCode = 404
        $b = [System.Text.Encoding]::UTF8.GetBytes("404")
        $res.OutputStream.Write($b,0,$b.Length)
      }
      $res.Close()
    } catch { break }
  }
} -ArgumentList $site,$port

Start-Sleep -Milliseconds 1500

function Fetch($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8
    return @{ ok=$true; code=$r.StatusCode; body=$r.Content }
  } catch {
    return @{ ok=$false; code=0; body=("ERR: " + $_.Exception.Message) }
  }
}

$lines.Add("")
$lines.Add("=== HTTP serve test (HttpListener, port $port) ===")
foreach ($f in @("index.html","menu.js","home.css","iso-17024.html","country-template.html","assets/images/JOBORDERS_logo_light.png")) {
  $r = Fetch "http://localhost:$port/$f"
  if ($r.ok) { $lines.Add("[" + $r.code + "] " + $f) }
  else { $lines.Add("[ERR] " + $f + " : " + $r.body) }
}

$idx = (Fetch "http://localhost:$port/index.html").body
$lines.Add("")
$lines.Add("=== index.html static markers ===")
$lines.Add("jo-feature section id=joborders present : " + [bool]($idx -match 'id="joborders"'))
$lines.Add("external JOBORDERS url present          : " + [bool]($idx -match 'joborders\.cfipec\.org'))
$lines.Add("cards--2 quick-links present            : " + [bool]($idx -match 'cards--2'))
$lines.Add("JOBORDERS_logo_light img present        : " + [bool]($idx -match 'JOBORDERS_logo_light\.png'))
$lines.Add("For Workers card GONE                   : " + (-not [bool]($idx -match 'data-page="workerProfile"')))

$menu = (Fetch "http://localhost:$port/menu.js").body
$lines.Add("")
$lines.Add("=== menu.js static markers ===")
$lines.Add("JOBORDERS_URL defined           : " + [bool]($menu -match 'const JOBORDERS_URL'))
$lines.Add("isExternal helper present       : " + [bool]($menu -match 'function isExternal'))
$lines.Add("For Workers MAIN entry GONE      : " + (-not [bool]($menu -match 'For Workers')))
$lines.Add("workerKeys variable GONE        : " + (-not [bool]($menu -match 'workerKeys')))
$lines.Add("workerItems variable GONE       : " + (-not [bool]($menu -match 'workerItems')))
$lines.Add("'My Worker Profile' label GONE   : " + (-not [bool]($menu -match 'My Worker Profile')))

Stop-Job $job -ErrorAction SilentlyContinue
Remove-Job $job -Force -ErrorAction SilentlyContinue

$lines.Add("")
$lines.Add("END " + (Get-Date -Format "o"))
[System.IO.File]::WriteAllText($out, ($lines -join "`r`n"))
