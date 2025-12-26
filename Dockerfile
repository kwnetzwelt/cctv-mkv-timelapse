FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install dependencies and enable non-free repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cron \
    ffmpeg \
    gnupg \
    software-properties-common \
    && sed -i 's/Components: main/Components: main contrib non-free/' /etc/apt/sources.list.d/debian.sources \
    && apt-get update
# 2. Install Intel Media Driver and VA-API tools
RUN apt-get install -y --no-install-recommends \
    intel-media-va-driver-non-free \
    libmfx1 \
    vainfo \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for VA-API
ENV LIBVA_DRIVER_NAME=iHD

WORKDIR /app

COPY process_videos.sh .
RUN chmod +x process_videos.sh

# Add cron job
COPY timelapse-cron /etc/cron.d/timelapse-cron
RUN chmod 0644 /etc/cron.d/timelapse-cron

# Create log file for cron
RUN touch /var/log/cron.log

# Create archive directory for processed files
RUN mkdir -p /videos/input/archive

# Run cron in the foreground
CMD ["cron", "-f"]
