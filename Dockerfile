FROM rocm/rocm-terminal

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

# Get and build tools
RUN git clone https://github.com/neovim/neovim.git .neovim
RUN cd .neovim; make CMAKE_BUILD=Release && make install 

RUN git clone https://github.com/junegunn/fzf.git .fzf
RUN ~/.fzf/install

ENV PATH="/root/.local/bin:${PATH}"
COPY .local /root/.local
COPY .config /root/.config
COPY .zshrc /root/.zshrc
COPY .tmux /root/.tmux
COPY .tmux.conf /root/.tmux.conf
SHELL ["/usr/bin/zsh", "-c"]
RUN echo 'export PS1="🐳 %F{blue}$DOCKER_CONTAINER_NAME%f %~ # "' >> /root/.zshrc
RUN source ~/.zshrc

# get latest npm
RUN npm install -g npm@latest

RUN git clone https://github.com/LunarVim/LunarVim .LunarVim
RUN ~/.LunarVim/utils/installer/install.sh -y

ENTRYPOINT ["/bin/zsh"]
