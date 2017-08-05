#!/bin/sh
# Adds pingdom IPs to an EC2 SG you specify

usage() {
          echo "Usage: $0 profile group port"
            exit 1
    }

    # print usage if cli args not provided
    [[ ! $# -eq 3 ]] && usage

    # set group and port or default port
    profile=$1
    group=$2
    port=$3
    : ${port:="8080"}

    echo "Fetching new pingdom probe ips..."
    lines=$(curl https://my.pingdom.com/probes/feed | grep "ip>" | sed 's/<\/*pingdom:ip>//g' | sort -u | wc -l)
    
    # for each ip, call the ec2 cli to add ips to a specified pingdom only security group
    echo "Adding IPs to security group: $group"
    for ip in $lines ; do
        aws ec2 authorize-security-group-ingress --profile $profile --group-id "$group" --protocol tcp --port $port --cidr "$ip/32"
      done
