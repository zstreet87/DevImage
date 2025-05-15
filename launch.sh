#!/usr/bin/env bash
# DevImage Launch Script - runs after building with `docker build -t IMAGE_NAME -f Dockerfile`

# Strict error handling
set -eo pipefail

# Default values
DEFAULT_CONTAINER_NAME="devimage"
DEFAULT_SHM_SIZE="16G"
MOUNT_HOME=true
WORKDIR=""

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage information
usage() {
	echo -e "${BLUE}DevImage Container Launch Script${NC}"
	echo
	echo "Usage: $0 [options] IMAGE_ID [CONTAINER_NAME]"
	echo
	echo "Arguments:"
	echo "  IMAGE_ID          The Docker image ID or name to run"
	echo "  CONTAINER_NAME    Name for the container (default: ${DEFAULT_CONTAINER_NAME})"
	echo
	echo "Options:"
	echo "  -h, --help        Show this help message"
	echo "  -s, --shm SIZE    Set shared memory size (default: ${DEFAULT_SHM_SIZE})"
	echo "  -n, --no-home     Don't mount the home directory"
	echo "  -w, --workdir DIR Mount and set specified directory as working directory"
	echo
	echo "Examples:"
	echo "  $0 devimage:latest my-dev-container"
	echo "  $0 -s 32G devimage:cuda cuda-dev"
	echo "  $0 --workdir ~/projects/myproject devimage myproject-dev"
	exit 1
}

# Function to detect GPU environment
detect_gpu() {
	echo -e "${BLUE}Detecting GPU environment...${NC}"

	if command -v rocm-smi &>/dev/null && rocm-smi &>/dev/null; then
		echo -e "${GREEN}AMD ROCm detected${NC}"
		return 1
	elif command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
		echo -e "${GREEN}NVIDIA GPU detected${NC}"
		return 2
	else
		echo -e "${YELLOW}No supported GPU detected, will run in CPU-only mode${NC}"
		return 0
	fi
}

# Parse command line options
while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		usage
		;;
	-s | --shm)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo -e "${RED}Error: --shm requires a size argument${NC}"
			exit 1
		fi
		SHM_SIZE="$2"
		shift 2
		;;
	--shm=*)
		SHM_SIZE="${1#*=}"
		shift
		;;
	-n | --no-home)
		MOUNT_HOME=false
		shift
		;;
	-w | --workdir)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo -e "${RED}Error: --workdir requires a directory argument${NC}"
			exit 1
		fi
		WORKDIR="$2"
		shift 2
		;;
	--workdir=*)
		WORKDIR="${1#*=}"
		shift
		;;
	-*)
		echo -e "${RED}Error: Unknown option: $1${NC}"
		usage
		;;
	*)
		break
		;;
	esac
done

# Check for required arguments
if [ $# -lt 1 ]; then
	echo -e "${RED}Error: Missing required IMAGE_ID argument${NC}"
	usage
fi

# Set variables from arguments
IMAGE_ID="$1"
CONTAINER_NAME="${2:-$DEFAULT_CONTAINER_NAME}"
SHM_SIZE="${SHM_SIZE:-$DEFAULT_SHM_SIZE}"

# Verify image exists
if ! docker image inspect "$IMAGE_ID" &>/dev/null; then
	echo -e "${RED}Error: Docker image '$IMAGE_ID' not found${NC}"
	echo -e "Run 'docker images' to see available images"
	exit 1
fi

# Check if container name is already in use
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
	echo -e "${YELLOW}Warning: Container with name '$CONTAINER_NAME' already exists${NC}"
	read -p "Do you want to remove it and continue? [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo -e "${BLUE}Removing existing container...${NC}"
		docker rm -f "$CONTAINER_NAME" >/dev/null
	else
		echo -e "${RED}Aborting.${NC}"
		exit 1
	fi
fi

# Build docker run command with common options
CMD="docker run -it --privileged --network=host --pid=host"
CMD="$CMD --group-add=video --ipc=host --cap-add=SYS_PTRACE"
CMD="$CMD --security-opt seccomp=unconfined --shm-size $SHM_SIZE"

# Add volume mounts
if $MOUNT_HOME; then
	CMD="$CMD -v $HOME:$HOME"
fi

if [ -n "$WORKDIR" ]; then
	WORKDIR=$(realpath "$WORKDIR")
	if [ ! -d "$WORKDIR" ]; then
		echo -e "${YELLOW}Warning: Working directory '$WORKDIR' does not exist, creating it${NC}"
		mkdir -p "$WORKDIR"
	fi
	CMD="$CMD -v $WORKDIR:$WORKDIR -w $WORKDIR"
fi

# Add environment variables
CMD="$CMD -e TERM=xterm-256color -e DOCKER_CONTAINER_NAME=$CONTAINER_NAME"

# Add container name
CMD="$CMD --name $CONTAINER_NAME"

# Detect and configure for GPU
detect_gpu
GPU_TYPE=$?

if [ $GPU_TYPE -eq 1 ]; then
	# AMD ROCm
	CMD="$CMD --device=/dev/kfd --device=/dev/dri"
elif [ $GPU_TYPE -eq 2 ]; then
	# NVIDIA
	CMD="$CMD --gpus all"
fi

# Add image ID and execute
CMD="$CMD $IMAGE_ID"

echo -e "${BLUE}Launching container with command:${NC}"
echo -e "${GREEN}$CMD${NC}"
echo

# Execute the command
eval "$CMD"
