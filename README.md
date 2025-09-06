# huhgit

`huhgit` is a terminal-based tool for interacting with GitHub repositories. It provides a TUI for pushing branches, creating pull requests, and generating conventional commits, all from the command line.

## Features

* Push local branches to a remote repository.
* Create pull requests with title and body input.
* Generate conventional commit messages interactively.
* Terminal-native interface with themes for a clean workflow.

## Requirements

* Go 1.21+
* Git installed and initialized in the repository
* GitHub Personal Access Token with repo permissions (`GITHUB_TOKEN` environment variable)

## Usage

1. Set your GitHub token:

   ```bash
   export GITHUB_TOKEN=your_personal_access_token
   ```
2. Build the tool:

   ```bash
   go build
   ```
3. Run the TUI:

   ```bash
   ./huhgit
   ```
4. Follow the prompts to push, create a pull request, and commit changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
