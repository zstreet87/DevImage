#!/usr/bin/env bash
# update-devimage.sh - Script to update DevImage with latest configs

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}DevImage Configuration Update Script${NC}"
echo -e "${GREEN}====================================${NC}"

# Check if DevImage repo directory is provided as an argument
if [ -z "$1" ]; then
  echo -e "${YELLOW}Usage: $0 /path/to/DevImage/repo${NC}"
  exit 1
fi

DEVIMAGE_DIR="$1"
ZFILES_DIR="$HOME/zfiles"     # Assuming zfiles is in your home directory
NVIM_DIR="$HOME/.config/nvim" # Assuming nvim config is in default location

# Check if the directories exist
if [ ! -d "$DEVIMAGE_DIR" ]; then
  echo -e "${RED}Error: DevImage directory does not exist: $DEVIMAGE_DIR${NC}"
  exit 1
fi

if [ ! -d "$ZFILES_DIR" ]; then
  echo -e "${YELLOW}Warning: zfiles directory does not exist at $ZFILES_DIR${NC}"
  read -p "Do you want to specify a different path to your zfiles repo? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter the path to your zfiles repository: " ZFILES_DIR
    if [ ! -d "$ZFILES_DIR" ]; then
      echo -e "${RED}Error: Directory does not exist: $ZFILES_DIR${NC}"
      exit 1
    fi
  else
    echo -e "${RED}Cannot continue without zfiles repository.${NC}"
    exit 1
  fi
fi

if [ ! -d "$NVIM_DIR" ]; then
  echo -e "${YELLOW}Warning: Neovim config directory does not exist at $NVIM_DIR${NC}"
  read -p "Do you want to specify a different path to your nvim config? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter the path to your neovim config directory: " NVIM_DIR
    if [ ! -d "$NVIM_DIR" ]; then
      echo -e "${RED}Error: Directory does not exist: $NVIM_DIR${NC}"
      exit 1
    fi
  else
    echo -e "${YELLOW}Will proceed without custom Neovim configuration.${NC}"
    NVIM_DIR=""
  fi
fi

# Check zfiles structure to ensure it's stow-compatible
echo -e "${BLUE}Analyzing zfiles repository structure...${NC}"
STOW_PACKAGES=()
for dir in "$ZFILES_DIR"/*/; do
  if [ -d "$dir" ]; then
    package=$(basename "$dir")
    STOW_PACKAGES+=("$package")
  fi
done

if [ ${#STOW_PACKAGES[@]} -eq 0 ]; then
  echo -e "${RED}Error: No stow packages found in $ZFILES_DIR${NC}"
  echo -e "${RED}Your zfiles repository should contain directories for each configuration (e.g., zsh, fzf, yazi)${NC}"
  exit 1
fi

echo -e "${GREEN}Found the following stow packages:${NC}"
for pkg in "${STOW_PACKAGES[@]}"; do
  echo -e "  - ${GREEN}$pkg${NC}"
done

# Check if DevImage repo is clean
cd "$DEVIMAGE_DIR"
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}Warning: DevImage repository has uncommitted changes.${NC}"
  read -p "Continue anyway? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborting.${NC}"
    exit 1
  fi
fi

# Update DevImage repo with the new Dockerfile
echo -e "${GREEN}Updating Dockerfile in DevImage repository...${NC}"
cp "$DEVIMAGE_DIR/Dockerfile" "$DEVIMAGE_DIR/Dockerfile.bak" 2>/dev/null || true
echo -e "${GREEN}Backed up original Dockerfile to Dockerfile.bak${NC}"

# Copy the updated Dockerfile
cat >"$DEVIMAGE_DIR/Dockerfile" <<'EOF'
FROM rocm/megatron-lm:v25.3

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    unzip \
    zip \
    pkg-config \
    libssl-dev \
    cmake \
    python3 \
    python3-pip \
    pkg-config \
    libfreetype6-dev \
    libfontconfig1-dev \
    libxcb-xfixes0-dev \
    libxkbcommon-dev \
    xclip \
    sudo \
    gnupg2 \
    lsb-release \
    software-properties-common \
    stow \
    ripgrep \
    locales \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install latest Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup update stable && \
    rustup default stable
ENV PATH="/root/.cargo/bin:${PATH}"

# Workspace directory for building tools
WORKDIR /tmp/build

# Install Neovim from source
RUN apt-get update && apt-get install -y \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/neovim/neovim.git \
    && cd neovim \
    && make CMAKE_BUILD_TYPE=Release \
    && make install

# Install additional tools that your config might use
RUN apt-get update && apt-get install -y \
    bat \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

RUN cargo install --locked eza

# After installing eza, copy the completion file
RUN mkdir -p ~/.local/share/zsh/site-functions && \
    cp ~/.cargo/registry/src/*/eza-*/completions/zsh/_eza ~/.local/share/zsh/site-functions/ || \
    curl -sSL https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza > ~/.local/share/zsh/site-functions/_eza && \
    chmod 644 ~/.local/share/zsh/site-functions/_eza

