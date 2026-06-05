$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$InfraDir = Join-Path $ProjectRoot "infra"

Set-Location $InfraDir

terraform init
terraform apply -auto-approve
terraform output alb_url
