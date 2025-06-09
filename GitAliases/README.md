This module provides a collection of short, convenient aliases for common Git commands to speed up your development workflow in the terminal.

## Alias Reference

### Status & Logging


| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| gs | git status | Show the working tree status. |
| gss | git status -s | Show a brief, short-format status. |
| glog | git log | Show the standard commit log. |
| glg | git log --graph --oneline --decorate --all | Display a compact, graphical log history. |
| glo | git log --oneline | Show a one-line summary for each commit. |
| gls | git log --stat | Show commit log with file change statistics. |
| glp | git log --patch | Show commit log with the full diff (patch) of changes. |

### Staging & Committing

| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| ga | git add | Stage a file. |
| gaa | git add --all | Stage all changes. |
| gc | git commit | Record changes to the repository (opens editor). |
| gcm | git commit -m | Commit with an inline message. |
| gca | git commit --amend | Amend the previous commit (opens editor). |
| gcan | git commit --amend --no-edit | Amend, but keep the previous commit message. |

### Branching & Checkout

| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| gb | git branch | List all local branches. |
| gba | git branch -a | List all local and remote branches. |
| gco | git checkout | Switch branches or restore files. |
| gcb | git checkout -b | Create a new branch and switch to it. |

### Remote Operations

| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| gp | git push | Push commits to a remote repository. |
| gpf | git push --force-with-lease | A safer way to force push. |
| gl | git pull | Fetch from and integrate with another repo. |
| glr | git pull --rebase | Fetch and rebase onto the remote branch. |
| gf | git fetch | Download objects from another repository. |
| gfa | git fetch --all --prune | Fetch all remotes and remove deleted ones. |

### Diffs

| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| gd | git diff | Show changes between commits, commit and working tree, etc. |
| gds | git diff --staged | Show changes between the index and HEAD (what you've staged). |

### Stash

| Alias | Full Command | Description |
| ----- | ------------ | ----------- |
| gst | git stash | Stash the changes in a dirty working directory. |
| gstp | git stash pop | Apply stashed changes and remove from stash. |
| gstl | git stash list | List all stashed changes. ||
