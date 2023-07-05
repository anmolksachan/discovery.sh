#!/bin/bash

### INFO
# Created by kcasyn
# Run in a folder containing a urls.txt containing all scope URLs.

### Required tools

## apt
# theharvester

### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Functions

## Recon: Employees, Emails, and Users

# Performs OSINT with theHarvester
harvester(){
    echo -e "${GREEN}[+]${RESET} Running the Harvester..."
    for i in $(cat urls.txt)
    do
	theHarvester -d "$i" -b all | tee -a harvester/$i.harvester
    done
}

## Create Folder Structure
echo -e "${GREEN}[+]${RESET} Creating folder structure..."
mkdir harvester

## Recon: Employees, Emails, Users
echo -e "${GREEN}[+]${RESET} Performing user OSINT..."
harvester
