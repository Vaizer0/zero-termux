#!/bin/bash

API_KEY="ca8f70cb5ff2440aa7d1df42226c1018"

while getopts "l:" opt; do
    case $opt in
        l) location="$OPTARG" ;;
    esac
done

curl -sL "https://timezone.abstractapi.com/v1/current_time/?api_key=$API_KEY&location=$location" | jq
