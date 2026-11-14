param([switch]$SinNavegador)

$ErrorActionPreference = 'Continue'
$raiz = Split-Path -Parent $PSScriptRoot
$pagina = 'http://localhost:8080'
$editar = 'https://github.com/Armandoj1/gitops-medicops-demo/edit/main/app/deployment.yaml'
$tiempos = [ordered]@{}

function Titulo($texto) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor DarkCyan
    Write-Host "  $texto" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor DarkCyan
}

function Linea($texto, $color = 'Gray') { Write-Host "  $texto" -ForegroundColor $color }

function Frase($texto) { Write-Host "  DI: `"$texto`"" -ForegroundColor Yellow }

function Pausa($texto) {
    Write-Host ''
    Write-Host "  >> $texto" -ForegroundColor Green -NoNewline
    $respuesta = [Console]::ReadLine()
    if ($null -eq $respuesta) { return '' }
    return $respuesta.Trim()
}

function VersionPagina {
    $html = curl.exe -s --max-time 2 $pagina
    if ("$html" -match 'Estado v(\d+\.\d+)') { return $Matches[1] }
    return ''
}

function PodsListos {
    $n = kubectl -n medicops get deployment medicops-estado -o jsonpath='{.status.readyReplicas}' 2>$null
    return [int]"0$n"
}

function IdDeployment {
    return (kubectl -n medicops get deployment medicops-estado -o jsonpath='{.metadata.uid}' 2>$null)
}

function Cronometro([scriptblock]$listo, [int]$limite = 180) {
    $inicio = Get-Date
    $avisado = $false
    while ($true) {
        $seg = [int]((Get-Date) - $inicio).TotalSeconds
        if (& $listo) { Write-Host ''; return $seg }
        if ($seg -ge $limite) { Write-Host ''; return -1 }
        if ($seg -ge 45 -and -not $avisado) {
            Write-Host ''
            Linea 'Va lento: en Argo CD (localhost:8081) dale al boton REFRESH de la aplicacion.' 'Magenta'
            $avisado = $true
        }
        Write-Host -NoNewline "`r  Esperando... $seg s   "
        Start-Sleep -Seconds 1
    }
}

function Resultado($nombre, $seg, $texto) {
    if ($seg -lt 0) {
        Linea "No se vio el cambio a tiempo. Revisa Argo CD en http://localhost:8081" 'Red'
        $tiempos[$nombre] = 'sin completar'
    } else {
        Linea "$texto en $seg segundos." 'Green'
        $tiempos[$nombre] = "$seg s"
    }
}

Titulo 'DEMO GITOPS - preparando'
kubectl config use-context kind-gitops-demo 2>$null | Out-Null
docker info --format '{{.ServerVersion}}' 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Linea 'Docker Desktop esta apagado: lo enciendo (tarda menos de un minuto)...' 'Yellow'
    $docker = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (Test-Path $docker) { Start-Process $docker }
    $limite = (Get-Date).AddMinutes(4)
    do {
        Start-Sleep -Seconds 5
        docker info --format '{{.ServerVersion}}' 2>&1 | Out-Null
    } until ($LASTEXITCODE -eq 0 -or (Get-Date) -gt $limite)
    if ($LASTEXITCODE -ne 0) { Linea 'Docker no arranco. Abre Docker Desktop a mano y vuelve a correr esto.' 'Red'; exit 1 }
    Start-Sleep -Seconds 10
}
$kind = (Get-Command kind -ErrorAction SilentlyContinue).Source
if (-not $kind) { $kind = Join-Path $HOME '.local\bin\kind.exe' }
$existe = (Test-Path $kind) -and (@(& $kind get clusters 2>$null) -contains 'gitops-demo')
if ($existe) {
    Linea 'Despertando el cluster...'
    $limite = (Get-Date).AddMinutes(2)
    do {
        kubectl get --raw /readyz 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds 3
    } until ((Get-Date) -gt $limite)
    $limite = (Get-Date).AddMinutes(2)
    while ((PodsListos) -lt 1 -and (Get-Date) -lt $limite) { Start-Sleep -Seconds 3 }
}
if ((PodsListos) -lt 1) {
    Linea 'El cluster no esta listo: lo preparo ahora (1 minuto, o 10 si es la primera vez)...' 'Yellow'
    & (Join-Path $PSScriptRoot '1-preparar.ps1')
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

$limite = (Get-Date).AddMinutes(4)
while ((curl.exe -s -o NUL -w '%{http_code}' --max-time 2 $pagina) -ne '200' -or (curl.exe -s -o NUL -w '%{http_code}' --max-time 2 'http://localhost:8081') -ne '200') {
    if ((Get-Date) -gt $limite) { Linea 'La pagina o Argo CD no responden. Corre demo\1-preparar.ps1' 'Red'; exit 1 }
    Write-Host -NoNewline "`r  Esperando a que la pagina y Argo CD respondan (normal si Docker acaba de arrancar)...   "
    Start-Sleep -Seconds 3
}
Write-Host ''

git -C $raiz pull --quiet 2>&1 | Out-Null
$version = VersionPagina
Linea "La pagina esta en la version $version con $(PodsListos) pods."
if ($version -ne '1.0') {
    Linea 'OJO: deberia arrancar en la version 1.0. Si quedo en 2.0 de un ensayo, haz solo el ACTO 3 antes de empezar.' 'Red'
}

if (-not $SinNavegador) {
    $codificada = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($codificada)) | Set-Clipboard
    Start-Process $pagina
    Start-Process 'http://localhost:8081'
    Start-Process $editar
    Linea 'Abri 3 pestanas: la pagina (8080), Argo CD (8081) y el editor del YAML en GitHub.'
    Linea 'Argo CD: usuario admin, la clave ya esta en el portapapeles (Ctrl+V).'
}

