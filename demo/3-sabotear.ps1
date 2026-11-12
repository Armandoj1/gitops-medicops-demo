kubectl config use-context kind-gitops-demo | Out-Null
Write-Host 'Borrando a mano la aplicacion de produccion, sin pasar por Git...'
kubectl -n medicops delete deployment medicops-estado
Write-Host 'Mira Argo CD y la pagina: en segundos vuelve sola. Ctrl+C para salir.'
kubectl -n medicops get pods --watch
