#!/usr/bin/env bash

# Script to create and then parse credentials reports from AWS IAM
# uses mac-isms for date command

if [[ $1 == help ]]; then
  echo "Usage:"
  echo "credsreport.sh help - this"
  echo "credsreport.sh file - csv file friendly output"
  echo "credsreport.sh - cli highlighted output"
  exit 0
fi

#dates
olderthanninety() {
  ninetydaysago=$(date -j -v-90d +"%s")
  if [[ $1 == 20* ]]; then
    lastdate=$(date -j -f "%Y-%m-%dT%T+00:00" "$1" +"%s")
    if [[ "$ninetydaysago" -gt "$lastdate" ]]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# list accounts
#accounts=$(grep -oE '\[aws-.*?\]' ~/.aws/credentials | grep -Ev 'aws-dmz-mfa' | tr -d '[]')
accounts="aws-hipaa"
# Call report generation
for account in $accounts; do
  aws --profile=${account} iam generate-credential-report >/dev/null
  if [[ ! $1 == "file" ]]; then
    echo -e "${account} report requested"
  fi
done

#colour output
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREY='\033[0;30m'
NC='\033[0m'

# set column headers
if [[ $1 == "file" ]]; then
  echo "account,user,arn,user_creation_time,password_enabled,password_last_used,pass_old,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,key1_old,access_key_2_active,access_key_2_last_rotated,access_key_2_last_used_date, key2_old"
else
  echo "account,user,arn,user_creation_time,password_enabled,password_last_used,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_2_active,access_key_2_last_rotated,access_key_2_last_used_date"
fi

# retrieve report and parse for required fields
for account in $accounts; do
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


    #if [[ $line =~ ^[a-z]+\.[a-z]+\,.* ]]; then
    if [[ $line != user* ]] && [[ $line != \<root_account\>* ]]; then

      # reassemble line
      echo -n "$account, ${user_array[0]}, ${user_array[1]}, ${user_array[2]}, "

      if [[ $1 == "file" ]]; then

        if olderthanninety "${user_array[4]}"; then
          echo -n "${user_array[3]}, ${user_array[4]}, true, "
        else
          echo -n "${user_array[3]}, ${user_array[4]}, false, "
        fi

        if olderthanninety "${user_array[10]}" && [[ ${user_array[8]} == "true" ]]; then
          echo -n "${user_array[8]}, ${user_array[9]}, ${user_array[10]}, true, "
        else
          echo -n "${user_array[8]}, ${user_array[9]}, ${user_array[10]}, false, "
        fi

        if olderthanninety "${user_array[15]}" && [[ ${user_array[13]} == "true" ]]; then
          echo -n "${user_array[13]}, ${user_array[14]}, ${user_array[15]}, true"
        else
          echo -n "${user_array[13]}, ${user_array[14]}, ${user_array[15]}, false"
        fi

        echo ""

      else

        #check for password age
        if olderthanninety "${user_array[4]}"; then
          echo -en "${YELLOW}${user_array[3]}, ${user_array[4]}, ${NC}"
        else
          echo -n "${user_array[3]}, ${user_array[4]}, "
        fi

        #check for first access key existence and age
        if olderthanninety "${user_array[10]}" && [[ ${user_array[8]} == "true" ]]; then
          echo -en "${RED}${user_array[8]}, ${user_array[9]}, ${user_array[10]}, ${NC}"
        elif [[ ${user_array[8]} == "false" ]]; then
          echo -en "${GREY}${user_array[8]}, ${user_array[9]}, ${user_array[10]}, ${NC}"
        else
          echo -n "${user_array[8]}, ${user_array[9]}, ${user_array[10]}, "
        fi

        #check for second access key existence and age
        if olderthanninety "${user_array[15]}" && [[ ${user_array[13]} == "true" ]]; then
          echo -en "${RED}${user_array[13]}, ${user_array[14]}, ${user_array[15]}${NC}"
        elif [[ ${user_array[13]} == "false" ]]; then
          echo -en "${GREY}${user_array[13]}, ${user_array[14]}, ${user_array[15]}${NC}"
        else
          echo -n "${user_array[13]}, ${user_array[14]}, ${user_array[15]}"
        fi

        echo ""
      fi
    fi
  done
done
