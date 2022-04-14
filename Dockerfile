FROM rocm/pytorch:latest

# May need bash commands 
# SHELL ["/bin/bash", "-c"]

# Setting workspace
ENV WORKSPACE_DIR=/home/zstreet
WORKDIR ${WORKSPACE_DIR} 

# Install dependencies
RUN sudo apt-get update
# RUN sudo apt-get update && sudo apt-get install -y \
#   curl unzip python3-pip git cmake pkg-config python-neovim libsqlite3-dev numactl

# add sshpass, sshfs for downloading from mlse-nas
RUN sudo apt-get install -y sshpass sshfs

# add locale en_US.UTF-8
RUN sudo apt-get install -y locales
RUN sudo locale-gen en_US.UTF-8

# Installing zsh
RUN sudo apt-get install -y zsh

# # Installing Neovim
RUN add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get install -y neovim

# # Install fzf (rocm/pytorch image should have conda installed)
RUN conda install -c conda-forge fzf

# record configuration for posterity
RUN pip3 list

# COPY $HOME/.zshrc /etc/zsh.zshrc
# RUN chmod a+rwx /etc/zsh.zshrc

# Run zsh on container start
CMD ["zsh"]
