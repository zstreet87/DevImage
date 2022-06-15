FROM rocm/rocm-terminal

# Setting workspace
ENV WORKSPACE_DIR=/home/zstreet
WORKDIR $WORKSPACE_DIR 

ENV PATH="$WORKSPACE_DIR:${PATH}"
ENV PATH="$WORKSPACE_DIR/.miniconda3/bin:${PATH}"

# Install dependencies
RUN sudo apt-get update && sudo apt-get install -y \
  wget curl unzip python3-pip git cmake pkg-config python-neovim libsqlite3-dev numactl

# Install Miniconda
RUN sudo wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && sudo mkdir $WORKSPACE_DIR/.conda \
    && sudo bash Miniconda3-latest-Linux-x86_64.sh -b -u -p $WORKSPACE_DIR \
    && sudo rm -f Miniconda3-latest-Linux-x86_64.sh

# add sshpass, sshfs for downloading from mlse-nas
RUN sudo apt-get update && sudo apt-get install -y sshpass sshfs

# add locale en_US.UTF-8
RUN sudo apt-get update && sudo apt-get install -y locales
RUN sudo locale-gen en_US.UTF-8

# Installing zsh
RUN sudo apt-get update && sudo apt-get install -y zsh

# Need this for add-apt-repository
RUN sudo apt-get update && sudo apt-get install -y software-properties-common

# # Installing Neovim
RUN sudo apt-get update && sudo add-apt-repository ppa:neovim-ppa/unstable
RUN sudo apt-get update && sudo apt-get install -y neovim

# # Install fzf (rocm/pytorch image should have conda installed)
# RUN conda install -c conda-forge fzf

# record configuration for posterity
RUN pip3 list

# COPY $HOME/.zshrc /etc/zsh.zshrc
# RUN chmod a+rwx /etc/zsh.zshrc

# Run zsh on container start
CMD ["zsh"]

# ENTRYPOINT ["/bin/bash", "-c", "source .zprofile"]
# ENTRYPOINT ["conda", "install -c conda-forge fzf"]
