param(
    [Parameter(Mandatory=$true)]
    [string]$RepoUrl,

    [string]$Branch = "main",

    [string]$CommitMessage = "checkpoint: Phase 1 accepted and Phase 2A in progress"
)

$ErrorActionPreference = "Stop"

Write-Host "TrackerDigitalModel Git bootstrap" -ForegroundColor Cyan
Write-Host "Working directory: $(Get-Location)"

if (-not (Test-Path ".\TrackerDigitalModel.prj")) {
    Write-Warning "TrackerDigitalModel.prj was not found in the current directory."
    Write-Warning "Run this script from the MATLAB project root."
    $answer = Read-Host "Continue anyway? (y/N)"
    if ($answer -notin @("y","Y")) {
        exit 1
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is not available in PATH."
}

if (-not (Test-Path ".git")) {
    git init
}

# Make sure the intended default branch exists locally.
git checkout -B $Branch

# Configure remote safely.
$existingOrigin = git remote 2>$null | Where-Object { $_ -eq "origin" }
if ($existingOrigin) {
    $currentUrl = git remote get-url origin
    if ($currentUrl -ne $RepoUrl) {
        Write-Host "Updating origin from '$currentUrl' to '$RepoUrl'"
        git remote set-url origin $RepoUrl
    }
} else {
    git remote add origin $RepoUrl
}

Write-Host ""
Write-Host "Git status before add:" -ForegroundColor Yellow
git status --short

Write-Host ""
Write-Host "Checking for files larger than GitHub's normal 100 MB per-file limit..." -ForegroundColor Yellow
$large = Get-ChildItem -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.Length -ge 100MB
    } |
    Select-Object FullName, @{Name='SizeMB';Expression={[math]::Round($_.Length / 1MB, 2)}}

if ($large) {
    $large | Format-Table -AutoSize
    throw "At least one file is >= 100 MB. Remove it, ignore it, or intentionally configure Git LFS before pushing."
}

git add -A

Write-Host ""
Write-Host "Staged summary:" -ForegroundColor Yellow
git status --short

$hasStaged = git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m $CommitMessage
} else {
    Write-Host "No new staged changes to commit."
}

Write-Host ""
Write-Host "Pushing to $RepoUrl ($Branch)..." -ForegroundColor Cyan
git push -u origin $Branch

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Next recommended local branch:"
Write-Host "  git checkout -b dev/phase2a"
