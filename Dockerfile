FROM rocm/rocm-terminal
# FROM rocm/pytorch-private:rocm_pyt20_triton_ub20

MAINTAINER Zachary Streeter <Zachary.Streeter@amd.com>
USER root

# Setting workspace
ENV WORKSPACE_DIR=/root
RUN mkdir -p $WORKSPACE_DIR
WORKDIR $WORKSPACE_DIR 

RUN apt-get update && apt-get install -y \
  apt-utils \
  python3-pip \
  python3-neovim \
  libsqlite3-dev \
  numactl \
  ncurses-bin \
  cgdb \
  bash \
  util-linux \
  mandoc \
  ntfs-3g \
  git \
  subversion \
  curl \
  wget \
  net-tools \
  nmap \
  w3m \
  aria2 \
  tar \
  gzip \
  zip \
  unzip \
  ripgrep \
  neofetch \
  socat \
  tcpdump \
  rsync \
  subversion \
  sysbench \
  nnn \
  zsh \
  tmux \
  fzf \
  vim \
  make \
  cmake \
  autoconf \
  automake \
  pkgconf \
  bison \
  flex \
  binutils \
  patch \
  gettext \
  texinfo \
  gcc \
  g++ \
  gdb \
  clang \
  nodejs \
  npm \
  software-properties-common \
  yarn \
  python3 \
  libtool \
  libtool-bin \
  libreadline-dev \
  cargo

# add locale en_US.UTF-8
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8

SHELL ["/usr/bin/zsh", "-c"]

# installing rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Installing gdb-dashboard
RUN git clone https://github.com/cyrus-and/gdb-dashboard.git .gdb-dashboard
RUN cp /root/.gdb-dashboard/.gdbinit /root/.gdbinit

# Get and build tools
RUN git clone https://github.com/neovim/neovim.git .neovim
RUN cd .neovim; make CMAKE_BUILD=Release && make install 

RUN git clone https://github.com/junegunn/fzf.git .fzf
RUN ~/.fzf/install

# get latest npm
RUN npm install -g npm@latest

# LunarVim
RUN git clone https://github.com/LunarVim/LunarVim .LunarVim
RUN ~/.LunarVim/utils/installer/install.sh -y

# zsh highlighting and autosuggestion
RUN mkdir -p /root/.local/zsh/plugins
RUN git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git /root/.local/share/zsh/plugins/fast-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions /root/.local/share/zsh/plugins/zsh-autosuggestions

# Tmux plugin manager
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

COPY .local /root/.local
COPY .config /root/.config
COPY .zshrc /root/.zshrc
COPY .tmux.conf /root/.tmux.conf
# RUN sed -i '146i\export RPROMPT="$RPROMPT🐳%F{blue}$DOCKER_CONTAINER_NAME"' /root/.zshrc
#ENV DOCKER_PROMPT_INFO="🐳%F{blue}$DOCKER_CONTAINER_NAME"
RUN source ~/.zshrc

ENTRYPOINT ["/bin/zsh"]
