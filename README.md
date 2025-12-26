# CCTV MKV Timelapse Generator

This project provides a Dockerized solution to automatically create timelapse videos from a collection of CCTV `.mkv` files.

It groups the `.mkv` files by day (based on file modification time) and generates one timelapse video for each day.

## Prerequisites

- Docker
- Docker Compose

## How to Use

1.  **Place your video files:**
    -   Put your `.mkv` video files into the `videos/input` directory.

2.  **Build and run the service:**
    -   Open a terminal in the project directory and run the following command:
    ```bash
    docker-compose up
    ```
    -   This will build the Docker image (the first time) and then start the timelapse creation process.

3.  **Find your timelapses:**
    -   The generated timelapse videos will be saved in the `videos/output` directory.
    -   The output files will be named `timelapse-YYYY-MM-DD.mp4`.

## How it Works

The `process_videos.sh` script finds all `.mkv` files in the input directory, groups them by their modification date, and then uses `ffmpeg` to create the timelapse. The `ffmpeg` command speeds up the video by a factor of 30 and creates a smooth 30fps MP4 file.

After a timelapse is successfully created for a specific day, the script will automatically delete the corresponding input folder from `videos/input` to save space.
