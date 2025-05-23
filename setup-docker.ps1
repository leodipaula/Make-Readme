$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Docker.ps1"

$functionDefinition = @'
# >>> MAKE-DOCKER START
<#
.SYNOPSIS
    Gera um README.md usando Docker.
.DESCRIPTION
    Compila e executa o gerador de README via Docker com o repositório informado.
.PARAMETER RepoPath
    O caminho para o repositório Git.
.EXAMPLE
    Make-Docker -RepoPath "C:\MeuProjeto"
    mdr .  # Usa o diretório atual
#>
function Make-Docker {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$RepoPath = "."
    )

    if (-not (Test-Path $RepoPath -PathType Container)) {
        Write-Error "❌ O caminho informado não existe ou não é um diretório: $RepoPath"
        return
    }

    Write-Host "🐋 Gerando README.md via Docker, por favor aguarde..." -ForegroundColor Yellow

    try {
        # Convert Windows paths to Docker-compatible paths
        $absolutePath = Resolve-Path $RepoPath
        $dockerPath = if ($IsWindows) {
            ($absolutePath.Path -replace '\\', '/') -replace '^([A-Za-z]):', '/\L$1'
        } else {
            $absolutePath.Path
        }

        & "SCRIPTPATH" -RepoPath $dockerPath
    }
    catch {
        Write-Error "❌ Erro ao executar Make-Docker: $_"
    }
}

Set-Alias -Name mdr -Value Make-Docker
# <<< MAKE-DOCKER END
'@

$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', $scriptPath)

$psProfile = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $psProfile)) {
    New-Item -Path $psProfile -ItemType File -Force | Out-Null
    Write-Host "✅ Arquivo de perfil criado em: $psProfile"
}

$currentContent = Get-Content $psProfile -Raw -ErrorAction SilentlyContinue
if (-not $currentContent) { $currentContent = "" }

$pattern = '(?ms)# >>> MAKE-DOCKER START.*?# <<< MAKE-DOCKER END'
if ($currentContent -match $pattern) {
    $currentContent = $currentContent -replace $pattern, ''
}

$updatedContent = $currentContent.TrimEnd() + "`n`n" + $functionDefinition

Set-Content -Path $psProfile -Value $updatedContent -Force -Encoding UTF8

Write-Host "✅ Função Make-Docker instalada com sucesso!"
Write-Host "`n🎉 Para usar, feche e reabra o PowerShell, então execute:" -ForegroundColor Yellow
Write-Host "   Make-Docker -RepoPath <caminho-do-repositório>" -ForegroundColor Cyan
Write-Host "   # ou use o alias" -ForegroundColor Yellow
Write-Host "   mdr <caminho-do-repositório>" -ForegroundColor Cyan
