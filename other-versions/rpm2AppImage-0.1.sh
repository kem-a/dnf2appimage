#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
  exit 1
fi

# Set the file path
FILEPATH="$1"

# Initialize variables
REQUIREMENTS=""
RECOMMENDATIONS=""

# Read the file line by line
while read line; do

  # Check if the line starts with "Requires"
  if [[ $line == Requires* ]]; then
    # Extract the value after "Requires", delimit by colon, trim, and keep the first value
    REQUIREMENT=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    # Run rpm -qa | grep with the requirement without the prefix
    if ! rpm -qa | grep -q "$REQUIREMENT"; then
      REQUIREMENTS="$REQUIREMENTS ${REQUIREMENT#*=}"
    fi
  fi

  # Check if the line starts with "Recommends"
  if [[ $line == Recommends* ]]; then
    # Extract the value after "Recommends", delimit by colon, trim, and keep the first value
    RECOMMENDATION=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    # Run rpm -qa | grep with the recommendation without the prefix
    if ! rpm -qa | grep -q "$RECOMMENDATION"; then
      RECOMMENDATIONS="$RECOMMENDATIONS ${RECOMMENDATION#*=}"
    fi
  fi

done < "$FILEPATH"

# Print the combined output
OUTPUT=""
if [ -n "$REQUIREMENTS" ]; then
  OUTPUT="$REQUIREMENTS"
fi
if [ -n "$RECOMMENDATIONS" ]; then
  if [ -n "$OUTPUT" ]; then
    OUTPUT="$OUTPUT "
  fi
  OUTPUT="$OUTPUT$RECOMMENDATIONS"
fi

if [ -n "$OUTPUT" ]; then
  MISSING_PACKAGES=""
  for PKG in $OUTPUT; do
    if ! toolbox run dnf list installed | grep -q "$PKG"; then
      toolbox run dnf download "$PKG"
      MISSING_PACKAGES="$MISSING_PACKAGES $PKG"
    fi
  done
  if [ -n "$MISSING_PACKAGES" ]; then
    echo "Packages downloaded: $MISSING_PACKAGES"
  fi
fi
