#!/bin/bash

path=$1
size_of_dir=$2
size_limit=$3
sum=0
m=0

parent_dir=$(dirname "$path")
pwd_to_backup="$parent_dir/backup"

if [ ! -d "$path" ]; then
    echo "Error: directory '$path' does not exist."
    exit 1
fi

if [ ! -d "$pwd_to_backup" ]; then
    mkdir -p "$pwd_to_backup" || { echo "Cannot create backup directory."; exit 1; }
fi
current_size=$(du -s "$path" | awk '{print $1}')
result=$((current_size * 100 / size_of_dir))
echo "The directory is $result% full"
mapfile -t sorted_files < <(ls -tr "$path")

if [ "$result" -gt "$size_limit" ]; then
    echo "Directory exceeds size limit ($size_limit%). Selecting files to archive..."
    for f in "${sorted_files[@]}"; do
        file_size=$(du "$path/$f" | awk '{print $1}')
        result=$((result - (file_size * 100 / size_of_dir)))
        m=$((m + 1))
	if [ "$result" -le "$((size_limit/(3/2)))" ]; then
            break
        fi
    done
else
    echo "Directory usage is within limit."
    exit 0
fi
if [ "$m" -gt 0 ]; then
    backup_file="$pwd_to_backup/backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    echo "Archiving $m oldest files to: $backup_file"
    tar -czPf "$backup_file" -C "$path" "${sorted_files[@]:0:$m}"

    if [ $? -eq 0 ]; then
        echo "Archive created successfully. Deleting archived files..."
        for ((i=0; i<m; i++)); do
            rm -rf "$path/${sorted_files[i]}"
        done
        echo "Deleted $m old files."
    else
        echo "Error: failed to create archive. Files will not be deleted."
        exit 1
    fi
else
    echo "No files selected for archiving."
fi

echo "Cleanup completed successfully."
exit 0
