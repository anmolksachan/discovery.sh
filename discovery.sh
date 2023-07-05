#!/bin/bash

### INFO
# Created by kcasyn

### Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

### Required tools

## apt
declare apt_tools=("curl" "nmap" "amass" "gobuster" "powershell" "seclists" "theharvester")
declare apt_tools_check=("curl" "nmap" "amass" "gobuster" "pwsh" "theharvester")
# curl
# nmap
# amass (or from github)
# gobuster
# powershell
# seclists

declare github_tools=("dnsrecon:https://github.com/darkoperator/dnsrecon.git" "ctfr:https://github.com/UnaPibaGeek/ctfr.git" "Get-SSLCertInfo-Scan:https://raw.githubusercontent.com/NetSPI/PowerShell/master/Get-SSLCertInfo-Scan.psm1" "Get-FederationEndpoints:https://github.com/NetSPI/PowerShell/blob/master/Get-FederationEndpoint.ps1" "https://github.com/laramies/theHarvester.git")
## github
# dnsrecon - https://github.com/darkoperator/dnsrecon.git
# ctfr - https://github.com/UnaPibaGeek/ctfr.git
# theHarvester - https://github.com/laramies/theHarvester.git
# Get-SSLCertInfo-Scan - https://raw.githubusercontent.com/NetSPI/PowerShell/master/Get-SSLCertInfo-Scan.psm1
# Get-FederationEndpoints - https://github.com/NetSPI/PowerShell/blob/master/Get-FederationEndpoint.ps1

## Tool check
for tool in "${apt_tools_check[@]}"
do
    if ! which "$tool" > /dev/null
    then
	echo -e "\n[${RED}!${RESET}] $tool ${YELLOW}not found${RESET}"
	echo -e "\n[${YELLOW}!${RESET}] Use the following command to install tools:"
	echo -e "\nsudo apt install -y ${apt_tools[@]}"
	echo -e "\n\n[${YELLOW}!${RESET}] Ensure the following are also installed in a common directory (e.g. ~/Tools/):"
	tr ' ' '\n' <<<  "${github_tools[@]}"
	exit 1
    fi
done

### Global Variables

WD=$(pwd)
HOST_FILE=""
OUTPUT_DIR=""
IP_LIST=()
URL_LIST=()
CLIENT=""
WORDLIST=""
TOOL_PATH=""
LIVE_SYSTEM_SCAN=false
DOMAIN_RECON=false
OSINT=false
ADS_SCAN=false

### Functions

## Information Gathering: Live Systems

# Performs a ping scan to identify live hosts
pingscan(){
    echo -e "[${YELLOW}+${RESET}] Initializing Ping Scan"
    sudo nmap -sP -PE -iL $HOST_FILE -oA $OUTPUT_DIR/nmap/$CLIENT-Ping
    echo -e "[${GREEN}+${RESET}] Ping Scan Complete"
}

# Performs a TCP discovery scan on select ports
tcpscan(){
    echo -e "[${YELLOW}+${RESET}] Performing Targeted TCP Scan"
    sudo nmap -sT -Pn -n -T 4 --min-hostgroup 128 --max-retries 0 -p21,22,23,25,53,79,80,81,110,139,143,443,445,465,514,993,1433,3306,1521,5432,2902,5800,5900,3389,8000,8300,8080,8500,8501,8433,8888,51010,9090,9100,10000 -iL $HOST_FILE -oA $OUTPUT_DIR/nmap/$CLIENT-TCP-Disco
    echo -e "[${GREEN}+${RESET}] Targeted TCP Scan Complete"
}

# Performs a UDP discovery scan on select ports
udpscan(){
    echo -e "[${YELLOW}+${RESET}] Performing Targeted UDP Scan"
    sudo nmap -sU -sV -O -T4 -Pn -p53,69,161,111,123,514 -iL $OUTPUT_DIR/alive.ips -oA $OUTPUT_DIR/nmap/$CLIENT-UDP-Disco
    echo -e "[${GREEN}+${RESET}] Targeted UDP Scan Complete"
}

