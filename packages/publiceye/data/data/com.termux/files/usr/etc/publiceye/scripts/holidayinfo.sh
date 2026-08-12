#!/bin/bash

API_KEY="5b9b47be3b114016ae1d527c6521e20f"

while getopts "c:y:m:d:" opt; do
    case $opt in
        c) country="$OPTARG" ;;
        y) year="$OPTARG" ;;
        m) month="$OPTARG" ;;
        d) day="$OPTARG" ;;
    esac
done

curl -sL "https://holidays.abstractapi.com/v1/?api_key=$API_KEY&country=$country&year=$year&month=$month&day=$day" | jq
