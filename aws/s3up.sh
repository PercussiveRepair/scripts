#!/bin/sh -e

# Assemble build number and send to s3

s3Key=""
s3Secret=""
file="VERSION"
awsPath=""
bucket=""
contentType="text/plain"
BUILD_NUMBER=186

resource="/${bucket}${awsPath}${file}"
date=$(TZ=UTC date "+%a, %d %b %Y %T %z")
echo $date

string="PUT\n\n${contentType}\n${date}\n${resource}"
signature=$(echo -en ${string} | openssl sha1 -hmac ${s3Secret} -binary | base64)

echo "Sending Version file"
CFGVER=$(grep packageVersion config.xml | cut -d "\"" -f 10)
echo "$CFGVER($BUILD_NUMBER)" > VERSION
echo "Version file: "
cat VERSION
curl -v -L -X PUT -T "${file}" \
        -H "Host: ${bucket}.s3.amazonaws.com" \
        -H "Date: ${date}" \
        -H "Content-Type: ${contentType}" \
        -H "Authorization: AWS ${s3Key}:${signature}" \
        https://${bucket}.s3.amazonaws.com${awsPath}${file}

echo "Version file sent to s3"
