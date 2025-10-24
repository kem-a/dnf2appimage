#!/bin/bash

# Example string with %{name} substring
my_string="my-package-%{name}-1.0"

# Remove %{name} from string
modified_string=$(echo "$my_string" | sed 's/%{name}//g')

echo "Original string: $my_string"
echo "Modified string: $modified_string"
