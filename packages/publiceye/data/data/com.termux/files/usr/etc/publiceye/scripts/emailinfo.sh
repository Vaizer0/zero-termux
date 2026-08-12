#!/bin/bash

API_KEY="27fa8cc3015f4cf8969635a996a74639"

while getopts "e:" opt; do
    case $opt in
        e) email="$OPTARG" ;;
    esac
done

curl -sL "https://emailreputation.abstractapi.com/v1/?api_key=$API_KEY&email=$email" | jq
