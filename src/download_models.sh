#!/bin/bash
while IFS= read -r line; do
  url=$(echo $line | cut -d ' ' -f 1)
  file=$(echo $line | cut -d ' ' -f 2)
  # Extract the directory path from $file
  dir=$(dirname "/comfyui/$file")
  
  # Create the directory if it doesn't exist
  mkdir -p "$dir"

  wget -O "/comfyui/$file" "$url"
done < "$1"