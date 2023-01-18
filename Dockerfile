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
        software-properties-common \
        yarn \
        python3 \
        libtool \
        libtool-bin \
        libreadline-dev \
        cargo

# Miniconda
#ENV PATH="/root/.miniconda3/bin:${PATH}"
#ARG PATH="/root/.miniconda3/bin:${PATH}"
#RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
#    mkdir /root/.conda && \
#    bash Miniconda3-latest-Linux-x86_64.sh -p $HOME/.miniconda3 -b && \
#    rm -rf Miniconda3-latest-Linux-x86_64.sh
#RUN conda --version && \
#    conda update conda && \
#    conda init && \
#    conda install -c conda-forge fzf

# add locale en_US.UTF-8
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8

RUN mkdir -p /scripts
COPY ./scripts/install_cgdb.sh /scripts
COPY ./scripts/install_neovim.sh /scripts
# COPY ./scripts/install_lunarvim.sh /scripts
WORKDIR /scripts
RUN chmod +x install_cgdb.sh
RUN ./install_cgdb.sh
RUN chmod +x install_neovim.sh
RUN VERSION=Release ./install_neovim.sh
# RUN chmod +x install_lunarvim.sh
# RUN LV_BRANCH='release-1.2/neovim-0.8' ./install_lunarvim.sh -y --install_dependencies
# Install LunarVim manually to save hassle
# TODO: make this automated

WORKDIR $WORKSPACE_DIR 

ENV PATH="/root/.local/bin:${PATH}"
COPY .local /root/.local
COPY .npm /root/.npm
COPY .npm-global /root/.npm-global
COPY .config /root/.config
COPY .zshrc /root/.zshrc
COPY .tmux /root/.tmux
COPY .tmux.conf /root/.tmux.conf
SHELL ["/usr/bin/zsh", "-c"]
RUN source ~/.zshrc

ENTRYPOINT ["/bin/zsh"]
