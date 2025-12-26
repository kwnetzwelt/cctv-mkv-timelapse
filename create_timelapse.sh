#!/bin/bash

# Removed 'set -e' to prevent sudden crashes on minor file errors
INPUT_DIR="/videos/input"
OUTPUT_DIR="/videos/output"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi
mkdir -p "$OUTPUT_DIR"

# Use find to get directories to avoid issues with spaces or empty globs
find "$INPUT_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r day_dir; do
    day=$(basename "$day_dir")
    OUTPUT_FILE="$OUTPUT_DIR/timelapse-$day.mp4"

    if [ -f "$OUTPUT_FILE" ]; then
      echo "Skipping $day: Output already exists."
      continue
    fi

    echo "Gathering files for $day..."
    CONCAT_LIST=$(mktemp)
    
    count=0
    # Find all mkv files in the current day directory
    while IFS= read -r -d $'\0' file; do
      # Use a subshell for ffprobe so it doesn't trigger an exit
      if (ffprobe -v error -show_entries format=duration "$file" > /dev/null 2>&1); then
        echo "file '$file'" >> "$CONCAT_LIST"
        ((count++))
      else
        echo "Warning: File $file appears unreadable, skipping."
      fi
    done < <(find "$day_dir" -name '*.mkv' -print0 | sort -z)

    if [ "$count" -eq 0 ]; then
      echo "No valid files found for $day in $day_dir"
      rm -f "$CONCAT_LIST"
      continue
    fi

    echo "Processing $count files for $day..."

    ffmpeg -vaapi_device /dev/dri/renderD128 -err_detect ignore_err \
      -f concat -safe 0 -i "$CONCAT_LIST" \
      -vf "setpts=1/15*PTS,fps=30,format=nv12,hwupload,scale_vaapi=w=1280:h=720" \
      -c:v hevc_vaapi \
      -rc_mode 1\
      -qp 28 \
      -an "$OUTPUT_FILE" -y < /dev/null

    # Check if FFmpeg actually succeeded
    if [ $? -eq 0 ]; then
      echo "Successfully created $OUTPUT_FILE"
      rm -rf "$day_dir"
      echo "Deleted input folder: $day_dir"
    else
      echo "FFmpeg failed on $day"
    fi

    rm -f "$CONCAT_LIST"
done

echo "Script finished."
