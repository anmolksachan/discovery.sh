#!/bin/bash

### INFO
# Created by kcasyn
# Run in a folder containing a hosts.txt with all scope IPs/URLs, and an ips.txt with all inscope IPs/Ranges.

### Required tools

## apt
# nmap

### Global Variables

CLIENT=$1
HOSTFILE=$2
IPFILE=$3

### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Functions

## Information Gathering: Live Systems

# Performs a ping scan to identify live hosts
pingscan(){
    echo -e "${GREEN}[+]${RESET} Performing ping scan..."
    sudo nmap -sP -PE -iL $HOSTFILE -oA nmap/$CLIENT-Ping
}

# Performs a TCP discovery scan on select ports
tcpscan(){
    echo -e "${GREEN}[+]${RESET} Performing tcp scan..."
    sudo nmap -sT -Pn -n -T 4 --min-hostgroup 128 --max-retries 0 -p21,22,23,25,53,79,80,81,110,139,143,443,445,465,514,993,1433,3306,1521,5432,2902,5800,5900,3389,8000,8300,8080,8500,8501,8433,8888,51010,9090,9100,10000 -iL $HOSTFILE -oA nmap/$CLIENT-TCP-Disco
}

# Performs a UDP discovery scan on select ports
udpscan(){
    echo -e "${GREEN}[+]${RESET} Performing udp scan..."
    sudo nmap -sU -sV -O -T4 -Pn -p53,69,161,111,123,514 -iL $HOSTFILE -oA nmap/$CLIENT-UDP-Disco
}

# Performs a TCP discovery scan on all ports on live hosts
tcpfullscan(){
    echo -e "${GREEN}[+]${RESET} Performing full tcp scan"
    sudo nmap -sT -sV -O -T4 -Pn -p1-65535 --min-hostgroup 128 --max-retries 0 -iL alive.ips -oA nmap/$CLIENT-TCP-Full
}

## Parsers

# Parses nmap scans and creates a list of alive IPs
parsealive(){
    echo -e "${GREEN}[+]${RESET} Parsing alive IPs..."
    awk '/Up/{ print $2 }' nmap/$CLIENT-Ping.gnmap > disco.raw
    awk '/open/{ print $2 }' nmap/$CLIENT-TCP-Disco.gnmap >> disco.raw
    touch alive.ips
    cat disco.raw | sort -u > disco.ips
    for i in $(cat disco.ips)
    do
	grep "^$i$" scope.ips >> alive.ips
    done
}

# Generates a list of all in-scope IPs
createscope(){
    echo -e "${GREEN}[+]${RESET} Creating scope list..."
    sudo nmap -sL -Pn -n -iL $IPFILE | awk '{print $5}' | grep -v "address" | grep -v "nmap" | sort -u > scope.ips
}

## Create Folder Structure
echo -e "${GREEN}[+]${RESET} Creating folder structure..."
mkdir nmap

## Create Scope
echo -e "${GREEN}[+]${RESET} Creating scope..."
createscope

## Information Gathering: Live Systems
echo -e "${GREEN}[+]${RESET} Identifying live hosts and open ports..."
pingscan
tcpscan
parsealive
tcpfullscan
udpscan
