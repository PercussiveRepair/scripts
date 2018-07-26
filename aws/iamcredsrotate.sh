#! /bin/bash

# rotates all IAM creds in .aws/credentials 

USER=$1
for i in $(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default' | tr -d '[]' | sort); do
  OLDKEY=$(aws --profile ${i} iam list-access-keys --user-name ${USER} | jq -r '.AccessKeyMetadata[].AccessKeyId')
  NEWKEYS=$(aws --profile ${i} iam create-access-key --user-name ${USER} | jq -r '.AccessKey | [ .AccessKeyId, .SecretAccessKey ] | @csv')
  echo "${i}:"
  echo "${NEWKEYS}"
  aws --profile ${i} iam delete-access-key --access-key-id ${OLDKEY} --user-name ${USER}
done
