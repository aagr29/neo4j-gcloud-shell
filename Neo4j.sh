#!/bin/bash
export MACHINE=n1-standard-2
export DISK_TYPE=pd-ssd
export DISK_SIZE=20GB
export ZONE=australia-southeast1-a
export DEFAULT_LISTEN_ADDRESS=0.0.0.0
export PASSWORD="enzen"  #$(openssl rand -base64 6) #(tr -dc A-Za-z0-9 </dev/urandom | head -c 8) # Alternative
export STACK_NAME=neo4j-standalone
export IMAGE=neo4j-community-1-4-2-2-apoc

# Setup firewalling.
echo "Creating firewall rules"
gcloud compute firewall-rules create "$STACK_NAME" \
    --allow tcp:7473,tcp:7687 \
    --source-ranges 0.0.0.0/0 \
    --target-tags neo4j \

if [ $? -ne 0 ] ; then
   echo "Firewall creation failed. "
   echo "Firewall may already exist, try removing"
   exit 1
fi

echo "Creating instance"
OUTPUT=$(gcloud compute instances create $STACK_NAME \
   --machine-type $MACHINE \
   --boot-disk-type $DISK_TYPE \
   --boot-disk-size $DISK_SIZE \
   --zone $ZONE \
   --image $IMAGE \
   --tags neo4j \
   --image-project launcher-public )

echo $OUTPUT
# Pull out the IP addresses, and toss out the private internal one (10.*)
IP=$(echo $OUTPUT | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' | grep --invert-match "^10\.")
echo "Discovered new machine IP at $IP"

tries=0
echo "Waiting for VM and Database to start up, this may take over a minute..."
tries=0
while true ; do
   OUTPUT=$(echo $PASSWORD | ./cypher-shell -a $IP -u neo4j -p "neo4j" 2>&1)
   EC=$?
   echo $OUTPUT

   if [ $EC -eq 0 ]; then
     echo "Machine is up ... $tries tries"
   break
fi
  if [ $tries -gt 30 ] ; then
    echo STACK_NAME=$STACK_NAME
    echo "Machine is not coming up, giving up"
    exit 1
  fi
  tries=$(($tries+1))
  echo "Machine is not up yet ... $tries tries"
  sleep 5;
done

echo $PASSWORD
echo NEO4J_IP=$IP:7687
echo STACK_NAME=$STACK_NAME
exit 0
