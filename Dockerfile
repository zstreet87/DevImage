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
    && rm -rf /var/lib/apt/lists/*

# Install latest Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Workspace directory for cloning repos and building
WORKDIR /tmp

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

# Install zsh
RUN apt-get update && apt-get install -y zsh \
    && rm -rf /var/lib/apt/lists/*

# Install fzf from source
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all

# Install yazi from source
RUN cargo install --locked yazi-fm

# Create directory for dotfiles
WORKDIR /root

# Clone your zfiles repository
RUN git clone https://github.com/zstreeter/zfiles.git /root/zfiles

# Clone your nvim repository
RUN git clone https://github.com/zstreeter/nvim.git /root/.config/nvim

# Apply zfiles configuration using GNU stow
WORKDIR /root/zfiles
RUN stow --target=/root zsh \
    && stow --target=/root fzf \
    && stow --target=/root yazi

# Install additional tools that your config might use
RUN apt-get update && apt-get install -y \
    bat \
    exa \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for fd (fd-find in Debian/Ubuntu)
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Install zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Node.js (needed for some Neovim plugins)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set zsh as default shell
RUN chsh -s $(which zsh)

# Cleanup
WORKDIR /root
RUN rm -rf /tmp/*

# Set default command
CMD ["zsh"]
