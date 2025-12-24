FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ffmpeg cron

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
