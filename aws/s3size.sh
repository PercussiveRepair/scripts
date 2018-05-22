#!/bin/bash
echo -n "running"
for profile in $(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default' | tr -d '[]' | sort); do 
  for bucket in $(aws --profile ${profile} s3 ls |cut -d " " -f 3); do
    for region in $(aws ec2 describe-regions --output text | cut -f 3); do
      now=$(date +%s)
      size=$(aws --profile ${profile} cloudwatch get-metric-statistics --namespace AWS/S3 --start-time "$(echo "$now - 259200" | bc)" --end-time "$(echo "$now - 172800" | bc)" --period 86400 --region ${region} --statistics Average  --metric-name BucketSizeBytes --dimensions Name=BucketName,Value="$bucket" Name=StorageType,Value=StandardStorage \
      | jq -r '.Datapoints[].Average')
      if [ ! -z $size ]; then
        echo "$profile,$bucket,$region,$size" >> buckets.csv
      fi
      echo -n "."
    done
  done
done