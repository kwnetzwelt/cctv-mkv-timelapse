#!/bin/bash

set -e

INPUT_DIR="/videos/input"
OUTPUT_DIR="/videos/output"
ARCHIVE_DIR="/videos/input/archive"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

if [ ! -d "$ARCHIVE_DIR" ]; then
  mkdir -p "$ARCHIVE_DIR"
fi

find "$INPUT_DIR" -name '*.mkv' -daystart -mtime +0 -print0 | while IFS= read -r -d $'\0' file; do
  date=$(date -r "$file" +%Y-%m-%d)
  echo "$file" >> "$OUTPUT_DIR/$date.txt"
done

for list in "$OUTPUT_DIR"/*.txt; do
  if [ -f "$list" ]; then
    day=$(basename "$list" .txt)
    echo "Processing files for $day..."
    sort "$list" -o "$list"

    # Store original file paths before modifying the list for ffmpeg
    original_files=()
    while IFS= read -r line; do
      original_files+=("$line")
    done < "$list"

    # Prepare file list for ffmpeg's concat demuxer
    sed -i "s/^/file '/g" "$list"
    sed -i "s/$/'/g" "$list"

    if ffmpeg -f concat -safe 0 -i "$list" -vf "setpts=PTS/30" -r 30 -an "$OUTPUT_DIR/timelapse-$day.mp4" -y; then
      echo "Created timelapse-$day.mp4. Moving processed files to archive..."
      for file_to_move in "${original_files[@]}"; do
        mv "$file_to_move" "$ARCHIVE_DIR/"
      done
    else
      echo "Error creating timelapse for $day. Keeping files in input directory."
    fi

    rm "$list"
  fi
done

echo "Timelapse creation complete."
