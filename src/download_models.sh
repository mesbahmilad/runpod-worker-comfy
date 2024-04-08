#!/bin/bash
while IFS= read -r line; do
  url=$(echo $line | cut -d ' ' -f 1)
  file=$(echo $line | cut -d ' ' -f 2)
  wget -q -O "/comfyui/$file" "$url"
done < "$1"