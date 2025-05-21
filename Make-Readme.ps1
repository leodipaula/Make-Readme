param (
    [Parameter(Mandatory = $true)]
    [string]$RepoPath
)

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

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{
            "User-Agent" = "Make-Readme-Script"
            "Accept"     = "application/vnd.github.v3+json"
        }
    }
    catch {
        Write-Error "❌ Failed to fetch repository information: $_"
        exit 1
    }

    $repoName = $response.name
    $description = if ($response.description) { $response.description } else { "No description provided" }
    $language = if ($response.language) { $response.language } else { "Not specified" }

    $prompt = @"
Responda apenas o pedido. Gere um README.md em markdown para o seguinte projeto:
Nome: $repoName
Descrição: $description
Linguagem: $language
URL: https://github.com/$repoSlug
"@

    $rustProjectPath = Join-Path $PSScriptRoot "gerador_readme"
    $envPath = Join-Path $rustProjectPath ".env"
    
    if (-not (Test-Path $envPath)) {
        Write-Error "❌ .env file not found at: $envPath"
        Write-Host "ℹ️ Please create a .env file in $rustProjectPath with your HUGGINGFACE_API_TOKEN"
        exit 1
    }

    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $env:HUGGINGFACE_API_TOKEN = $matches[2].Trim()
        }
    }

    if (-not $env:HUGGINGFACE_API_TOKEN) {
        Write-Error "❌ HUGGINGFACE_API_TOKEN not found in .env file"
        exit 1
    }

    $geradorPath = Join-Path $PSScriptRoot "gerador_readme\target\release\gerador_readme.exe"
    if (-not (Test-Path $geradorPath)) {
        Write-Error "❌ gerador_readme.exe not found at: $geradorPath"
        Write-Host "ℹ️ Run 'cargo build --release' in the gerador_readme directory"
        exit 1
    }

    try {
        $argumentos = @("--prompt", $prompt)
        $output = & $geradorPath @argumentos | Out-String

        if ($LASTEXITCODE -eq 0) {
            $readme = $output.Trim() -replace "`r`n", "`n"
            
            $readme = $readme -replace '```markdown\s*', '' -replace '```\s*$', ''
            
            $readme = $readme -replace '(?m)^#', "`n#" -replace '\n{3,}', "`n`n"
        }
        else {
            throw "gerador_readme.exe failed with exit code $LASTEXITCODE`nOutput: $output"
        }

        if ([string]::IsNullOrEmpty($readme)) {
            throw "No output generated from gerador_readme.exe"
        }
    }
    catch {
        Write-Error "❌ Failed to generate README: $_"
        exit 1
    }

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
            Write-Host "✅ README.md overwritten (backup saved as README.md.backup)."
        }
    }
    else {
        $wrapped = @"
<!-- BEGIN AUTO README -->
$readme
<!-- END AUTO README -->
"@
        Set-Content -Path $readmePath -Value $wrapped -Encoding UTF8
        Write-Host "✅ README.md created successfully at: $readmePath"
    }

}
catch {
    Write-Error "❌ An unexpected error occurred: $_"
    exit 1
}
