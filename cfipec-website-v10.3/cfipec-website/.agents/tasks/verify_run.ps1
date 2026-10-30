# =========================================================
# verify_run.ps1
# Real verification for the "remove For Workers + feature JobOrders" change.
# Steps:
#   1. Serve the site with an in-process .NET HttpListener (file:// won't honor ?demo=signedin).
#   2. Use Microsoft Edge headless --dump-dom to capture the RENDERED DOM (menu.js executed).
#   3. Inspect the rendered DOM for the required markers (with real excerpts as evidence).
#   4. Grep reachable HTML for any remaining worker-page hrefs.
#   5. Confirm the six worker page files still exist on disk.
#   6. Write everything to .agents/tasks/verify.txt.
# =========================================================

$ErrorActionPreference = 'Stop'
$site     = 'c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website'
$tasksDir = 'c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/.agents/tasks'
$edge     = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$port     = 8137
$base     = "http://localhost:$port"
$domDir   = Join-Path $tasksDir '_dom'
New-Item -ItemType Directory -Force -Path $domDir | Out-Null
$tempProfile = Join-Path ([IO.Path]::GetTempPath()) "edge_verify_profile_$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tempProfile | Out-Null

# ---------- 1. Static file server (in-process runspace, so the live HttpListener object is shared) ----------
$mimes = @{
  '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'
  '.css'='text/css; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'
  '.jpeg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'
  '.json'='application/json'; '.woff'='font/woff'; '.woff2'='font/woff2'
  '.ttf'='font/ttf'; '.map'='application/json'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

$server = [PowerShell]::Create()
[void]$server.AddScript({
  param($listener, $site, $mimes)
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
      $req = $ctx.Request; $resp = $ctx.Response
      $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
      if ($rel -eq '/' -or $rel -eq '') { $rel = '/index.html' }
      $path = Join-Path $site ($rel.TrimStart('/').Replace('/', '\'))
      if ((Test-Path -LiteralPath $path) -and -not (Test-Path -LiteralPath $path -PathType Container)) {
        $ext = [IO.Path]::GetExtension($path).ToLower()
        $ct  = if ($mimes.ContainsKey($ext)) { $mimes[$ext] } else { 'application/octet-stream' }
        $bytes = [IO.File]::ReadAllBytes($path)
        $resp.ContentType = $ct
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      } else { $resp.StatusCode = 404 }
    } catch { $resp.StatusCode = 500 } finally { $resp.Close() }
  }
}).AddArgument($listener).AddArgument($site).AddArgument($mimes)
$serverHandle = $server.BeginInvoke()

# wait for server to be ready
$ready = $false
for ($i=0; $i -lt 20; $i++) {
  try { $r = Invoke-WebRequest -Uri "$base/index.html" -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -eq 200) { $ready=$true; break } } catch { Start-Sleep -Milliseconds 150 }
}
if (-not $ready) { throw "HTTP server did not become ready on port $port" }

