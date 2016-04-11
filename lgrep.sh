#!/usr/bin/bash

#TODO: function to check config file (are files present and writable)

if [ "$#" == "0" ]; then
    echo "Let's lgrep all of you."                                      #TODO: core of lgrep - lgrep them all
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
                echo "   -i <file path>  - disable config in filepath"
            ;;
            "i")
                echo "Initialize lgrep"                                 #TODO: function: copy directory tree from TO_FILTER_DIR to AVAILABLE_CONF_DIR and so on
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
                echo "No argument value for option $OPTARG"
            ;;
            *)
                # Should not occur
                echo "Unknown error while processing options"
            ;;
        esac
        #echo "OPTIND is now $OPTIND" #debug
    done
fi

source lgrep_config.sh

# function p_show() {
#     local p="$@" &&
#         for p; do [[ ${!p} ]] &&
#             echo -e ${!p//:/\\n};
#     done
# }

# while read -r
#     do [[ $REPLY = `echo $LOG_DIR` ]] && echo "$REPLY"
# done < file

#TODO: same in LOG_DIR as in CONFIG_DIR

cd $LOG_DIR || {
   echo "Cannot change to necessary directory." >&2
   exit $E_XCD;
 }

# (cd /var/log && find .) > /tmp/drzewo_varloga
# (cd $CONFIG_DIR && find .) > /tmp/drzewo_configdira
# for filename in drzewo_configdira { grep /tmp/drzewo_varloga } # tu będą te same

exit 0
