#!/bin/bash

print_banner() {
    clear
    gum style --foreground 45 --bold --border rounded --padding "1 2" --margin "1" \
" ___           _      _              ___                 
(  _\`\        ( )    (_ )  _        (  _\`\               
| |_) ) _   _ | |_    | | (_)   ___ | (_(_) _   _    __  
| ,__/'( ) ( )| '_\`\  | | | | /'___)|  _)_ ( ) ( ) /'__\`\\
| |    | (_) || |_) ) | | | |( (___ | (_( )| (_) |(  ___/
(_)    \`\___/'(_,__/'(___)(_)\`\____)(____/'\`\__, |\`\____)
                                           ( )_| |       
                                           \`\___/'       "
    
    gum style --foreground 213 --bold --margin "1" "🔍 PUBLIC EYE - OSINT Information Gathering Tool"
    gum style --foreground 121 --margin "0 1" "👨‍💻 Created by Alienkrishn"
    echo
}

main_menu() {
    while true; do
        print_banner
        choice=$(gum choose \
            --header="🎯 Select an option" \
            --cursor="➤" \
            --height=11 \
            "📱 Phone Information" \
            "📧 Email Information" \
            "🌐 IP Information" \
            "🕒 Timezone Information" \
            "🎄 Holiday Information" \
            "🏢 Company Information" \
            "𝒊  About" \
            "✖  Exit")
        
        case $choice in
            "📱 Phone Information")
                phone_info
                ;;
            "📧 Email Information")
                email_info
                ;;
            "🌐 IP Information")
                ip_info
                ;;
            "🕒 Timezone Information")
                timezone_info
                ;;
            "🎄 Holiday Information")
                holiday_info
                ;;
            "🏢 Company Information")
                company_info
                ;;
            "𝒊  About")
                about_info
                ;;
            "✖  Exit")
                gum style --foreground 211 --bold --margin "1" "👋 Goodbye!"
                exit 0
                ;;
        esac
        
        if gum confirm "🔄 Continue with another lookup?" --affirmative="✅ Yes" --negative="❌ No"; then
            continue
        else
            gum style --foreground 211 --bold --margin "1" "👋 Goodbye!"
            exit 0
        fi
    done
}

phone_info() {
    gum style --foreground 45 --bold --margin "1" "📱 PHONE INFORMATION LOOKUP"
    phone=$(gum input --placeholder "Enter phone number (e.g., 9198******08)" --prompt "📞 " --width 50)
    
    if [[ -n "$phone" ]]; then
        gum spin --spinner dot --title "🔍 Fetching phone information..." -- sleep 2
        echo
        ./scripts/phoneinfo.sh -n "$phone"
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: No phone number entered!"
    fi
}

email_info() {
    gum style --foreground 45 --bold --margin "1" "📧 EMAIL INFORMATION LOOKUP"
    email=$(gum input --placeholder "Enter email address (e.g., test@gmail.com)" --prompt "📧 " --width 50)
    
    if [[ -n "$email" ]]; then
        gum spin --spinner dot --title "🔍 Fetching email information..." -- sleep 2
        echo
        ./scripts/emailinfo.sh -e "$email"
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: No email address entered!"
    fi
}

ip_info() {
    gum style --foreground 45 --bold --margin "1" "🌐 IP INFORMATION LOOKUP"
    ip=$(gum input --placeholder "Enter IP address (e.g., 8.8.8.8)" --prompt "🌐 " --width 50)
    
    if [[ -n "$ip" ]]; then
        gum spin --spinner dot --title "🔍 Fetching IP information..." -- sleep 2
        echo
        ./scripts/ipinfo.sh -i "$ip"
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: No IP address entered!"
    fi
}

timezone_info() {
    gum style --foreground 45 --bold --margin "1" "🕒 TIMEZONE INFORMATION LOOKUP"
    location=$(gum input --placeholder "Enter location (e.g., London, UK)" --prompt "🕒 " --width 50)
    
    if [[ -n "$location" ]]; then
        gum spin --spinner dot --title "🔍 Fetching timezone information..." -- sleep 2
        echo
        ./scripts/timezoneinfo.sh -l "$location"
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: No location entered!"
    fi
}

holiday_info() {
    gum style --foreground 45 --bold --margin "1" "🎄 HOLIDAY INFORMATION LOOKUP"
    
    country=$(gum input --placeholder "Country code (e.g., US)" --prompt "🇺🇸 " --width 20)
    year=$(gum input --placeholder "Year (e.g., 2024)" --prompt "📅 " --width 20)
    
    if gum confirm "📆 Add specific month and day?" --affirmative="✅ Yes" --negative="❌ No"; then
        month=$(gum input --placeholder "Month (1-12)" --prompt "📆 " --width 20)
        day=$(gum input --placeholder "Day (1-31)" --prompt "📅 " --width 20)
    else
        month=""
        day=""
    fi
    
    if [[ -n "$country" && -n "$year" ]]; then
        gum spin --spinner dot --title "🔍 Fetching holiday information..." -- sleep 2
        echo
        
        if [[ -n "$month" && -n "$day" ]]; then
            ./scripts/holidayinfo.sh -c "$country" -y "$year" -m "$month" -d "$day"
        elif [[ -n "$month" ]]; then
            ./scripts/holidayinfo.sh -c "$country" -y "$year" -m "$month"
        elif [[ -n "$day" ]]; then
            ./scripts/holidayinfo.sh -c "$country" -y "$year" -d "$day"
        else
            ./scripts/holidayinfo.sh -c "$country" -y "$year"
        fi
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: Country and year are required!"
    fi
}

company_info() {
    gum style --foreground 45 --bold --margin "1" "🏢 COMPANY INFORMATION LOOKUP"
    domain=$(gum input --placeholder "Enter domain (e.g., google.com)" --prompt "🏢 " --width 50)
    
    if [[ -n "$domain" ]]; then
        gum spin --spinner dot --title "🔍 Fetching company information..." -- sleep 2
        echo
        ./scripts/companyinfo.sh -d "$domain"
    else
        gum style --foreground 211 --margin "1" "❌ ERROR: No domain entered!"
    fi
}

about_info() {
    clear
    gum style --foreground 45 --bold --border rounded --padding "1 2" --margin "1" \
" ___           _      _              ___                 
(  _\`\        ( )    (_ )  _        (  _\`\               
| |_) ) _   _ | |_    | | (_)   ___ | (_(_) _   _    __  
| ,__/'( ) ( )| '_\`\  | | | | /'___)|  _)_ ( ) ( ) /'__\`\\
| |    | (_) || |_) ) | | | |( (___ | (_( )| (_) |(  ___/
(_)    \`\___/'(_,__/'(___)(_)\`\____)(____/'\`\__, |\`\____)
                                           ( )_| |       
                                           \`\___/'       "
    
    gum style --foreground 213 --bold --border rounded --padding "1 2" --margin "2 1" "🔍 ABOUT PUBLIC EYE"
    
    gum style --foreground 121 --bold --margin "1 2" "📝 Script Name:"
    gum style --foreground 255 --margin "0 2" "PublicEye OSINT Tool"
    
    gum style --foreground 121 --bold --margin "1 2" "👨‍💻 Author:"
    gum style --foreground 255 --margin "0 2" "Alienkrishn"
    
    gum style --foreground 121 --bold --margin "1 2" "💻 Language:"
    gum style --foreground 255 --margin "0 2" "Bash Shell Script"
    
    gum style --foreground 121 --bold --margin "1 2" "📖 About:"
    gum style --foreground 255 --margin "0 2" "PublicEye is a comprehensive OSINT (Open Source Intelligence) tool"
    gum style --foreground 255 --margin "0 2" "that provides various information lookup services including phone"
    gum style --foreground 255 --margin "0 2" "numbers, email addresses, IP addresses, company domains, timezone"
    gum style --foreground 255 --margin "0 2" "data, and holiday information using AbstractAPI services."
    
    gum style --foreground 121 --bold --margin "1 2" "🔗 GitHub Repository:"
    gum style --foreground 45 --margin "0 2" "https://github.com/Anon4You/publiceye"
    
    gum style --foreground 121 --bold --margin "1 2" "✨ Features:"
    gum style --foreground 255 --margin "0 2" "• 📱 Phone number intelligence lookup"
    gum style --foreground 255 --margin "0 2" "• 📧 Email reputation validation"
    gum style --foreground 255 --margin "0 2" "• 🌐 IP address geolocation"
    gum style --foreground 255 --margin "0 2" "• 🏢 Company domain enrichment"
    gum style --foreground 255 --margin "0 2" "• 🕒 Timezone information"
    gum style --foreground 255 --margin "0 2" "• 🎄 Holiday data lookup"
    
    gum style --foreground 121 --bold --margin "1 2" "🚀 Powered by:"
    gum style --foreground 255 --margin "0 2" "• Gum for beautiful CLI interfaces"
    gum style --foreground 255 --margin "0 2" "• AbstractAPI for reliable data"
    gum style --foreground 255 --margin "0 2" "• Bash for cross-platform compatibility"
    
    echo
    gum confirm "Return to main menu?" --affirmative="✅ OK" --negative="❌ Exit"
}

if [[ ! -d "scripts" ]]; then
    gum style --foreground 211 --bold --border rounded --padding "1 2" --margin "1" "❌ ERROR: scripts directory not found!"
    exit 1
fi

trap 'gum style --foreground 211 --bold --margin "1" "👋 Goodbye!"; exit 0' INT

main_menu
