#!/bin/bash

if [ "$1" != "" ]; then
    profiles=$1
else
    profiles=$(grep -oE '\[.*?\]' ~/.aws/credentials | grep -Ev 'default|awsbillingmaster' | tr -d '[]')
fi
echo "<head> <script src='sorttable.js'></script><script src='searchtable.js'></script><link rel='stylesheet' href='https://unpkg.com/purecss@1.0.0/build/pure-min.css' integrity='sha384-nn4HPE8lTHyVtfCBi5yW9d20FjT8BJwUXyWZT9InLYax14RDjBj46LmSztkmNP9w' crossorigin='anonymous'></head>"
echo "<body><h2>IAM Users</h2>"
echo "<form class='pure-form'><input type='search' class='light-table-filter' data-table='order-table' placeholder='Filter'></form>"
echo "<table class='sortable order-table pure-table pure-table-horizontal'><thead><tr><th>Account</th><th>User</th><th class='sorttable_numeric'>Last Login</th><th>AttachedPolicies</th><th>UserPolicies</th><th>Groups</th><th>AccessKeys</th><th class='sorttable_numeric'>Keys Last Used</th></thead><tbody>"
for profile in $(echo "$profiles"); do
  Users=$(aws --profile $profile iam list-users)
  for User in $(echo "$Users" | jq -r '.Users[].UserName'); do 
    echo "<tr><td>$profile</td>"
    echo "<td>$User</td>"
    LastLogin=$(echo $Users | jq -r --arg User "$User" '.[] | .[] |select(.UserName==$User) | .PasswordLastUsed')
    if [ $LastLogin == null ]; then
      Days="None"
    else
      Days="$(( ($(date +%s)-$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LastLogin" +%s)) / (60*60*24) )) days"
    fi
    echo "<td>$Days</td>"
    AttachedPolicies=$(aws --profile $profile iam list-attached-user-policies --user-name $User | jq -r '.AttachedPolicies[].PolicyName')
    echo "<td>$AttachedPolicies</td>"
    UserPolicies=$(aws --profile $profile iam list-user-policies --user-name $User | jq -r '.PolicyNames[]')
    echo "<td>$UserPolicies</td>"
    Groups=$(aws --profile $profile iam list-groups-for-user --user-name $User | jq -r '.Groups[].GroupName')
    echo "<td>$Groups</td>"
    AccessKeys=$(aws --profile $profile iam list-access-keys --user-name $User | jq -r '[.AccessKeyMetadata[] | .AccessKeyId,.Status] | @tsv')
    echo "<td>$AccessKeys</td>"
    KeysLastUsed=""
    for key in $( echo $AccessKeys | cut -d " " -f1,3) ; do 
      KeyLastUsed=$(aws --profile $profile iam get-access-key-last-used --access-key-id $key | jq -r '.AccessKeyLastUsed.LastUsedDate')
      if [ $KeyLastUsed == null ]; then
        KeyDays="Never"
      else
        KeyDays="$(( ($(date +%s)-$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$KeyLastUsed" +%s)) / (60*60*24) )) days"
      fi
      KeysLastUsed="${KeysLastUsed} ${KeyDays}\n"
    done
    echo -e "<td>${KeysLastUsed}</td></tr>" 
      
  done
done
echo "</tbody></table></body></html>"