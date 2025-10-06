#!/bin/bash

# Проверка количества аргументов
if [ $# -ne 3 ]; then
    echo "Usage: $0 <path> <size_of_dir> <size_limit>"
    exit 1
fi

path=$1
size_of_dir=$2
size_limit=$3
sum=0
m=0
pwd_to_backup="$PWD/backup"

# Проверка, что каталог существует
if [ ! -d "$path" ]; then
    echo "Error: directory '$path' does not exist."
    exit 1
fi

# Проверка, что аргументы — числа
if ! [[ "$size_of_dir" =~ ^[0-9]+$ && "$size_limit" =~ ^[0-9]+$ ]]; then
    echo "Error: size_of_dir and size_limit must be integers."
    exit 1
fi

# Проверка существования папки backup
if [ ! -d "$pwd_to_backup" ]; then
    mkdir -p "$pwd_to_backup" || { echo "Cannot create backup directory."; exit 1; }
fi

# Определение текущего размера каталога
current_size=$(du -s "$path" | awk '{print $1}')
result=$((current_size * 100 / size_of_dir))
echo "The directory is $result% full"

# Проверка превышения лимита
if [ "$result" -gt "$size_limit" ]; then
    echo "Directory exceeds size limit ($size_limit%). Removing oldest files..."
    for f in $(ls -tr "$path"); do
        file_size=$(du "$path/$f" | awk '{print $1}')
        echo "Considering file: $f ($file_size KB)"
        result=$((result - (file_size * 100 / size_of_dir)))
        m=$((m + 1))
        if [ "$result" -le "$size_limit" ]; then
            echo "Reached target limit. Stopping at $result%."
            break
        fi
    done
else
    echo "Directory usage is within limit."
fi

# Архивация выбранных файлов
mapfile -t sorted_files < <(ls -tr "$path")
tar_cmd=(tar -czPf "$pwd_to_backup/backup_$(date +%Y%m%d_%H%M%S).tar.gz")

for ((i=0; i<m; i++)); do
    tar_cmd+=("$path/${sorted_files[i]}")
done

if [ "$m" -gt 0 ]; then
    echo "Archiving $m oldest files to backup..."
    "${tar_cmd[@]}"
    echo "Backup completed: $pwd_to_backup"
else
    echo "No files to archive."
fi

exit 0
