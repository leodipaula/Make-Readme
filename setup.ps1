$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Readme.ps1"

Write-Host "🔧 Compilando o binário gerador_readme..."
Push-Location "$projectRoot\gerador_readme"
cargo build --release
Pop-Location

$functionDefinition = @'
# >>> MAKE-README START
<#
.SYNOPSIS
    Gera um README.md para um repositório Git usando IA.
.DESCRIPTION
    Utiliza IA para gerar um README.md formatado baseado nas informações do repositório.
.PARAMETER RepoPath
    O caminho para o repositório Git.
.EXAMPLE
    Make-Readme -RepoPath "C:\MeuProjeto"
#>
function Make-Readme {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$RepoPath
    )

    if (-not (Test-Path $RepoPath -PathType Container)) {
        Write-Error "❌ O caminho informado não existe ou não é um diretório: $RepoPath"
        return
    }

    Write-Host "⏳ Gerando README.md, por favor aguarde..." -ForegroundColor Yellow

    try {
        # Executa o script principal
        & "SCRIPTPATH" -RepoPath $RepoPath
        Write-Host "✅ README.md gerado com sucesso!" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Erro ao executar Make-Readme: $_"
    }
}

Set-Alias -Name mr -Value Make-Readme
# <<< MAKE-README END
'@

$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', $scriptPath)

$psProfile = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $psProfile)) {
    New-Item -Path $psProfile -ItemType File -Force | Out-Null
    Write-Host "✅ Arquivo de perfil criado em: $psProfile"
}

$currentProfile = Get-Content $psProfile -Raw -ErrorAction SilentlyContinue
if (-not $currentProfile) { $currentProfile = "" }

$startMarker = "# >>> MAKE-README START"
$endMarker = "# <<< MAKE-README END"
$pattern = "(?ms)$startMarker.*?$endMarker"

if ($currentProfile -match $pattern) {
    $updatedProfile = [regex]::Replace($currentProfile, $pattern, $functionDefinition)
    Write-Host "🔄 Atualizando função Make-Readme existente..."
}
else {
    $updatedProfile = $currentProfile.TrimEnd() + "`n`n" + $functionDefinition
    Write-Host "➕ Adicionando nova função Make-Readme..."
}

Set-Content -Path $psProfile -Value $updatedProfile -Force -Encoding UTF8

Write-Host "✅ Função Make-Readme instalada com sucesso!"
Write-Host "`n🎉 Para usar, feche e reabra o PowerShell, então execute:" -ForegroundColor Yellow
Write-Host "   Make-Readme -RepoPath <caminho-do-repositório>" -ForegroundColor Cyan
Write-Host "`n💡 ou também você pode usar o alias:" -ForegroundColor Yellow
Write-Host "   mr <caminho-do-repositório>" -ForegroundColor Cyan