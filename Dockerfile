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

# Install runpod
RUN pip3 install runpod requests --quiet

#Download Models
COPY src/download_models.sh /scripts/download_models.sh
COPY src/models.txt /scripts/models.txt

RUN chmod +x /scripts/download_models.sh
RUN bash /scripts/download_models.sh /scripts/models.txt

# Install custom nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack /comfyui/custom_nodes/ComfyUI-Impact-Pack
WORKDIR /comfyui/custom_nodes/ComfyUI-Impact-Pack
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/LykosAI/ComfyUI-Inference-Core-Nodes.git /comfyui/custom_nodes/ComfyUI-Inference-Core-Nodes
WORKDIR /comfyui/custom_nodes/ComfyUI-Inference-Core-Nodes
RUN python3 install.py

RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes
WORKDIR /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git /comfyui/custom_nodes/ComfyUI_IPAdapter_plus
WORKDIR /comfyui/custom_nodes/ComfyUI_IPAdapter_plus
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale /comfyui/custom_nodes/ComfyUI_UltimateSDUpscale
WORKDIR /comfyui/custom_nodes/ComfyUI_UltimateSDUpscale
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git /comfyui/custom_nodes/comfyui_controlnet_aux
WORKDIR /comfyui/custom_nodes/comfyui_controlnet_aux
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/jags111/efficiency-nodes-comfyui.git /comfyui/custom_nodes/efficiency-nodes-comfyui
WORKDIR /comfyui/custom_nodes/efficiency-nodes-comfyui
RUN pip3 install -r requirements.txt

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
