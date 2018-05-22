#!/bin/bash

# Script to find failed multipart uploads across all accounts & buckets

#colour output
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

for AWSPROFILE in $(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default|awsbillingmaster' | tr -d '[]' | sort)
do
  echo -e "\\n${RED}${AWSPROFILE}${NC}"
  for BUCKET in $(aws --profile ${AWSPROFILE} s3api list-buckets | jq -r .Buckets[].Name)
  do
    PARTCOUNT=$(aws --profile ${AWSPROFILE} s3api list-multipart-uploads --bucket ${BUCKET} | jq -r .Uploads[].Key | wc -l)
    if [ $PARTCOUNT -gt 10 ]; 
    then 
      echo -e "${BLUE}${BUCKET}${NC}"
      echo $PARTCOUNT
      aws --profile ${AWSPROFILE} s3api put-bucket-lifecycle --bucket ${BUCKET} --lifecycle-configuration file://lifecycle.json 
      aws --profile ${AWSPROFILE} s3api get-bucket-lifecycle --bucket ${BUCKET}
    fi
  done
done