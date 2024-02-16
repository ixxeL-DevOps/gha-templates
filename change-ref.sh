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

if ! command -v yq &> /dev/null; then
    echo -e "${RED}[ ERROR ] > yq not installed${BLANK}" >&2
    exit 1
fi

if [ -z "$PROJECT_REF" ]; then
    echo -e "${RED}[ ERROR ] > No parameter provided for PROJECT_REF${BLANK}" >&2
    exit 1
fi

for file in $DIR_WORKFLOWS
do
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}[ WARNING ] > The file $file does not exist${BLANK}"
        continue
    fi
    for line in $(yq e '.jobs[].steps[].uses | select(.) | select(.=="'"$ACTIONS_ORGA"'*@*")' $file)
    # | select(.) to avoid null
    do
        if [ $? -ne 0 ]; then
          echo -e "${RED}[ ERROR ] > File $file for line $line failed${BLANK}"
          continue
        fi
        ACTION=$(echo "$line" | awk -F@ '{print $1}' | awk -F/ '{print $NF}')
        REF=$(echo "$line" | awk -F@ '{print $NF}')
        if [[ "$REF" != "$PROJECT_REF" ]]; then
            echo -e "${CYAN}[ INFO ] > File ${YELLOW}$file${CYAN} and ${BLUE}action${CYAN} ${PURPLE}$ACTION${CYAN} is currently set to ref ${RED}$REF${CYAN} and will be changed to ${GREEN}$PROJECT_REF${BLANK}"
            yq e -i '.jobs[].steps[] |= select(.uses).uses |= select(.=="'"$line"'") |= sub("'"@$REF"'", "'"@$PROJECT_REF"'")' $file
            if [ $? -ne 0 ]; then
              echo -e "${RED}[ ERROR ] > Failed to update action file $file on line $line${BLANK}" >&2
            fi
            # "|= select(.uses).uses" prevent insertiopn of element not wanted like "null"
        else
            echo -e "${PURPLE}[ CANCEL ] > File ${YELLOW}$file${PURPLE} and ${BLUE}action${CYAN} ${RED}$ACTION${PURPLE} is already set to ${RED}$PROJECT_REF${PURPLE} ref${BLANK}"
        fi
    done

    for key in $(yq e '.jobs | select(.) | keys' $file)
    do
        if [ $? -ne 0 ]; then
          echo -e "${RED}[ ERROR ] > File $file for key $key failed${BLANK}"
          continue
        fi
        for line in $(yq e '.jobs."'"$key"'".uses | select(.) | select(.=="'"$ACTIONS_ORGA"'*@*")' $file)
        do
            if [ $? -ne 0 ]; then
              echo -e "${RED}[ ERROR ] > File $file for line $line and key $key failed${BLANK}"
              continue
            fi
            ACTION=$(echo "$line" | awk -F@ '{print $1}' | awk -F/ '{print $NF}')
            REF=$(echo "$line" | awk -F@ '{print $NF}')
            if [[ "$REF" != "$PROJECT_REF" ]]; then
                echo -e "${CYAN}[ INFO ] > File ${YELLOW}$file${CYAN} and ${BLUE}workflow${CYAN} ${PURPLE}$ACTION${CYAN} is currently set to ref ${RED}$REF${CYAN} and will be changed to ${GREEN}$PROJECT_REF${BLANK}"
                yq e -i '.jobs."'"$key"'" |= select(.uses).uses |= select(.=="'"$line"'") |= sub("'"@$REF"'", "'"@$PROJECT_REF"'")' $file
                if [ $? -ne 0 ]; then
                  echo -e "${RED}[ ERROR ] > Failed to update workflow file $file on line $line${BLANK}" >&2
                fi
            else
                echo -e "${PURPLE}[ CANCEL ] > File ${YELLOW}$file${PURPLE} and ${BLUE}workflow${CYAN} ${RED}$ACTION${PURPLE} is already set to ${RED}$PROJECT_REF${PURPLE} ref${BLANK}"
            fi
        done
    done
done
