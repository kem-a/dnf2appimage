#!/bin/bash

# input file
file="geary.spec"
EXCLUDE="meson|vala|valadoc|make|cmake|gcc-c++"
REQUIREMENTS=""

# loop through each line in the file
while IFS= read -r line; do
  # check if the line contains "BuildRequires"
  if [[ $line =~ ^(BuildRequires|Requires|Recommends):.* ]]; then
    # check if the line contains "()"
    if [[ "$line" == *"("* ]]; then
        # extract the REQUIREMENTS between the parentheses
        text=$(echo $line | sed 's/.*(\([^)]*\)).*/\1/')
    else
        # extract the REQUIREMENTS after the colon
        text=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    fi
    # check if REQUIREMENTS is not empty and not in EXCLUDE list
    if [[ ! -z "$text" && ! "$EXCLUDE" =~ $text ]]; then
        if ! rpm -qa | grep -q "$text"; then
            echo "Testing... $text"
            REQUIREMENTS="$REQUIREMENTS ${text#*=}"
        fi
            output+=" $text"
    fi
  fi
done < "$file"

echo $REQUIREMENTS
echo "----"
echo $output
