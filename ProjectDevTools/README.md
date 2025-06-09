# **ProjectDevTools PowerShell Module**

ProjectDevTools is a powerful PowerShell module designed to streamline a terminal-first development workflow. It provides context-aware commands that automatically detect your project's technology (like .NET, Node.js, Rust, etc.) and offers a system for managing project-specific environment configurations.

## **Key Features**

* **Context-Aware Commands:** Run the same command (e.g., Invoke-ProjectBuild) in any project, and the module will use the correct toolchain (dotnet build, npm run build, etc.).  
* **Project-Specific Configuration:** Create and load custom environment profiles for each project. Set environment variables, aliases, and helper functions that only exist when you're working on that project.  
* **Centralized Management:** All project profiles are stored in a single \~/.project\_profiles directory for easy backup and management.  
* **Custom Overrides:** Define custom Invoke-Build or Start-App functions in a project's profile to override the default behavior for complex projects.

## **Installation**

1. Find one of your PowerShell module paths by running $env:PSModulePath \-split ';'. A good user-specific location is typically \~\\Documents\\PowerShell\\Modules\\.  
2. Create a new folder named ProjectDevTools inside your chosen modules directory.  
3. Save the ProjectDevTools.psm1 and ProjectDevTools.psd1 files inside this new ProjectDevTools folder.  
4. Open a new PowerShell terminal. The functions will be automatically available.

## **Commands and Workflow**

This module is designed around a specific workflow: Index \-\> Enter \-\> Work.

### **1\. Sync-ProjectIndex**

This is the first command you should run. It scans a directory, finds all Git projects, and creates a corresponding configuration script for each one in \~/.project\_profiles.

| Command | Description |
| :---- | :---- |
| Sync-ProjectIndex | Scans \\$HOME for projects and creates config files. |
| Sync-ProjectIndex \-Path D:\\source | Scans a specific directory for projects. |

### **2\. Enter-Project**

This is the main entry point for working on a project. It replaces a simple cd.

| Command | Description |
| :---- | :---- |
| Enter-Project | Opens a filterable menu of all indexed projects to enter. |

**Workflow:**

1. Presents a filterable list of all projects found by Sync-ProjectIndex.  
2. When you select a project, it navigates to the project's directory.  
3. It then **loads the environment** by executing the project's corresponding .ps1 script from \~/.project\_profiles. Any aliases or environment variables you defined are now active.

### **3\. Edit-ProjectConfig**

Opens the configuration file for the project you are currently in.

| Command | Description |
| :---- | :---- |
| Edit-ProjectConfig | Opens \~/.project\_profiles\\\<current-project-name\>.ps1 in Neovim. |

Use this to add project-specific environment variables, aliases, or helper functions.

### **4\. Invoke-ProjectBuild & Start-Project**

These are your primary, context-aware commands for working on the project.

| Command | Description |
| :---- | :---- |
| Invoke-ProjectBuild | Runs the appropriate build command (e.g., dotnet build). |
| Start-Project | Runs the appropriate start command (e.g., npm start). |
| Start-Project \-Watch | Attempts to run the project in watch mode (e.g., dotnet watch run). |

### **5\. Show-ProjectLog**

A utility for cleaning up log output from a running application.

| Command | Description |
| :---- | :---- |
| Show-ProjectLog | Filters and highlights piped output in real-time. |

**Example:**

Start-Project | Show-ProjectLog \-Highlight "Error" \-Exclude "DEBUG"

This runs the project, hides all lines containing "DEBUG", and highlights any line containing "Error" in red.

## **Example Full Workflow**

1. **Index your code directory:**  

 ```
 Sync-ProjectIndex \-Path D:\\source
 ```

2. **Enter your API project:**  

```
 Enter-Project
 ```

*(Select my-dotnet-api from the menu.)*
   
3. **Enter your API project:**  

```
Edit-ProjectConfig

#   In the script file, add:

$env:ASPNETCORE\_ENVIRONMENT \= 'Development'  
Set-Alias \-Name "dtest" \-Value "dotnet test"

```

4. **Re-enter the project to apply changes:**  
 ```
 Enter-Project
 ```

 *(Select my-dotnet-api again. The environment variable and alias are now active.)*  
 
5. **Build and run:**  
 ```Invoke-ProjectBuild  
 Start-Project | Show-ProjectLog \-Highlight "Exception"
```


6. **Run your custom alias:**  

```
dtest \# Runs 'dotnet test'
```  
