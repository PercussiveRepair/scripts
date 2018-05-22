#!/bin/bash

bucket=
contentType="application/x-compressed-tar"
dateValue=`date -R`
s3Key=
s3Secret=
for file in $(ls /cassandra/ | grep .gz-); do
  resource="/${bucket}/${file}"
  stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
  signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
    curl -X PUT -T "/cassandra/${file}" \
      -H "Host: ${bucket}.s3-eu-west-1.amazonaws.com" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Authorization: AWS ${s3Key}:${signature}" \
      https://${bucket}.s3-eu-west-1.amazonaws.com/${file}
done
