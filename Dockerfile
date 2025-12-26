FROM ubuntu:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install dependencies from official Ubuntu repositories
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        tzdata \
        cron \
        ffmpeg \
        intel-media-va-driver \
        libmfx1 \
        vainfo \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for VA-API
# Note: The driver name might be different on Ubuntu.
# Common values are iHD, i965.
ENV LIBVA_DRIVER_NAME=iHD

WORKDIR /app

COPY process_videos.sh .
RUN chmod +x process_videos.sh

# Add cron job
COPY timelapse-cron /etc/cron.d/timelapse-cron
RUN chmod 0644 /etc/cron.d/timelapse-cron

# Create log file for cron
RUN touch /var/log/cron.log

# Run cron in the foreground
CMD ["cron", "-f"]