# Create symlink for fd and bat (different names in Debian/Ubuntu)
RUN ln -s $(which fdfind) /usr/local/bin/fd \
    && ln -s $(which batcat) /usr/local/bin/bat 2>/dev/null || true

# Install fzf from source
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all --no-update-rc

# Install yazi from source
RUN cargo install --locked yazi-fm
RUN mkdir -p /root/.config/yazi/plugins
# Install Yazi plugins by cloning the official plugin repository
# and copying the specific plugins.
RUN PLUGIN_DIR="/root/.config/yazi/plugins" && \
    mkdir -p ${PLUGIN_DIR} && \
    git clone --depth 1 https://github.com/yazi-rs/plugins.git /tmp/yazi-plugins-repo && \
    if [ -d "/tmp/yazi-plugins-repo/full-border.yazi" ]; then \
        cp -R /tmp/yazi-plugins-repo/full-border.yazi ${PLUGIN_DIR}/ ; \
    else \
        echo "Error: full-border.yazi not found in repository root" ; \
        # Depending on the repo structure, it might be in a subdirectory e.g. /tmp/yazi-plugins-repo/plugins/full-border.yazi
        # Adjust the path if necessary after inspecting the repository structure.
        # For yazi-rs/plugins, they are typically at the root.
        exit 1; \
    fi && \
    if [ -d "/tmp/yazi-plugins-repo/smart-enter.yazi" ]; then \
        cp -R /tmp/yazi-plugins-repo/smart-enter.yazi ${PLUGIN_DIR}/ ; \
    else \
        echo "Error: smart-enter.yazi not found in repository root" ; \
        exit 1; \
    fi && \
    rm -rf /tmp/yazi-plugins-repo

# Install Node.js (needed for some Neovim plugins)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create directory for dotfiles and configs
WORKDIR /root

# Prepare config directories
RUN mkdir -p ~/.config ~/.local/share

# Install Zsh ZAP (Zsh plugin manager) from your setup
RUN rm -rf ~/.local/share/zap && \
    zsh -c "$(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep"

# Install F-Sy-H (Fast Syntax Highlighting for Zsh)
RUN git clone https://github.com/z-shell/F-Sy-H ~/.local/share/zap/plugins/f-sy-h

# Clone your zfiles repository
RUN git clone https://github.com/zstreeter/zfiles.git /root/zfiles

# Clone your nvim repository
RUN git clone https://github.com/zstreeter/nvim.git /root/.config/nvim

# Backup default .zshrc if it exists
RUN if [ -f ~/.zshrc ]; then mv ~/.zshrc ~/.zshrc.backup; fi

