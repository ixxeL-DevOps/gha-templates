#!/bin/bash
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
BLANK="\033[0m"

ACTIONS_ORGA=ixxeL-DevOps
DIR_WORKFLOWS="./.github/workflows/*.yaml"
PROJECT_REF=$1

for file in $DIR_WORKFLOWS
do
    for line in $(yq e '.jobs[].steps[].uses | select(.) | select(.=="'"$ACTIONS_ORGA"'*@*")' $file)
    # | select(.) to avoid null
    do
        ACTION=$(echo "$line" | awk -F@ '{print $1}' | awk -F/ '{print $NF}')
        REF=$(echo "$line" | awk -F@ '{print $NF}')
        if [[ "$REF" != "$PROJECT_REF" ]]; then
            echo -e "${CYAN}[ INFO ] > File ${YELLOW}$file${CYAN} and ${BLUE}action${CYAN} ${PURPLE}$ACTION${CYAN} is currently set to ref ${RED}$REF${CYAN} and will be changed to ${GREEN}$PROJECT_REF${BLANK}"
            yq e -i '.jobs[].steps[] |= select(.uses).uses |= select(.=="'"$line"'") |= sub("'"@$REF"'", "'"@$PROJECT_REF"'")' $file
            # "|= select(.uses).uses" prevent insertiopn of element not wanted like "null"
        else
            echo -e "${PURPLE}[ CANCEL ] > File ${YELLOW}$file${PURPLE} and ${BLUE}action${CYAN} ${RED}$ACTION${PURPLE} is already set to ${RED}$PROJECT_REF${PURPLE} ref${BLANK}"
        fi
    done

    for key in $(yq e '.jobs | select(.) | keys' $file)
    do
        for line in $(yq e '.jobs."'"$key"'".uses | select(.) | select(.=="'"$ACTIONS_ORGA"'*@*")' $file)
        do
            ACTION=$(echo "$line" | awk -F@ '{print $1}' | awk -F/ '{print $NF}')
            REF=$(echo "$line" | awk -F@ '{print $NF}')
            if [[ "$REF" != "$PROJECT_REF" ]]; then
                echo -e "${CYAN}[ INFO ] > File ${YELLOW}$file${CYAN} and ${BLUE}workflow${CYAN} ${PURPLE}$ACTION${CYAN} is currently set to ref ${RED}$REF${CYAN} and will be changed to ${GREEN}$PROJECT_REF${BLANK}"
                yq e -i '.jobs."'"$key"'" |= select(.uses).uses |= select(.=="'"$line"'") |= sub("'"@$REF"'", "'"@$PROJECT_REF"'")' $file
            else
                echo -e "${PURPLE}[ CANCEL ] > File ${YELLOW}$file${PURPLE} and ${BLUE}workflow${CYAN} ${RED}$ACTION${PURPLE} is already set to ${RED}$PROJECT_REF${PURPLE} ref${BLANK}"
            fi
        done
    done
done
