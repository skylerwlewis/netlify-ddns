#!/bin/bash
#
# This is a Bash script to update a Netlify subdomain A record with the current external IP.
# The example below would update the local.example.com A record to the current external IP with a TTL of 5 minutes.
#
# Repo: https://github.com/skylerwlewis/netlify-ddns
# Gist: https://gist.github.com/skylerwlewis/ba052db5fe26424255674931d43fc030
#
# Usage:
# netlify-ddns.sh <ACCESS_TOKEN> <DOMAIN> <SUBDOMAIN> <TTL>
#
# Example:
# netlify-ddns.sh aCcEsStOKeN example.com local 300
#
if [ "$#" -ne 4 ]; then
    echo "Wrong number of parameters passed"
    echo "Usage:"
    echo "$0 <ACCESS_TOKEN> <DOMAIN> <SUBDOMAIN> <TTL>"
    exit
fi

ACCESS_TOKEN="$1"
DOMAIN="$2"
SUBDOMAIN="$3"
TTL="$4"

NETLIFY_API="https://api.netlify.com/api/v1"

EXTERNAL_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
echo "Current external IP is $EXTERNAL_IP"

HOSTNAME="$SUBDOMAIN.$DOMAIN"

DNS_ZONES_RESPONSE=`curl -s "$NETLIFY_API/dns_zones?access_token=$ACCESS_TOKEN" --header "Content-Type:application/json"`
ZONE_ID=`echo $DNS_ZONES_RESPONSE | jq ".[]  | select(.name == \"$DOMAIN\") | .id" --raw-output`
DNS_RECORDS_RESPONSE=`curl -s "$NETLIFY_API/dns_zones/$ZONE_ID/dns_records?access_token=$ACCESS_TOKEN" --header "Content-Type:application/json"`
RECORD=`echo $DNS_RECORDS_RESPONSE | jq ".[]  | select(.hostname == \"$HOSTNAME\")" --raw-output`
RECORD_VALUE=`echo $RECORD | jq ".value" --raw-output`
echo "Current $HOSTNAME value is $RECORD_VALUE"

if [[ "$RECORD_VALUE" != "$EXTERNAL_IP" ]]; then

  if [[ "$RECORD_VALUE" != "" ]]; then
    echo "Deleting current entry for $HOSTNAME"
    RECORD_ID=`echo $RECORD | jq ".id" --raw-output`
    DELETE_RESPONSE_CODE=`curl -X DELETE -s -w "%{response_code}" "$NETLIFY_API/dns_zones/$ZONE_ID/dns_records/$RECORD_ID?access_token=$ACCESS_TOKEN" --header "Content-Type:application/json"`

    if [[ $DELETE_RESPONSE_CODE != 204 ]]; then
      echo "There was a problem deleting the existing $HOSTNAME entry, response code was $DELETE_RESPONSE_CODE"
      exit
    fi
  fi

  echo "Creating new entry for $HOSTNAME with value $EXTERNAL_IP"
  CREATE_BODY=`jq -n --arg hostname "$HOSTNAME" --arg externalIp "$EXTERNAL_IP" --arg ttl $TTL '
  {
      "type": "A",
      "hostname": $hostname,
      "value": $externalIp,
      "ttl": $ttl|tonumber
  }'`

  CREATE_RESPONSE=`curl -s --data "$CREATE_BODY" "$NETLIFY_API/dns_zones/$ZONE_ID/dns_records?access_token=$ACCESS_TOKEN" --header "Content-Type:application/json"`

  NEW_RECORD_TYPE=`echo $CREATE_RESPONSE | jq ".type" --raw-output`
  NEW_RECORD_HOSTNAME=`echo $CREATE_RESPONSE | jq ".hostname" --raw-output`
  NEW_RECORD_VALUE=`echo $CREATE_RESPONSE | jq ".value" --raw-output`
  NEW_RECORD_TTL=`echo $CREATE_RESPONSE | jq ".ttl" --raw-output`

  if [[ $NEW_RECORD_TYPE != "A" ]] || [[ $NEW_RECORD_HOSTNAME != $HOSTNAME ]] || [[ $NEW_RECORD_VALUE != $EXTERNAL_IP ]] || [[ $NEW_RECORD_TTL != $TTL ]]; then
    echo "There was a problem creating the new entry, some values did not match"
    exit
  fi
fi