# Apply zfiles configurations using GNU stow
# This approach automatically detects and applies all stow packages in your zfiles repo
WORKDIR /root/zfiles
RUN for dir in */; do \
        if [ -d "$dir" ]; then \
            package="${dir%/}"; \
            echo "Applying configuration for $package"; \
            stow --target=/root "$package"; \
        fi \
    done

# Ensure .zshrc exists and sources config if applicable
RUN if [ -f ~/.config/zsh/.zshrc ]; then \
        echo 'source ~/.config/zsh/.zshrc' > ~/.zshrc; \
    elif [ -f ~/.config/zsh/zshrc ]; then \
        echo 'source ~/.config/zsh/zshrc' > ~/.zshrc; \
    elif [ -f ~/.zshrc.backup ]; then \
        mv ~/.zshrc.backup ~/.zshrc; \
    else \
        echo 'export PATH=$HOME/.local/bin:$PATH' > ~/.zshrc; \
    fi

# Setup ZDOTDIR environment variable if needed
RUN echo 'export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}' >> ~/.zshenv

# Make sure .zshrc is sourced properly
RUN echo 'if [ -f ~/.zshrc ]; then source ~/.zshrc; fi' >> ~/.zshenv

# Add the XDG_CONFIG_HOME environment variable if not set
RUN echo 'export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}' >> ~/.zshenv

# Ensure zap initialization is in .zshrc if not already there
RUN if ! grep -q "source \"\$HOME/.local/share/zap/zap.zsh\"" ~/.zshrc; then \
        echo '# Initialize zap (plugin manager for zsh)' >> ~/.zshrc; \
        echo '[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"' >> ~/.zshrc; \
        echo '# Load plugins via zap - add these if they do not exist in your config' >> ~/.zshrc; \
        echo 'plug "zsh-users/zsh-autosuggestions"' >> ~/.zshrc; \
        echo 'plug "z-shell/F-Sy-H"' >> ~/.zshrc; \
    fi

# Ensure correct permissions
RUN chmod -R 755 /root/.config /root/.local/share/zap

# Set zsh as default shell
RUN chsh -s $(which zsh)

# Create a script to update configurations
RUN echo '#!/bin/bash\n\
cd /root/zfiles && git pull\n\
cd /root/.config/nvim && git pull\n\
cd /root/zfiles\n\
for dir in */; do\n\
    if [ -d "$dir" ]; then\n\
        package="${dir%/}"\n\
        echo "Restowing configuration for $package"\n\
        stow --restow --target=/root "$package"\n\
    fi\n\
done\n\
echo "Configuration updated!"' > /usr/local/bin/update-configs && \
chmod +x /usr/local/bin/update-configs

# Create ZSH initialization helper
RUN echo '#!/bin/bash\n\
# Check structure of zsh config\n\
echo "ZSH config directory contents:"\n\
ls -la ~/.config/zsh/\n\
echo\n\
echo "ZAP installation:"\n\
ls -la ~/.local/share/zap/\n\
echo\n\
echo "Main config files:"\n\
find ~/.config/zsh -name "*zshrc*" -o -name "*.zsh"\n\
echo\n\
echo "Current shell: $SHELL"\n\
echo "ZDOTDIR=$ZDOTDIR"\n\
echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"\n\
echo\n\
echo "To load your ZSH config manually, try one of:"\n\
echo "1. source ~/.zshrc"\n\
echo "2. source ~/.config/zsh/.zshrc"\n\
echo "3. source ~/.config/zsh/zshrc"\n\
echo "4. source ~/.local/share/zap/zap.zsh"' > /usr/local/bin/zsh-debug && \
chmod +x /usr/local/bin/zsh-debug

# Cleanup
WORKDIR /root
RUN rm -rf /tmp/build

# Set default command
CMD ["zsh"]
EOF

# Update the README.md with information about the stow packages
cat >"$DEVIMAGE_DIR/README.md" <<EOF
# DevImage with zfiles Configuration

