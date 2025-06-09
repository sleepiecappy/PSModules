<#
.SYNOPSIS
    A collection of convenient aliases for common Git operations.
.DESCRIPTION
    This module provides a set of short, easy-to-remember aliases to speed up
    your command-line workflow with Git.
#>

# --- Alias Definitions ---

# Status & Logging
Set-Alias -Name 'gs' -Value 'git status'
Set-Alias -Name 'gss' -Value 'git status -s' # Short status
Set-Alias -Name 'glog' -Value 'git log'
Set-Alias -Name 'glg' -Value 'git log --graph --oneline --decorate --all'
Set-Alias -Name 'glo' -Value 'git log --oneline' # Log with one line per commit
Set-Alias -Name 'gls' -Value 'git log --stat' # Log with stats (file changes)
Set-Alias -Name 'glp' -Value 'git log --patch' # Log with patch (full diff)
# Staging & Committing
Set-Alias -Name 'ga' -Value 'git add'
Set-Alias -Name 'gaa' -Value 'git add --all'
Set-Alias -Name 'gc' -Value 'git commit'
Set-Alias -Name 'gcm' -Value 'git commit -m'
Set-Alias -Name 'gca' -Value 'git commit --amend'
Set-Alias -Name 'gcan' -Value 'git commit --amend --no-edit'

# Branching & Checkout
Set-Alias -Name 'gb' -Value 'git branch'
Set-Alias -Name 'gba' -Value 'git branch -a' # All branches (local and remote)
Set-Alias -Name 'gco' -Value 'git checkout'
Set-Alias -Name 'gcb' -Value 'git checkout -b' # Create new branch

# Remote Operations
Set-Alias -Name 'gp' -Value 'git push'
Set-Alias -Name 'gpf' -Value 'git push --force-with-lease' # Safer force push
Set-Alias -Name 'gl' -Value 'git pull'
Set-Alias -Name 'glr' -Value 'git pull --rebase'
Set-Alias -Name 'gf' -Value 'git fetch'
Set-Alias -Name 'gfa' -Value 'git fetch --all --prune' # Fetch all and prune deleted

# Diffs
Set-Alias -Name 'gd' -Value 'git diff'
Set-Alias -Name 'gds' -Value 'git diff --staged' # Diff staged changes

# Stash
Set-Alias -Name 'gst' -Value 'git stash'
Set-Alias -Name 'gstp' -Value 'git stash pop'
Set-Alias -Name 'gstl' -Value 'git stash list'


# --- Export Members ---
# Export all the newly created aliases so they are available to the user.
Export-ModuleMember -Alias 'gs', 'gss', 'glg', 'glog', 'ga', 'gaa', 'gc', 'gcm', 'gca', 'gcan', 'gb', 'gba', 'gco', 'gcb', 'gp', 'gpf', 'gl', 'glr', 'gf', 'gfa', 'gd', 'gds', 'gst', 'gstp', 'gstl'

