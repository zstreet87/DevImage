FROM rocm/pytorch:latest

LABEL maintainer="Zachary Streeter Zachary.Streeter@amd.com"
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
RUN sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN NODE_MAJOR=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
RUN sudo apt-get update && sudo apt-get install nodejs -y
RUN npm install -g npm@latest
RUN npm cache clean -f
RUN npm install -g n
RUN n latest

# installing miniconda
#RUN mkdir -p /root/.miniconda3
# RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /root/.miniconda3/miniconda.sh
# RUN bash /root/.miniconda3/miniconda.sh -b -u -p /root/.miniconda3
# RUN rm -rf /root/.miniconda3/miniconda.sh
# RUN /root/.miniconda3/bin/conda init zsh
# ENV PATH="/root/.miniconda3/bin:$PATH"

# installing rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# installing yazi
RUN cargo install --locked --git https://github.com/sxyazi/yazi.git

# Installing gdb-dashboard
RUN git clone https://github.com/cyrus-and/gdb-dashboard.git .gdb-dashboard
RUN cp /root/.gdb-dashboard/.gdbinit /root/.gdbinit

# Get and build tools
RUN git clone https://github.com/neovim/neovim.git .neovim
RUN cd .neovim; make CMAKE_BUILD=Release && make install 

RUN git clone https://github.com/junegunn/fzf.git .fzf
RUN ~/.fzf/install --no-bash --no-fish --all

# Install my nvim config
RUN git clone https://github.com/zstreeter/nvim /root/.config/nvim

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
RUN source ~/.zshrc

ENTRYPOINT ["/bin/zsh"]
