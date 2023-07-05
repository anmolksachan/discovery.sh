#sudo apt update && sudo apt upgrade -y
echo "[+] Installing nmap amass gobuster powershell seclists theharvester python3-pip"
sudo apt install -y curl nmap amass gobuster powershell seclists theharvester python3-pip
echo "[+] You need to manually update theharvester command in the script"
mkdir ~/Client/
cd ~/Client/
mkdir ~/output/
mkdir ~/Tools/
cd ~/Tools/
echo "[+] Installing dnsrecon"
git clone https://github.com/darkoperator/dnsrecon.git
echo "[+] Installing ctfr"
git clone https://github.com/UnaPibaGeek/ctfr.git
echo "[+] Installing https://github.com/NetSPI/PowerShell.git | Note: You might have to manually install thsi since this is an [Internal Tool]"
git clone https://github.com/NetSPI/PowerShell.git
echo "[+] Pipenv should be used to install ctfr.py"
echo "[+] Pipenv should be used to install ctfr.py.running command pip3 install pipenv"
pip3 install pipenv
echo "Done. Cheers!!"
echo "Usage: discovery.sh [scan types] [tool path] [-w /path/to/wordlist.txt] [-i /path/to/host/file.txt] [-o /path/to/output/dir/] [-c Client_Name]"
echo "Example: discovery.sh --all --tool-path ~/Tools/ -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -i ~/Client/hosts.txt -o ~/Client/output -c Client"