Pausa 'Cuando estes listo para el ACTO 1, presiona Enter '

Titulo 'ACTO 1 - Un commit es un despliegue'
Linea 'En la pestana de GitHub (editor del YAML) cambia estas 4 lineas:'
Linea '   replicas: 2                      ->  replicas: 4' 'White'
Linea '   VERSION  value: "1.0"            ->  value: "2.0"' 'White'
Linea '   COLOR    value: "#0f766e"        ->  value: "#7c3aed"' 'White'
Linea '   MENSAJE  value: "Todos los..."   ->  value: "Nueva version desplegada desde Git"' 'White'
Linea 'Luego boton verde "Commit changes" -> "Commit directly to main" -> "Commit changes".'
Linea 'Plan B (sin internet en el navegador o sin sesion en GitHub): escribe B y Enter, y el cambio lo hago yo desde aqui.' 'DarkGray'
$eleccion = Pausa 'Cuando hayas hecho el commit, presiona Enter (o B + Enter) '
if ($eleccion -match '^[bB]') {
    $archivo = Join-Path $raiz 'app\deployment.yaml'
    $yaml = [IO.File]::ReadAllText($archivo)
    $yaml = $yaml.Replace('replicas: 2', 'replicas: 4').Replace('value: "1.0"', 'value: "2.0"').Replace('value: "#0f766e"', 'value: "#7c3aed"').Replace('value: "Todos los servicios operando con normalidad"', 'value: "Nueva version desplegada desde Git"')
    [IO.File]::WriteAllText($archivo, $yaml)
    git -C $raiz add app/deployment.yaml
    git -C $raiz commit --quiet -m 'Despliega la version 2.0 de la pagina de estado'
    git -C $raiz push --quiet 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Linea 'No se pudo hacer push a GitHub. Revisa la conexion.' 'Red'; exit 1 }
    Linea 'Commit hecho y subido a GitHub.' 'Green'
}
Linea 'Ahora muestra Argo CD: en unos segundos ve el commit nuevo y sincroniza solo.'
Frase 'Nadie se conecto al servidor: solo hicimos un commit.'
$seg = Cronometro { (VersionPagina) -eq '2.0' -and (PodsListos) -ge 4 }
Resultado 'Acto 1 (commit a version 2)' $seg 'La pagina paso a la version 2 con 4 pods'
Linea 'Muestra la pagina: ahora es morada y dice v2.0.'

Pausa 'Cuando quieras el ACTO 2 (sabotaje), presiona Enter '

Titulo 'ACTO 2 - Alguien borra produccion a mano'
Frase 'Imaginen que alguien con todos los permisos borra la aplicacion de produccion.'
$antes = IdDeployment
kubectl -n medicops delete deployment medicops-estado --wait=false
Linea 'Borrada. Mira Argo CD: la app sale en rojo un instante y la vuelve a crear.'
$seg = Cronometro { $id = IdDeployment; $id -and $id -ne $antes -and (PodsListos) -ge 1 } 120
Resultado 'Acto 2 (autocorreccion)' $seg 'Argo CD la volvio a crear y ya esta atendiendo'
Frase 'El cambio que no esta en Git no sobrevive. Es el termostato.'

Pausa 'Cuando quieras el ACTO 3 (rollback), presiona Enter '

Titulo 'ACTO 3 - La version 2 salio mal: rollback con Git'
git -C $raiz pull --quiet 2>&1 | Out-Null
$tocados = git -C $raiz diff --name-only HEAD~1 HEAD
if ("$tocados".Trim() -ne 'app/deployment.yaml') {
    Linea "El ultimo commit no es el cambio del acto 1 (toco: $tocados). No reviertas a ciegas: revisa el historial en GitHub." 'Red'
    exit 1
}
Linea 'Ejecutando en la carpeta del repo:' 'White'
Linea '   git revert --no-edit HEAD' 'White'
git -C $raiz revert --no-edit HEAD
Linea '   git push' 'White'
git -C $raiz push --quiet 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Linea 'No se pudo hacer push a GitHub. Revisa la conexion.' 'Red'; exit 1 }
Frase 'No borramos historia: agregamos un commit que deshace el anterior.'
$seg = Cronometro { (VersionPagina) -eq '1.0' -and (PodsListos) -eq 2 }
Resultado 'Acto 3 (rollback a version 1)' $seg 'La pagina volvio a la version 1 con 2 pods'
Linea 'Muestra en GitHub el historial de commits: el despliegue y la reversa, con autor y hora.'
if (-not $SinNavegador) { Start-Process 'https://github.com/Armandoj1/gitops-medicops-demo/commits/main' }

Titulo 'DEMO TERMINADA'
foreach ($k in $tiempos.Keys) { Linea ("{0,-32} {1}" -f $k, $tiempos[$k]) 'White' }
Write-Host ''
