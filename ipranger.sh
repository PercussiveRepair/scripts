#!/bin/bash

#MODIFY FOR YOUR LIST OF IP ADDRESSES
BADIPS=./ori.ips
twentyfour="twentyfour.ips" #temp file for all IPs converted to twentyfour net ids
sixteen="sixteen.ips"   #temp file for sixteen bit
twentyfourlst1="twentyfour1.txt"    #temp file for 24 bit IDs
twentyfourlst2="twentyfour2.txt"    #temp file for 24 bit IDs filtered by 16 bit IDs that match
sixteenlst="sixteen.txt"    #temp file for parsed sixteenbit
#MODIFY FOR YOUR OUTPUT OF CIDR ADDRESSES
finalfile="ips.list"   #Final file post-merge

cat $BADIPS | while read line; do
oc1=`echo "$line" | cut -d '.' -f 1`
oc2=`echo "$line" | cut -d '.' -f 2`
oc3=`echo "$line" | cut -d '.' -f 3`
oc4=`echo "$line" | cut -d '.' -f 4`
echo "$oc1.$oc2.$oc3.0/24" >> $twentyfour
echo "$oc1.$oc2.0.0/16" >> $sixteen
done
awk '{i=1;while(i <= NF){a[$(i++)]++}}END{for(i in a){if(a[i]>4){print i,a[i]}}}' $sixteen | sed 's/ [0-9]\| [0-9][0-9]\| [0-9][0-9][0-9]//g' > $sixteenlst
sort -u $twentyfour > twentyfour.txt
# THIS FINDS NEAR DUPLICATES MATCHING FIRST TWO OCTETS
cat $sixteenlst | while read line; do
   oc1=`echo "$line" | cut -d '.' -f 1`
   oc2=`echo "$line" | cut -d '.' -f 2`
   oc3=`echo "$line" | cut -d '.' -f 3`
   oc4=`echo "$line" | cut -d '.' -f 4`
   grep "\b$oc1.$oc2\b" twentyfour.txt >> duplicates.txt    
done
#THIS REMOVES THE NEAR DUPLICATES FROM THE TWENTYFOUR FILE
fgrep -vw -f duplicates.txt twentyfour.txt > twentyfourfinal.txt
#THIS MERGES BOTH RESULTS
cat twentyfourfinal.txt $sixteenlst > $finalfile
sort -u $finalfile
ori=`cat $BADIPS | wc -l`
new=`cat $finalfile | wc -l`
echo "$ori"
echo "$new"
