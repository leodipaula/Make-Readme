[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Readme.ps1"

$checkMark = [char]0x221A
$rocket = "*"
$warning = "!"
$hourglass = "..."


$hasUTF8Support = try {
    Write-Host "✅ Suporte a UTF-8" -ErrorAction Stop
    $true
}
catch {
    $false
}

$emoji = @{
    Check     = if ($hasUTF8Support) { "✅" } else { $checkMark }
    Rocket    = if ($hasUTF8Support) { "🚀" } else { $rocket }
    Warning   = if ($hasUTF8Support) { "⚠️" } else { $warning }
    Hourglass = if ($hasUTF8Support) { "⏳" } else { $hourglass }
}

Write-Host "$($emoji.Rocket) Compilando o binário gerador_readme..."
try {
    Push-Location "$projectRoot\gerador_readme"
    cargo build --release
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao compilar o binário"
    }
    Pop-Location
}
catch {
    Write-Error "$($emoji.Warning) Erro durante a compilação: $_"
    if ((Get-Location).Path -ne $projectRoot) {
        Pop-Location
    }
    exit 1
}

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
        Write-Error "ERROR: O caminho informado nao existe ou nao e um diretorio: $RepoPath"
        return
    }

    Write-Host "INICIANDO: Gerando README.md, por favor aguarde..." -ForegroundColor Yellow

    try {
        & "SCRIPTPATH" -RepoPath $RepoPath
    }
    catch {
        Write-Error "ERROR: Erro ao executar Make-Readme: $_"
    }
}

Set-Alias -Name mr -Value Make-Readme
# <<< MAKE-README END
'@

$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', "`"$scriptPath`"" )

try {
    $psProfile = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path $psProfile)) {
        New-Item -Path $psProfile -ItemType File -Force -Encoding UTF8 | Out-Null
        Write-Host "$($emoji.Check) Arquivo de perfil criado em: $psProfile"
    }

    $currentContent = if (Test-Path $psProfile) {
        [System.IO.File]::ReadAllText($psProfile, [System.Text.Encoding]::UTF8)
    }
    else { "" }

    $pattern = '(?ms)# >>> MAKE-README START.*?# <<< MAKE-README END'
    if ($currentContent -match $pattern) {
        $currentContent = $currentContent -replace $pattern, ''
    }

    $updatedContent = $currentContent.TrimEnd() + "`n`n" + $functionDefinition
    [System.IO.File]::WriteAllText($psProfile, $updatedContent, [System.Text.Encoding]::UTF8)

    Write-Host "$($emoji.Check) Funcao Make-Readme instalada com sucesso!"
    Write-Host "`n$($emoji.Rocket) Para usar, feche e reabra o PowerShell, entao execute:" -ForegroundColor Yellow
    Write-Host "   Make-Readme -RepoPath <caminho-do-repositorio>" -ForegroundColor Cyan
    Write-Host "   # ou use o alias" -ForegroundColor Yellow
    Write-Host "   mr <caminho-do-repositorio>" -ForegroundColor Cyan
}
catch {
    Write-Error "$($emoji.Warning) Erro durante a instalacao: $_"
    exit 1
}