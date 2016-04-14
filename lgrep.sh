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

function enable() {
    file="$1.conf"
    ls $AVAILABLE_CONF_DIR/$file 2>/dev/null 1>/dev/null || {
        echo "Cannot find $file in $AVAILABLE_CONF_DIR"
        exit 8
    }
    ls $CONF_DIR/$1 2>/dev/null && {
        echo "$1 is enabled"
        exit 11
    }

    SAVEIFS=$IFS
    IFS='/'

    dirs=()
    for dir in $file; do
        dirs+=("$dir")
    done
    IFS=$SAVEIFS

    cd $CONF_DIR || {
        echo "Cannot change to $CONF_DIR directory." >&2
        exit 5;
    }

    for dir in "${dirs[@]:0:(${#dirs[@]}-1)}"; do
        test -d $dir || mkdir $dir || {
            echo "Cannot create $dir directory." >&2
            exit 5;
        }
        cd $dir || {
            echo "Cannot change to $dir directory." >&2
            exit 5;
        }
    done
    cp $AVAILABLE_CONF_DIR/$file ${dirs[@]: -1} 2>/dev/null || {
        echo "Problems with cp"
        exit 7
    }
}

function disable() {
    file="$1.conf"
    ls $CONF_DIR/$file 2>/dev/null 1>/dev/null || {
        echo "Cannot find $file in $CONF_DIR"
        exit 8
    }
    SAVEIFS=$IFS
    IFS='/'
    dirs=()
    for dir in $file; do
        dirs+=("$dir")
    done
    IFS=$SAVEIFS

    cd $CONF_DIR || {
        echo "Cannot change to $CONF_DIR directory." >&2
        exit 5;
    }
    counter=0
    for dir in "${dirs[@]:0:(${#dirs[@]}-1)}"; do
        cd $dir || {
            echo "Cannot change to $dir directory." >&2
            exit 5;
        }
        counter=$((counter+1))
    done
    rm ${dirs[(${#dirs[@]}-1)]} 2>/dev/null || {
        echo "Problems with rm"
        exit 9
    }
    for i in $(seq 2 $((counter+1))); do
        # echo $((${#dirs[@]}-$i))
        [ "$(ls -A .)" ] && break || cd .. && rm -r ${dirs[$((${#dirs[@]}-$i))]} || {
            echo "Problems with rm dir"
            exit 10
        }
    done
}

#----------------------------------------------------------------- Lgrep core

if [ "$#" == "0" ]; then
    #create directories in FILTERED_DIR comparing to CONF_DIR
    cd $CONF_DIR || {
        echo "Cannot change to $CONF_DIR directory." >&2
        exit 5;
    }

    find . -type d > $TMP_DIR/lgrep-to_filter_tree

    to_filter_tree_dirs=()
    while read line; do
        to_filter_tree_dirs+=("$line")
    done < $TMP_DIR/lgrep-to_filter_tree

    for dir in "${to_filter_tree_dirs[@]:1}"; do
        mkdir $FILTERED_DIR/${dir:2} 2>/dev/null
    done

    #------------------------------ Let's go
    cd $CONF_DIR || {
        echo "Cannot change to $CONF_DIR directory." >&2
        exit 5;
    }
    if test -z "`find . -type f -name "*.conf"`"; then
        echo "No configs found in $CONF_DIR"
    fi
    for file in `find . -type f -name "*.conf"`; do
        added_keywords=()
        removed_keywords=()
        while read line; do
            first=`echo ${line:0:1}`
            if [ "$first" = "+" ]; then
                added_keywords+=("${line:1}")
            elif [ "$first" = "-" ]; then
                removed_keywords+=("${line:1}")
            fi
        done < $file

        remove_request=""
        for removed_keyword in "${removed_keywords[@]}"; do
            remove_request="$remove_request|$removed_keyword"
        done

        add_request=""
        for added_keyword in "${added_keywords[@]}"; do
            add_request="$add_request|$added_keyword"
        done

        if test -z "$remove_request" -a -z "$add_request"; then
            echo "None keywords specified to filter file ${file:1:-5}"
            continue
        elif test -z "$remove_request"; then
            egrep "${add_request:1}" $TO_FILTER_DIR${file:1:-5} > $FILTERED_DIR${file:1:-5}
        elif test -z "$add_request"; then
            egrep -v "${removed_keywords:1}" $TO_FILTER_DIR${file:1:-5} > $FILTERED_DIR${file:1:-5}
        else
            egrep -v "${removed_keywords:1}" $TO_FILTER_DIR${file:1:-5} | egrep "${add_request:1}" > $FILTERED_DIR${file:1:-5}
        fi
        echo ${file:2:-5} lgrepped
    done
    echo
    echo Check $FILTERED_DIR for filtered files
    exit
else
    while getopts ":ie:d:h" optname   # ------------------------------------------ Invoke parameters handling
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
            "e")
                if (enable $OPTARG); then
                    echo "Lgrep config $OPTARG enabled."
                else
                    echo Enabling failed
                fi
            ;;
            "d")
                if (disable $OPTARG); then
                    echo "Lgrep config $OPTARG disabled."
                else
                    echo Disabling failed
                fi
            ;;
            "?")
                echo "Usage:"
                echo "$0 [-i | -e <filepath> | -d <filepath>]"
            ;;
            ":")
                echo "Option $OPTARG requires parameter. Check $0 -h for details."
            ;;
            *)
                # Should not occur
                echo "Unknown error while processing options"
            ;;
        esac
    done
fi

exit 0
