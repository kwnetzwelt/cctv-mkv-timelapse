#!/bin/bash

set -e

INPUT_DIR="/videos/input"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

echo "Organizing files into date-based folders..."

find "$INPUT_DIR" -maxdepth 1 -name '*.mkv' -mmin +30 -mtime 1 -print0 | while IFS= read -r -d $'\0' file; do
  # Get the modification date of the file in YYYY.mm.dd format
  date_dir=$(date -r "$file" +%Y.%m.%d)
  
  # Create the destination directory if it doesn't exist
  dest_path="$INPUT_DIR/$date_dir"
  mkdir -p "$dest_path"
  
  # Move the file into the directory
  mv "$file" "$dest_path/"
  
  echo "Moved $(basename "$file") to $dest_path/"
done

echo "File organization complete."
