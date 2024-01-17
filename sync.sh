#!/bin/bash
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/secret.sh"

MY_IP=$(curl -s https://cloudflare.com/cdn-cgi/trace | grep -E '^ip' | cut -d = -f 2)

ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=2501.sh" -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" | jq -r '.result[0].id')
DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$RECORD&name=$DOMAIN" -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json")

DNS_RECORD_ID=$(echo $DNS_RECORD | jq -r '.result[0].id')
CF_IP=$(echo $DNS_RECORD | jq -r '.result[0].content')

if [ "$MY_IP" != "$CF_IP" ]; then
	curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" -H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $API_KEY" -H "Content-Type: application/json" --data '{"content":"'"$MY_IP"'","name":"'"$DOMAIN"'","type":"'"$RECORD"'"}' >/dev/null
	echo "IP address for $DOMAIN updated to $MY_IP"
else
	echo "IP address for $DOMAIN is equal to current IP address $MY_IP. There is nothing to do."
fi
