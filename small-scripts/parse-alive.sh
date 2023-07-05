#! /bin/bash

nmap -sL -Pn -n -iL ips.txt | awk '{print $5}' | grep -v "address" | grep -v "nmap" | sort -u > scope.ips
awk '/Up/{ print $2 }' nmap/*-Ping.gnmap > disco.raw
awk '/open/{ print $2 }' nmap/*-TCP-Disco.gnmap >> disco.raw
touch alive.ips
cat disco.raw | sort -u > disco.ips
for i in $(cat disco.ips)
do
	grep "^$i$" scope.ips >> alive.ips
done
