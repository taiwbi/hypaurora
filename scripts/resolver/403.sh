#!/bin/bash

# DNS server to use
DNS_SERVER="10.202.10.202" # 403

# File containing the list of domains
DOMAIN_LIST="domains-403.txt"

# Temporary file for storing results
TEMP_FILE=$(mktemp)

# Read domains from the file and resolve IP addresses
while read -r domain; do
  ip=$(dig +short @"$DNS_SERVER" "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
  if [ "$ip" != "" ]; then
    echo "$ip	$domain" >> "$TEMP_FILE"
  fi
done < "$DOMAIN_LIST"

while read -r line; do
  ip=$(echo "$line" | awk '{print $1}')
  domain=$(echo "$line" | awk '{print $2}')

  if grep -q "	$domain" /etc/hosts; then
    sed -i "s/.*	$domain/$ip	$domain/" /etc/hosts
  else
    echo "$ip	$domain" | tee -a /etc/hosts > /dev/null
  fi
done < "$TEMP_FILE"

rm "$TEMP_FILE"
echo "IP addresses have been updated in /etc/hosts for 403"
