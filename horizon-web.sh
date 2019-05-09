#!/bin/bash

echo '
██╗  ██╗ ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗      ██╗    ██╗███████╗██████╗
██║  ██║██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║      ██║    ██║██╔════╝██╔══██╗
███████║██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗██║ █╗ ██║█████╗  ██████╔╝
██╔══██║██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║╚════╝██║███╗██║██╔══╝  ██╔══██╗
██║  ██║╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║      ╚███╔███╔╝███████╗██████╔╝
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝       ╚══╝╚══╝ ╚══════╝╚═════╝

                                                         Web Application Reconniassance
                                                                             by noobhax
'

BASE_PATH=`pwd`
SELF_PATH=$(dirname "$(readlink -f "$0")")
ERROR=0

if [[ -z "`which wafw00f 2>/dev/null`" ]]; then
    echo '[!!] Error: wafw00f is required - https://github.com/EnableSecurity/wafw00f'
    ERROR=1
fi

if [[ -z "`which wappalyzer 2>/dev/null`" ]]; then
    echo '[!!] Error: wappalyzer is required - https://www.npmjs.com/package/wappalyzer'
    ERROR=1
fi

if [[ -z "`which dirsearch 2>/dev/null`" ]]; then
    echo '[!!] Error: dirsearch is required - https://github.com/maurosoria/dirsearch'
    ERROR=1
fi

if [[ -z "`which linkfinder 2>/dev/null`" ]]; then
    echo '[!!] Error: linkfinder is required - https://github.com/GerbenJavado/LinkFinder'
    ERROR=1
fi

if [[ "$ERROR" -gt "0" ]]; then
    exit
fi

while getopts ":d:e:o:r:t:u:w:x:h" opt;
do
    case "${opt}" in
        d) DELAY=$OPTARG ;;
        e) EXTENSIONS=$OPTARG ;;
        h) DISPLAY_HELP=1 ;;
        o) SAVE_PATH=$OPTARG ;;
        r) REGEX=$OPTARG ;;
        t) THREADS=$OPTARG ;;
        u) DOMAIN=$OPTARG ;;
        w) WORDLIST=$OPTARG ;;
        x) EXCLUDE_CODES=$OPTARG ;;
    esac
done

if [[ -n $DISPLAY_HELP ]];
then
    echo "
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
    "
    exit
fi

# Domain is a required option. Throw an error if one was not provided
if [[ -z $DOMAIN ]]; then
    echo '[!!] Error: Domain cannot be empty. Use -h for more info'
    exit
fi

# Set default delay in seconds if none was provided
# Used by: dirsearch
if [[ -z $DELAY ]]; then
    DELAY=0
fi

# Set default extension list if none was provided.
# Used by: dirsearch
if [[ -z $EXTENSIONS ]]; then
    EXTENSIONS=,
fi

# Set default output path if one was not provided
if [[ -z $SAVE_PATH ]]; then
    SAVE_PATH=$BASE_PATH/horizon_web
fi

# If path does not exist create one, otherwise ask if the user wants to delete
# it first. Default choice: no
if [[ ! -d $SAVE_PATH ]]; then
    mkdir -p $SAVE_PATH
else
    echo -n '[?] Output directory already exists. Do you wish to delete it? [y/N] '
    read choice
    if [[ -z $choice ]]; then choice='no'; fi
    case $choice in
        y*|Y*)
            rm -Rf $SAVE_PATH
            mkdir -p $SAVE_PATH
            ;;
        n*|N*) ;;
        *)
            echo '[!!] Error: Invalid choice. Aborting...'
            exit
            ;;
    esac
fi
SAVE_PATH=`realpath $SAVE_PATH`
cd $SAVE_PATH

# Set default regular expression for LinkFinder if one was not provided
# Used by: LinkFinder
if [[ -z $REGEX ]]; then
    REGEX=.
fi

# Set default threads count if one was not provided
# Used by: dirsearch
if [[ -z $THREADS ]]; then
    THREADS=10
fi

# Set default wordlist if one was not provided
# Used by: dirsearch
if [[ -z $WORDLIST ]]; then
    WORDLIST=$SELF_PATH/lists/web-wordlist.txt
else
    if [[ ! -f $WORDLIST ]]; then
        echo "[!!] Error: Unable to open wordlist. File does not exist"
        exit
    fi
fi
COUNT_WORDLIST=`cat $WORDLIST | wc -l`

# Set default exclude codes if none was provided
# Used by: dirsearch
if [[ -z $EXCLUDE_CODES ]]; then
    EXCLUDE_CODES=500,503
fi


TIME_START=`date +"%Y-%m-%d %H:%M:%S"`
TIMER_START=`date +"%s"`

echo "[*] Process started @ $TIME_START"
echo "  Target        : $DOMAIN"
echo "  Exclude codes : $EXCLUDE_CODES"
echo "  Extensions    : $EXTENSIONS"
echo "  Output path   : $SAVE_PATH"
echo "  Threads       : $THREADS"
echo "  RegEx pattern : $REGEX"
echo "  Wordlist      : $WORDLIST (words: $COUNT_WORDLIST)"
echo "  Delay         : $DELAY"

echo
echo "[*] Checking if the website is behind a WAF"
wafw00f --findall $DOMAIN \
    | grep behind \
    | sed -E 's/The site .+ behind a?\s?//;s/WAF\.$//;s/^/  /'

echo
echo "[*] Checking technologies via wappalyzer"
wappalyzer $DOMAIN \
    | jq '.applications[].name' \
    | sed 's/"//g;s/^/  /'

echo
echo "[*] Checking for existence of robots.txt"
rm -f robots.txt # Removing any old robots.txt file to avoid confusion
wget -q -O robots.txt $DOMAIN/robots.txt
if [[ "`cat robots.txt | wc -l`" -gt "0" ]]; then
    cat robots.txt | sed 's/^/  /'
    echo
else
    rm -f robots.txt
    echo "  No robots.txt file present"
fi

echo
echo "[*] Looking for files and directories"
dirsearch -b -u $DOMAIN -x $EXCLUDE_CODES -t $THREADS -s $DELAY -e $EXTENSIONS --plain-text-report dirsearch.out

DOMAIN_HOST=`echo $DOMAIN | cut -d'/' -f3`
echo
echo "[*] Searching Wayback Machine"
curl -s "http://web.archive.org/cdx/search/cdx?url=$DOMAIN_HOST*&output=plaintext&fl=original&collapse=urlkey" > wayback.out
echo "  Found $(cat wayback.out | wc -l) archived urls"

echo
echo "[*] Identifying JavaScript files"
cat wayback.out \
    | echo -e "$(sed 's/+/ /g;s/%\(..\)/\\x\1/g;')" \
    | cut -d'?' -f1 \
    | grep -E '\.js$' \
    | sort -u \
    > javascript.out
echo "  Found $(cat javascript.out | wc -l) archived JavaScript files"

echo
echo "[*] Looking for endpoints in JavaScript files"
linkfinder -d -i $DOMAIN -r $REGEX -o cli > linkfinder.out
echo "  Found $(cat linkfinder.out | grep -v Running | grep -vE '^$' | sort -u | wc -l) endpoints"

TIME_END=`date +"%Y-%m-%d %H:%M:%S"`
TIMER_END=`date +"%s"`
TIMER_DURATION=$(($TIMER_END - $TIMER_START))

echo
echo "[*] Process ended @ $TIME_END"
echo "  Duration: $TIMER_DURATION seconds"
