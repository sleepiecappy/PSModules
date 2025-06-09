A set of functions that implements the Git Trunk Workflow/

Here’s how you would use these commands in your daily work.

1. Start a New Task

You're ready to work on a new feature, like adding a "share button".

Use the alias for `Start-GitFeature`

```sgf```

The script will pull the latest from main and then prompt you.

```
Enter the name for the new feature branch (e.g., 'login-validation'): share-button
```

You are now on a new branch feature/share-button, ready to code.

2. Keep Your Branch Updated

A teammate has just merged a big change into main. To avoid integration problems later, you want to sync your branch.

While on your `feature/share-button` branch

```
syncf
````

The script will automatically update your branch with the latest from main using rebase, keeping your commit history clean.

3. Finish Your Work
You've completed and committed your changes for the share button. Now, you need to push it to create a pull request.

Use the alias for `Complete-GitFeature`

```
cgf
```

This pushes your branch to the remote repository. You can now go to GitHub, GitLab, or your Git provider of choice to open a pull request.

4. Clean Up After Merging
Your pull request has been approved and merged. Your local feature/share-button branch is no longer needed.

Use the alias for `Cleanup-GitBranches`

```cleanup```

This command will fetch the latest remote state and safely delete your local feature/share-button branch, along with any other local branches that have also been merged, keeping your repository tidy.
