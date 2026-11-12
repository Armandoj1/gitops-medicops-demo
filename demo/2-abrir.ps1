$ErrorActionPreference = 'Stop'
kubectl config use-context kind-gitops-demo | Out-Null
$codificada = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($codificada)) | Set-Clipboard
Start-Process 'http://localhost:8080'
Start-Process 'http://localhost:8081'
Start-Process 'https://github.com/Armandoj1/gitops-medicops-demo/blob/main/app/deployment.yaml'
Write-Host 'Clave de admin de Argo CD copiada al portapapeles (usuario: admin)'
