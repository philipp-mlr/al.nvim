# Release Pipeline Documentation

This document explains how to use the comprehensive GitHub Actions release pipeline for al.nvim.

## 🏗️ Pipeline Overview

The release pipeline consists of three main workflows:

### 1. **CI Workflow** (`.github/workflows/ci.yml`)
- **Triggers**: Every push and pull request
- **Purpose**: Quality assurance and code validation
- **Jobs**:
  - **Lua Quality**: StyLua formatting, Selene linting, plugin structure validation
  - **Go Quality**: Go formatting, golangci-lint, module verification
  - **Documentation**: README link validation, TOML syntax checking

### 2. **Build Workflow** (`.github/workflows/build.yml`)
- **Triggers**: Push to main branch, manual dispatch
- **Purpose**: Build and package all release assets
- **Jobs**:
  - **Proxy Building**: Cross-platform Go binary compilation
  - **Plugin Packaging**: Complete plugin archive creation
  - **Validation**: Asset verification and integrity checks

### 3. **Release Workflow** (`.github/workflows/release.yml`)
- **Triggers**: Manual dispatch only
- **Purpose**: Create official GitHub releases with semantic versioning
- **Jobs**:
  - **Version Calculation**: Semantic version determination
  - **Changelog Generation**: Automated release notes from conventional commits
  - **Asset Creation**: Fresh builds with version embedding
  - **GitHub Release**: Professional release creation with all assets

## 🚀 How to Create a Release

### Step 1: Prepare Your Code

1. **Ensure all changes are merged** to the main branch
2. **Verify CI passes** - all quality checks must be green
3. **Use conventional commits** for automatic changelog generation:
   ```bash
   feat: add new debugging feature
   fix: resolve proxy connection issue
   docs: update installation guide
   feat!: breaking change to configuration API
   ```

### Step 2: Trigger the Release

1. **Go to GitHub Actions** tab in your repository
2. **Select "Release" workflow** from the left sidebar
3. **Click "Run workflow"** button
4. **Configure the release**:

   ![Release Configuration](doc/assets/release-config-example.png)

   - **Version Type**: Choose the semantic version bump
     - `patch` (1.0.1) - Bug fixes, backward compatible
     - `minor` (1.1.0) - New features, backward compatible  
     - `major` (2.0.0) - Breaking changes
   
   - **Custom Version** (optional): Override automatic versioning
     - Example: `1.5.0` or `v2.0.0-beta.1`
   
   - **Pre-release**: Check if this is a beta/alpha release
   
   - **Draft**: Check to create a draft release for review

5. **Click "Run workflow"** to start the process

### Step 3: Monitor the Release

The workflow will run through three stages:

1. **Prepare Release** (~2 minutes)
   - Calculate next version
   - Generate changelog from commits
   - Validate release parameters

2. **Build Release Assets** (~5 minutes)
   - Compile cross-platform binaries
   - Create plugin archive
   - Generate checksums

3. **Create GitHub Release** (~1 minute)
   - Upload all assets
   - Create release with changelog
   - Tag the repository

### Step 4: Review and Publish

1. **Check the release** in the GitHub Releases section
2. **Review the changelog** and assets
3. **If created as draft**: Edit and publish when ready
4. **Announce the release** to users

## 📦 Release Assets

Each release includes:

### Cross-Platform Binaries
- `al-debug-proxy.exe` - Windows (amd64)
- `al-debug-proxy` - Linux (amd64)
- `al-debug-proxy-darwin` - macOS Intel (amd64)
- `al-debug-proxy-darwin-arm64` - macOS Apple Silicon (arm64)

### Plugin Archive
- `al.nvim-v{version}.tar.gz` - Complete plugin package
- Includes: Lua code, documentation, binaries, configuration files

### Security & Verification
- `checksums.txt` - SHA256 checksums for all assets
- `VERSION.txt` - Build information and metadata

## 🔄 Conventional Commits for Changelog

The pipeline automatically generates changelogs from conventional commits:

### Commit Types
- `feat:` → ✨ **Features** section
- `fix:` → 🐛 **Bug Fixes** section
- `docs:` → 📚 **Documentation** section
- `perf:` → ⚡ **Performance** section
- `refactor:` → 🔧 **Refactoring** section

