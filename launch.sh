#!/usr/bin/env bash

# ran after `docker build -t IMAGE_NAME -f Dockerfile`

set -ex

IMAGE_ID=$1
CONTAINER_NAME="${2:-default}"

if rocm-smi; then
	docker run -it \
		--privileged \
		--network=host \
		--pid=host \
		--device=/dev/kfd \
		--device=/dev/dri \
		--group-add=video \
		--ipc=host \
		--cap-add=SYS_PTRACE \
		--security-opt \
		seccomp=unconfined \
		--shm-size 16G \
		-v $HOME:$HOME \
		-e TERM=xterm-256color \
		-e DOCKER_CONTAINER_NAME=$CONTAINER_NAME \
		--name $CONTAINER_NAME \
		$IMAGE_ID
elif nvidia-smi; then
	docker run -it \
		--privileged \
		--network=host \
		--pid=host \
		--gpus all \
		--group-add=video \
		--ipc=host \
		--cap-add=SYS_PTRACE \
		--security-opt \
		seccomp=unconfined \
		--shm-size 16G \
		-v $HOME:$HOME \
		-e TERM=xterm-256color \
		-e DOCKER_CONTAINER_NAME=$CONTAINER_NAME \
		--name $CONTAINER_NAME \
		$IMAGE_ID
fi
