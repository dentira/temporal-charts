# Helm Repository Setup for GitHub Pages

This guide explains how to host this Temporal Helm chart repository on GitHub Pages.

## Prerequisites

- Helm 3.x installed
- Git repository on GitHub
- Access to enable GitHub Pages for your repository

## Initial Setup

### 1. Enable GitHub Pages

1. Go to your GitHub repository settings
2. Navigate to **Settings** → **Pages**
3. Under "Build and deployment":
   - Source: Select "Deploy from a branch"
   - Branch: Select `main` (or your default branch)
   - Folder: Select `/docs`
4. Save the settings

Your Helm repository will be available at:
```
https://dentira.github.io/temporal-charts/
```

### 2. Verify the Repository URL

The repository is already configured for the Dentira organization. The URL is set to:

```bash
https://dentira.github.io/temporal-charts/
```

You can verify this in `docs/index.yaml`. The update script has already been run with this URL.

### 3. Package and Index the Chart

The initial packaging has already been done. The `docs/` directory contains:
- `temporal-1.0.0-rc.1.tgz` - The packaged Helm chart
- `index.yaml` - The Helm repository index file

## Updating the Repository

Whenever you make changes to the chart:

1. **Update the chart version** in `charts/temporal/Chart.yaml`
2. **Run the update script**:
   ```bash
   ./update-helm-repo.sh https://dentira.github.io/temporal-charts/
   ```
3. **Commit and push the changes**:
   ```bash
   git add docs/ charts/
   git commit -m "Release version X.Y.Z"
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   git push origin main
   git push origin vX.Y.Z
   ```

Alternatively, you can use the Jenkins CI/CD pipeline which automatically packages and publishes the chart when you push a version tag. See [JENKINS_SETUP.md](JENKINS_SETUP.md) for configuration details.

## Using the Helm Repository

Once published on GitHub Pages, users can add and use your repository:

### Add the Repository

```bash
helm repo add temporal-charts https://dentira.github.io/temporal-charts/
helm repo update
```

### Search for Charts

```bash
helm search repo temporal-charts
```

### Install the Chart

```bash
# Install with default values
helm install my-temporal temporal-charts/temporal

# Install with custom values
helm install my-temporal temporal-charts/temporal -f my-values.yaml

# Install specific version
helm install my-temporal temporal-charts/temporal --version 1.0.0-rc.1
```

### Upgrade the Chart

```bash
helm upgrade my-temporal temporal-charts/temporal
```

## Directory Structure

```
temporal-charts/
├── charts/
│   └── temporal/              # Helm chart source
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── docs/                      # Helm repository (served by GitHub Pages)
│   ├── index.yaml            # Repository index
│   └── temporal-*.tgz        # Packaged chart versions
├── Jenkinsfile               # Jenkins CI/CD pipeline
├── update-helm-repo.sh       # Script to update the repository
├── HELM_REPOSITORY.md        # This file
└── JENKINS_SETUP.md          # Jenkins setup guide
```

## Automation with CI/CD

### Jenkins Pipeline

This repository includes a comprehensive `Jenkinsfile` that automatically:
- Validates chart structure on every commit
- Lints charts on every commit
- Tests chart templates
- Packages and publishes on version tags (v*)
- Updates the repository index
- Commits and pushes changes to GitHub
- Creates GitHub releases

The pipeline runs automatically when you:
- Push commits (runs validation and linting)
- Push version tags like `v1.0.0` (runs full release process)

See [JENKINS_SETUP.md](JENKINS_SETUP.md) for complete Jenkins configuration instructions.

## Troubleshooting

### Chart not found after adding repository

1. Verify GitHub Pages is enabled and published
2. Check that the `docs/` directory is committed and pushed
3. Ensure the URL in `index.yaml` matches your GitHub Pages URL
4. Wait a few minutes for GitHub Pages to update (it may take 5-10 minutes)
5. Check the Jenkins pipeline runs to ensure the build and deployment succeeded

### Index file not updating

Make sure to use the `--merge` flag when running `helm repo index` to preserve previous versions:
```bash
helm repo index docs/ --url <base-url> --merge docs/index.yaml
```

### SSL/TLS errors

GitHub Pages serves content over HTTPS by default. Make sure you're using `https://` in your repository URL.

## Best Practices

1. **Version Management**: Always bump the version in `Chart.yaml` before packaging
2. **Git Tags**: Create git tags for each release (e.g., `v1.0.0-rc.1`)
3. **Changelog**: Maintain a CHANGELOG.md to track changes between versions
4. **Testing**: Test charts locally before publishing:
   ```bash
   helm install test-release ./charts/temporal --dry-run --debug
   ```
5. **Keep Old Versions**: Don't delete old `.tgz` files from `docs/` - users may need them

## Security Considerations

- Review all chart changes before publishing
- Use signed commits for releases
- Consider implementing chart signing with Helm Provenance
- Regularly update dependencies and scan for vulnerabilities

## Support

For issues with the Temporal chart itself, please open an issue in this repository.
For GitHub Pages issues, consult the [GitHub Pages documentation](https://docs.github.com/en/pages).

