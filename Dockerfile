FROM ubuntu:latest

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
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
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

# Install exa (modern ls replacement)
RUN cargo install --locked eza

# Create symlink for fd and bat (different names in Debian/Ubuntu)
RUN ln -s $(which fdfind) /usr/local/bin/fd \
    && ln -s $(which batcat) /usr/local/bin/bat 2>/dev/null || true

# Install fzf from source
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all --no-update-rc

# Install yazi from source
RUN cargo install --locked yazi-fm
RUN mkdir -p /root/.config/yazi/plugins
# Chain commands with && to ensure they run sequentially and fail the build if one fails
RUN ya pack -a yazi-rs/plugins:full-border && \
    ya pack -a yazi-rs/plugins:smart-enter

# Install Node.js (needed for some Neovim plugins)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create directory for dotfiles and configs
WORKDIR /root

# Prepare config directories
RUN mkdir -p ~/.config ~/.local/share

# Install Zsh ZAP (Zsh plugin manager) from your setup
RUN mkdir -p ~/.local/share/zap \
    && zsh -c "$(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep"

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
