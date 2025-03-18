# Deploying to Digital Ocean App Platform

This guide walks you through deploying the Zarr Getting Started project to Digital Ocean App Platform.

## Prerequisites

1. A [Digital Ocean](https://www.digitalocean.com/) account
2. Your code pushed to a GitHub repository
3. [Digital Ocean CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/) (optional but recommended)

## Deployment Files

This project includes dedicated files for Digital Ocean App Platform deployment:

- `Dockerfile.digitalocean`: A Docker configuration specifically optimized for Digital Ocean
- `app.yaml`: The Digital Ocean App Platform specification file
- `scripts/digitalocean_start.sh`: A dedicated startup script for Digital Ocean App Platform
- `Procfile`: Defines the web process for Digital Ocean

These files are maintained separately from the local development configuration to keep both environments working correctly.

## Deployment Steps

### 1. Push Your Code to GitHub

Make sure your code is in a GitHub repository, including all the files modified for Digital Ocean App Platform:
- `app.yaml`
- `Dockerfile.digitalocean`
- `scripts/digitalocean_start.sh`
- `Procfile`

### 2. Deploy with the Digital Ocean Web Interface

1. Log in to your Digital Ocean account
2. Navigate to the App Platform section
3. Click "Create App" or "Create App From Source"
4. Choose GitHub as your source
5. Select your repository
6. Digital Ocean will automatically detect your `app.yaml` file. If not, you can manually configure:
   - Choose "Dockerfile" as your build method
   - Specify `Dockerfile.digitalocean` as your Dockerfile path
   - Set HTTP port to 8888
   - Set run command to `/bin/bash /scripts/digitalocean_start.sh`
7. Configure environment variables:
   - Add `JUPYTER_TOKEN` as a secret (use a secure token)
   - Add `DO_APP_PLATFORM=true`
8. Configure additional settings:
   - Memory: At least 1GB recommended
   - CPU: At least 1 vCPU recommended
9. Click "Next" and review your app configuration
10. Click "Create Resources"

### 3. Using the Digital Ocean CLI

If you prefer using the CLI, you can deploy with these commands:

```bash
# Authenticate with Digital Ocean
doctl auth init

# Create an app from app.yaml
doctl apps create --spec app.yaml

# Update an existing app
doctl apps update YOUR_APP_ID --spec app.yaml
```

## Post-Deployment Configuration

### 1. Set Up a Custom Domain (Optional)

1. In your app's settings, navigate to "Domains"
2. Add your custom domain
3. Configure DNS records as instructed by Digital Ocean

### 2. Configure Storage (Recommended)

For persistent storage, add a volume to your app:

1. In your app's settings, navigate to "Components"
2. Select your Jupyter component
3. Click "Edit"
4. Add a volume mount:
   - Mount path: `/notebooks` (for notebooks)
   - Mount path: `/root/.ipfs` (for IPFS data)

### 3. Access Your Jupyter Notebook

Once deployed, you can access your Jupyter notebook at:
- Your app's URL (e.g., `https://your-app-name.ondigitalocean.app`)
- You'll need to use the `JUPYTER_TOKEN` you set during configuration to log in

## Troubleshooting

### "Unable to detect a run command" Error

If you encounter the error "Unable to detect a run command", there are two ways to fix it:

1. Make sure your `app.yaml` file includes the `run_command` parameter:
   ```yaml
   services:
     - name: jupyter
       # other configurations...
       run_command: /bin/bash /scripts/digitalocean_start.sh
   ```

2. Ensure your Dockerfile uses CMD instead of ENTRYPOINT:
   ```dockerfile
   # Use CMD instead of ENTRYPOINT for Digital Ocean App Platform compatibility
   CMD ["/bin/bash", "/scripts/digitalocean_start.sh"]
   ```

The current setup includes both solutions for maximum compatibility.

### "Process type web was not found" Error

If you encounter the error "failed to launch: determine start command: process type web was not found", there are two ways to fix it:

1. Add a `type: web` to your service in the `app.yaml` file:
   ```yaml
   services:
     - name: jupyter
       type: web
       # other configurations...
   ```

2. Add a `Procfile` to your repository with a web process defined:
   ```
   web: /bin/bash /scripts/digitalocean_start.sh
   ```

The current setup includes both solutions for maximum compatibility.

### Check Logs

If your deployment fails or the app doesn't start properly:

1. Go to your app in the Digital Ocean dashboard
2. Navigate to "Components" > your component
3. Click "Logs" to view the container logs

Common issues:
- Port configuration problems
- Memory limitations
- Networking issues with IPFS

### IPFS Connectivity

If IPFS isn't connecting properly:
1. Check that port 4001 is properly configured
2. Verify the IPFS daemon is running (check logs)
3. Make sure your app has outbound internet access

## Maintenance

To update your app:
1. Push changes to your GitHub repository
2. Digital Ocean will automatically rebuild if you enabled auto-deployments
3. Or manually trigger a rebuild in the Digital Ocean dashboard

## Security Considerations

- Always use a strong `JUPYTER_TOKEN`
- Consider restricting IPFS API access
- Be cautious about exposing internal ports publicly 