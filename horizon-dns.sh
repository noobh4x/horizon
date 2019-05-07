#!/bin/bash

echo '
██╗  ██╗ ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗      ██████╗ ███╗   ██╗███████╗
██║  ██║██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║      ██╔══██╗████╗  ██║██╔════╝
███████║██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗██║  ██║██╔██╗ ██║███████╗
██╔══██║██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║╚════╝██║  ██║██║╚██╗██║╚════██║
██║  ██║╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║      ██████╔╝██║ ╚████║███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝

                                                              Automated DNS Enumeration
                                                                             by noobhax
'

################################################################################
# Preparations
################################################################################

BASE_PATH=`pwd`
SELF_PATH=$(dirname "$(readlink -f "$0")")
ERROR=0

# Checking dependencies
if [[ -z "`which jq 2>/dev/null`" ]]; then
    echo '[!!] Error: jq is required'
    ERROR=1
fi

if [[ -z "`which dig 2>/dev/null`" ]]; then
    echo '[!!] Error: dig is required'
    ERROR=1
fi

if [[ -z "`which curl 2>/dev/null`" ]]; then
    echo '[!!] Error: curl is required'
    ERROR=1
fi

if [[ -z "`which amass 2>/dev/null`" ]]; then
    echo '[!!] Error: amass is required - https://github.com/caffix/amass'
    ERROR=1
fi

if [[ -z "`which knockpy 2>/dev/null`" ]]; then
    echo '[!!] Error: knockpy is required - https://github.com/guelfoweb/knock'
    ERROR=1
fi

if [[ -z "`which massdns 2>/dev/null`" ]]; then
    echo '[!!] Error: massdns is required - https://github.com/blechschmidt/massdns'
    ERROR=1
fi

if [[ -z "`which takeover 2>/dev/null`" ]]; then
    echo '[!!] Error: takeover is required - https://github.com/m4ll0k/takeover'
    ERROR=1
fi

if [[ "$ERROR" -gt "0" ]]; then
    exit
fi

# Loading configuration file
if [[ -f $SELF_PATH/config/dns.conf ]]; then
    . $SELF_PATH/config/dns.conf
else
    echo '[!!] Error: Unable to load config/dns.conf'
fi

# Handling arguments
while getopts ":d:o:r:w:h" opt; do
    case $opt in
        d) DOMAIN=$OPTARG ;;
        h) SHOW_HELP=1 ;;
        o) OUTPUT_PATH=$OPTARG ;;
        r) RESOLVERS=$OPTARG ;;
        w) WORDLIST=$OPTARG ;;
    esac
done

if [[ -n $SHOW_HELP ]];
then
    echo "
  Required:
    -d <domain>     Domain

  Optional:
    -h              This help menu

    -o <path>       Output directory where files will be stored

    -r <resolvers>  List of resolvers
                    Used by: massdns

    -w <wordlist>   Wordlist to be used when brute forcing subdomains
                    Used by: amass, knockpy
    "
    exit
fi

# Domain is required
if [[ -z $DOMAIN ]]; then
    echo "Usage: $0 domain"
    exit
fi

if [[ -z $OUTPUT_PATH ]]; then
    SAVE_PATH=$BASE_PATH/horizon_output
    mkdir $SAVE_PATH
else
    SAVE_PATH=$OUTPUT_PATH
    if [[ -d $SAVE_PATH ]]; then
        SAVE_PATH=$(realpath $SAVE_PATH)
        echo -n "[?] The output directory already exists. Do you wish to clear it? [Y/n]: "
        read choice
        if [[ -z $choice ]]; then choice='yes'; fi
        case $choice in
            y*|Y*) rm -Rf $SAVE_PATH; mkdir -p $SAVE_PATH ;;
            n*|N*) ;;
            *) echo '[*] Invalid choice. Aborting...'; exit ;;
        esac
    else
        mkdir -p $SAVE_PATH
        SAVE_PATH=$(realpath $SAVE_PATH)
    fi
fi

cd $SAVE_PATH


if [[ -z $WORDLIST ]]; then
    WORDLIST=$SELF_PATH"/lists/dns-wordlist.txt"
else
    WORDLIST=$(realpath $WORDLIST)
fi

if [[ ! -f $WORDLIST ]]; then
    echo "[!!] Error: Unable to load wordlist. File does not exist. Aborting..."
    exit
fi

if [[ -z $RESOLVERS ]]; then
    RESOLVERS=$SELF_PATH"/lists/dns-resolvers.txt"
else
    RESOLVERS=$(realpath $RESOLVERS)
