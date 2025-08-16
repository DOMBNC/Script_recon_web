# 🔎 Recon Pipeline

Reconnaissance and vulnerability scanning automation script** for penetration testing and bug bounty hunting.  
It integrates multiple well-known tools into a single pipeline, with support for both **fast scans** and **full deep scans**.

---

## ✨ Features
- **Modes**
  - `--fast` → Quick scan (subdomain enumeration + live host detection + nuclei scanning).
  - `--full` → Full-scope recon (subdomains, DNS, IPs, ports, technologies, screenshots, vulnerabilities, SQLi/XSS checks, etc.).
- **Automatic tool checking** → ensures all required tools are installed before running.
- **Parallel execution** → speeds up scans using GNU `parallel`.
- **Organized output** → results are saved into structured directories.
- **Logging** → all console output is saved in `recon.log` for later review.

---

## 📦 Requirements

Make sure the following tools are installed and accessible in your `$PATH`:

- [subfinder](https://github.com/projectdiscovery/subfinder)  
- [assetfinder](https://github.com/tomnomnom/assetfinder)  
- [amass](https://github.com/owasp-amass/amass)  
- [httpx](https://github.com/projectdiscovery/httpx)  
- [nuclei](https://github.com/projectdiscovery/nuclei)  
- [ffuf](https://github.com/ffuf/ffuf)  
- [parallel](https://www.gnu.org/software/parallel/)  

*(Full mode requires additional tools like `nmap`, `masscan`, `rustscan`, `nikto`, `sqlmap`, `xsser`, `wafw00f`, `gowitness`, `theHarvester`, `subjack`, `waybackurls`, `whatweb`, etc.)*

---

## 🚀 Usage

chmod +x recon_pipeline.sh
./recon_pipeline.sh <domain> <--fast|--full>

---

## Examples

### Fast mode (quick nuclei scan on live subdomains):

    ./recon_pipeline.sh example.com --fast

### Full mode (comprehensive recon + vulnerability scanning):

    ./recon_pipeline.sh example.com --full

---

## 📂 Output Structure

All results are stored inside a folder named recon_<domain>/:

    recon_example.com/
    │── recon.log              # Log file with all console output
    │── subdomains/            # Enumerated subdomains
    │── ip_addresses/          # Resolved IPs and reverse DNS
    │── ports/                 # Nmap, Masscan, Rustscan results
    │── content/               # Live subdomains, ffuf, waybackurls, etc.
    │── vulnerabilities/       # Nuclei, SQLi, XSS, SSRF, CORS, takeover, etc.
    │── technologies/          # WhatWeb, Wappalyzer results
    │── screenshots/           # Website screenshots
    │── dns/                   # DNS enumeration, zone transfer attempts
    │── certificates/          # Certificate transparency logs
    │── emails/                # Harvested emails
    │── scans/                 # Other scan results
