# Jenkins CI/CD Setup Guide

This guide provides step-by-step instructions for setting up Jenkins CI/CD for the Temporal Helm chart repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Jenkins Configuration](#jenkins-configuration)
- [Credentials Setup](#credentials-setup)
- [Pipeline Job Setup](#pipeline-job-setup)
- [Webhook Configuration](#webhook-configuration)
- [Testing the Pipeline](#testing-the-pipeline)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Jenkins Plugins

Ensure the following plugins are installed on your Jenkins server:

1. **Git Plugin** - For Git repository integration
2. **Pipeline Plugin** - For pipeline support
3. **Docker Pipeline Plugin** - For Docker agent support
4. **Credentials Plugin** - For secure credential management
5. **GitHub Plugin** (optional) - For GitHub integration
6. **Blue Ocean** (optional) - For better UI

To install plugins:
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click on **Available** tab
3. Search for each plugin and install
4. Restart Jenkins if required

### System Requirements

- Jenkins 2.x or higher
- Docker installed on Jenkins server (for Docker agent)
- Git installed on Jenkins server
- Network access to GitHub
- Sufficient disk space for chart packages

## Jenkins Configuration

### 1. Configure Docker

Ensure Jenkins can access Docker:

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **Docker** section
3. Add Docker installation if not present
4. Test Docker connectivity

### 2. Configure Git

1. Go to **Manage Jenkins** → **Global Tool Configuration**
2. Under **Git**, ensure Git is configured
3. Set the path to Git executable (usually auto-detected)

## Credentials Setup

You need to configure credentials for GitHub access.

### GitHub Personal Access Token (Recommended)

1. **Create a GitHub Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a descriptive name: `Jenkins Temporal Charts`
   - Select scopes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `write:packages` (if using GitHub Packages)
     - ✅ `workflow` (if using GitHub Actions)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again!)

2. **Add Credentials to Jenkins**:
   
   **For Git Operations (Username/Password):**
   - Go to **Manage Jenkins** → **Manage Credentials**
   - Click on **(global)** domain
   - Click **Add Credentials**
   - Configure:
     - Kind: `Username with password`
     - Scope: `Global`
     - Username: Your GitHub username
     - Password: Paste your GitHub Personal Access Token
     - ID: `github-credentials`
     - Description: `GitHub credentials for temporal-charts`
   - Click **OK**

   **For GitHub API (Secret text):**
   - Click **Add Credentials** again
   - Configure:
     - Kind: `Secret text`
     - Scope: `Global`
     - Secret: Paste your GitHub Personal Access Token
     - ID: `github-token`
     - Description: `GitHub API token for releases`
   - Click **OK**

### SSH Key (Alternative)

If you prefer SSH:

1. **Generate SSH Key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "jenkins@dentira.com" -f ~/.ssh/jenkins_temporal_charts
   ```

2. **Add Public Key to GitHub**:
   - Copy the public key: `cat ~/.ssh/jenkins_temporal_charts.pub`
   - Go to GitHub → Repository Settings → Deploy keys
   - Click "Add deploy key"
   - Paste the public key
   - ✅ Check "Allow write access"
   - Click "Add key"

3. **Add Private Key to Jenkins**:
   - Go to **Manage Jenkins** → **Manage Credentials**
   - Click **Add Credentials**
   - Configure:
     - Kind: `SSH Username with private key`
     - Scope: `Global`
     - ID: `github-ssh-key`
     - Username: `git`
     - Private Key: Enter directly → Paste private key content
     - Passphrase: (if you set one)
   - Click **OK**

## Pipeline Job Setup

### Create a Multibranch Pipeline Job

1. **Create New Job**:
   - Go to Jenkins Dashboard
   - Click **New Item**
   - Enter name: `temporal-charts`
   - Select **Multibranch Pipeline**
   - Click **OK**

2. **Configure Branch Sources**:
   - Under **Branch Sources**, click **Add source** → **Git**
   - Configure:
     - Project Repository: `https://github.com/dentira/temporal-charts.git`
     - Credentials: Select `github-credentials`
   - Under **Behaviors**, add:
     - **Discover branches**: All branches
     - **Discover tags**: (Important for releases!)
   - Click **Save**

3. **Configure Build Configuration**:
   - Script Path: `Jenkinsfile` (default)
   - Click **Save**

### Alternative: Create a Pipeline Job

If you prefer a simple pipeline job:

1. **Create New Job**:
   - Click **New Item**
   - Enter name: `temporal-charts-pipeline`
   - Select **Pipeline**
   - Click **OK**

2. **Configure Pipeline**:
   - Under **Pipeline** section:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/dentira/temporal-charts.git`
     - Credentials: Select `github-credentials`
     - Branch Specifier: `*/main` (or `*/tags/*` for tags)
     - Script Path: `Jenkinsfile`
   - Click **Save**

## Webhook Configuration

Configure GitHub webhooks to trigger Jenkins builds automatically.

### 1. Get Jenkins Webhook URL

Your webhook URL will be:
```
http://your-jenkins-server/github-webhook/
```
or
```
http://your-jenkins-server/multibranch-webhook-trigger/invoke?token=YOUR_TOKEN
```

### 2. Configure GitHub Webhook

1. Go to your GitHub repository: `https://github.com/dentira/temporal-charts`
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - Payload URL: Your Jenkins webhook URL
   - Content type: `application/json`
   - Secret: (optional, for security)
   - Which events: Select:
     - ✅ Pushes
     - ✅ Pull requests
     - ✅ Branch or tag creation
   - ✅ Active
4. Click **Add webhook**

### 3. Test Webhook

1. After adding webhook, GitHub will send a test payload
2. Check the webhook's "Recent Deliveries" tab
3. Ensure the delivery was successful (green checkmark)

## Testing the Pipeline

### Test 1: Lint on Push

1. Make a small change to the repository
2. Commit and push to `main` branch:
   ```bash
   git add .
   git commit -m "Test Jenkins pipeline"
   git push origin main
   ```
3. Check Jenkins - the pipeline should trigger automatically
4. Verify the "Lint Chart" stage passes

### Test 2: Package on Tag

1. Update the chart version in `charts/temporal/Chart.yaml`:
   ```yaml
   version: 1.0.1
   ```

2. Commit, tag, and push:
   ```bash
   git add charts/temporal/Chart.yaml
   git commit -m "Bump version to 1.0.1"
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin main
   git push origin v1.0.1
   ```

3. Check Jenkins - the pipeline should:
   - Lint the chart
   - Package the chart
   - Update the repository index
   - Commit and push to `main`
   - Create a GitHub release

4. Verify:
   - Check `docs/` directory for new `.tgz` file
   - Check `docs/index.yaml` for updated entries
   - Check GitHub releases for new release

## Pipeline Behavior

### On Every Commit/PR

The pipeline will:
- ✅ Validate chart structure
- ✅ Lint the Helm chart
- ✅ Test chart templates

### On Version Tags (v*.*.*)

The pipeline will additionally:
- 📦 Package the Helm chart
- 📝 Update the repository index
- 📤 Commit and push changes
- 🚀 Create a GitHub release

### Manual Trigger with FORCE_PACKAGE

You can manually trigger packaging without a tag:

1. Go to the Jenkins job
2. Click **Build with Parameters**
3. Check ✅ **FORCE_PACKAGE**
4. Click **Build**

## Customization

### Update Credentials ID

If your credentials have different IDs, update the Jenkinsfile:

```groovy
environment {
    GIT_CREDENTIALS_ID = 'your-credentials-id' // Update this
}
```

### Update Git Configuration

Change the Git user information in the Jenkinsfile:

```groovy
git config user.email "your-email@dentira.com"
git config user.name "Your Jenkins CI"
```

### Update Repository URL

If using SSH instead of HTTPS, update the push command in the Jenkinsfile:

```groovy
git push git@github.com:dentira/temporal-charts.git HEAD:main
```

### Notifications

Add email or Slack notifications to the `post` section:

```groovy
post {
    success {
        emailext (
            subject: "✅ Helm Chart Published: ${env.TAG_NAME}",
            body: "Chart version ${env.TAG_NAME} has been published successfully.",
            to: "team@dentira.com"
        )
    }
    failure {
        emailext (
            subject: "❌ Helm Chart Pipeline Failed: ${env.BUILD_NUMBER}",
            body: "Pipeline failed. Check logs: ${env.BUILD_URL}",
            to: "team@dentira.com"
        )
    }
}
```

## Troubleshooting

### Issue: Docker agent fails to start

**Solution:**
- Ensure Docker is installed and running on Jenkins server
- Check Jenkins has permission to access Docker socket
- Add Jenkins user to docker group:
  ```bash
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins
  ```

### Issue: Git push fails with authentication error

**Solution:**
- Verify credentials are correctly configured in Jenkins
- Check the credentials ID matches the Jenkinsfile
- Ensure the GitHub token has `repo` scope
- Test credentials manually:
  ```bash
  git clone https://username:token@github.com/dentira/temporal-charts.git
  ```

### Issue: Helm command not found

**Solution:**
- The pipeline uses `alpine/helm:latest` Docker image
- Ensure Docker can pull this image
- Alternatively, install Helm on Jenkins server and use a different agent

### Issue: GitHub release creation fails

**Solution:**
- Verify `github-token` credential exists
- Ensure token has necessary permissions
- Check GitHub API rate limits
- Review Jenkins console output for API error messages

### Issue: Changes not pushed to repository

**Solution:**
- Check `[skip ci]` in commit message (prevents recursive builds)
- Verify Git credentials have write access
- Check branch protection rules on GitHub
- Review Jenkins console output for Git errors

### Issue: Webhook not triggering builds

**Solution:**
- Verify webhook URL is correct
- Check webhook delivery status on GitHub
- Ensure Jenkins is accessible from GitHub (not behind firewall)
- Check Jenkins system log for webhook events
- Verify multibranch pipeline is configured to discover tags

## Security Best Practices

1. **Use Credentials Plugin**: Never hardcode tokens in Jenkinsfile
2. **Limit Token Scope**: Use minimal required permissions
3. **Rotate Tokens**: Regularly update GitHub tokens
4. **Use SSH Keys**: Consider SSH over HTTPS for better security
5. **Enable Branch Protection**: Protect `main` branch on GitHub
6. **Review Logs**: Regularly check Jenkins logs for security issues
7. **Update Jenkins**: Keep Jenkins and plugins up to date

## Monitoring and Maintenance

### Regular Checks

- Monitor Jenkins disk space (chart packages accumulate)
- Review pipeline execution times
- Check for failed builds
- Verify GitHub Pages deployment
- Test Helm repository periodically

### Cleanup

Periodically clean up old chart packages:

```bash
# Keep only last 10 versions
cd docs/
ls -t temporal-*.tgz | tail -n +11 | xargs rm -f
```

Update the repository index after cleanup:

```bash
./update-helm-repo.sh
git add docs/
git commit -m "Cleanup old chart versions"
git push origin main
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitHub Webhooks](https://docs.github.com/en/webhooks)
- [Helm Documentation](https://helm.sh/docs/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)

## Support

For issues:
- **Jenkins setup**: Check Jenkins logs and documentation
- **Pipeline errors**: Review console output in Jenkins
- **GitHub integration**: Check webhook delivery logs
- **Helm chart issues**: Open an issue in this repository

