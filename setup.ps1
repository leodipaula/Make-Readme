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
function Make-Readme {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$RepoPath = "."
    )

    Write-Host "INICIANDO: Gerando README.md, por favor aguarde..."

    try {
        $scriptPath = "SCRIPTPATH"
        if (-not (Test-Path $scriptPath)) {
            throw "Script Make-Readme.ps1 não encontrado em: $scriptPath"
        }

        # Resolver caminho do repositório
        $RepoPath = Resolve-Path $RepoPath -ErrorAction Stop
        
        # Executar script com caminho completo
        & "$scriptPath" -RepoPath "$RepoPath"
        if (-not $?) {
            throw "Falha ao executar Make-Readme"
        }
    }
    catch {
        Write-Error "Erro ao executar Make-Readme: $_"
        return
    }
}

# Criar alias de forma segura
Set-Alias -Name mr -Value Make-Readme -Option AllScope -Scope Global -Force
# <<< MAKE-README END
'@

# Replace placeholder with actual path
$makeReadmePath = Join-Path $PSScriptRoot "Make-Readme.ps1"
$makeReadmePath = [System.IO.Path]::GetFullPath($makeReadmePath)
$functionDefinition = $functionDefinition.Replace('SCRIPTPATH', $makeReadmePath)

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