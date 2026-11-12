$kind = (Get-Command kind -ErrorAction SilentlyContinue).Source
if (-not $kind) { $kind = Join-Path $HOME '.local\bin\kind.exe' }
& $kind delete cluster --name gitops-demo
