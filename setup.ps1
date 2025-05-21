$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Readme.ps1"

Write-Host "🔧 Compilando o binário gerador_readme..."
Push-Location "$projectRoot\gerador_readme"
cargo build --release
Pop-Location

$profileFunction = @"
function Make-Readme {
    param (
        [string]\$RepoPath
    )
    & '$scriptPath' -RepoPath \$RepoPath
}
"@

$psProfile = $PROFILE
if (-not (Test-Path $psProfile)) {
    New-Item -Path $psProfile -ItemType File -Force | Out-Null
}

if (-not (Get-Content $psProfile | Select-String -Pattern "function Make-Readme")) {
    Add-Content -Path $psProfile -Value $profileFunction
    Write-Host "✅ Função Make-Readme adicionada ao perfil do PowerShell."
}
else {
    Write-Host "ℹ️ Função Make-Readme já está no perfil do PowerShell."
}

Write-Host "`n🎉 Tudo pronto! Abra um novo terminal e use:" -ForegroundColor Green
Write-Host "   Make-Readme <caminho-do-repositório>" -ForegroundColor Cyan
