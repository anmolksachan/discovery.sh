#!/bin/bash

### INFO
# Created by kcasyn
# Run in a folder containing a urls.txt containing all scope URLs.

### Required tools

## apt
# curl
# powershell

## github
# Get-FederationEndpoints - https://github.com/NetSPI/PowerShell/blob/master/Get-FederationEndpoint.ps1

### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Functions

## Information Gathering: ADS Domains

# Attempts to discover ADS domains from lyncdiscover URLs
lyncdiscover(){
    echo -e "${GREEN}[+]${RESET} Checking for ADS domains with lyncdiscover..."
    for i in $(cat urls.txt)
    do
	curl -k -I https://lyncdiscover.$i | tee -a ads/$i.lyncdiscover
    done
}

# Attempts to discover ADS domains from autodiscover URLs
autodiscover(){
    echo -e "${GREEN}[+]${RESET} Checking for ADS domains with autodiscover..."
    for i in $(cat urls.txt)
    do
	curl -k -I --ntlm -u user:password https://autodiscover.$i | tee -a ads/$i.autodiscover
    done
}

# Attempts to discover ADS domains from azure redirects
azure(){
    echo -e "${GREEN}[+]${RESET} Checking for ADS domains with Azure Redirects..."
    for i in $(cat urls.txt)
    do
	pwsh -Command "&Import-Module ~/Tools/PowerShell/Get-FederationEndpoint.ps1; Get-FederationEndpoint -domain $i" | tee -a ads/$i.azure
    done
}

## Create Folder Structure
echo -e "${GREEN}[+]${RESET} Creating folder structure..."
mkdir ads

## Information Gathering: ADS Domains
echo -e "${GREEN}[+]${RESET} Identifying ADS domains..."
lync
autodiscover
azure
