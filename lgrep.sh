#!/usr/bin/bash
CONFIG_FILE=lgrep_config.cfg

#ensure lgrep will work even through $PATH or different location
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

#check readability of main config file
if ! test -r "$DIR/$CONFIG_FILE" -a -f "$DIR/$CONFIG_FILE";then
    echo Lgrep config file: \"$CONFIG_FILE\" not readable or does not exist.
    exit 1
fi

source "$DIR/$CONFIG_FILE"

#check if required directories exist and have read permission granted
CONFIG_DIRS=("$TO_FILTER_DIR" "$CONF_DIR" "$AVAILABLE_CONF_DIR" "$FILTERED_DIR" "$TMP_DIR")
for dir in "${CONFIG_DIRS[@]}"; do
    if ! test -d "$dir" -a -r "$dir";then
        echo Defined in config file \"$dir\" should exist and be readable.
        exit 2
    fi
done

#check if required directories are writable
CONFIG_DIRS=("$CONF_DIR" "$AVAILABLE_CONF_DIR" "$FILTERED_DIR" "$TMP_DIR")
for dir in "${CONFIG_DIRS[@]}"; do
    if ! test -w "$dir";then
        echo Defined in config file \"$dir\" is not writable.
        exit 3
    fi
done

function initialize() {
    #check if $TO_FILTER_DIR has read permission recursively
    if test -z "`find $TO_FILTER_DIR -type d -exec ls {} \; 1>/dev/null`" -o -z "`find $TO_FILTER_DIR -type f -exec cat {} \; 1>/dev/null`";then
        echo
        echo You do not have required permission to read recursively from $TO_FILTER_DIR
        exit 4
    fi
}

#----------------------------------------------------------------- Let's go

if [ "$#" == "0" ]; then

    echo "Let's lgrep all of you."                                      #TODO: core of lgrep - lgrep them all
    echo $CONF_DIR
    exit
else
    while getopts ":if:e:d:h" optname
    do
        case "$optname" in
            "h")
                echo " You can start lgrep using such parameters:"
                echo "   <no parameters> - will lgrep all enabled files"
                echo "   -h              - show this help"
                echo "   -i              - initialize config files for files to lgrep"
                echo "   -e <file path>  - enable config in filepath"
                echo "   -d <file path>  - disable config in filepath"
            ;;
            "i")
                #TODO: function: copy directory tree from TO_FILTER_DIR to AVAILABLE_CONF_DIR and so on
                echo "Do you want to initialize lgrep config files?"
                select yn in "Yes" "No"; do
                    case $yn in
                        Yes ) initialize ; break;;
                        No ) exit 0;;
                    esac
                done
            ;;
            "f")
                echo "Option $optname with relative filepath: $OPTARG"
            ;;
            "e")
                echo "Lgrep config $OPTARG enabled."                    #TODO: copy file from AVAILABLE_CONF_DIR to CONFIG_DIR and mkdirs if none present
            ;;
            "d")
                echo "Lgrep config $OPTARG disabled."                   #TODO: remove config file from CONFIG_DIR and rmdir if last one
            ;;
            "?")
                echo "Usage:"
                echo "$0 [-i | -f <filepath> | -e <filepath> | -d <filepath>]"
            ;;
            ":")
                echo "Option $OPTARG requires parameter. Check $0 -h for details."
            ;;
            *)
                # Should not occur
                echo "Unknown error while processing options"
            ;;
        esac
        #echo "OPTIND is now $OPTIND" #debug
    done
fi



# function p_show() {
#     local p="$@" &&
#         for p; do [[ ${!p} ]] &&
#             echo -e ${!p//:/\\n};
#     done
# }

# while read -r
#     do [[ $REPLY = `echo $LOG_DIR` ]] && echo "$REPLY"
# done < file


cd $LOG_DIR || {
    echo "Cannot change to necessary directory." >&2
    exit $E_XCD;
}

# (cd /var/log && find .) > /tmp/drzewo_varloga
# (cd $CONFIG_DIR && find .) > /tmp/drzewo_configdira
# for filename in drzewo_configdira { grep /tmp/drzewo_varloga } # tu będą te same

exit 0
