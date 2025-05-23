$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Readme.ps1"

Write-Host "🔧 Compilando o binário gerador_readme..."
Push-Location "$projectRoot\gerador_readme"
cargo build --release
Pop-Location

# Define the function with proper string formatting
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
        [Parameter(Position=0)]
        [string]$RepoPath = "."
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

# Replace placeholder with actual path
$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', $scriptPath)

# Clean up and update profile
$psProfile = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $psProfile)) {
    New-Item -Path $psProfile -ItemType File -Force | Out-Null
}

# Read current profile content
$currentContent = Get-Content $psProfile -Raw -ErrorAction SilentlyContinue
if (-not $currentContent) { $currentContent = "" }

# Remove any existing Make-Readme function
$pattern = '(?ms)# >>> MAKE-README START.*?# <<< MAKE-README END'
$updatedContent = [regex]::Replace($currentContent, $pattern, '')

# Add the new function definition
$updatedContent += "`n`n" + $functionDefinition

# Write the updated content back to the profile
Set-Content -Path $psProfile -Value $updatedContent -Force -Encoding UTF8

Write-Host "✅ Função Make-Readme instalada com sucesso!"
Write-Host "`n🎉 Para usar, feche e reabra o PowerShell, então execute:" -ForegroundColor Yellow
Write-Host "   Make-Readme -RepoPath <caminho-do-repositório>" -ForegroundColor Cyan
Write-Host "`n💡 ou também você pode usar o alias:" -ForegroundColor Yellow
Write-Host "   mr <caminho-do-repositório>" -ForegroundColor Cyan