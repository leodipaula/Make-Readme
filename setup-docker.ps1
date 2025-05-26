[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$projectRoot = $PSScriptRoot
$scriptPath = Join-Path $projectRoot "Make-Docker.ps1"

$checkMark = [char]0x221A
$rocket = "*"
$warning = "!"

$hasUTF8Support = try {
    Write-Host "✅ Suporte a UTF-8" -ErrorAction Stop
    $true
}
catch {
    $false
}

$emoji = @{
    Check   = if ($hasUTF8Support) { "✅" } else { $checkMark }
    Rocket  = if ($hasUTF8Support) { "🚀" } else { $rocket }
    Warning = if ($hasUTF8Support) { "⚠️" } else { $warning }
}

$functionDefinition = @'
# >>> MAKE-DOCKER START
function Make-Docker {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$RepoPath = "."
    )

    if (-not (Test-Path $RepoPath -PathType Container)) {
        Write-Error "ERROR: O caminho informado nao existe ou nao e um diretorio: $RepoPath"
        return
    }

    Write-Host "🐳 Gerando README.md via Docker, por favor aguarde..." -ForegroundColor Yellow

    try {
        $absolutePath = Resolve-Path $RepoPath
        $dockerPath = if ($IsWindows) {
            ($absolutePath.Path -replace "\\", "/") -replace "^([A-Za-z]):", "/`$1"
        } elseif ($IsMacOS) {
            $absolutePath.Path -replace "^/Users", "/home"
        } else {
            $absolutePath.Path
        }

        $scriptPath = "SCRIPTPATH"
        & $scriptPath -RepoPath $dockerPath
    }
    catch {
        Write-Error "ERROR: Erro ao executar Make-Docker: $_"
    }
}

Set-Alias -Name mdr -Value Make-Docker -ErrorAction Stop
# <<< MAKE-DOCKER END
'@

$escapedPath = $scriptPath.Replace('\', '\\')
$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', $escapedPath)

$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', "`"$scriptPath`"")

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

    $pattern = '(?ms)# >>> MAKE-DOCKER START.*?# <<< MAKE-DOCKER END'
    if ($currentContent -match $pattern) {
        $currentContent = $currentContent -replace $pattern, ''
    }

    $updatedContent = $currentContent.TrimEnd() + "`n`n" + $functionDefinition
    [System.IO.File]::WriteAllText($psProfile, $updatedContent, [System.Text.Encoding]::UTF8)

    Write-Host "$($emoji.Check) Funcao Make-Docker instalada com sucesso!"
    Write-Host "`n$($emoji.Rocket) Para usar, feche e reabra o PowerShell, entao execute:" -ForegroundColor Yellow
    Write-Host "   Make-Docker -RepoPath <caminho-do-repositorio>" -ForegroundColor Cyan
    Write-Host "   # ou use o alias" -ForegroundColor Yellow
    Write-Host "   mdr <caminho-do-repositorio>" -ForegroundColor Cyan
}
catch {
    Write-Error "$($emoji.Warning) Erro durante a instalacao: $_"
    exit 1
}
