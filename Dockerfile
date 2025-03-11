FROM runpod/pytorch:3.10-2.0.0-117

SHELL ["/bin/bash", "-c"]
WORKDIR /

# Update and upgrade the system packages (Worker Template)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ffmpeg wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create cache directory and required folders
RUN mkdir -p /cache/models && \
    mkdir -p /root/.cache/torch/hub/checkpoints && \
    mkdir -p /models/vad

# Copy only requirements file first to leverage Docker cache
COPY builder/requirements.txt /builder/requirements.txt

# Install Python dependencies without upgrading existing packages
RUN pip install --no-cache-dir -r /builder/requirements.txt --no-deps && \
    pip install --no-cache-dir -r /builder/requirements.txt

# Download VAD model directly
RUN wget -O /models/vad/whisperx-vad-segmentation.bin https://github.com/m-bain/whisperX/raw/main/whisperx/models/vad.bin

# Copy the rest of the builder files
COPY builder /builder

# Download Faster Whisper Models
RUN chmod +x /builder/download_models.sh
RUN --mount=type=cache,target=/cache/models \
    /builder/download_models.sh

# Copy source code
COPY src .

CMD [ "python", "-u", "/rp_handler.py" ]
