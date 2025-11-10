# Contributing to Enterprise SSO Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful, constructive, and professional in all interactions.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

1. **Clear title**: Describe the issue briefly
2. **Description**: Detailed explanation of the problem
3. **Steps to reproduce**: How to trigger the bug
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Environment**: OS, shell version, IdP provider
7. **Logs**: Relevant error messages (sanitize secrets!)

### Suggesting Enhancements

For feature requests or enhancements:

1. Check if the feature already exists or is in progress
2. Open an issue describing the enhancement
3. Explain the use case and benefits
4. Provide examples if possible

### Adding Support for New IdP Providers

To add a new Identity Provider:

1. Create a directory: `providers/NEW_PROVIDER/`
2. Add configuration scripts:
   - `configure-saml.sh` - SAML 2.0 configuration
   - `configure-oidc.sh` - OIDC configuration
   - `README.md` - Provider-specific documentation

#### Script Template Structure

```bash
#!/bin/bash
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

# Gather information
gather_info() {
    # Prompt for necessary information
}

# Generate configuration
generate_config() {
    # Create config files
}

# Display instructions
display_instructions() {
    # Show setup steps
}

main() {
    gather_info
    generate_config
    display_instructions
}

main "$@"
```

### Improving Documentation

Documentation improvements are always welcome:

1. Fix typos or unclear instructions
2. Add examples or use cases
3. Improve troubleshooting guides
4. Add translations (future)

### Submitting Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/enterprise-sso-setup.git
   cd enterprise-sso-setup
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Add comments for complex logic
   - Test your changes thoroughly

4. **Test your changes**
   ```bash
   # Test scripts work
   ./your-script.sh --help
   
   # Test with shellcheck if available
   shellcheck your-script.sh
   
   # Verify no secrets are committed
   git diff
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Provide a clear description
   - Reference any related issues
   - List changes made
   - Include testing notes

## Development Guidelines

### Shell Script Standards

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Include helpful error messages
- Make scripts executable: `chmod +x script.sh`
- Use color codes consistently
- Add `--help` option to all scripts

### Security Considerations

**Never commit:**
- Real credentials (client IDs, secrets, passwords)
- Private keys or certificates
- Personal or company information
- API tokens or access keys

**Always:**
- Use placeholders like `YOUR_CLIENT_ID`
- Sanitize logs and error messages
- Validate user input
- Use secure defaults
- Document security best practices

### Code Style

**Bash Scripts:**
```bash
# Good: Clear variable names
local config_file="$1"

# Good: Quoted variables
echo "Value: $variable"

# Good: Check before using
if [ -f "$file" ]; then
    cat "$file"
fi

# Good: Functions for reusability
generate_metadata() {
    local entity_id=$1
    # ...
}
```

**JSON/XML:**
- Properly formatted and indented
- Valid syntax
- Include comments where appropriate (JSON5 for examples)

### Documentation Style

- Use clear, concise language
- Include code examples
- Provide both quick starts and detailed guides
- Keep examples up to date
- Use proper Markdown formatting

## Testing

Before submitting:

1. **Test scripts execute without errors**
   ```bash
   ./your-script.sh --help
   ```

2. **Verify generated files are correct**
   ```bash
   cat output/test-file.json
   ```

3. **Check for common issues**
   - Syntax errors
   - Missing dependencies
   - Broken links in documentation
   - Incorrect file paths

4. **Test on different systems** (if possible)
   - Linux
   - macOS
   - WSL (Windows)

## Project Structure

```
enterprise-sso-setup/
├── setup.sh                 # Main wizard
├── scripts/                 # Shared utilities
├── providers/               # Provider-specific scripts
│   └── PROVIDER/
│       ├── configure-saml.sh
│       ├── configure-oidc.sh
│       └── README.md
├── templates/               # Configuration templates
├── docs/                    # Documentation
├── examples/                # Example configs
└── README.md               # Main documentation
```

## Release Process

Releases are managed by maintainers:

1. Version bump
2. Update CHANGELOG
3. Tag release
4. Create GitHub release

## Getting Help

- **Questions**: Open a discussion on GitHub
- **Issues**: Open an issue with details
- **Chat**: (Future) Join our community chat

## Recognition

Contributors will be:
- Listed in the repository
- Mentioned in release notes
- Credited in documentation

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Questions?

If you have questions about contributing:
- Open a discussion on GitHub
- Review existing issues and PRs
- Check documentation

Thank you for contributing to Enterprise SSO Setup! 🎉
