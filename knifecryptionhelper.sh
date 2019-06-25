#!/bin/bash

#
# Helper script for knife file decrypt
#

# config & options
SECRETFILE=$HOME/.chef/encrypted_data_bag_secret
DATABAG=$1

# check for help needed and databag file exists 
if [ -z ${DATABAG} ] || [ ${DATABAG} = "-h" ] || [ ${DATABAG} = "--help" ]; then
  echo "usage: $0 databag_file"
  exit 1
elif [ ! -f ${DATABAG} ]; then
  echo "Cannot find ${DATABAG} file"
  exit 1
fi

# clean up old files
if [ -f /tmp/decrypted.json ]; then
  rm /tmp/decrypted.json
fi

# check which md5 we have
if [ ! -z $(which md5) ]; then
  MD5TOOL=$(which md5)
elif [ ! -z $(which md5sum) ]; then
  MD5TOOL=$(which md5sum)
else
  echo "md5 file checksum tool not found. Please specify with MD5TOOL=whatever knifecryptionhelper.sh"
fi

# decrypt file for editing
knife file decrypt ${DATABAG} --secret-file ${SECRETFILE} -Fj > /tmp/decrypted.json

# get checksum before
ORIGINALFILE=$(${MD5TOOL} /tmp/decrypted.json)

#edit file
vi /tmp/decrypted.json

# get checksum after
EDITEDFILE=$(${MD5TOOL} /tmp/decrypted.json)

if [ "$ORIGINALFILE" == "$EDITEDFILE" ]; then
  echo "File unchanged. Exiting"
  rm /tmp/decrypted.json
  exit 0
else
  read -p "File changed. Re-encrypt file? y/n" REENCRYPT
  if [ $REENCRYPT = "y" ]; then
    knife file encrypt /tmp/decrypted.json --secret-file ${SECRETFILE} -Fj > ${DATABAG}
    rm /tmp/decrypted.json
  fi
fi
