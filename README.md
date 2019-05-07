# Horizon - Automate Reconnaissance

* [horizon-dns](#horizon-dns)
* [horizon-web](#horizon-web)

### Todo

Currently I'm working on `horizon-web` and `horizon-code`. These will be made
available once they reach a usable state.

## horizon-dns

Subdomain enumeration using various tools and online services.

```
  Required:
    -d <url>        URL

  Optional:
    -h              This help menu
    -o <path>       Output directory where files will be stored
    -r <resolvers>  List of resolvers
    -w <wordlist>   Wordlist to be used when brute forcing subdomains
```

### Dependencies

* jq
* curl
* dig
* [massdns](https://github.com/blechschmidt/massdns)
* [takeover](https://github.com/m4ll0k/takeover)
* [amass](https://github.com/caffix/amass)
* [knockpy](https://github.com/guelfoweb/knock)

### What does it do?

The script starts off by checking if there's a wildcard dns record on the target.
Based on this the script will decide wether or not to use brute forcing.

It will then run `amass`, and if a wildcard was not detected, it will then run
`knockpy`.

If you add the required Cloudflare data in `config/dns.conf` it will then try to
leverage Cloudflare to gain more knowledge about the DNS records.

Next it will search `Buffer Over`, `Cert Spotter`, `Crt.sh`, `Threat Crowd` and,
if configured with API key, `Virus Total`

Everything that has been found after these steps will be merged, sorted and
duplicates will be removed before writing all of it to a single file. This file
will be used with `massdns` to determine online hosts.

After this whole process is complete, a report is provided in the terminal, and
the final results can be seen in the output files.

#### Detecting new hosts

If future scans for the same target is done in the same output directory, the
script will detect new hosts which has not been seen before and these will be
available in the file `hosts-new.txt`

The way this works is that the script writes all detected hosts to
`hosts-all.txt`. After the file `hosts-merged.txt` has been created for the
current scan, it will compare the hosts in this file against the `hosts-all.txt`
file detecting new findings.

## horizon-web

Web application reconnaissance and content discovery

```
  Required:
    -u <url>            URL

  Optional:
    -d <seconds>        Time in seconds, to way between requests
                        Used by: dirsearch

    -e <extensions>     Extensions for brute forcing files and directories separated by comma
                        Used by: dirsearch

    -h                  This help menu

    -o <directory>      Output directory

    -r <regex>          Regular expression pattern to search for links
                        Used by: linkfinder

    -t <threads>        Number of threads to use (default: 10)
                        Used by: dirsearch

    -w <wordlist>       Wordlist for file and directory brute forcing
                        Used by: dirsearch

    -x <codes>          Comma separated list of response codes to ignore (default: 500,503)
                        Used by: dirsearch
```

### Dependencies

* [wafw00f](https://github.com/EnableSecurity/wafw00f)
* [wappalyzer](https://www.npmjs.com/package/wappalyzer)
* [dirsearch](https://github.com/maurosoria/dirsearch)
* [linkfinder](https://github.com/GerbenJavado/LinkFinder)

### What does it do?

Currently this script only perform some simple web application reconnaissance
and content discovery. It uses

* `wafw00f` to detect web application firewalls
* `wappalyzer` to determine which technologies that are used
* `dirsearch` to brute force files and directories
* `linkfinder` to detect endpoints in javascript files

It will look for and download `robots.txt` if available, and search wayback
machine to find archived urls for the given domain.
