# Deploying to Fly.io

This guide explains how to deploy your Jupyter + IPFS environment to Fly.io.

## Prerequisites

1. Install the Fly CLI:
   ```
   curl -L https://fly.io/install.sh | sh
   ```
   Or use Homebrew on macOS:
   ```
   brew install flyctl
   ```

2. Sign up and authenticate:
   ```
   fly auth signup
   # or if you already have an account
   fly auth login
   ```

## Deployment Steps

1. **Create your app first**:
   ```
   fly apps create zarr-jupyter
   ```
   This reserves your app name in fly.io.

2. **Copy the deployment files to your project**:
   Make sure these files are set up correctly:
   - `fly.toml` - Configuration for Fly.io deployment
   - `Dockerfile.fly` - Docker image for Fly.io
   - `scripts/start-fly.sh` - Startup script for Fly.io
   - `scripts/install_packages.sh` - Package installer script

3. **Create the required volumes** (must be done after app creation):
   ```
   fly volumes create zarr_ipfs_data --size 10 --region iad
   fly volumes create zarr_venv_data --size 5 --region iad
   fly volumes create zarr_notebooks_data --size 10 --region iad
   ```
   
   **Important**: Replace `iad` with your chosen region. This must match the `primary_region` in your `fly.toml` file.

4. **Deploy your application**:
   ```
   fly deploy --dockerfile Dockerfile.fly
   ```

5. **Set a secure Jupyter token** (if not already in your fly.toml):
   ```
   fly secrets set JUPYTER_TOKEN=your_secure_token
   ```

## Accessing Your Application

After deployment, you can access your Jupyter environment:

```
fly open
```

This will open your browser to the Jupyter Lab interface. Use the JUPYTER_TOKEN you set to log in.

## Monitoring and Management

- View logs:
  ```
  fly logs
  ```

- SSH into the running container:
  ```
  fly ssh console
  ```

- Stop the application:
  ```
  fly apps stop
  ```

- Start the application:
  ```
  fly apps start
  ```

## Troubleshooting

### App Not Found When Creating Volumes
If you see an error like:
```
❯ fly volumes create zarr_ipfs_data --size 10
Error: failed to list volumes: app not found
```
Make sure you've created the app first with `fly apps create zarr-jupyter`.

### Configuration Version Error
If you see an error about configuration versions, ensure your `fly.toml` is properly formatted for the current version. The example in this repository is compatible with the latest fly.io platform.

## Important Notes

1. The IPFS node is configured to run within your Fly.io application. Ensure your application has enough resources by adjusting the `cpus` and `memory_mb` settings in your `fly.toml` file.

2. The persistent volumes (`zarr_ipfs_data`, `zarr_venv_data`, and `zarr_notebooks_data`) ensure your data persists across deployments.

3. For production use, consider setting a more secure JUPYTER_TOKEN via the secrets management. 