fi

if [[ ! -f $RESOLVERS ]]; then
    echo "[!!] Error: Unable to load resolvers list. File does not exist. Aborting..."
    exit
fi

################################################################################
# Preparations complete - process begins
################################################################################

TIME_START=`date +"%Y-%m-%d %H:%M:%S"`
TIMER_START=`date +"%s"`
echo "[*] Process started @ $TIME_START"
echo "  Domain     : $DOMAIN"
echo "  Output dir : $SAVE_PATH"
echo "  Resolvers  : $RESOLVERS"
echo "  Wordlist   : $WORDLIST"
echo
exit
WILDCARD=$(dig @1.1.1.1 A,CNAME {foohica7291673,b0r4m4dr4m41928,1sh0uldn0t3x1st}.$DOMAIN +short | wc -l)
if [[ "$WILDCARD" -gt "1" ]];
then
    echo "[*] Possible wildcard detected. Skipping brute forcing"
else
    echo "[*] No wildcard detected"
fi

echo "[*] Running amass"
if [[ "$WILDCARD" -gt "1" ]];
then
    amass -src -ip -active -noalts -norecursive -exclude crtsh,certspotter,bufferover,threatcrowd,virustotal -d $DOMAIN
else
    amass -src -ip -active -brute --min-for-recursive 3 -exclude crtsh,certspotter,bufferover,threatcrowd,virustotal -w $WORDLIST -d $DOMAIN
fi

COUNT_AMASS=0
if [[ -f "amass_output/amass.txt" ]]; then
    cat amass_output/amass.txt \
        | cut -d']' -f2 \
        | awk '{print $1}' \
        | sort -u \
        > hosts-amass.tmp
    COUNT_AMASS=`cat hosts-amass.tmp | wc -l`
fi

COUNT_KNOCKPY=0
if [[ "$WILDCARD" -lt "2" ]]; then
    echo
    echo "[*] Running knockpy"
    KNOCKFILES=`echo $DOMAIN | tr '.' '_'`"*.json"
    rm -f $KNOCKFILES
    knockpy -j -w $WORDLIST $DOMAIN
    KNOCKFILE=`find $BASE_PATH -name $KNOCKFILES -type f`
    cat $KNOCKFILE \
        | jq '.found.subdomain[]' \
        | sed 's/"//g' \
        | sed 's/*\.//' \
        | sort -u \
        > hosts-knockpy.tmp
    COUNT_KNOCKPY=`cat hosts-knockpy.tmp | wc -l`
fi

COUNT_CLOUDFLARE=0
if [[ -n $CF_API_KEY && -n $CF_API_EMAIL && -n $CF_USER_ID ]]; then
    echo
    echo "[*] Attempting to get DNS data via Cloud Flare"
    # Create new zone
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
        -H "X-Auth-Email: $CF_API_EMAIL" \
        -H "X-Auth-Key: $CF_API_KEY" \
        -H "Content-Type: application/json" \
        --data '{
            "account": {
                "id": "'$CF_USER_ID'"
            },
            "name": "'$DOMAIN'",
            "jump_start":true
        }' \
        > cloudflare-zone.tmp
    CF_ZONE_ID=`cat cloudflare-zone.tmp | jq '.result.id' | sed 's/"//g'`

    if [[ "$CF_ZONE_ID" == "null" ]];
    then
        CF_ERROR_MESSAGE=`cat cloudflare-zone.tmp | jq '.errors[].message' | sed 's/"//g'`
        echo "  [-] Error: $CF_ERROR_MESSAGE"
    else
        echo "  [+] Zone successully added"

        # Fetch dns records
        echo "  [*] Fetching DNS records"
        curl -s "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
            -H "X-Auth-Email: $CF_API_EMAIL" \
            -H "X-Auth-Key: $CF_API_KEY" \
            -H "Content-Type: application/json" \
            > cloudflare-dns.tmp
        cat cloudflare-dns.tmp \
            | python -m json.tool \
            | grep '"name":' \
            | awk '{print $2}' \
            | sed 's/"//g' \
            | sed 's/,$//' \
            | sort -u \
            > hosts-cloudflare.tmp
        COUNT_CLOUDFLARE=`cat hosts-cloudflare.tmp | wc -l`

        # Delete zone and temporary file file
        echo "  [*] Cleaning up"
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID" \
            -H "X-Auth-Email: $CF_API_EMAIL" \
            -H "X-Auth-Key: $CF_API_KEY" \
            -H "Content-Type: application/json" > /dev/null
    fi