# ---------- 2. Dump rendered DOM via Edge headless ----------
function Dump-Dom($url, $outFile) {
  & $edge --headless=new --disable-gpu --no-first-run --no-default-browser-check `
    --user-data-dir="$tempProfile" --dump-dom "$url" 2>$null |
    Out-File -LiteralPath $outFile -Encoding utf8
  return (Get-Content -LiteralPath $outFile -Raw)
}

$domIndex    = Join-Path $domDir 'index_signedout.html'
$domSignedIn= Join-Path $domDir 'index_signedin.html'
$domIso      = Join-Path $domDir 'iso-17024.html'
$domCountry  = Join-Path $domDir 'country-template.html'

$null = Dump-Dom "$base/index.html"              $domIndex
$null = Dump-Dom "$base/index.html?demo=signedin" $domSignedIn
$null = Dump-Dom "$base/iso-17024.html"          $domIso
$null = Dump-Dom "$base/country-template.html"   $domCountry

# ---------- stop server ----------
$listener.Stop()
$server.EndInvoke($serverHandle)
$server.Dispose()

# ---------- 3. Helpers to extract rendered excerpts ----------
function Get-Match($text, $pattern) { if ($text -match $pattern) { $matches[0] } else { $null } }
function Has($text,$p){ $text -match $p }

# ---------- 4. Build evidence ----------
$idx   = Get-Content -LiteralPath $domIndex     -Raw
$sgn   = Get-Content -LiteralPath $domSignedIn -Raw
$iso   = Get-Content -LiteralPath $domIso      -Raw
$ctry  = Get-Content -LiteralPath $domCountry  -Raw

$report = New-Object System.Text.StringBuilder
function Add-Line($s) { [void]$report.AppendLine($s) }

Add-Line "================================================================"
Add-Line "VERIFY.TXT  (verification re-run, iteration 2)"
Add-Line "Task: Remove the For Workers nav flow; feature JobOrders on the landing page."
Add-Line "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Add-Line "Site root: $site"
Add-Line "Edge binary: $edge"
Add-Line "================================================================"
Add-Line ""
Add-Line "## Commands run"
Add-Line "1. In-process .NET HttpListener static server on http://localhost:$port/ serving $site"
Add-Line "   (file:// was avoided because the signed-in state is read from ?demo=signedin"
Add-Line "    via URLSearchParams, which file:// URLs do not reliably honor.)"
Add-Line "2. Microsoft Edge headless DOM capture per page:"
Add-Line "   msedge --headless=new --disable-gpu --no-first-run --no-default-browser-check"
Add-Line "          --user-data-dir=<temp> --dump-dom <url>   (=> rendered DOM after JS)"
Add-Line "   Pages dumped (saved under .agents/tasks/_dom/):"
Add-Line "     - index.html            -> _dom/index_signedout.html"
Add-Line "     - index.html?demo=signedin -> _dom/index_signedin.html"
Add-Line "     - iso-17024.html        -> _dom/iso-17024.html"
Add-Line "     - country-template.html -> _dom/country-template.html"
Add-Line "3. PowerShell grep (Select-String) for remaining worker-page hrefs across all"
Add-Line "   reachable (non-orphan) HTML files."
Add-Line "4. File-existence check for the six worker page HTML files."
Add-Line ""

# ---- A. Pre-sign-in nav ----
Add-Line "## A. Pre-sign-in navigation (rendered DOM of index.html)"
$navBlock = Get-Match $idx '(?s)<ul class="nav-list">.*?</ul>'
Add-Line "Rendered <ul class=""nav-list""> excerpt:"
Add-Line ($navBlock -replace '(?m)^','    ')
Add-Line ""
$forWorkersInNav = Has $idx 'For Workers'
Add-Line ("A1. 'For Workers' present anywhere in rendered index.html DOM : " + [bool]$forWorkersInNav + "  (expected: False)")
$joNavLink = Get-Match $idx '(?s)<a class="nav-link[^"]*"[^>]*href="https://joborders\.cfipec\.org"[^>]*>.*?</a>'
Add-Line ("A2. JOBORDERS top-level nav link is the external platform : " + [bool][bool]$joNavLink)
if ($joNavLink) { Add-Line ("     -> " + $joNavLink) }
Add-Line ("A3. JOBORDERS nav link opens a new tab (target=_blank, rel=noopener) : " + [bool]($(Has $idx 'href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer"')))
$browseInNav = Has $idx 'browse-joborders\.html'
Add-Line ("A4. Any internal link to browse-joborders.html in rendered index.html : " + [bool]$browseInNav + "  (expected: False)")
Add-Line ""

# ---- B. Post-sign-in profile menu ----
Add-Line "## B. Post-sign-in profile menu (rendered DOM of index.html?demo=signedin)"
$profileMenu = Get-Match $sgn '(?s)<div class="submenu submenu--right profile-menu">.*?</div>\s*</li>'
Add-Line "Rendered profile-menu excerpt:"
Add-Line ($profileMenu -replace '(?m)^','    ')
Add-Line ""
$workerTerms = 'My Worker Profile','My Profile','My CV','My Certification','Career Pathway','worker-profile\.html','worker-cv\.html','worker-certification\.html','career-pathway\.html','my-joborders\.html'
$hits = @()
foreach ($t in $workerTerms) { if (Has $sgn $t) { $hits += $t } }
Add-Line ("B1. Worker-related items present in rendered signed-in DOM : " + ($hits -join ', ')) 
if ($hits.Count -eq 0) { Add-Line "     -> NONE (expected)" }
Add-Line ("B2. Profile menu shows Account Details link : " + [bool]$(Has $sgn 'account-details\.html'))
Add-Line ("B3. Profile menu shows Settings link : " + [bool]$(Has $sgn 'account-settings\.html'))
Add-Line ("B4. Profile menu shows Log out link : " + [bool]$(Has $sgn 'data-logout'))
Add-Line ""
# signed-in footer account column
$footerAcct = Get-Match $sgn '(?s)<div class="footer-col"><h3>Account</h3>.*?</div>'
Add-Line "Rendered signed-in footer 'Account' column excerpt:"
Add-Line ($footerAcct -replace '(?m)^','    ')
Add-Line ""

# ---- C. Landing page JobOrders feature ----
Add-Line "## C. Landing page JobOrders feature (rendered DOM of index.html)"
$joSection = Get-Match $idx '(?s)<section class="section section--alt" id="joborders">.*?</section>'
Add-Line ("C1. #joborders feature section rendered : " + [bool][bool]$joSection)
Add-Line ("C2. Light logo used on dark gradient panel : " + [bool]$(Has $idx 'assets/images/JOBORDERS_logo_light\.png'))
Add-Line ("C3. Logo has alt text : " + [bool]$(Has $idx '<img src="assets/images/JOBORDERS_logo_light\.png" alt="JOBORDERS logo"'))
$joCta = Get-Match $idx '(?s)<a class="btn btn-primary"[^>]*href="https://joborders\.cfipec\.org"[^>]*>Go to JOBORDERS.*?</a>'
Add-Line ("C4. 'Go to JOBORDERS' CTA points to external platform : " + [bool][bool]$joCta)
Add-Line ("C5. Feature CTA opens new tab + keyboard-navigable (<a href> with target/rel) : " + [bool]$(Has $idx 'href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer"'))
Add-Line "Rendered #joborders section excerpt:"
Add-Line ($joSection -replace '(?m)^','    ')
Add-Line ""

# ---- D. Quick-links card (finding 2 fix) ----
Add-Line "## D. Quick-links JOBORDERS card accessibility (review finding 2)"
$joCard = Get-Match $idx '(?s)<a class="card reveal"[^>]*href="https://joborders\.cfipec\.org"[^>]*>.*?</a>'
Add-Line "Rendered JOBORDERS quick-link card excerpt:"
Add-Line ($joCard -replace '(?m)^','    ')
Add-Line ""
Add-Line ("D1. Card NO LONGER has aria-label (so accessible name = contents) : " + (-not [bool]$(Has $joCard 'aria-label="')))
Add-Line ("D2. Card has visually-hidden 'Opens in a new tab' span : " + [bool]$(Has $joCard '<span class="visually-hidden">Opens in a new tab</span>'))
Add-Line ("D3. Card keeps descriptive <p> in the DOM (announced as accessible name) : " + [bool]$(Has $joCard '<p>Learn how to register'))
Add-Line ("D4. cards--2 two-card grid class present in static index.html : " + [bool]$(Has $idx 'class="container cards cards--2"'))
Add-Line ""

# ---- E. Reachable-page CTAs repointed ----
Add-Line "## E. Reachable-page CTAs repointed to external JobOrders"
$isoCta = Get-Match $iso '(?s)<div class="cta-actions">.*?</div>'
Add-Line ("E1. iso-17024.html CTA points to external platform : " + [bool]$(Has $iso 'href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer"'))
Add-Line ("E2. iso-17024.html CTA no longer links worker-certification : " + (-not [bool]$(Has $iso 'worker-certification\.html|data-page="workerCertification"')))
Add-Line ("E3. country-template.html CTA points to external platform : " + [bool]$(Has $ctry 'href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer"'))
Add-Line ("E4. country-template.html no longer links browse-joborders.html : " + (-not [bool]$(Has $ctry 'browse-joborders\.html')))
Add-Line ""

# ---- F. Grep: remaining worker-page hrefs in reachable (non-orphan) HTML ----
Add-Line "## F. Regression grep: remaining hrefs to worker pages (reachable pages only)"
$workerPages = @('worker-certification.html','worker-cv.html','worker-profile.html','career-pathway.html','my-joborders.html','browse-joborders.html')
$allHtml = Get-ChildItem -LiteralPath $site -Filter *.html
$reachable = $allHtml | Where-Object { $workerPages -notcontains $_.Name }
$pattern = ($workerPages -join '|')
$grepResults = $reachable | Select-String -Pattern $pattern
if ($grepResults) {
  Add-Line "MATCHES FOUND (unexpected):"
  foreach ($m in $grepResults) { Add-Line ("   $($m.Filename):$($m.LineNumber): $($m.Line.Trim())" ) }
} else {
  Add-Line "   NONE - no reachable HTML links to any worker page. (expected: PASS)"
}
Add-Line ""

# ---- G. menu.js source checks ----
Add-Line "## G. menu.js source checks (no For Workers nav / worker profile group)"
$menuJs = Get-Content -LiteralPath (Join-Path $site 'menu.js') -Raw
Add-Line ("G1. menu.js has no 'For Workers' MAIN entry text : " + (-not [bool]$(Has $menuJs 'For Workers')))
Add-Line ("G2. menu.js has no workerKeys/workerItems locals : " + (-not [bool]$(Has $menuJs 'workerKeys|workerItems')))
Add-Line ("G3. menu.js defines JOBORDERS_URL external constant : " + [bool]$(Has $menuJs 'const JOBORDERS_URL = "https://joborders.cfipec.org"'))
Add-Line ("G4. menu.js defines isExternal helper : " + [bool]$(Has $menuJs 'function isExternal'))
Add-Line ""

# ---- H. Worker page files still on disk ----
Add-Line "## H. Worker page files still exist on disk (kept, unlinked)"
foreach ($f in $workerPages) {
  $p = Join-Path $site $f
  Add-Line ("   $f : exists=" + (Test-Path -LiteralPath $p))
}
Add-Line ""

# ---- I. Per-file change list ----
Add-Line "## I. Per-file change list (this iteration 2 = fix review findings)"
Add-Line "   index.html"
Add-Line "     - Fixed review finding 2: removed aria-label from the JOBORDERS quick-link card"
Add-Line "       (it was overriding the accessible name derived from the card's h2+p, dropping"
Add-Line "       the descriptive sentence for screen readers). Added a visually-hidden"
Add-Line "       '<span class=visually-hidden>Opens in a new tab</span>' so the description is"
Add-Line "       announced as the accessible name AND the new-tab hint is still conveyed."
Add-Line "     - (Iteration 1 already: hero/CTA/quick-link JOBORDERS links -> external;"
Add-Line "        For Workers card removed; #joborders feature section added.)"
Add-Line "   home.css"
Add-Line "     - Added '.visually-hidden' utility (screen-reader-only text) used by the card fix."
Add-Line "     - (Iteration 1 already: .jo-feature-list, .jo-feature-logo, .cards--2 grid.)"
Add-Line "   menu.js   (unchanged this iteration; iteration-1 edits verified intact)"
Add-Line "     - JOBORDERS nav -> external https://joborders.cfipec.org (no dropdown);"
Add-Line "       For Workers removed from MAIN; worker group removed from profile menu + footer."
Add-Line "   iso-17024.html, country-template.html (unchanged this iteration; verified intact)"
Add-Line "     - CTAs repointed to external JobOrders."
Add-Line "   Worker files kept on disk, unlinked: worker-profile.html, worker-cv.html,"
Add-Line "     worker-certification.html, career-pathway.html, my-joborders.html, browse-joborders.html."
Add-Line ""

# ---- J. Summary verdict ----
$passA = (-not $forWorkersInNav) -and [bool]$joNavLink -and (-not $browseInNav)
$passB = ($hits.Count -eq 0) -and (Has $sgn 'account-details\.html') -and (Has $sgn 'account-settings\.html') -and (Has $sgn 'data-logout')
$passC = [bool]$joSection -and (Has $idx 'JOBORDERS_logo_light\.png') -and [bool]$joCta
$passD = (-not (Has $joCard 'aria-label="')) -and (Has $joCard '<span class="visually-hidden">Opens in a new tab</span>')
$passE = (Has $iso 'href="https://joborders.cfipec.org"') -and (Has $ctry 'href="https://joborders.cfipec.org"')
$passF = (-not $grepResults)
$passG = (-not (Has $menuJs 'For Workers')) -and (-not (Has $menuJs 'workerKeys|workerItems')) -and (Has $menuJs 'const JOBORDERS_URL')
$passH = ($workerPages | ForEach-Object { Test-Path -LiteralPath (Join-Path $site $_) }) -notcontains $false

Add-Line "## J. Summary"
Add-Line ("A. Pre-sign-in nav has no 'For Workers', JOBORDERS links external    : " + [bool]$passA)
Add-Line ("B. Post-sign-in profile menu has no worker buttons                : " + [bool]$passB)
Add-Line ("C. Landing page features JobOrders (section + logo + external CTA) : " + [bool]$passC)
Add-Line ("D. Quick-links card aria-label fix (finding 2)                     : " + [bool]$passD)
Add-Line ("E. Reachable CTAs repointed to JobOrders                          : " + [bool]$passE)
Add-Line ("F. No reachable page links to worker pages (grep)                  : " + [bool]$passF)
Add-Line ("G. menu.js has no For Workers / worker profile group               : " + [bool]$passG)
Add-Line ("H. Worker page files still exist on disk                           : " + [bool]$passH)
Add-Line ""
$allPass = $passA -and $passB -and $passC -and $passD -and $passE -and $passF -and $passG -and $passH
Add-Line ("OVERALL: " + $(if ($allPass) { 'PASS' } else { 'FAIL' }))

# ---------- write report ----------
$verifyPath = Join-Path $tasksDir 'verify.txt'
$report.ToString() | Out-File -LiteralPath $verifyPath -Encoding utf8

Write-Output "verify.txt written to: $verifyPath"
Write-Output "OVERALL: $(if ($allPass) { 'PASS' } else { 'FAIL' })"
Write-Output "Rendered DOM dumps in: $domDir"

# cleanup temp profile
try { Remove-Item -LiteralPath $tempProfile -Recurse -Force -ErrorAction SilentlyContinue } catch {}
