#!/bin/bash

# Script to copy and encrypt new MFA token pngs to ops-secrets repo

MFALOCATION="/Users/jayharrison/Desktop/mfa"
SECRETSREPO="/Users/jayharrison/repos/ops-secrets"

cp $MFALOCATION/*.png $SECRETSREPO/passwords/root_mfa_qr/
for i in $(ls $SECRETSREPO/passwords/root_mfa_qr/*.png); do
  echo "encrypting $i"
  gpg  $(cat $SECRETSREPO/ops.recipients | awk '{print "-r", $1}' | xargs) --always-trust --encrypt $i
  if [ -e $i.gpg ]; then
    echo "encrypted $(ls $i) to $(ls $i.gpg)"
    rm $i.gpg
  fi
done