fi

echo
echo "[*] Searching Cert Spotter"
curl -s https://certspotter.com/api/v0/certs?domain=$DOMAIN \
    | jq '.[].dns_names[]' \
    | sed 's/\"//g' \
    | sed 's/\*\.//g' \
    | sort -u \
    > hosts-certspotter.tmp
COUNT_CERTSPOTTER=`cat hosts-certspotter.tmp | wc -l`

echo "[*] Searching crt.sh"
curl -s "https://crt.sh/?q=%.$DOMAIN&output=json" \
    | jq '.[].name_value' \
    | sed 's/\"//g' \
    | sed 's/\*\.//g' \
    | sort -u \
    > hosts-crtsh.tmp
COUNT_CRTSH=`cat hosts-crtsh.tmp | wc -l`

echo '[*] Searching Buffer Over'
curl -s "https://dns.bufferover.run/dns?q=.$DOMAIN" \
    | jq '.FDNS_A[]' \
    | sed 's/"//g' \
    | cut -d',' -f2 \
    | sort -u \
    > hosts-bufferover.tmp
COUNT_BUFFEROVER=`cat hosts-bufferover.tmp | wc -l`

echo '[*] Searching Threat Crowd'
curl -s "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$DOMAIN" \
    | jq '.subdomains[]' \
    | sed 's/"//g' \
    | sort -u \
    > hosts-threatcrowd.tmp
COUNT_THREATCROWD=`cat hosts-threatcrowd.tmp | wc -l`

if [[ -n $VT_API_KEY ]];
then
    echo "[*] Searching Virus Total"
    curl -s "https://www.virustotal.com/vtapi/v2/domain/report?apikey=$VT_API_KEY&domain=$DOMAIN" \
        | jq '.subdomains[]' \
        | sed 's/"//g' \
        | sed 's/*\.//' \
        | sort -u \
        > hosts-vt.tmp
    COUNT_VT=`cat hosts-vt.tmp | wc -l`
fi

echo "[*] Merging all results and removing duplicates"
cat hosts-*.tmp \
    | sed '/^*./d' \
    | sort -u \
    > hosts-merged.txt
COUNT_UNIQUE=`cat hosts-merged.txt | wc -l`

if [[ -f hosts-all.txt ]]; then
    grep -Fxvf hosts-all.txt hosts-merged.txt > hosts-new.txt
    COUNT_NEW=`cat hosts-new.txt | wc -l`
    cat hosts-all.txt hosts-merged.txt | sort -u > hosts-all.tmp
    mv hosts-all.{tmp,txt}
    echo "[*] Found $COUNT_NEW new hosts"
    if [[ "$COUNT_NEW" -gt "0" ]]; then
        cat hosts-new.txt
    else
        rm -f hosts-new.txt
    fi
else
    cp hosts-{merged,all}.txt
    COUNT_NEW=`cat hosts-all.txt | wc -l`
fi

echo
echo "[*] Running massdns"
massdns -r $RESOLVERS -q -t A -o S -w massdns.out hosts-merged.txt
cat massdns.out | awk '{print $1}' | sed 's/\.$//' | sort -u > hosts-online.txt
COUNT_MASSDNS=`cat hosts-online.txt | wc -l`

echo "[*] Testing for possible subdomain takeover"
takeover -l hosts-online.txt --set-output takeover.out

TIME_END=`date +"%Y-%m-%d %H:%M:%S"`
TIMER_END=`date +"%s"`
TIMER_ELAPSED=$(($TIMER_END - $TIMER_START))

echo
echo "[*] Process ended @ $TIME_END"
echo "  Duration: $TIMER_ELAPSED seconds"
echo
echo "[*] Results for $DOMAIN"
echo "  Online       : $COUNT_MASSDNS"
echo "  Unique hosts : $COUNT_UNIQUE"
echo "  New hosts    : $COUNT_NEW"
echo
echo "  Amass        : $COUNT_AMASS"
echo "  Buffer Over  : $COUNT_BUFFEROVER"
echo "  Cert Spotter : $COUNT_CERTSPOTTER"
echo "  CloudFlare   : $COUNT_CLOUDFLARE"
echo "  Crt.sh       : $COUNT_CRTSH"
echo "  KnockPY      : $COUNT_KNOCKPY"
echo "  Threat Crowd : $COUNT_THREATCROWD"
echo "  Virus Total  : $COUNT_VT"

# Cleaning up temporary files
rm -Rf amass_output/ hosts-*.tmp cloudflare-*.tmp *.out
