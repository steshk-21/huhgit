# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in huhgit, please report it responsibly.

### How to Report

1. **Do not** open a public issue
2. Email security details to: [security@example.com](mailto:security@example.com)
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- We will acknowledge receipt within 48 hours
- We will investigate and provide updates within 7 days
- We will coordinate disclosure timing with you
- We will credit you in the security advisory (unless you prefer anonymity)

### Scope

This security policy covers:
- huhgit binary and source code
- GitHub Actions workflows
- Documentation and examples

### Out of Scope

- Third-party dependencies (report to their maintainers)
- Issues in development/testing environments
- Social engineering attacks
- Physical security issues

## Security Best Practices

When using huhgit:

- Keep your GitHub Personal Access Token secure
- Use tokens with minimal required permissions
- Regularly rotate your access tokens
- Run huhgit only in trusted environments
- Verify binary checksums before execution

## Dependencies

huhgit uses the following key dependencies:
- github.com/charmbracelet/huh
- github.com/go-git/go-git/v5
- github.com/google/go-github/v62

We monitor these dependencies for security updates and update them regularly.

## Disclosure Timeline

- **Day 0**: Vulnerability reported
- **Day 1**: Acknowledgment and initial assessment
- **Day 7**: Detailed analysis and fix development
- **Day 14**: Fix testing and release preparation
- **Day 21**: Coordinated disclosure and release

Timeline may vary based on complexity and severity.
