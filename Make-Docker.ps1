param (
    [Parameter(Position = 0)]
    [string]$RepoPath = "."
)

try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        $errorMsg = $dockerInfo | Out-String
        Write-Error "❌ Docker não está rodando. Inicie o Docker Desktop`nErro: $errorMsg"
        exit 1
    }
    
    if ($IsWindows) {
        if (-not ($dockerInfo | Select-String "Operating System: Linux")) {
            Write-Host "🔄 Alternando para modo Linux containers..." -ForegroundColor Yellow
            
            if (Get-Command "docker-switch-linux" -ErrorAction SilentlyContinue) {
                docker-switch-linux
                Start-Sleep -Seconds 5 
                
                $dockerInfo = docker info 2>&1
                if (-not ($dockerInfo | Select-String "Operating System: Linux")) {
                    Write-Error @"
❌ Não foi possível alternar para Linux containers automaticamente.

Por favor, faça manualmente:
1. Clique com o botão direito no ícone do Docker Desktop na bandeja do sistema
2. Selecione 'Switch to Linux containers...'
3. Aguarde a conclusão
4. Execute o comando novamente
"@
                    exit 1
                }
            }
            else {
                Write-Error @"
❌ Docker está configurado para Windows containers.

Para mudar para Linux containers:
1. Clique com o botão direito no ícone do Docker Desktop na bandeja do sistema
2. Selecione 'Switch to Linux containers...'
3. Aguarde a conclusão
4. Execute o comando novamente
"@
                exit 1
            }
        }
    }
    elseif ($IsMacOS) {
        Write-Host "✅ Docker está configurado corretamente (macOS)" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Docker está configurado corretamente (Linux)" -ForegroundColor Green
    }
}
catch {
    Write-Error "❌ Docker não está instalado ou acessível: $_"
    exit 1
}

if (-not (Test-Path $RepoPath)) {
    Write-Error "❌ Repository path does not exist: $RepoPath"
    exit 1
}

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    Write-Error "❌ Not a Git repository: $RepoPath"
    exit 1
}

try {
    $gitUrl = git -C $RepoPath ls-remote --get-url

    if ($gitUrl -match "github\.com[:/]+([^/]+)/([^/.]+)") {
        $user = $matches[1]
        $repo = $matches[2]
        $repoSlug = "$user/$repo"
    }
    else {
        Write-Error "❌ Invalid remote URL or repository not linked to GitHub."
        exit 1
    }

    $apiUrl = "https://api.github.com/repos/$repoSlug"
    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{
        "User-Agent" = "Make-Docker-Script"
        "Accept"     = "application/vnd.github.v3+json"
    }

    $repoName = $response.name
    $description = if ($response.description) { $response.description } else { "No description provided" }
    $language = if ($response.language) { $response.language } else { "Not specified" }

    $prompt = @"
Responda apenas o pedido. Gere um README.md em markdown para explicar com detalhes o intuito, como funciona e como contribuir para o seguinte projeto (Use emojis nos títulos):
Nome: $repoName
Descrição: $description
Linguagem: $language
URL: https://github.com/$repoSlug
"@
}
catch {
    Write-Error "❌ Failed to fetch repository information: $_"
    exit 1
}

$envPath = Join-Path $PSScriptRoot "gerador_readme/.env"
if (-not (Test-Path $envPath)) {
    Write-Error "❌ .env file not found at: $envPath"
    Write-Host "ℹ️ Create a .env file in gerador_readme directory with your HUGGINGFACE_API_TOKEN"
    exit 1
}

$envContent = Get-Content $envPath -Raw
if ($envContent -match 'HUGGINGFACE_API_TOKEN=(.+)') {
    $token = $matches[1].Trim()
}

if (-not $token) {
    Write-Error "❌ HUGGINGFACE_API_TOKEN não encontrada em gerador_readme/src/.env"
    exit 1
}

Write-Host "Checando se já existe a imagem make-readme..."
try {
    Push-Location $PSScriptRoot
    
    $imageExists = docker images -q make-readme 2>$null
    
    if (-not $imageExists) {
        Write-Host "🏗️ Construindo nova imagem..." -ForegroundColor Yellow
        docker build --platform linux/amd64 -t make-readme .
        
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao construir imagem Docker"
        }
        
        Write-Host "✅ Imagem Docker construída" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Usando a imagem existente" -ForegroundColor Green
    }
    
    Pop-Location
}
catch {
    Write-Error "❌ Erro ao construir imagem Docker: $_"
    if ((Get-Location).Path -ne $PSScriptRoot) {
        Pop-Location
    }
    exit 1
}

$absolutePath = Resolve-Path $RepoPath
$dockerVolume = if ($IsWindows) {
    ($absolutePath.Path -replace '\\', '/') -replace '^([A-Za-z]):', '/\L$1'
}
elseif ($IsMacOS) {
    $absolutePath.Path -replace '^/Users', '/home'
}
else {
    $absolutePath.Path
}

Write-Host "🚀 Running container..."
try {
    $escapedPrompt = $prompt -replace '"', '\"'

    $containerOutput = docker run --rm `
        -v "${dockerVolume}:/repo" `
        -e "HUGGINGFACE_API_TOKEN=$token" `
        make-readme --prompt "$escapedPrompt" 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Container execution failed: $($containerOutput)"
    }

    $readme = $containerOutput

    $lines = $readme -split "`n"
    
    $formattedLines = $lines | ForEach-Object {
        $line = $_
        
        if ($line -match '^```markdown\s*$' -or $line -match '^\s*```\s*$') {
            return $null
        }
        
        return $line
    }
    
    $readme = ($formattedLines | Where-Object { $_ -ne $null }) -join "`n"
    
    $readme = $readme -replace '<!--\s*BEGIN AUTO README\s*-->', ''
    $readme = $readme -replace '<!--\s*END AUTO README\s*-->', ''

    $readme = $readme.Trim()

    $readmePath = Join-Path $RepoPath "README.md"

    if (Test-Path $readmePath) {
        $original = Get-Content $readmePath -Raw -Encoding UTF8

        if ($original -match '(?s)<!-- BEGIN AUTO README -->.*?<!-- END AUTO README -->') {
            $newContent = $original -replace '(?s)<!-- BEGIN AUTO README -->.*?<!-- END AUTO README -->', @"
<!-- BEGIN AUTO README -->
$readme
<!-- END AUTO README -->
"@
            Set-Content -Path $readmePath -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "✅ README.md successfully updated within markers."
        }
        else {
            Copy-Item -Path $readmePath -Destination "$readmePath.backup" -Force
            Set-Content -Path $readmePath -Value $readme -Encoding UTF8
            Write-Host "✅ README.md sobrescrito (backup salvo em README.md.backup)."
        }
    }
    else {
        $wrapped = @"
<!-- BEGIN AUTO README -->
$readme
<!-- END AUTO README -->
"@
        Set-Content -Path $readmePath -Value $wrapped -Encoding UTF8
        Write-Host "✅ README.md feito com sucesso, confira em: $readmePath"
    }
}
catch {
    Write-Error "❌ Container error: $_"
    exit 1
}
