#! /bin/bash

### INFO
# Created by kcasyn
# Run in a folder containing a urls.txt containing all scope URLs.

### Required tools

## apt
# googler

## github


### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Variables
company=$1
paste_sites=("pastebin.com" "filedropper.com" "FriendPaste.com" "CopyTaste.com" "Cl1p.net" "ShortText.com" "TextSave.de" "TextSnip.com" "TxtB.in")

### Functions

## Vulnerability Enumeration: Manual Web Application Checks

## Vulnerability Enumeration: Company Files

# Identify potential company information on paste sites
clipboards(){
        for i in ${paste_sites[@]}
        do
                echo "Searching $i..."
                echo "\n\n" | googler -C $company site:$i > $i.txt
		jitter=$(shuf -i 1-3 -n 1)
		sleep $jitter
        done
}

clipboards
