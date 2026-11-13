param([int]$Veces = 0)

$ErrorActionPreference = 'Continue'
kubectl config use-context kind-gitops-demo 2>$null | Out-Null
$visitas = 12
$n = 0

while ($Veces -eq 0 -or $n -lt $Veces) {
    $n++
    $pods = @(kubectl -n medicops get pods -l app=medicops-estado --no-headers 2>$null)
    $conteo = [ordered]@{}
    $version = '-'
    for ($i = 0; $i -lt $visitas; $i++) {
        $html = "$(curl.exe -s --max-time 1 http://localhost:8080)"
        if ($html -match 'Estado v(\d+\.\d+)') { $version = $Matches[1] }
        if ($html -match 'pod (medicops-estado-[a-z0-9-]+)') { $quien = $Matches[1] } else { $quien = '(nadie respondio)' }
        $conteo[$quien] = 1 + [int]$conteo[$quien]
    }

    if ($Veces -eq 0) { Clear-Host }
    Write-Host ''
    Write-Host '  REPLICAS EN VIVO                        (Ctrl+C para salir)' -ForegroundColor Cyan
    Write-Host '  ------------------------------------------------------------' -ForegroundColor DarkCyan
    Write-Host "  Version de la pagina:  v$version" -ForegroundColor White
    $corriendo = @($pods | Where-Object { $_ -match '\sRunning\s' }).Count
    Write-Host "  Copias (pods) corriendo:  $corriendo" -ForegroundColor Yellow
    Write-Host ''
    foreach ($p in $pods) {
        $c = $p -split '\s+'
        Write-Host ("    {0,-36} {1,-12} lista {2,-5} edad {3}" -f $c[0], $c[2], $c[1], $c[4])
    }
    Write-Host ''
    Write-Host "  Quien atendio las ultimas $visitas visitas:" -ForegroundColor Cyan
    foreach ($k in $conteo.Keys) {
        $color = 'Green'
        if ($k -like '(*') { $color = 'Red' }
        Write-Host ("    {0,-36} {1} {2}" -f $k, ('#' * $conteo[$k]), $conteo[$k]) -ForegroundColor $color
    }
    Start-Sleep -Seconds 1
}
