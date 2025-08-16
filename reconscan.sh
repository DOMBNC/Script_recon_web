#!/bin/bash

# ==============================
# Recon & Vulnerability Scanner
# ==============================

if [ $# -lt 2 ]; then
    echo "Usage: $0 <domain> <--fast|--full>"
    exit 1
fi

domain=$1
mode=$2
output_dir="recon_$domain"

# Logging setup
mkdir -p $output_dir
exec > >(tee -i $output_dir/recon.log)
exec 2>&1

# ==============================
# Check tools before running
# ==============================
check_tool() {
    command -v "$1" >/dev/null 2>&1 || { echo "[!] $1 not installed. Exiting."; exit 1; }
}

TOOLS_COMMON=(subfinder assetfinder amass httpx nuclei ffuf parallel)
TOOLS_FULL=(nmap masscan rustscan nikto sqlmap xsser wafw00f gowitness dirsearch \
    theHarvester subjack dnsenum dnsrecon sslyze testssl.sh whatweb wappalyzer \
    curl jq dig)

for t in "${TOOLS_COMMON[@]}"; do check_tool $t; done
if [ "$mode" == "--full" ]; then
    for t in "${TOOLS_FULL[@]}"; do check_tool $t; done
fi

# ==============================
# Create output folders
# ==============================
mkdir -p $output_dir/{subdomains,ip_addresses,ports,screenshots,content,vulnerabilities,emails,technologies,dns,certificates,scans}

echo "[+] Starting $mode reconnaissance for $domain"

# ==============================
# Subdomain enumeration
# ==============================
echo "[+] Enumerating subdomains..."
subfinder -d $domain -o $output_dir/subdomains/subfinder.txt
assetfinder --subs-only $domain > $output_dir/subdomains/assetfinder.txt
amass enum -d $domain -o $output_dir/subdomains/amass.txt

sort -u $output_dir/subdomains/*.txt > $output_dir/subdomains/all_subdomains.txt

# ==============================
# Web probing
# ==============================
echo "[+] Probing live subdomains..."
cat $output_dir/subdomains/all_subdomains.txt | httpx -silent -o $output_dir/content/live_subdomains.txt

# ==============================
# Fast mode: nuclei only
# ==============================
if [ "$mode" == "--fast" ]; then
    echo "[+] Running nuclei (fast mode)..."
    nuclei -l $output_dir/content/live_subdomains.txt -o $output_dir/vulnerabilities/nuclei_results.txt
    echo "[+] FAST scan completed. Results in $output_dir"
    exit 0
fi

# ==============================
# Full mode
# ==============================
echo "[+] Resolving IP addresses..."
cat $output_dir/subdomains/all_subdomains.txt | dnsx -a -resp-only -o $output_dir/ip_addresses/resolved_ips.txt

echo "[+] Port scanning with nmap + masscan + rustscan..."
parallel -j 3 ::: \
    "nmap -iL $output_dir/ip_addresses/resolved_ips.txt -p- -sV -sC -oN $output_dir/ports/nmap_full_scan.txt" \
    "masscan -iL $output_dir/ip_addresses/resolved_ips.txt -p1-65535 --rate=1000 -oG $output_dir/ports/masscan_results.txt" \
    "rustscan -a $output_dir/ip_addresses/resolved_ips.txt --ulimit 5000 -- -sV -sC -oN $output_dir/ports/rustscan_results.txt"

echo "[+] WAF detection..."
wafw00f -i $output_dir/content/live_subdomains.txt -o $output_dir/content/waf_detection.txt

echo "[+] Screenshots..."
gowitness file -f $output_dir/content/live_subdomains.txt -P $output_dir/screenshots/

echo "[+] Content discovery..."
cat $output_dir/content/live_subdomains.txt | parallel -j 5 "ffuf -w /path/to/wordlist.txt -u \"https://{}/FUZZ\" -mc 200,204,301,302,307,401,403 -o $output_dir/content/ffuf_{}.json"

echo "[+] Running nuclei (full mode)..."
nuclei -l $output_dir/content/live_subdomains.txt -o $output_dir/vulnerabilities/nuclei_results.txt

echo "[+] Running nikto..."
nikto -h $output_dir/content/live_subdomains.txt -output $output_dir/vulnerabilities/nikto_results.txt

echo "[+] Harvesting emails..."
theHarvester -d $domain -b all -f $output_dir/emails/theharvester_results.txt

echo "[+] Checking subdomain takeover..."
subjack -w $output_dir/subdomains/all_subdomains.txt -t 100 -timeout 30 -o $output_dir/vulnerabilities/subjack_results.txt -ssl

echo "[+] Checking Wayback Machine URLs..."
waybackurls $domain | sort -u > $output_dir/content/wayback_urls.txt

echo "[+] Running sqlmap on historical URLs..."
sqlmap -m $output_dir/content/wayback_urls.txt --batch --random-agent --level 1 --risk 1 -o -report-file $output_dir/vulnerabilities/sqlmap_results.txt

echo "[+] Running XSS scanner..."
xsser --url "https://$domain" --auto --Cw 3 --Cl 5 --Cs 5 --Cp 5 --CT 5 --threads 10 --output $output_dir/vulnerabilities/xsser_results.xml

echo "[+] Technology detection..."
cat $output_dir/content/live_subdomains.txt | parallel -j 5 "whatweb {} >> $output_dir/technologies/whatweb_results.txt"

echo "[+] FULL scan completed. Results in $output_dir"
