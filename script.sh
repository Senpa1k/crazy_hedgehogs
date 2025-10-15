#!/bin/bash

path=$1
size_limit=$2
sum=0
m=0

if [ $# -ne 2 ]; then
    echo "Use correct form!"
    exit 1
fi

if [ ! -d "$path" ]; then
    echo "Directory '$path' does not exist."
    exit 1
fi

parent_dir=$(dirname "$path")
pwd_to_backup="$parent_dir/backup"
if [ ! -d "$pwd_to_backup" ]; then
    mkdir -p "$pwd_to_backup" || { echo "Cannot create backup directory."; exit 1; }
fi

current_percentage=$(df --output=pcent "$path" | tail -n 1 | tr -d ' %')

total_size=$(du -s "$path"| awk '{print $1}')

echo "The directory is $current_percentage% full"

mapfile -t sorted_files < <(ls -tr "$path")

if [ "$current_percentage" -gt "$size_limit" ]; then
    echo "Directory exceeds size limit ($size_limit%). Selecting files to archive..."
    for f in "${sorted_files[@]}"; do
        if [ -f "$path/$f" ]; then
            file_size=$(du -s "$path/$f" | awk '{print $1}')
            percentage_reduction=$(( (file_size * 100) / total_size ))
            current_percentage=$((current_percentage - percentage_reduction))
            m=$((m + 1))
            if [ "$current_percentage" -le "$((size_limit * 2 / 3))" ]; then
                break
            fi
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
            if [ -f "$path/${sorted_files[i]}" ]; then
                rm -f "$path/${sorted_files[i]}"
            fi
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

