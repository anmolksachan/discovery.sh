# discovery.sh

![image](https://github.com/anmolksachan/discovery.sh/assets/60771253/57a4d3af-05e0-404d-9b71-a85e5809ab2d)

* Discovery.sh
This is the main script for this project.

* Requirements
    From apt:
    - curl
    - nmap
    - amass
    - gobuster
    - powershell
    - seclists
    - theHarvester
    - python3-pip

#+BEGIN_SRC sh
sudo apt update && sudo apt upgrade -y && sudo apt install -y curl nmap amass gobuster powershell seclists theharvester python3-pip
#+END_SRC

    From pip:
    - pipenv

#+BEGIN_SRC sh
pip3 install pipenv
#+END_SRC

    From github:
    - dnsrecon - https://github.com/darkoperator/dnsrecon
    - ctfr - https://github.com/UnaPibaGeek/ctfr
    - Get-SSLCertInfo-Scan - https://github.com/NetSPI/PowerShell
    - Get-FederationEndpoints - https://github.com/NetSPI/PowerShell

#+BEGIN_SRC sh
git clone https://github.com/darkoperator/dnsrecon.git && git clone https://github.com/UnaPibaGeek/ctfr.git && https://github.com/NetSPI/PowerShell.git
#+END_SRC

Pipenv should be used to install ctfr.py.

#+BEGIN_SRC sh
cd path/to/ctfr
pipenv install --three
#+END_SRC
*** Usage
The general format is:
#+BEGIN_SRC sh
discovery.sh [scan types] [tool path] [-w /path/to/wordlist.txt] [-i /path/to/host/file.txt] [-o /path/to/output/dir/] [-c Client_Name]
#+END_SRC

For example:
#+BEGIN_SRC sh
discovery.sh --all --tool-path ~/Tools/ -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -i ~/Client/hosts.txt -o ~/Client/output -c Client
#+END_SRC

Full list of options:
#+BEGIN_SRC sh
Scan Types:
        --nmap              Perform live host discovery using nmap
        --domain            Perform Domain Name recon
        --osint             Perform OSINT for emails and users
        --ads               Check for ADS domains
        --all               Perform all checks and scans

Tools Path:
        --tool-path         Provide the path to the directory containing github tools

Input/Output:
        -i                  Provide the path to a file containing all target hosts (IPs/URLs)
        -o                  Provide the path for the directory to write out files

Client Name:
        -c                  Provide the client name

Help:
        -h or --help        Print this help
#+END_SRC

In general you will just want to run with the ~--all~ flag, but specific groups of scans can be run as well. A ~[scan type]~, ~[input file]~, ~[output directory]~, and ~[client name]~ must be supplied. The domain and ADS scans also require ~[tool path]~ for both, and ~[wordlist]~ for domain scans.

Note: The script has been picked from here (https://gitlab.com/kcasyn/discovery.sh) and all credit goes to the original author, i just created innstall.sh script to make installation process easier. 
CHEERS 🍻 
