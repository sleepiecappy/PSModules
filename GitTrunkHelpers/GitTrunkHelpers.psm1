
<#
.SYNOPSIS
    A PowerShell module with helper functions to streamline a Trunk-Based Development
    workflow using Git.
.DESCRIPTION
    This module simplifies common tasks such as creating, synchronizing, and cleaning up
    short-lived feature branches, ensuring they stay up-to-date with the main trunk
    (either 'main' or 'master').
#>
[CmdletBinding()]
param()

#------------------------------------------------------------------------------------------------
# Private Helper Functions
#------------------------------------------------------------------------------------------------

function Get-GitTrunkName
{
    <#
    .SYNOPSIS
        (Internal) Determines if the main branch is 'main' or 'master'.
    #>
    # Check for 'main' first as it's the modern default
    $mainExists = git branch --list main | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq 'main' }
    if ($mainExists)
    {
        return 'main'
    }

    $masterExists = git branch --list master | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq 'master' }
    if ($masterExists)
    {
        return 'master'
    }

    # Fallback if neither is found locally (e.g., in a new repo)
    return 'main'
}

#------------------------------------------------------------------------------------------------
# Public Functions
#------------------------------------------------------------------------------------------------

<#
.SYNOPSIS
    Starts a new feature branch from the latest version of the trunk.
.DESCRIPTION
    This function performs the following sequence:
    1. Switches to the main trunk branch ('main' or 'master').
    2. Pulls the latest changes from the remote.
    3. Prompts for a new feature branch name.
    4. Creates and checks out the new feature branch.
.EXAMPLE
    Start-GitFeature
    (You will be prompted to enter a branch name)
#>
function Start-GitFeature
{
    [CmdletBinding()]
    param()

    $trunk = Get-GitTrunkName
    Write-Host "Switching to trunk branch '$trunk'..." -ForegroundColor Cyan
    git checkout $trunk

    Write-Host "Pulling latest changes for '$trunk'..." -ForegroundColor Cyan
    git pull origin $trunk

    $featureName = Read-Host -Prompt "Enter the name for the new feature branch (e.g., 'login-validation')"
    if ([string]::IsNullOrWhiteSpace($featureName))
    {
        Write-Error "Feature name cannot be empty."
        return
    }

    $branchName = "feature/$featureName"
    Write-Host "Creating and switching to new branch '$branchName'..." -ForegroundColor Green
    git checkout -b $branchName
}

<#
.SYNOPSIS
    Syncs the current feature branch with the latest changes from the trunk.
.DESCRIPTION
    Keeps your feature branch up-to-date with the trunk using a rebase strategy.
    It performs the following sequence:
    1. Stashes any uncommitted local changes.
    2. Switches to the trunk and pulls the latest changes.
    3. Switches back to your feature branch.
    4. Rebases your feature branch on top of the updated trunk.
    5. Re-applies your stashed changes.
.EXAMPLE
    Sync-GitFeature
#>
function Sync-GitFeature
{
    [CmdletBinding()]
    param()

    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -like "main" -or $currentBranch -like "master")
    {
        Write-Error "You are already on the trunk. No need to sync."
        return
    }

    Write-Host "Stashing local changes..."
    git stash

    $trunk = Get-GitTrunkName
    Write-Host "Updating trunk '$trunk'..." -ForegroundColor Cyan
    git checkout $trunk
    git pull origin $trunk

    Write-Host "Returning to '$currentBranch'..." -ForegroundColor Cyan
    git checkout $currentBranch

    Write-Host "Rebasing '$currentBranch' onto '$trunk'..." -ForegroundColor Green
    git rebase $trunk

    Write-Host "Applying stashed changes..."
    git stash pop
}

<#
.SYNOPSIS
    Pushes the current feature branch to the remote to prepare for a pull request.
.DESCRIPTION
    Pushes the current branch to the remote repository and sets it to track the
    upstream branch. This is the final step before creating a pull request.
.EXAMPLE
    Complete-GitFeature
#>
function Complete-GitFeature
{
    [CmdletBinding()]
    param()

    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "Pushing '$currentBranch' to remote and setting upstream..." -ForegroundColor Green
    git push --set-upstream origin $currentBranch

    Write-Host "`n✅ Branch pushed successfully. You can now create a pull request." -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Cleans up local branches that have been merged into the trunk.
.DESCRIPTION
    Performs local repository cleanup by:
    1. Fetching the latest remote state and pruning deleted remote branches.
    2. Switching to the trunk and pulling the latest changes.
    3. Deleting all local branches that have already been merged into the trunk.
.EXAMPLE
    Cleanup-GitBranches
#>
function Cleanup-GitBranches
{
    [CmdletBinding()]
    param()

    Write-Host "Fetching remote state and pruning old branches..." -ForegroundColor Cyan
    git fetch --prune

    $trunk = Get-GitTrunkName
    Write-Host "Switching to '$trunk' to perform cleanup..." -ForegroundColor Cyan
    git checkout $trunk
    git pull origin $trunk

    Write-Host "Finding and deleting local branches already merged into '$trunk'..."
    $mergedBranches = git branch --merged $trunk | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "* $trunk" -and $_ -ne $trunk -and $_ -ne "master" -and $_ -ne "main"}

    if ($mergedBranches.Count -eq 0)
    {
        Write-Host "No merged branches to clean up." -ForegroundColor Green
        return
    }

    foreach ($branch in $mergedBranches)
    {
        Write-Host "  Deleting local branch '$branch'..." -ForegroundColor Yellow
        git branch -d $branch
    }

    Write-Host "`n✅ Cleanup complete." -ForegroundColor Green
}

# --- Alias Definitions ---
Set-Alias -Name 'sgf' -Value 'Start-GitFeature' -Description 'Alias for Start-GitFeature'
Set-Alias -Name 'syncf' -Value 'Sync-GitFeature' -Description 'Alias for Sync-GitFeature'
Set-Alias -Name 'cgf' -Value 'Complete-GitFeature' -Description 'Alias for Complete-GitFeature'
Set-Alias -Name 'cleanup' -Value 'Cleanup-GitBranches' -Description 'Alias for Cleanup-GitBranches'

Export-ModuleMember -Function 'Start-GitFeature', 'Sync-GitFeature', 'Complete-GitFeature', 'Cleanup-GitBranches' -Alias 'sgf', 'syncf', 'cgf', 'cleanup'
