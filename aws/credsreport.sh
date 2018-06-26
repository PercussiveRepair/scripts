#!/bin/bash

# Script to create and then parse credentials reports from AWS IAM
# uses mac-isms for date command

#dates
ninetydaysago=$(date -j -v-90d +"%s")

# Call report generation
for account in $(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default' | tr -d '[]' | sort); do

  echo -e "\n${account}"
  aws --profile=${account} iam generate-credential-report
done

#colour output
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# set column headers
echo "account,user,arn,user_creation_time,password_enabled,password_last_used,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_2_active,access_key_2_last_rotated,access_key_2_last_used_date"

# retrieve report and parse for required fields
for account in $(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default' | tr -d '[]' | sort); do
  creds=$(aws --profile=${account} iam get-credential-report | jq -r .Content | base64 --decode)

  printf %s "$creds" | while IFS= read -r line; do

    user_array=(${line//,/ })
    # awsuser=${user_array[0]}
    # awsarn=${user_array[1]}
    # awsusercreated=${user_array[2]}
    # awspassenabled=${user_array[3]}
    # awspassuseddate=${user_array[4]}
    # awskey1enabled=${user_array[8]}
    # awskey1rotateddate=${user_array[9]}
    # awskey1useddate=${user_array[10]}
    # awskey2enabled=${user_array[13]}
    # awskey2rotateddate=${user_array[14]}
    # awskey2useddate=${user_array[15]}


    if [[ $line =~ ^[a-z]+\.[a-z]+\,.* ]]; then
      # change dates to unix epoch
      if [[ ${user_array[4]} == 20* ]]; then
        passlastut=$(date -j -f "%Y-%m-%dT%T+00:00" "${user_array[4]}" +"%s")
      elif [[ ${user_array[10]} == 20* ]]; then
        key1lastut=$(date -j -f "%Y-%m-%dT%T+00:00" "${user_array[10]}" +"%s")
      elif [[ ${user_array[15]} == 20* ]]; then
        key2lastut=$(date -j -f "%Y-%m-%dT%T+00:00" "${user_array[15]}" +"%s")
      fi

      # reassemble line
      echo -n "$account, ${user_array[0]}, ${user_array[1]}, ${user_array[2]}, "
      
      #check for password age
      if [[ $ninetydaysago -gt $passlastut ]]; then
        echo -en "${YELLOW}"
        echo -n "${user_array[3]}, ${user_array[4]}, "
        echo -en "${NC}"
      else
        echo -n "${user_array[3]}, ${user_array[4]}, "
      fi
      
      #check for first access key existence and age
      if [[ $ninetydaysago -gt $key1lastut ]] && [[ ${user_array[8]} == "true" ]]; then
        echo -en "${RED}"
        echo -n "${user_array[8]}, ${user_array[9]}, ${user_array[10]}, "
        echo -en "${NC}"
      else
        echo -n "${user_array[8]}, ${user_array[9]}, ${user_array[10]}, "
      fi
      
      #check for second access key existence and age
      if [[ $ninetydaysago -gt $key2lastut  ]] && [[ ${user_array[13]} == "true" ]]; then
        echo -en "${RED}"
        echo -n "${user_array[13]}, ${user_array[14]}, ${user_array[15]}"
        echo -en "${NC}"
      else
        echo -n "${user_array[13]}, ${user_array[14]}, ${user_array[15]}"
      fi
      
      echo ""
    fi
  done 
done 

