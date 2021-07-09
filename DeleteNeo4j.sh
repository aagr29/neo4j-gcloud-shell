#!/bin/bash
if [ -z $1 ] ; then
   echo "Missing argument"
   exit 1
fi
echo "Deleting instance and firewall rules"
gcloud compute instances delete "$1" --zone "australia-southeast1-a" 
gcloud compute firewall-rules delete "$1" # --quiet
exit $?
