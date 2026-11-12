$ErrorActionPreference = 'Continue'
$raiz = Split-Path -Parent $PSScriptRoot
$versionArgo = 'v3.5.7'

function Revisar($mensaje) {
    if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: $mensaje" -ForegroundColor Red; exit 1 }
}

$kind = (Get-Command kind -ErrorAction SilentlyContinue).Source
if (-not $kind) { $kind = Join-Path $HOME '.local\bin\kind.exe' }
if (-not (Test-Path $kind)) { Write-Host 'Falta kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation'; exit 1 }

docker info --format '{{.ServerVersion}}' 2>&1 | Out-Null
Revisar 'Docker Desktop no esta encendido'

$clusters = & $kind get clusters 2>&1
if ($clusters -notcontains 'gitops-demo') {
    Write-Host '1/5 Creando el cluster local (kind)...'
    & $kind create cluster --config (Join-Path $PSScriptRoot 'kind.yaml') --wait 180s
    Revisar 'no se pudo crear el cluster'
} else {
    Write-Host '1/5 El cluster gitops-demo ya existe'
}
kubectl config use-context kind-gitops-demo | Out-Null

Write-Host "2/5 Instalando Argo CD $versionArgo (la primera vez descarga imagenes, puede tardar)..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - | Out-Null
kubectl apply -n argocd --server-side --force-conflicts -f "https://raw.githubusercontent.com/argoproj/argo-cd/$versionArgo/manifests/install.yaml" | Out-Null
Revisar 'no se pudo instalar Argo CD'

Write-Host '3/5 Ajustando Argo CD para la demo (revisa Git cada 15 s, interfaz en http://localhost:8081)...'
$parches = Join-Path $PSScriptRoot 'parches'
kubectl -n argocd patch configmap argocd-cm --type merge --patch-file (Join-Path $parches 'argocd-cm.yaml') | Out-Null
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge --patch-file (Join-Path $parches 'argocd-cmd-params-cm.yaml') | Out-Null
kubectl -n argocd patch service argocd-server --patch-file (Join-Path $parches 'argocd-server-svc.yaml') | Out-Null
Revisar 'no se pudo ajustar Argo CD'
kubectl -n argocd rollout restart deployment argocd-server argocd-repo-server | Out-Null
kubectl -n argocd rollout restart statefulset argocd-application-controller | Out-Null
kubectl -n argocd rollout status deployment argocd-server --timeout=900s | Out-Null
kubectl -n argocd rollout status deployment argocd-repo-server --timeout=900s | Out-Null
kubectl -n argocd rollout status statefulset argocd-application-controller --timeout=900s | Out-Null
Revisar 'Argo CD no arranco a tiempo'

Write-Host '4/5 Registrando la aplicacion: Argo CD empieza a vigilar el repo'
kubectl apply -f (Join-Path $raiz 'argocd\aplicacion.yaml') | Out-Null
Revisar 'no se pudo registrar la aplicacion'

Write-Host '5/5 Esperando el primer despliegue desde Git...'
$limite = (Get-Date).AddMinutes(5)
do {
    Start-Sleep -Seconds 3
    $listos = kubectl -n medicops get deployment medicops-estado -o jsonpath='{.status.readyReplicas}' 2>$null
} until ([int]"0$listos" -ge 1 -or (Get-Date) -gt $limite)
if ([int]"0$listos" -lt 1) { Write-Host 'La aplicacion no quedo lista en 5 minutos: revisa http://localhost:8081'; exit 1 }

Write-Host ''
Write-Host 'Listo.'
Write-Host '  Aplicacion MedicOps:  http://localhost:8080'
Write-Host '  Argo CD:              http://localhost:8081  (usuario admin; corre demo\2-abrir.ps1 para copiar la clave)'
