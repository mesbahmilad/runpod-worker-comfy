# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir --timeout=1000 torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 --quiet
RUN pip3 install --no-cache-dir xformers==0.0.21 --quiet
RUN pip3 install --no-cache-dir --timeout=1000 -r requirements.txt --quiet

# Install custom nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack /comfyui/custom_nodes/ComfyUI-Impact-Pack
WORKDIR /comfyui/custom_nodes/ComfyUI-Impact-Pack
RUN pip3 install -r requirements.txt

# Install runpod
RUN pip3 install runpod requests --quiet

# Download checkpoints/vae/LoRA to include in image
RUN wget -q -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
RUN wget -q -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

# Example for adding specific models into image
#ADD models/checkpoints/realvisxlV40_v40Bakedvae.safetensors models/checkpoints/

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
