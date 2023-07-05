#!/bin/bash

### INFO
# Created by kcasyn
# Run in a folder containing a urls.txt containing all scope URLs.

### Required tools

## apt
# nmap
# amass
# gobuster
# seclists

## github
# dnsrecon - https://github.com/darkoperator/dnsrecon.git
# ctfr - https://github.com/UnaPibaGeek/ctfr.git

### Global Variables

WD=$(pwd)
CLIENT=$1

### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Functions

## Recon: Domain Names

# Performs RDNS lookup on all hosts
rdns(){
    echo -e "${GREEN}[+]${RESET} Performing RDNS scan..."
    sudo nmap -sL -iL hosts.txt -oA nmap/$CLIENT-RDNS
}

# Performs OSINT using amass
amass_scan(){
    echo -e "${GREEN}[+]${RESET} Performing amass scan..."
    for i in $(cat urls.txt)
    do
	amass enum -passive -d $i -o amass/$i.amass.txt
    done
}

# Identifies subdomains using crt.sh
ctfr(){
    echo -e "${GREEN}[+]${RESET} Performing crt.sh scan..."
    cd ~/Tools/ctfr
    mkdir ctfr
    for i in $(cat $WD/urls.txt)
    do
	pipenv run python3 ctfr.py -d $i -o ctfr/$i.ctfr
    done
    mv ctfr $WD/
    cd $WD
}

# Performs DNS bruteforcing with gobuster
dnsbrute(){
    echo -e "${GREEN}[+]${RESET} Performing DNS brute forcing..."
    for i in $(cat urls.txt)
    do
	gobuster dns -t 50 -d $i -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -o domains/$i.dnsbrute
    done
}

# Performs DNS discovery and testing using dnsrecon
dnsrecon(){
    echo -e "${GREEN}[+]${RESET} Performing dnsrecon scan..."
    for i in $(cat urls.txt)
    do
	python3 ~/Tools/dnsrecon/dnsrecon.py -d $i -a -z --csv dns/$i.dnsrecon.csv
	python3 ~/Tools/dnsrecon/dnsrecon.py -d $i -a -z --xml dns/$i.dnsrecon.xml
    done
}

## Parsers

# Parses domain/subdomain discovery files and creates a list of all discovered domains/subdomains
aggregate(){
    echo -e "${GREEN}[+]${RESET} Aggregating subdomains..."
    cat amass/* > subdomains.raw
    cat ctfr/* >> subdomains.raw
    awk '{ print $2 }' domains/*.dnsbrute >> subdomains.raw
    cat subdomains.raw | sort -u > subdomains.list
}

# Verifies discovered domains/subdomains correlate to scope IPs
scopecheck(){
    echo -e "${GREEN}[+]${RESET} Checking subdomain IPs against scope..."
    echo "subdomain,ip" > subdomains.csv
    for i in $(cat subdomains.list)
    do
        for x in $(dig +short $i)
        do
            TEST=$(grep $x scope.ips)
            if [[ -n "$TEST" ]]
            then
                echo "$i,$x" >> subdomains.csv
            fi
        done
    done
}

# Generates a list of IPs resolved from discovered domains/subdomains
subdomainips(){
    echo -e "${GREEN}[+]${RESET} Parsing subdomain IPs..."
    awk -F, '{ print $2 }' subdomains.csv | grep -v "ip" | sort -u > subdomain-ips.txt
}

## Create Folder Structure
echo -e "${GREEN}[+]${RESET} Creating folder structure..."
mkdir domains
mkdir amass
mkdir dns

## Recon: Domain Names
echo -e "${GREEN}[+]${RESET} Performing domain OSINT..."
rdns
dnsrecon
ctfr
dnsbrute
amass_scan
aggregate
scopecheck
subdomainips
