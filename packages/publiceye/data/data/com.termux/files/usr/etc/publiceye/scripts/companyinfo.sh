#!/bin/bash

API_KEY="60520cd03243429ba0520ca709e29e5a"

while getopts "d:" opt; do
    case $opt in
        d) domain="$OPTARG" ;;
    esac
done

curl -sL "https://companyenrichment.abstractapi.com/v2/?api_key=$API_KEY&domain=$domain" | jq