### Breaking Changes
- `feat!:` or `fix!:` → ⚠️ **BREAKING CHANGES** section
- `BREAKING CHANGE:` in commit body → ⚠️ **BREAKING CHANGES** section

### Examples
```bash
# Feature release (minor version bump)
feat: add support for AL code analysis integration
feat(debugger): implement cross-platform proxy improvements

# Bug fix release (patch version bump)
fix: resolve proxy connection timeout on macOS
fix(lsp): handle startup race condition properly

# Breaking change (major version bump)
feat!: redesign configuration API for better extensibility
fix!: remove deprecated authentication methods

# With detailed breaking change
feat: new configuration system

BREAKING CHANGE: The configuration format has changed.
See MIGRATION.md for upgrade instructions.
```

## 🎯 Version Strategy

### Semantic Versioning (SemVer)
- **MAJOR** (2.0.0): Breaking changes, API modifications
- **MINOR** (1.1.0): New features, backward compatible
- **PATCH** (1.0.1): Bug fixes, backward compatible

### Pre-releases
- **Alpha**: `v1.0.0-alpha.1` - Early development
- **Beta**: `v1.0.0-beta.1` - Feature complete, testing
- **RC**: `v1.0.0-rc.1` - Release candidate

### Version Calculation
1. **Automatic**: Based on conventional commits since last release
2. **Manual Override**: Specify exact version in workflow input
3. **First Release**: Starts from `v1.0.0` if no previous tags exist

## 🛠️ Troubleshooting

### Common Issues

#### CI Failures
- **StyLua formatting**: Run `stylua .` locally and commit
- **Selene linting**: Fix Lua code issues reported by Selene
- **Go formatting**: Run `gofmt -s -w .` in `proxy-src/`
- **Go linting**: Fix issues reported by golangci-lint

#### Build Failures
- **Go compilation errors**: Check Go code syntax and dependencies
- **Missing files**: Ensure all required files are committed
- **Permission issues**: Check file permissions in repository

#### Release Failures
- **Version conflicts**: Ensure the calculated version doesn't already exist
- **Asset upload**: Check GitHub token permissions
- **Changelog generation**: Verify conventional commit format

### Manual Recovery

If a release fails partway through:

1. **Check the workflow logs** for specific error messages
2. **Fix the underlying issue** (code, permissions, etc.)
3. **Re-run the workflow** with the same or corrected parameters
4. **Delete failed releases/tags** if necessary before retrying

### Getting Help

- **Workflow logs**: Check GitHub Actions tab for detailed error information
- **Issue tracker**: Report pipeline bugs with workflow run links
- **Documentation**: Refer to GitHub Actions documentation for advanced usage

## 📋 Best Practices

### Development Workflow
1. **Use feature branches** for development
2. **Write conventional commits** for automatic changelog
3. **Ensure CI passes** before merging PRs
4. **Test locally** before releasing

### Release Management
1. **Regular releases** - don't let changes accumulate too long
2. **Meaningful versions** - follow semantic versioning strictly
3. **Test pre-releases** - use beta/alpha for major changes
4. **Document breaking changes** - provide migration guides

### Quality Assurance
1. **Never skip CI** - all quality checks must pass
2. **Review changelogs** - ensure they accurately reflect changes
3. **Verify assets** - check that all binaries work correctly
4. **Monitor feedback** - watch for user issues after releases

## 🔧 Pipeline Maintenance

### Updating Dependencies
- **GitHub Actions**: Update action versions in workflow files
- **Go version**: Update in workflows and go.mod
- **Node.js**: Update for semantic-release tools
- **Linters**: Update StyLua, Selene, golangci-lint versions

### Adding New Platforms
To add support for new platforms (e.g., ARM Linux):

1. **Update build steps** in both `build.yml` and `release.yml`
2. **Add new binary names** to validation and upload steps
3. **Update documentation** to reflect new platform support
4. **Test the new platform** thoroughly before releasing

### Customizing Workflows
- **Modify triggers**: Change when workflows run
- **Add new checks**: Include additional quality gates
- **Customize changelog**: Modify conventional commit parsing
- **Add notifications**: Integrate with Slack, Discord, etc.

---

This pipeline provides a professional, automated release process that ensures quality, consistency, and reliability for al.nvim releases. The manual trigger approach gives you full control while automating all the tedious aspects of creating releases.
