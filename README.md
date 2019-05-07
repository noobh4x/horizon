# Horizon - Automate Reconnaissance

### Todo

Currently I'm working on `horizon-web` and `horizon-code`. These will be made
available once they reach a usable state.

## horizon-dns

Subdomain enumeration using various tools and online services.

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
