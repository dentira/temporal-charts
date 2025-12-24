#!/bin/bash

# Script to package Helm chart and update repository index
# Usage: ./update-helm-repo.sh [base-url]

set -e

CHART_DIR="charts/temporal"
DOCS_DIR="docs"
BASE_URL="${1:-https://dentira.github.io/temporal-charts/}"

echo "📦 Packaging Helm chart..."
helm package "$CHART_DIR" -d "$DOCS_DIR/"

echo "📝 Updating repository index..."
helm repo index "$DOCS_DIR/" --url "$BASE_URL" --merge "$DOCS_DIR/index.yaml"

echo "✅ Helm repository updated successfully!"
echo ""
echo "Next steps:"
echo "1. Commit the changes: git add docs/ && git commit -m 'Update Helm repository'"
echo "2. Push to GitHub: git push origin main"
echo ""
echo "To use this repository:"
echo "  helm repo add temporal-charts $BASE_URL"
echo "  helm repo update"
echo "  helm search repo temporal-charts"

