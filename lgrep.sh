#!/usr/bin/bash
#change this value if you want to change localization of lgrep main config file
CONFIG_FILE=lgrep_config.cfg

#fight with whitespaces in files and directories names
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#ensure lgrep will work even through $PATH or different location
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

#check readability of main config file
if ! test -r "$DIR/$CONFIG_FILE" -a -f "$DIR/$CONFIG_FILE";then
    echo Lgrep config file: \"$CONFIG_FILE\" not readable or does not exist.
    exit 1
fi

#including config file
source "$DIR/$CONFIG_FILE"

#check if required directories exist and have read permission granted
CONFIG_DIRS=("$TO_FILTER_DIR" "$CONF_DIR" "$AVAILABLE_CONF_DIR" "$FILTERED_DIR" "$TMP_DIR")
for idir in "${CONFIG_DIRS[@]}"; do
    if ! test -d "$idir" -a -r "$idir";then
        echo Defined in config file $idir should exist and be readable.
        exit 2
    fi
done

#check if required directories are writable
CONFIG_DIRS=("$CONF_DIR" "$AVAILABLE_CONF_DIR" "$FILTERED_DIR" "$TMP_DIR")
for idir in "${CONFIG_DIRS[@]}"; do
    if ! test -w "$idir";then
        echo Defined in config file \"$idir\" is not writable.
        exit 3
    fi
done

function initialize() {
    #check if $TO_FILTER_DIR has read permission recursively
    if ! test -z "`find $TO_FILTER_DIR -type d -exec ls {} \; 1>/dev/null`" -a -z "`find $TO_FILTER_DIR -type f -exec cat {} \; 1>/dev/null`";then
        echo
        echo You do not have required permission to read recursively from $TO_FILTER_DIR
        echo You have to add read permission recursively or add your configs manually
        exit 4
    fi

    #create directories
    cd $TO_FILTER_DIR || {
        echo "Cannot change to $TO_FILTER_DIR directory." >&2
        exit 5;
    }

    find . -type d > $TMP_DIR/lgrep-to_filter_tree

    to_filter_tree_dirs=()
    while read line; do
        to_filter_tree_dirs+=("$line")
    done < $TMP_DIR/lgrep-to_filter_tree

    for dir in "${to_filter_tree_dirs[@]:1}"; do
        mkdir $AVAILABLE_CONF_DIR/${dir:2}
    done

    #create files
    find . -type f > $TMP_DIR/lgrep-to_filter_tree

    to_filter_tree_files=()
    while read line; do
        to_filter_tree_files+=("$line")
    done < $TMP_DIR/lgrep-to_filter_tree

    read -d '' file_content <<"EOF"
#All lines have to start with a sign "+", "-" or "#"
#    "#" sign tells lgrep to ignore the line
#    "+" sign means that the keyword afterward should be used to filter the log
#        when you use multiple "+" directives they are treated as merged with logic OR
#        for example you can write:
#            +warn
#            +security
#        And this will search whole file for lines that include "warn" OR "security" keywords
#    "-" sign informs lgrep to ignore the line including the keyword afterwards
#        for example you can write:
#            -info
#            -debug
#        And this will ignore all lines that include "info" OR "debug" keywords
EOF

    for file in "${to_filter_tree_files[@]}"; do
        echo "$file_content" > $AVAILABLE_CONF_DIR/${file:2}.conf
    done
}

 #TODO: copy file from AVAILABLE_CONF_DIR to CONFIG_DIR and mkdirs if none present
function enable() {
    ls $AVAILABLE_CONF_DIR/$1 2>/dev/null 1>/dev/null || {
        echo "Cannot find $1 in $AVAILABLE_CONF_DIR"
        exit 8
    }
    SAVEIFS=$IFS
    IFS='/'
    dirs=()
    for dir in $1; do
        dirs+=("$dir")
    done
    IFS=$SAVEIFS

    cd $CONF_DIR || {
        echo "Cannot change to $CONF_DIR directory." >&2
        exit 5;
    }

    for dir in "${dirs[@]:0:(${#dirs[@]}-1)}"; do
        mkdir $dir && cd $dir || {
            echo "Cannot create or change to $dir directory." >&2
            exit 5;
        }
    done
    cp $AVAILABLE_CONF_DIR/$1 ${dirs[(${#dirs[@]}-1)]} || {
        echo "Problems with cp"
        exit 7
    }
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
                        Yes )
                            if (initialize); then
                                echo initializing passed
                            else
                                echo initializing failed
                            fi
                            break;;
                        No )
                            exit 0;;
                    esac
                done
            ;;
            "f")
                echo "Option $optname with relative filepath: $OPTARG"
            ;;
            "e")
                if (enable $OPTARG); then
                    echo "Lgrep config $OPTARG enabled."
                else
                    echo Enabling failed
                fi
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
