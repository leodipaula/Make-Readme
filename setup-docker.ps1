[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$projectRoot = $PSScriptRoot

# Get the full path to Make-Docker.ps1
$makeDockerPath = Join-Path $projectRoot "Make-Docker.ps1"
$makeDockerPath = [System.IO.Path]::GetFullPath($makeDockerPath)

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

    Write-Host "🐳 Gerando README.md via Docker, por favor aguarde..."

    try {
        # Use the pre-stored full path to Make-Docker.ps1
        $scriptPath = "MAKE_DOCKER_PATH"
        if (-not (Test-Path $scriptPath)) {
            throw "Script Make-Docker.ps1 não encontrado em: $scriptPath"
        }

        # Resolver caminho do repositório
        $RepoPath = Resolve-Path $RepoPath -ErrorAction Stop
        
        # Executar script com caminho completo
        & "$scriptPath" -RepoPath "$RepoPath"
        if (-not $?) {
            throw "Falha ao executar Make-Docker"
        }
    }
    catch {
        Write-Error "Erro ao executar Make-Docker: $_"
        return
    }
}

# Criar alias de forma segura
Set-Alias -Name mdr -Value Make-Docker -Option AllScope -Scope Global -Force
# <<< MAKE-DOCKER END
'@

# Replace placeholder with actual path
$functionDefinition = $functionDefinition.Replace('MAKE_DOCKER_PATH', $makeDockerPath)

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
    Write-Host "`n$($emoji.Rocket) Para usar:"
    Write-Host "    mdr [caminho-do-repositorio]"
}
catch {
    Write-Error "Erro durante a instalação: $_"
}
