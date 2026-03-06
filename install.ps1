# Bootstrap: fetches main script with no-cache to avoid CDN/proxy caching
$url = "https://raw.githubusercontent.com/Neel49/uBlock-Chrome-Setup/main/Install-uBlock-Chrome.ps1"
$r = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers @{"Cache-Control"="no-cache"; "Pragma"="no-cache"}
Invoke-Expression $r.Content