This repository contains a Dockerfile that creates a development environment with all your preferred tools and configurations from your zfiles and nvim repositories.

## What's Included

- **Based on rocm/megatron-lm:v25.3**: Built on top of ROCm's Megatron-LM image for ML development
- **Latest Tools**: All tools are built from source to ensure you have the most recent versions
- **ZAP Plugin Manager**: Modern, lightweight Zsh plugin manager
- **GNU Stow Integration**: Automatically applies all your stow packages from zfiles:
EOF

# Add the stow packages to the README
for pkg in "${STOW_PACKAGES[@]}"; do
  echo "  - **$pkg**" >>"$DEVIMAGE_DIR/README.md"
done

# Continue with the rest of the README
cat >>"$DEVIMAGE_DIR/README.md" <<'EOF'
- **Neovim Setup**: Your custom Neovim configuration
- **Yazi File Manager**: File manager with plugins (full-border, smart-enter)
- **Eza**: Modern ls replacement (previously exa)

## How It Works

The Dockerfile:

1. Starts with the rocm/megatron-lm:v25.3 base image
2. Installs all necessary build dependencies
3. Builds and installs the latest versions of tools from source
4. Sets up ZAP plugin manager for Zsh
5. Clones your zfiles and nvim repositories
6. Uses GNU Stow to intelligently apply all your configurations
7. Sets zsh as the default shell
8. Creates utility scripts for debugging and updating configurations

## Utility Scripts

- **update-configs**: Updates your zfiles and nvim configurations from their repositories
- **zsh-debug**: Helps troubleshoot Zsh configuration issues by displaying key information

## Building the Image

```bash
docker build -t devimage .
```

## Running the Container

```bash
docker run -it --rm devimage
```

For development work, you'll likely want to mount your working directory:

```bash
docker run -it --rm -v $(pwd):/workspace devimage
```

## Customization

If you need to modify the configuration, you have two options:

1. Update your zfiles or nvim repositories, then rebuild this image
2. Inside the container, run `update-configs` to pull the latest changes

## Updating

When you make changes to your zfiles or nvim repositories, you'll need to rebuild this image:

```bash
docker build --no-cache -t devimage .
```

The `--no-cache` flag ensures fresh clones of your repositories.

## Additional Notes

- The container uses ZSH as the default shell with ZAP plugin manager
- The stow packages from your zfiles repository are automatically detected and applied
- You can add new stow packages to your zfiles repo, and they'll be included in the next build
- If you need to update configurations inside a running container, use the `update-configs` command
- If you encounter ZSH configuration issues, use the `zsh-debug` script

## Troubleshooting

If you encounter any issues with configurations:

1. Make sure your stow packages are properly structured
2. Check that all required dependencies are installed in the Dockerfile
3. Use the `zsh-debug` script to diagnose ZSH configuration problems
4. For complex issues, you can enter the container and manually restow: `cd /root/zfiles && stow --restow --target=/root [package]`
EOF

echo -e "${GREEN}Updated Dockerfile and README in DevImage repository.${NC}"

# Ask to commit the changes
read -p "Do you want to commit the changes to the DevImage repository? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  cd "$DEVIMAGE_DIR"
  git add Dockerfile README.md
  git commit -m "Update Dockerfile to use rocm/megatron-lm base and ZAP plugin manager"
  echo -e "${GREEN}Changes committed to DevImage repository.${NC}"

  # Ask to push changes
  read -p "Do you want to push the changes to the remote repository? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
    echo -e "${GREEN}Changes pushed to remote repository.${NC}"
  fi
fi

# Build the Docker image
read -p "Do you want to build the Docker image now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  cd "$DEVIMAGE_DIR"
  docker build -t devimage .
  echo -e "${GREEN}Docker image built successfully.${NC}"

  # Ask to run the container
  read -p "Do you want to run the container to test it? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker run -it --rm devimage
  fi
fi

echo -e "${GREEN}DevImage update process completed!${NC}"
