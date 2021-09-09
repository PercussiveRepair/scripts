#!/usr/bin/env bash

schedules="PQMKMDX P82GZYM P64GTGE"; 
for i in $schedules; do 
  echo "Now"; 
  curl -s -H "Accept: application/vnd.pagerduty+json;version=2;charset=utf8" -H "Content-Type: application/json;charset=utf8" -H "From: jay.harrison@okta.com" -H "Authorization: Token token=`cat ~/.okta/pagerduty_token`" "https://api.pagerduty.com/oncalls?schedule_ids%5B%5D=${i}&since=`date -jv -1d -u +"%Y-%m-%dT%H:%M:%SZ"`&until=`date -jv +1d -u +"%Y-%m-%dT%H:%M:%SZ"`" | jq -r '.oncalls[]|[.schedule.summary,.user.summary]|@sh' | sort -u; 
  echo "Next"; 
  curl -s -H "Accept: application/vnd.pagerduty+json;version=2;charset=utf8" -H "Content-Type: application/json;charset=utf8" -H "From: jay.harrison@okta.com" -H "Authorization: Token token=`cat ~/.okta/pagerduty_token`" "https://api.pagerduty.com/oncalls?schedule_ids%5B%5D=${i}&since=`date -jv +5d -u +"%Y-%m-%dT%H:%M:%SZ"`&until=`date -jv +6d -u +"%Y-%m-%dT%H:%M:%SZ"`" | jq -r '.oncalls[]|[.schedule.summary,.user.summary]|@sh' |sort -u ;
done
