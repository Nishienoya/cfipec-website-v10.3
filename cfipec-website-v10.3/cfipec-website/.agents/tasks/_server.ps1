param($root, $port)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $res = $ctx.Response
    $rel = $ctx.Request.Url.AbsolutePath.TrimStart("/")
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
  } catch { break }
}
$listener.Close()
