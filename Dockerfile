# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip git wget \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir --quiet torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    xformers==0.0.21\
    runpod requests

WORKDIR /comfyui

# Get custom nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack /comfyui/custom_nodes/ComfyUI-Impact-Pack && \
    git clone https://github.com/LykosAI/ComfyUI-Inference-Core-Nodes.git /comfyui/custom_nodes/ComfyUI-Inference-Core-Nodes && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && \
    git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git /comfyui/custom_nodes/ComfyUI_IPAdapter_plus && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale /comfyui/custom_nodes/ComfyUI_UltimateSDUpscale --recursive && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git /comfyui/custom_nodes/comfyui_controlnet_aux && \
    git clone https://github.com/jags111/efficiency-nodes-comfyui.git /comfyui/custom_nodes/efficiency-nodes-comfyui

# Install all dependencies
RUN pip3 install -r requirements.txt &&\
    python3 custom_nodes/ComfyUI-Impact-Pack/install.py && \
    python3 custom_nodes/ComfyUI-Inference-Core-Nodes/install.py && \
    pip3 install -r custom_nodes/comfyui_controlnet_aux/requirements.txt && \
    pip3 install -r custom_nodes/efficiency-nodes-comfyui/requirements.txt

#Download Models
COPY src/download_models.sh /scripts/download_models.sh 
COPY src/models.txt /scripts/models.txt

RUN chmod +x /scripts/download_models.sh && \
    bash /scripts/download_models.sh /scripts/models.txt

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
