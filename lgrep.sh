#!/usr/bin/bash

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


exit 0
