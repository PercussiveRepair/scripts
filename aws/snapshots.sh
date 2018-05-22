#!/bin/sh

# gets all snapshots in all regions with shortids

profiles=$(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default|awsbillingmaster' | tr -d '[]' | sort)
#profiles="connectedhome-dev"
regions=$(aws ec2 describe-regions --output text | cut -f 3)

echo "account,region,snapshotid,description,starttime"
for profile in $profiles; do 
  for region in $regions; do
    idsandtags=$(aws --region=$region --profile=$profile ec2 describe-snapshots | jq -r '.Snapshots[] | [.SnapshotId, .Description, .StartTime ]| @csv')
    IFS=$'\n' 
    for idandtag in $idsandtags; do
      ec2info=$(echo $idandtag | tr -d \")
      #id=$(echo $ec2info | cut -f 1 -d ",")
      #LEN=$(echo ${#id})
      #if [ $LEN -lt 11 ]; then
        echo "$profile,$region,$ec2info"
      #fi
    done
  done
done