# Performs a TCP discovery scan on all ports on live hosts
tcpfullscan(){
    echo -e "[${YELLOW}+${RESET}] Performing Full TCP Scan"
    sudo nmap -sT -sV -O -T4 -Pn -p1-65535 --min-hostgroup 128 --max-retries 0 -iL $OUTPUT_DIR/alive.ips -oA $OUTPUT_DIR/nmap/$CLIENT-TCP-Full
    echo -e "[${GREEN}+${RESET}] Full TCP Scan Complete"
}

## Recon: Domain Names

# Performs RDNS lookup on all hosts
rdns(){
    echo -e "[${YELLOW}+${RESET}] Performing RDNS Scan"
    nmap -sL -iL $HOST_FILE -oA $OUTPUT_DIR/nmap/$CLIENT-RDNS
    echo -e "[${GREEN}+${RESET}] RDNS Scan Complete"
}

# Performs domain enumeration using amass
amass_scan(){
    echo -e "[${YELLOW}+${RESET}] Performing AMASS Scan"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	amass enum -passive -d $i -o $OUTPUT_DIR/amass/$i.amass.txt
    done
    echo -e "[${GREEN}+${RESET}] AMASS Scan Complete"
}

# Identifies subdomains using crt.sh
ctfr(){
    echo -e "[${YELLOW}+${RESET}] Performing crt.sh Scan"
    cd $TOOL_PATH/ctfr/
    mkdir ctfr
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	pipenv run python3 ctfr.py -d $i -o ctfr/$i.ctfr
    done
    mv ctfr $OUTPUT_DIR/domains/
    cd $WD
    echo -e "[${GREEN}+${RESET}] crt.sh Scan Complete"
}

# Identifies domain and subdomain names from SSL certificates.
sslcertinfo(){
    echo -e "[${YELLOW}+${RESET}] Performing SSL Certificate Information Scan"
    awk '/\/ssl/ {for(i=5;i<=NF;i++)if($i~"/open/.+/ssl"){sub("/.*","",$i); print $2":"$i}}' $OUTPUT_DIR/nmap/$CLIENT-TCP-Full.gnmap > $OUTPUT_DIR/domains/ssl.txt
    pwsh -C "&Import-Module $TOOL_PATH/PowerShell/Get-SSLCertInfo-Scan.psm1; Get-SSLCertInfo-Scan -InputFile $OUTPUT_DIR/domains/ssl.txt -OnlyDomainList;" | tee -a $OUTPUT_DIR/domains/sslcertscan.txt
    echo -e "[${GREEN}+${RESET}] SSL Certificate Information Scan Complete"
}

# Performs DNS bruteforcing with gobuster
dnsbrute(){
    echo -e "[${YELLOW}+${RESET}] Performing DNS Brute Force"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	gobuster dns -t 50 -d $i -w $WORDLIST -o $OUTPUT_DIR/domains/$i.dnsbrute
    done
    echo -e "[${GREEN}+${RESET}] DNS Brute Force Complete"
}

# Performs DNS discovery and testing using dnsrecon
dnsrecon(){
    echo -e "[${YELLOW}+${RESET}] Performing DNSRecon Scan"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	python3 $TOOL_PATH/dnsrecon/dnsrecon.py -d $i -a -z --csv $OUTPUT_DIR/dns/$i.dnsrecon.csv 2>/dev/null
	python3 $TOOL_PATH/dnsrecon/dnsrecon.py -d $i -a -z --xml $OUTPUT_DIR/dns/$i.dnsrecon.xml 2>/dev/null
    done
    echo -e "[${GREEN}+${RESET}] DNSRecon Scan Complete"
}

## Recon: Employees, Emails, and Users

# Performs OSINT with theHarvester
harvester(){
    echo -e "[${YELLOW}+${RESET}] Performing theHarvester Scan"
    cd $TOOL_PATH/theHarvester/
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	pipenv run python3 ./theHarvester.py -d "$i" -b all | tee -a $OUTPUT_DIR/osint/$i.harvester
    done
    cd $WD
    echo -e "[${GREEN}+${RESET}] theHarvester Scan Complete"
}

