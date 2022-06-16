FROM rocm/rocm-terminal

# Should look into how to get the $USER working
USER root

# Setting workspace
ENV WORKSPACE_DIR=/workspace
RUN mkdir -p $WORKSPACE_DIR
WORKDIR $WORKSPACE_DIR 

# Install dependencies
RUN apt-get update && apt-get install -y \
  wget curl unzip python3-pip git cmake pkg-config python-neovim libsqlite3-dev numactl

# Miniconda
ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    mkdir /root/.conda && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm -rf Miniconda3-latest-Linux-x86_64.sh
RUN conda --version && \
    conda update conda && \
    conda init && \
    conda install -c conda-forge fzf

# # add sshpass, sshfs for downloading from mlse-nas
RUN apt-get update && apt-get install -y sshpass sshfs

# add locale en_US.UTF-8
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8

# Installing zsh
RUN apt-get update && apt-get install -y zsh

# Need this for add-apt-repository
RUN apt-get update && apt-get install -y software-properties-common

# # Installing Neovim
RUN apt-get update && add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get update && apt-get install -y neovim

# record configuration for posterity
RUN pip3 list

# Configuration setup
ENV PATH="/root/.local/bin:${PATH}"
COPY .local /root/.local
COPY .config /root/.config
COPY .zshrc /root/.zshrc
CMD ["zsh"]
