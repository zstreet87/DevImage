#!/usr/bin/env bash
# Enhanced DevImage launch script for AMD ROCm, NVIDIA, or CPU environments
# Version 2.0

# Exit on errors, undefined variables, and pipe failures
set -euo pipefail

# Script name for usage messages
SCRIPT_NAME=$(basename "$0")

# Define colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with colors
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Display help message
show_help() {
	echo "Usage: $SCRIPT_NAME IMAGE_ID [CONTAINER_NAME] [OPTIONS]"
	echo
	echo "Arguments:"
	echo "  IMAGE_ID         Docker image ID or name (required)"
	echo "  CONTAINER_NAME   Name for the container (default: devimage)"
	echo
	echo "Options:"
	echo "  -h, --help       Display this help message and exit"
	echo "  -f, --force      Force remove existing container without prompting"
	echo "  -v, --volume     Additional volume to mount (can be used multiple times)"
	echo "                   Format: host_path:container_path"
	echo "  -e, --env        Additional environment variable (can be used multiple times)"
	echo "                   Format: NAME=VALUE"
	echo "  -p, --port       Port mapping (can be used multiple times)"
	echo "                   Format: host_port:container_port"
	echo "  --cpu-only       Force CPU-only mode even if GPU is available"
	echo "  --no-home        Don't mount home directory"
	echo
	echo "Examples:"
	echo "  $SCRIPT_NAME devimage:latest my-container"
	echo "  $SCRIPT_NAME devimage:latest --force -v /data:/data -p 8080:8080"
	exit 0
}

# Default values
FORCE=false
ADDITIONAL_VOLUMES=()
ADDITIONAL_ENV=()
PORT_MAPPINGS=()
CPU_ONLY=false
MOUNT_HOME=true

# Process arguments and options
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
	case $1 in
	-h | --help)
		show_help
		;;
	-f | --force)
		FORCE=true
		shift
		;;
	-v | --volume)
		ADDITIONAL_VOLUMES+=("$2")
		shift 2
		;;
	-e | --env)
		ADDITIONAL_ENV+=("$2")
		shift 2
		;;
	-p | --port)
		PORT_MAPPINGS+=("$2")
		shift 2
		;;
	--cpu-only)
		CPU_ONLY=true
		shift
		;;
	--no-home)
		MOUNT_HOME=false
		shift
		;;
	-* | --*)
		error "Unknown option $1"
		show_help
		;;
	*)
		POSITIONAL_ARGS+=("$1")
		shift
		;;
	esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

# Check for image ID
if [ ${#POSITIONAL_ARGS[@]} -lt 1 ]; then
	error "Missing image ID/name"
	show_help
fi

IMAGE_ID="${POSITIONAL_ARGS[0]}"
CONTAINER_NAME="${POSITIONAL_ARGS[1]:-devimage}"

# Prepare volume arguments
VOLUME_ARGS=()
if [ "$MOUNT_HOME" = true ]; then
	VOLUME_ARGS+=("-v" "$HOME:$HOME")
fi

for vol in "${ADDITIONAL_VOLUMES[@]}"; do
	VOLUME_ARGS+=("-v" "$vol")
done

# Prepare environment arguments
ENV_ARGS=(
	"-e" "TERM=xterm-256color"
	"-e" "DOCKER_CONTAINER_NAME=$CONTAINER_NAME"
)

for env_var in "${ADDITIONAL_ENV[@]}"; do
	ENV_ARGS+=("-e" "$env_var")
done

# Prepare port mapping arguments
PORT_ARGS=()
for port in "${PORT_MAPPINGS[@]}"; do
	PORT_ARGS+=("-p" "$port")
done

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
	if [ "$FORCE" = true ]; then
		warn "Force removing existing container '$CONTAINER_NAME'"
		docker rm -f "$CONTAINER_NAME" >/dev/null
	else
		warn "Container '$CONTAINER_NAME' already exists"
		read -p "Remove it and continue? [y/N] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			docker rm -f "$CONTAINER_NAME" >/dev/null
		else
			error "Aborted."
			exit 1
		fi
	fi
fi

# Common docker arguments
COMMON_ARGS=(
	"--privileged"
	"--ipc=host"
	"--cap-add=SYS_PTRACE"
	"--security-opt" "seccomp=unconfined"
	"--shm-size" "16G"
	"--name" "$CONTAINER_NAME"
	"${ENV_ARGS[@]}"
	"${VOLUME_ARGS[@]}"
	"${PORT_ARGS[@]}"
)

# Run the appropriate command based on GPU availability
if [ "$CPU_ONLY" = true ]; then
	info "Forcing CPU-only mode as requested"
	GPU_MODE="cpu"
else
	info "Detecting GPU environment..."
	GPU_MODE="cpu"

	# Check for AMD ROCm
	if command -v rocm-smi &>/dev/null && rocm-smi &>/dev/null; then
		info "AMD ROCm detected"
		GPU_MODE="rocm"
	# Check for NVIDIA
	elif command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
		info "NVIDIA GPU detected"
		GPU_MODE="nvidia"
	else
		info "No GPU detected"
	fi
fi

# Choose network mode based on port mappings
if [ ${#PORT_MAPPINGS[@]} -gt 0 ]; then
	NETWORK_ARGS=()
else
	NETWORK_ARGS=("--network=host")
fi

# Add GPU-specific arguments
case $GPU_MODE in
rocm)
	success "Launching container with AMD ROCm support"
	docker run -it \
		"${COMMON_ARGS[@]}" \
		"${NETWORK_ARGS[@]}" \
		--pid=host \
		--device=/dev/kfd \
		--device=/dev/dri \
		--group-add=video \
		"$IMAGE_ID"
	;;
nvidia)
	success "Launching container with NVIDIA GPU support"
	docker run -it \
		"${COMMON_ARGS[@]}" \
		"${NETWORK_ARGS[@]}" \
		--pid=host \
		--gpus all \
		--group-add=video \
		"$IMAGE_ID"
	;;
cpu)
	success "Launching container in CPU-only mode"
	docker run -it \
		"${COMMON_ARGS[@]}" \
		"${NETWORK_ARGS[@]}" \
		--pid=host \
		"$IMAGE_ID"
	;;
esac

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
	success "Container exited successfully."
else
	error "Container exited with code $EXIT_CODE."
fi
