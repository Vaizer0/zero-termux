#!/bin/bash

API_KEY="71c6c550806e4bcc8f36028227526562"

while getopts "n:" opt; do
    case $opt in
        n) phone="$OPTARG" ;;
    esac
done

curl -sL "https://phoneintelligence.abstractapi.com/v1/?api_key=$API_KEY&phone=$phone" | jq
