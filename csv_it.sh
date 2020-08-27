#!/usr/bin/env bash

# converts output from cli tools such as
# ./ejbcaClientToolBox.sh EjbcaWsRaCli finduser 
# to csv format for easier viewing

set -euxo pipefail

printf 'As,many,csv,headers,as,needed'

declare -a out
EOF=false
IFS=$':'

if [ -p /dev/stdin ]; then
    until $EOF; do
      read -r skip val || EOF=true
      if [ ! -z "$val" ]
      then
        out+=("${val//[[:space:]]/}")
      else
        tmp="${out[@]}"
        tmp2="${tmp//,/}"
        printf '%s\n' "${tmp2// /,}"
        out=()
      fi
    done
else
    file=${1-default}

    if [ $file = "default" ]; then
      echo "usage: $0 file_to_convert"
    fi

    until $EOF; do
      read -r skip val || EOF=true
      if [ ! -z "$val" ]
      then
        out+=("${val//[[:space:]]/}")
      else
        tmp="${out[@]}"
        tmp2="${tmp//,/}"
        printf '%s\n' "${tmp2// /,}"
        out=()
      fi
    done < $file
fi
