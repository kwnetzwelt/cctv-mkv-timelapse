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

# Find all unique dates for the video files that need processing
find "$INPUT_DIR" -name '*.mkv' -daystart -mtime +0 -printf "%TY-%Tm-%Td\n" | sort -u | while read -r day; do
  echo "Processing files for $day..."

  # Create an array of files for the current day, sorted by name
  files=()
  while IFS= read -r -d $'' file; do
    files+=("$file")
  done < <(find "$INPUT_DIR" -name '*.mkv' -daystart -newermt "$day 00:00:00" ! -newermt "$day 23:59:59" -print0 | sort -z)

  if [ ${#files[@]} -eq 0 ]; then
    echo "No files found for $day."
    continue
  fi

  # Construct the ffmpeg command in an array to handle spaces correctly
  ffmpeg_args=()
  filter_complex=""
  input_count=0
  for file in "${files[@]}"; do
    ffmpeg_args+=(-i "$file")
    filter_complex+="[${input_count}:v:0]"
    input_count=$((input_count + 1))
  done

  filter_complex+="concat=n=${input_count}:v=1:a=0[v]; [v]select='not(mod(n,15))',setpts=PTS/30[out]"
  ffmpeg_args+=(-filter_complex "$filter_complex" -map "[out]" -c:v hevc_qsv -global_quality 30 -an "$OUTPUT_DIR/timelapse-$day.mp4" -y)

  echo "Running ffmpeg with ${input_count} input files..."
  # Use ffmpeg to concatenate video files, select every 15th frame, and speed up the video by a factor of 30.
  if ffmpeg "${ffmpeg_args[@]}"; then
    echo "Created timelapse-$day.mp4. Moving processed files to archive..."
    for file_to_move in "${files[@]}"; do
      mv "$file_to_move" "$ARCHIVE_DIR/"
    done
  else
    echo "Error creating timelapse for $day. Keeping files in input directory."
  fi
done

echo "Timelapse creation complete."