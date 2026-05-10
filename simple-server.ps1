$port = 8000
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Host "Server started on port $port"
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $line = $reader.ReadLine()
        if ($line) {
            $file = $line.Split(' ')[1].Trim('/')
            if ($file -eq '' -or $file -eq '/') { $file = 'index.html' }
            
            # Remove query strings or anchors
            $file = $file.Split('?')[0].Split('#')[0]
            
            if (Test-Path $file) {
                $content = [System.IO.File]::ReadAllBytes((Get-Item $file).FullName)
                $ext = [System.IO.Path]::GetExtension($file).ToLower()
                $contentType = switch ($ext) {
                    ".html" { "text/html; charset=utf-8" }
                    ".css" { "text/css" }
                    ".js" { "application/javascript" }
                    ".png" { "image/png" }
                    ".jpg" { "image/jpeg" }
                    ".jpeg" { "image/jpeg" }
                    ".gif" { "image/gif" }
                    ".svg" { "image/svg+xml" }
                    default { "application/octet-stream" }
                }
                $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($content.Length)`r`nConnection: close`r`n`r`n"
                $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($content, 0, $content.Length)
            } else {
                $msg = "404 Not Found: $file"
                $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n$msg"
                $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
            }
        }
        $client.Close()
    }
} finally {
    $listener.Stop()
}
