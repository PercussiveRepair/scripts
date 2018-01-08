#!/bin/sh

# obtains all the instances in all the regions in all the accounts that have old (short) ids

profiles=$(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default|awsbillingmaster' | tr -d '[]' | sort)
regions=$(aws ec2 describe-regions --output text | cut -f 3)

echo "account, region, instanceid"
for profile in $profiles; do 
  for region in $regions; do
    ids=$(aws --region=$region --profile=$profile ec2 describe-instances | jq -r '.Reservations[].Instances[].InstanceId')
    for id in $ids; do
      LEN=$(echo ${#id})
      if [ $LEN -lt 11 ]; then
        echo "$profile, $region, $id"
      fi
    done
  done
done
