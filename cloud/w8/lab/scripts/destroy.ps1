$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$InfraDir = Join-Path $ProjectRoot "infra"

Set-Location $InfraDir

terraform destroy -auto-approve
