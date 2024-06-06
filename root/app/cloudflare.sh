#!/usr/bin/with-contenv sh

getCurrentDate(){
  date '+%Y-%m-%d %H:%M:%S'
}

# This file contains all the functions called by the scripts executed automatically

cloudflare() { # Generic function for making API calls
  if [ -f "$API_KEY_FILE" ]; then # Check if file exists and it's specified
      API_KEY=$(cat $API_KEY_FILE)
  fi
  
  if [ -z "$EMAIL" ]; then # True if length of string is zero
      curl -sSL \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $API_KEY" \
      "$@" # $@ is all of the parameters passed to the script. For instance, if you call ./someScript.sh foo bar then $@ will be equal to foo bar.
  else # Email is specified, let's add to api
      curl -sSL \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      "$@"
  fi
}

webhook() {
  if [ ! -z "$WEBHOOK_URL" ]; then # if webhook url is set
    curl -sSL \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "$@"
  fi
}

getLocalIpAddress() {
  if [ "$IP_TYPE" == "4" ]; then
    IP_ADDRESS=$(ip addr show $INTERFACE | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2; exit}')
  elif [ "$IP_TYPE" == "6" ]; then
    IP_ADDRESS=$(ip addr show $INTERFACE | awk '$1 == "inet6" {gsub(/\/.*$/, "", $2); print $2; exit}')
  fi

  echo $IP_ADDRESS
}

getCustomIpAddress() {
  IP_ADDRESS=$(sh -c "$CUSTOM_LOOKUP_CMD")
  echo $IP_ADDRESS
}

