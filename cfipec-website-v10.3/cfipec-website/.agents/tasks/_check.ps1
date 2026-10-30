$ErrorActionPreference = "Continue"
$site = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website"
$out  = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/.agents/tasks/_verify_out.txt"
$port = 8735

$lines = New-Object System.Collections.Generic.List[string]

function Fetch($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8
    return @{ ok=$true; code=$r.StatusCode; body=$r.Content }
  } catch {
    return @{ ok=$false; code=0; body=("ERR: " + $_.Exception.Message) }
  }
}

$lines.Add("=== HTTP serve test (PowerShell HttpListener, port $port) ===")
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
$lines.Add("cards--2 quick-links present             : " + [bool]($idx -match 'cards--2'))
$lines.Add("JOBORDERS_logo_light img present         : " + [bool]($idx -match 'JOBORDERS_logo_light\.png'))
$lines.Add("For Workers card GONE (no data-page=workerProfile) : " + (-not [bool]($idx -match 'data-page="workerProfile"')))

$menu = (Fetch "http://localhost:$port/menu.js").body
$lines.Add("")
$lines.Add("=== menu.js static markers ===")
$lines.Add("JOBORDERS_URL defined           : " + [bool]($menu -match 'const JOBORDERS_URL'))
$lines.Add("isExternal helper present       : " + [bool]($menu -match 'function isExternal'))
$lines.Add("For Workers MAIN entry GONE      : " + (-not [bool]($menu -match 'For Workers.\s*,\s*to:')))
$lines.Add("workerKeys variable GONE        : " + (-not [bool]($menu -match 'workerKeys')))
$lines.Add("workerItems variable GONE       : " + (-not [bool]($menu -match 'workerItems')))
$lines.Add("'My Worker Profile' label GONE   : " + (-not [bool]($menu -match 'My Worker Profile'))

[System.IO.File]::WriteAllText($out, ($lines -join "`r`n"))
Write-Output ("WROTE " + $out + " lines=" + $lines.Count)
