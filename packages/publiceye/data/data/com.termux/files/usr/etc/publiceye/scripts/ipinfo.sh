#!/bin/bash

API_KEY="b7a96fb445354bc5bed9b4581038f110"

while getopts "i:" opt; do
    case $opt in
        i) ip="$OPTARG" ;;
    esac
done

curl -sL "https://ip-intelligence.abstractapi.com/v1/?api_key=$API_KEY&ip_address=$ip" | jq
