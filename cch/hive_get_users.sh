#!/bin/bash
endPoint=$1; shift
cookie=$1; shift
cookie="Cookie: ApiToken=${cookie}"
baseUrl="https://${endPoint}/v5/users/all/search?fieldSet=user&"
first=1
quantity=1000
query=$1; shift
rm -f users "allUsers"
while (true); do
   echo "Fetching first $quantity from $first"
   curl -sL -w "%{http_code} %{url_effective}\\n" -o users --header "$cookie" "${baseUrl}query=$query&first=$first&quantity=$quantity" 
   echo "Fetched first $quantity from $first"
   cat users | awk -F',' '{for (i=1; i<NF; i++) print $i}' | grep username | cut -d '"' -f 4 >> "allUsers$first"
   users=$(cat users | awk -F',' '{for (i=1; i<NF; i++) print $i}' | grep username | wc -l)
   if [[ $users -eq 0 ]]; then
      break
   fi
   first=$(($first+$quantity))
done
rm -f users 
wc -l "allUsers$first"

exit 0
