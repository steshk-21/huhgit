# Contributing to huhgit

Thank you for your interest in contributing to huhgit. This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch from `main`
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

### Prerequisites

- Go 1.21 or later
- Git
- GitHub Personal Access Token with repo permissions

### Building

```bash
git clone https://github.com/Cod-e-Codes/huhgit.git
cd huhgit
go build
```

### Testing

```bash
go test ./...
```

## Code Standards

### Go Code

- Follow standard Go formatting (`gofmt -s`)
- Use `go vet` to check for issues
- Maintain test coverage
- Write clear, readable code

### Commit Messages

Use conventional commit format:

```
type(scope): description

Detailed explanation if needed
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Pull Request Process

1. Ensure your code passes all tests
2. Update documentation if needed
3. Add tests for new functionality
4. Keep pull requests focused and atomic
5. Provide clear description of changes

## Reporting Issues

When reporting issues, include:

- Operating system and version
- Go version
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages

## Feature Requests

Feature requests are welcome. Please:

- Check existing issues first
- Provide clear use case
- Explain the problem you're solving
- Consider implementation complexity

## Code of Conduct

- Be respectful and constructive
- Focus on the code, not the person
- Help others learn and improve
- Follow the golden rule

## Questions

For questions about contributing, open an issue with the `question` label.