## Information Gathering: ADS Domains

# Attempts to discover ADS domains from lyncdiscover URLs
lyncdiscover(){
    echo -e "[${YELLOW}+${RESET}] Checking for ADS domains with lyncdiscover"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	curl -k -I https://lyncdiscover.$i | tee -a $OUTPUT_DIR/ads/$i.lyncdiscover
    done
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Attempts to discover ADS domains from autodiscover URLs
autodiscover(){
    echo -e "[${YELLOW}+${RESET}] Checking for ADS domains with autodiscover"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	curl -k -I --ntlm -u user:password https://autodiscover.$i | tee -a $OUTPUT_DIR/ads/$i.autodiscover
    done
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Attempts to discover ADS domains from azure redirects
azure(){
    echo -e "[${YELLOW}+${RESET}] Checking for ADS domains with Azure Redirects"
    for i in $(cat $OUTPUT_DIR/urls.txt)
    do
	pwsh -Command "&Import-Module $TOOL_PATH/PowerShell/Get-FederationEndpoint.ps1; Get-FederationEndpoint -domain $i;" | tee -a $OUTPUT_DIR/ads/$i.azure
    done
    echo -e "[${GREEN}+${RESET}] Complete"
}

## Parsers

# Parses nmap scans and creates a list of alive IPs
parsealive(){
    echo -e "[${YELLOW}+${RESET}] Parsing Alive IPs"
    IP_ALIVE=($(awk '/Up/{ print $2 }' $OUTPUT_DIR/nmap/$CLIENT-Ping.gnmap | tr '\n' ' '))
    IP_ALIVE+=($(awk '/open/{ print $2 }' $OUTPUT_DIR/nmap/$CLIENT-TCP-Disco.gnmap | tr '\n' ' '))
    touch $OUTPUT_DIR/alive.ips
    tr ' ' '\n' <<< "${IP_ALIVE[@]}" | sort -u > $OUTPUT_DIR/alive.ips
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Parses domain/subdomain discovery files and creates a list of all discovered domains/subdomains
aggregate(){
    echo -e "[${YELLOW}+${RESET}] Aggregating Subdomains"
    SUBDOMAINS=($(cat $OUTPUT_DIR/amass/* | tr '\n' ' '))
    SUBDOMAINS+=($(cat $OUTPUT_DIR/domains/ctfr/* | tr '\n' ' '))
    SUBDOMAINS+=($(awk '{ print $2 }' $OUTPUT_DIR/domains/*.dnsbrute | tr '\n' ' '))
    tr ' ' '\n' <<< "${SUBDOMAINS[@]}" | sort -u > $OUTPUT_DIR/domains/subdomains.list
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Verifies discovered domains/subdomains correlate to scope IPs
scopecheck(){
    echo -e "[${YELLOW}+${RESET}] Comparing Subdomain IPs to Scope"
    echo "subdomain,ip" > $OUTPUT_DIR/domains/subdomains.csv
    for i in $(cat $OUTPUT_DIR/domains/subdomains.list)
    do
        for x in $(dig +short $i)
        do
            TEST=$(grep $x $OUTPUT_DIR/ips.txt)
            if [[ -n $TEST ]]
            then
                echo "$i,$x" >> $OUTPUT_DIR/domains/subdomains.csv
            fi
        done
    done
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Generates a list of all in-scope IPs and URLs
createscope(){
    echo -e "[${YELLOW}+${RESET}] Creating Scope"

    # Add IPs and URLs from $HOST_FILE to lists
    echo -e "[${YELLOW}+${RESET}] Creating IP and URL Lists"
    IP_LIST=($(awk '/[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}/{ print $1 }' $HOST_FILE | tr '\n' ' '))
    URL_LIST=($(egrep -v "[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}" $HOST_FILE | tr '\n' ' '))

    # Add IPs from DNS resolution of URLs to the list of IPs
    echo -e "[${YELLOW}+${RESET}] Adding URL IPs to IP List"
    for i in ${URL_LIST[@]}
    do
	for x in $(dig +short $i | egrep "[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}\.[1-2]{0,1}[0-9]{1,2}")
	do
	    IP_LIST+=("$x")
	done
    done

    # Expand any ranges in the $IP_LIST
    echo -e "[${YELLOW}+${RESET}] Expanding IP List"
    IP_LIST_EXPANDED=($(nmap -sL -Pn -n ${IP_LIST[@]} | awk '{print $5}' | sort -u | head -n -2 | tr '\n' ' '))
    
    # Add URLs from reverse DNS lookup of IPs to the list of URLs
    echo -e "[${YELLOW}+${RESET}] Adding rDNS of IPs to URL List"
    for i in ${IP_LIST_EXPANDED[@]}
    do
	for x in $(dig +short -x $i | sed 's/\.$//')
	do
	    URL_LIST+=("$x")
	done
    done

    # Output IP and URL lists to files for records and other functions
    tr ' ' '\n' <<< "${IP_LIST_EXPANDED[@]}" | sort -u > $OUTPUT_DIR/ips.txt
    tr ' ' '\n' <<< "${URL_LIST[@]}" | sort -u > $OUTPUT_DIR/urls.txt
    echo -e "[${GREEN}+${RESET}] Complete"
}

# Generates a list of IPs resolved from discovered domains/subdomains
subdomainips(){
    echo -e "[${YELLOW}+${RESET}] Parsing subdomain IPs..."
    awk -F, '{ print $2 }' $OUTPUT_DIR/domains/subdomains.csv | grep -v "ip" | sort -u > $OUTPUT_DIR/domains/subdomain-ips.txt
}

## Usage
usage(){
    cat <<EOF
Usage: discovery.sh [scan types] [tool path] [-w /path/to/wordlist.txt] [-i /path/to/host/file.txt] [-o /path/to/output/dir/] [-c Client_Name]

Example: discovery.sh --all --tool-path ~/Tools/ -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -i ~/Client/hosts.txt -o ~/Client/output -c Client

       Scan Types:
       	    --nmap		Perform live host discovery using nmap
	    --domain		Perform Domain Name recon
	    --osint		Perform OSINT for emails and users
	    --ads		Check for ADS domains
	    --all		Perform all checks and scans

       Tools Path:
       	    --tool-path		Provide the path to the directory containing github tools

       Input/Output:
	    -i			Provide the path to a file containing all target hosts (IPs/URLs)
	    -o			Provide the path for the directory to write out files

       Client Name:
       	    -c			Provide the client name

       Help:
	    -h or --help	Print this help


EOF
    exit 1
}

### Start
echo -e "[${YELLOW}+${RESET}] Initializing Program"
echo -e "[${GREEN}+${RESET}] Initialization Successful"
echo -e "[${YELLOW}+${RESET}] Parsing Operational Parameters"

### Argument parsing
if [[ $# -gt 0 ]]
then
   while [[ $# -gt 0 ]]
   do
       case "$1" in
	   -i)
	       HOST_FILE=$2
	       shift 2
	       ;;
	   -o)
	       OUTPUT_DIR=$2
	       shift 2
	       ;;
	   -c)
	       CLIENT=$2
	       shift 2
	       ;;
	   -w)
	       WORDLIST=$2
	       shift 2
	       ;;
	   --nmap)
	       LIVE_SYSTEM_SCAN=true
	       shift
	       ;;
	   --domain)
	       DOMAIN_RECON=true
	       shift
	       ;;
	   --tool-path)
	       TOOL_PATH=$2
	       shift 2
	       ;;
	   --osint)
	       OSINT=true
	       shift
	       ;;
	   --ads)
	       ADS_SCAN=true
	       shift
	       ;;
	   --all)
	       LIVE_SYSTEM_SCAN=true
	       DOMAIN_RECON=true
	       OSINT=true
	       ADS_SCAN=true
	       shift
	       ;;
	   -h|--help)
	       echo "Hello, Help?"
	       echo "Yes, this is Help"
	       usage
	       ;;
	   *)
	       echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
	       echo -e "Unknown option provided\n"
	       usage
	       ;;
       esac
   done
else
    echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
    echo -e "No arguments provided\n"
    usage
fi

echo -e "[${GREEN}+${RESET}] Parsing Complete"
echo -e "[${YELLOW}+${RESET}] Evaluating Operational Parameters"

if [[ $DOMAIN_RECON || $ADS_SCAN ]] && [[ -z $TOOL_PATH || -z $WORDLIST ]]
then
    if [[ $DOMAIN_RECON ]]
    then
	if [[ -z $TOOL_PATH && -z $WORDLIST ]]
	then
	    echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
	    echo "You must provide ${YELLOW}--tool-path${RESET} and ${YELLOW}-w${RESET} for domain scans"
	    exit 1
	elif [[ -z $TOOL_PATH ]]
	then
	    echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
	    echo "You must provide ${YELLOW}--tool-path${RESET} for domain scans"
	    exit 1
	elif [[ -z $WORDLIST ]]
	then
	    echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
	    echo "You must provide ${YELLOW}-w${RESET} for domain scans"
	    exit 1
	fi
    elif [[ $ADS_SCAN ]] && [[ -z $TOOL_PATH ]]
    then
	echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
	echo "You must provide ${YELLOW}--tool-path${RESET} for ADS scans"
	exit 1
    fi
fi

echo -e "[${GREEN}+${RESET}] Evaluation Complete"
echo -e "[${YELLOW}+${RESET}] Initializing Main Program"

if [[ ! -z $HOST_FILE ]] && [[ ! -z $OUTPUT_DIR ]] && [[ ! -z $CLIENT ]]
then

    ## Create Scope
    if [[ ! -f $OUTPUT_DIR/ips.txt || ! -f $OUTPUT_DIR/urls.txt ]]
    then
	createscope
    fi

    ## Create Folder Structure
    if [[ ! -z $OUTPUT_DIR ]]
    then
	echo -e "[${GREEN}+${RESET}] Creating Folder Structure"
	declare -a folders=("nmap" "domains" "dns" "amass" "osint" "ads")
	for folder in ${folders[*]}
	do
	    if [[ ! -d $OUTPUT_DIR/$folder ]]
	    then
		mkdir -p $OUTPUT_DIR/$folder
	    fi
	done
    fi

    ## Information Gathering: Live Systems
    if [[ $LIVE_SYSTEM_SCAN ]]
    then
	echo -e "[${GREEN}+${RESET}] Identifying Live Hosts and Open Ports"
	pingscan
	tcpscan
	parsealive
	tcpfullscan
	udpscan
    fi

    ## Recon: Domain Names
    if [[ $DOMAIN_RECON ]]
    then
	echo -e "[${GREEN}+${RESET}] Performing Domain OSINT"
	rdns
	dnsrecon
	ctfr
	sslcertinfo
	dnsbrute
	amass_scan
	aggregate
	scopecheck
	subdomainips
    fi

    ## Information Gathering: ADS Domains
    if [[ $ADS_SCAN ]]
    then
	echo -e "[${GREEN}+${RESET}] Identifying ADS Domains"
	lyncdiscover
	autodiscover
	azure
    fi

    ## Recon: Employees, Emails, Users
    if [[ $OSINT ]]
    then
	echo -e "[${GREEN}+${RESET}] Performing user OSINT"
	harvester
    fi
else
    echo -e "[${RED}!!!${RESET}] ${YELLOW}ERROR${RESET} [${RED}!!!${RESET}]\n"
    echo "You must provide ${YELLOW}-i${RESET}, ${YELLOW}-o${RESET}, and ${YELLOW}-c${RESET}"
    usage
fi
	  
echo -e "[${GREEN}+${RESET}] Program Complete"
echo -e "[${GREEN}+${RESET}] Shutting Down"