getPublicIpAddress() {
  if [ "$IP_TYPE" == "4" ]; then
    # Use DNS_SERVER ENV variable or default to 1.1.1.1
    DNS_SERVER=${DNS_SERVER:=1.1.1.1}
    # Use api.ipify.org
    IPIFY=$(curl -sf4 https://api.ipify.org)
    IP_ADDRESS=$([[ "$IPIFY" =~ ^[1-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[1-9][0-9]?[0-9]?$ ]] && echo "$IPIFY" || echo "")
     
    # if IPIFY method fails
    if [ "$IP_ADDRESS" = "" ]; then 
      # try dns method first.
      CLOUD_FLARE_IP=$(dig +short @$DNS_SERVER ch txt whoami.cloudflare +time=3 | tr -d '"')
      CLOUD_FLARE_IP_LEN=${#CLOUD_FLARE_IP}

      # if using cloud flare fails, try opendns (some ISPs block 1.1.1.1)
      IP_ADDRESS=$([ $CLOUD_FLARE_IP_LEN -gt 15 ] && echo $(dig +short myip.opendns.com @resolver1.opendns.com +time=3) || echo "$CLOUD_FLARE_IP")

      # another method: 
      # IP_ADDRESS=$(curl -sf4 https://ipinfo.io | jq -r '.ip' || echo "$CLOUD_FLARE_IP")
    fi

  
    # if dns method fails, use ipinfo.io | http method
    if [ "$IP_ADDRESS" = "" ]; then
      IPINFO=$(curl -sf4 https://ipinfo.io | jq -r '.ip')
      IP_ADDRESS=$([[ "$IPINFO" =~ ^[1-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[1-9][0-9]?[0-9]?$ ]] && echo "$IPIFY" || echo "")
    fi
    
    # Use ipecho.net/plain
    if [ "$IP_ADDRESS" = "" ]; then
      IPECHO=$(curl -sf4 https://ipecho.net/plain)
      IP_ADDRESS=$([[ "$IPECHO" =~ ^[1-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[1-9][0-9]?[0-9]?$ ]] && echo "$IPIFY" || echo "")
    fi

    echo $IP_ADDRESS
    
  elif [ "$IP_TYPE" == "6" ]; then #get public ipv6 addr
    # try dns method first.
    IP_ADDRESS=$(dig +short @2606:4700:4700::1111 -6 ch txt whoami.cloudflare | tr -d '"')

    # if dns method fails, use http method
    if [ "$IP_ADDRESS" = "" ]; then
      IP_ADDRESS=$(curl -sf6 https://ifconfig.co)
    fi

    echo $IP_ADDRESS
  fi
}

getDnsRecordName() {
  if [ ! -z "$SUBDOMAIN" ]; then # Subdomain is filled
    echo $SUBDOMAIN.$ZONE
  else
    echo $ZONE
  fi
}

verifyToken() {
  if [ -z "$EMAIL" ]; then
    cloudflare -o /dev/null -w "%{http_code}" "$CF_API"/user/tokens/verify
  else
    cloudflare -o /dev/null -w "%{http_code}" "$CF_API"/user
  fi
}

getZoneId() {
  cloudflare "$CF_API/zones?name=$ZONE" | jq -r '.result[0].id'
}

# ZONE_ID NAME_Record Record_Type
getDnsRecordId() {
  #echo "Parameters of getDnsRecordId: 1 - ${1}, 2 - ${2}, 3 - ${3}"
  record_type=$3
  if [ $record_type == "TXT-SPF" ]; then #Mapping for getting the right value
    record_type="TXT"
  fi
  cloudflare "$CF_API/zones/$1/dns_records?type=$record_type&name=$2" | jq -r '.result[0].id'
}

createDnsRecord() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false"
  fi
  record_type=$RRTYPE
  if [ $record_type == "TXT-SPF" ]; then #Mapping for getting the right value
    record_type="TXT"
  fi
  cloudflare -X POST -d "{\"type\": \"$record_type\",\"name\":\"$2\",\"content\":\"$3\",\"proxied\":$PROXIED,\"ttl\":1 }" "$CF_API/zones/$1/dns_records" | jq -r '.result.id'
}

updateDnsRecord() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false" # Setting default value if not standard
  fi

  cloudflare -X PATCH \
    -d "{\"type\": \"$RRTYPE\",\"name\":\"$3\",\"content\":\"$4\",\"proxied\":$PROXIED }" \
    "$CF_API/zones/$1/dns_records/$2" \
    | jq -r '.result.id'
}

getAllPtrRecord(){
  # Remove all previous PTR records
  # Get all PTR records, for each ID delete
  cloudflare "$CF_API/zones/$1/dns_records?type=PTR" | jq -r '.result | .[] | .id' > /tmp/ptr.txt
}

deleteDnsRecord() {
  cloudflare -X DELETE "$CF_API/zones/$1/dns_records/$2" | jq -r '.result.id'
}


createPTR_DnsRecord() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false"
  fi

  cloudflare -X POST -d "{\"type\": \"PTR\",\"name\":\"$1\",\"content\":\"$2\",\"proxied\":$PROXIED,\"ttl\":1 }" "$CF_API/zones/$3/dns_records" | jq -r '.result.id'
}

# 1 - $CF_RECORD_NAME 2- $currentIpAddress 3- $CF_ZONE_ID
updateSPF_record() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false"
  fi

  #echo "params for getDnsRecordId: ${1} ${2} ${3}"
  TXT_record_id=$(getDnsRecordId $3 $1 'TXT')
  SPF_RECORD="v=spf1 include:spf.efwd.registrar-servers.com ip4:${2} ~all"

  #echo "Record ID: ${TXT_record_id}"
  if [ "$TXT_record_id" == "null" ]; then
    msg="$(getCurrentDate) ERROR: Failed to get Dns Record for TXT rec."
    echo msg
  else
    #webhook -X POST --data "{\"content\": \"$CF_RECORD_NAME updated to $CurrentIpAddress\"}" "$WEBHOOK_URL"
    cloudflare -X PATCH -d "{\"type\": \"TXT\",\"name\":\"${1}\",\"content\":\"${SPF_RECORD}\",\"proxied\":$PROXIED,\"ttl\":1 }" "$CF_API/zones/$3/dns_records/$TXT_record_id" | jq -r '.result.id'
    msg="$(getCurrentDate): CloudFlare DNS - TXT record $CF_RECORD_NAME ($CurrentIpAddress) updated successfully."

    echo $msg
  fi
  
}

# $1: zone id
# $2: record id
getDnsRecordIp() { 
  cloudflare "$CF_API/zones/$1/dns_records/$2" | jq -r '.result.content'
}