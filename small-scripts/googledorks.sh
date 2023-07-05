#! /bin/bash

### INFO
# Created by kcasyn
# Provide the path to a file containing all in scope URLs, one per line.
# Provide the path to a file containing all the filetypes you would like to search for.

### Required tools

## apt
# googler

### Arguments

if [[ "$#" -eq 2 ]]
   then
       URLFILE=$1

       for x in $(cat $2)
       do
	   FILETYPES+=("$x")
       done
else
    cat <<EOF
Usage: googledorks.sh /url/file/path /filetype/file/path
EOF
    exit
fi

googledorks(){
	for i in $(cat $URLFILE)
	do
		for j in ${FILETYPES[@]}
		do
			echo "Searching $i for $j files..."
			echo "\n\n" | googler -C site:$i filetype:$j > google/$i.$j.txt
			jitter=$(shuf -i 1-3 -n 1)
			sleep $jitter
		done
	done
}

googledorks
