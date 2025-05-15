#!/usr/bin/env bash
# Simple DevImage launch script for AMD ROCm, NVIDIA, or CPU environments

# Exit on errors
set -e

# Get parameters
IMAGE_ID=$1
CONTAINER_NAME="${2:-devimage}"

# Check for image ID
if [ -z "$IMAGE_ID" ]; then
	echo "Error: Missing image ID/name"
	echo "Usage: $0 IMAGE_ID [CONTAINER_NAME]"
	echo "Example: $0 devimage:latest my-container"
	exit 1
fi

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
	echo "Warning: Container '$CONTAINER_NAME' already exists"
	read -p "Remove it and continue? [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		docker rm -f "$CONTAINER_NAME"
	else
		echo "Aborted."
		exit 1
	fi
fi

echo "Detecting GPU environment..."

# Check for AMD ROCm
if command -v rocm-smi &>/dev/null && rocm-smi &>/dev/null; then
	echo "AMD ROCm detected, launching container with ROCm support"
	docker run -it \
		--privileged \
		--network=host \
		--pid=host \
		--device=/dev/kfd \
		--device=/dev/dri \
		--group-add=video \
		--ipc=host \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--shm-size 16G \
		-v $HOME:$HOME \
		-e TERM=xterm-256color \
		-e DOCKER_CONTAINER_NAME=$CONTAINER_NAME \
		--name $CONTAINER_NAME \
		$IMAGE_ID

# Check for NVIDIA
elif command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
	echo "NVIDIA GPU detected, launching container with NVIDIA support"
	docker run -it \
		--privileged \
		--network=host \
		--pid=host \
		--gpus all \
		--group-add=video \
		--ipc=host \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--shm-size 16G \
		-v $HOME:$HOME \
		-e TERM=xterm-256color \
		-e DOCKER_CONTAINER_NAME=$CONTAINER_NAME \
		--name $CONTAINER_NAME \
		$IMAGE_ID

# Fallback to CPU-only
else
	echo "No GPU detected, launching in CPU-only mode"
	docker run -it \
		--privileged \
		--network=host \
		--pid=host \
		--group-add=video \
		--ipc=host \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--shm-size 16G \
		-v $HOME:$HOME \
		-e TERM=xterm-256color \
		-e DOCKER_CONTAINER_NAME=$CONTAINER_NAME \
		--name $CONTAINER_NAME \
		$IMAGE_ID
fi

echo "Container exited."
