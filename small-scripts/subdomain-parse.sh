#! /bin/bash

aggregate(){
	cat amass/* > subdomains.raw
	cat ctfr/* >> subdomains.raw
	awk '{ print $2 }' gobuster/*.dnsbrute >> subdomains.raw
	cat sslcerts/*.sslcert >> subdomains.raw
	cat subdomains.raw | tr '[:upper:]' '[:lower:]' | sort -u > subdomains.list
}

scope-check(){
	echo "subdomain,ip" > subdomains.csv
	for i in $(cat subdomains.list)
	do
		for x in $(dig +short $i)
		do
			TEST=$(grep "^$x$" scope.ips)
			if [[ -n $TEST ]]
			then
				echo "$i,$x" >> subdomains.csv
			fi
		done
	done
}

aggregate
scope-check
