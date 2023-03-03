# FROM rocm/rocm-terminal
FROM rocm/mlir
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
  highlight \
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

# installing latest nodejs and npm
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash
RUN apt install -y nodejs
RUN npm cache clean -f
RUN npm install -g n
RUN n latest

# get latest npm
RUN npm install -g npm@latest

# installing miniconda
RUN mkdir -p /root/.miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /root/.miniconda3/miniconda.sh
RUN bash /root/.miniconda3/miniconda.sh -b -u -p /root/.miniconda3
RUN rm -rf /root/.miniconda3/miniconda.sh
RUN /root/.miniconda3/bin/conda init zsh
ENV PATH="/root/.miniconda3/bin:$PATH"

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

# LunarVim
RUN git clone https://github.com/LunarVim/LunarVim .LunarVim
RUN ~/.LunarVim/utils/installer/install.sh -y

# Install Chris's LunarVim config
# TODO: fork and maintain own config
RUN mv /root/.config/lvim /root/config/lvim.old
RUN git clone https://github.com/zstreet87/lvim /root/.config/lvim

# zsh highlighting and autosuggestion
RUN mkdir -p /root/.local/zsh/plugins
RUN git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git /root/.local/share/zsh/plugins/fast-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions /root/.local/share/zsh/plugins/zsh-autosuggestions

# Tmux plugin manager
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

COPY .local /root/.local
COPY .config /root/.config
COPY .zshrc_no_emoji /root/.zshrc
COPY .tmux.conf /root/.tmux.conf
RUN source ~/.zshrc

ENTRYPOINT ["/bin/zsh"]
