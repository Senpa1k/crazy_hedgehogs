#!/bin/bash
path=$1
size_of_dir=$2
size_limit=$3
sum=0
m=0
pwd_to_backup='$PWD/backup'
current_size =$(du -s "$path" | awk '{print $1}')
result = $((current_size*100/size_of_dir))
echo "The directory is $result% full"

if [$result -gt $size_limit]; then
	for f in $(ls -tr "$path"); do
		file_size=$(du "$path/$f" | awk '{print $1}')
		echo $file_size
		result=$((result-file_size *100/size_of_dir))
		m=$((m+1))
		if [$result -le $size_limit ]; then
			break
		fi
	done
fi

mapfile -t sorted_files < < (ls -tr "$path")
tar_cmd = (tar - czPf "$pwd_to_backup/")
for (( i=0; i<m ; i++)); do
	tar_cmd+=("$path/${sorted_files[i]}")
done
exit
