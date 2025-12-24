# Temporal Helm Charts Repository

This directory contains the packaged Helm charts and repository index for hosting on GitHub Pages.

## Contents

- `index.yaml` - Helm repository index file
- `temporal-*.tgz` - Packaged Temporal Helm chart versions

## Usage

Add this repository to your Helm installation:

```bash
helm repo add temporal-charts https://dentira.github.io/temporal-charts/
helm repo update
helm search repo temporal-charts
```

Install the chart:

```bash
helm install my-temporal temporal-charts/temporal
```

## Available Versions

Check `index.yaml` for all available chart versions or use:

```bash
helm search repo temporal-charts/temporal --versions
```

## Documentation

See [HELM_REPOSITORY.md](../HELM_REPOSITORY.md) in the root directory for complete setup and usage instructions.

