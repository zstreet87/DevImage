# DevImage Setup

This artifact contains everything you need to set up a development environment with your zfiles and nvim configurations. Below is a guide to understanding and using the files provided.

## Files Included

1. **Dockerfile** - Main container definition that builds and sets up your environment
2. **launch.sh** - Enhanced script for launching containers with GPU support and customization
3. **update-devimage.sh** - Script to update and maintain your DevImage repository

## Quick Start

To get started with your DevImage:

1. Save the Dockerfile to your DevImage repository
2. Save the launch.sh script to your DevImage repository and make it executable:
   ```bash
   chmod +x launch.sh
   ```
3. Build your image:
   ```bash
   docker build -t devimage .
   ```
4. Launch a container:
   ```bash
   ./launch.sh devimage my-container
   ```

## Understanding What Each File Does

### Dockerfile

The Dockerfile:

- Starts with Ubuntu as the base image
- Installs all necessary dependencies
- Builds Neovim, fzf, and yazi from source to get latest versions
- Clones your zfiles and nvim repositories
- Uses GNU Stow to dynamically apply all your configurations
- Creates an update-configs script for use inside the container

### launch.sh

The launch script:

- Automatically detects your GPU environment (NVIDIA, AMD ROCm, or CPU-only)
- Provides options for customizing the container launch
- Mounts your home directory by default
- Sets up container with proper permissions
- Has helpful error handling and user feedback

### update-devimage.sh

This maintenance script:

- Analyzes your zfiles repository structure
- Dynamically updates the Dockerfile based on your stow packages
- Updates the README to reflect your actual configuration
- Handles git operations (commit, push)
- Offers to build and test the image

## Installation

1. Create or use your existing DevImage repository
2. Copy the Dockerfile and launch.sh to that repository
3. Optionally save update-devimage.sh somewhere in your path (e.g., ~/bin/)
4. Make both scripts executable:
   ```bash
   chmod +x launch.sh
   chmod +x ~/bin/update-devimage.sh
   ```

## Workflow

### Initial Setup

```bash
# Clone your DevImage repo
git clone https://github.com/zstreet87/DevImage.git
cd DevImage

# Update with your configurations
~/bin/update-devimage.sh $(pwd)

# Build the image
docker build -t devimage .

# Launch a container
./launch.sh devimage
```

### Updating After Config Changes

```bash
# When you've updated your zfiles or nvim repos
cd DevImage
~/bin/update-devimage.sh $(pwd)

# Rebuild and launch
docker build -t devimage .
./launch.sh devimage
```

## Key Benefits

This setup provides several advantages:

- **Isolation**: Keep your development environment separate from your host system
- **Consistency**: Same environment regardless of which machine you're using
- **Portability**: Easily share your setup with colleagues or across machines
- **Flexibility**: GPU acceleration when available, CPU-only when not
- **Maintainability**: Easy updates when your configurations change

## Tips

- When adding new config files, organize them as stow packages in your zfiles repo
- To debug the container, use: `./launch.sh --workdir /tmp devimage debug`
- For heavy workloads, increase shared memory: `./launch.sh -s 32G devimage`
- Inside the container, run `update-configs` to fetch latest config changes
