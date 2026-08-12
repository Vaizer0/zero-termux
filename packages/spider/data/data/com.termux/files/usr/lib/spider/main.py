#!/usr/bin/env python
import time
import os
import platform

# Color definitions
gn = '\033[00;32m'
lgn = '\033[01;32m'
yw = '\033[01;33m'
lrd = '\033[01;31m'
be = '\033[94m'
pe = '\033[01;35m'
cn = '\033[00;36m'
k = '\033[90m'
g = '\033[38;5;130m'
reset = '\033[0m'

def re(text):
    for char in text:
        print(char, end='', flush=True)
        time.sleep(0.001)

# Initialize colorama for Windows
if 'Windows' in platform.uname():
    try:
        from colorama import init
        init()
    except ImportError:
        os.system("pip install colorama")
        from colorama import init
        init()

os.system("clear" if platform.system() != 'Windows' else "cls")

banner = f"""{k}
⠀⠀⠀⠀⠀⠀⢰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀
⡇⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⢀
⡇⠀⠀⠀⠀⠀⢨⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡃⠀⠀⠀⠀⠀⠘
⢰⠀⠀⠀⠀⠀⢰⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡆⠀⠀⠀⠀⠀⡇
⢸⡄⠀⠀⠀⠀⠀⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠀⠀⠀⠀⠀⢠⠇
⠘⣧⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⣼⠀
⠀⠹⣆⠀⠀⠀⠀⠀⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠀⠀⠀⠀⠀⣰⠏⠀
⠀⠀⠹⣧⠀⠀⠀⠀⠸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡏⠀⠀⠀⠀⣰⠏⠀⠀
⠀⠀⠀⠹⣧⠀⠀⠀⠀⠹⣷⡀⠀⠀⠀⠀⠀⠀⢀⣾⠍⠀⠀⠀⠀⣴⠏⠀⠀⠀
⠀⠀⠀⠀⠙⡧⣀⠀⠀⠀⠘⣿⡄⠀⠀⠀⠀⢠⣾⠏⠀⠀⠀⣀⣼⠏⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠙⠻⣶⣤⡀⠘⢿⡄⣀⣀⢠⣿⠃⠀⣠⣴⡾⠛⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⢷⣜⣿⣿⣿⣿⣣⣶⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣽⣿⣿⣿⣿⣯⣅⣀⡀⠀⠀⠀⠀⠀⠀⠀{lgn}Telegram Report{k}⠀⠀
⠀⠀⠀⠀⢀⣤⣴⠾⠿⠛⢋⣥⣿⣿⣿⣿⣿⣿⣍⠛⠻⠿⢶⣤⣄⡀⠀⠀⠀⠀
⠀⠀⠀⢰⡟⠉⠀⠀⠀⣠⡾⣻⢟⣥⣶⣿⣿⣿⡿⣷⣄⠀⠀⠈⠀⢿⡄⠀⠀⠀
⠀⠀⢠⡟⠀⠀⠀⣠⡾⠋⢰⣯⣾⣿⣿⣿⣿⣿⣿⡈⠻⣷⣄⠀⠀⠈⢷⡀⠀⠀
⠀⢀⡾⠁⠀⠀⣼⠋⠀⠀⢸⢸⣿⡿⠿⣿⠿⣿⣿⡇⠀⠈⢫⣧⠀⠀⠘⣷⠀⠀
⠀⣼⠃⠀⠀⢠⣿⠀⠀⠀⠸⣿⣿⣿⡆⠀⣼⡟⣹⠀⠀⠀⠀⣿⠀⠀⠀⠸⣧⠀
⠀⡟⠀⠀⠀⢸⡏⠀⠀⠀⠀⠙⢿⣯⣶⣶⣮⡿⠃⠀⠀⠀⠀⢹⡇⠀⠀⠀⣿⠀
⠀⡇⠀⠀⠀⣼⠇⠀⠀⠀⠀⠀⠀⠉⠛⠋⠉⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⢸⠀
⠀⡇⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⠀⠀⠀⢸⠀
⠀⡇⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⢸⠀
⠀⡇⠀⠀⠀⢸⡆⠀ \033[1mAlienkrishn{k}⠀ ⢰⡏⠀⠀⠀⢸⠀
⠀⠁⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠁⠀⠀⠀⠈⠀
⠀⠀⠀⠀⠀⠀⠸⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡸⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠁⠀⠀⠀⠀⠀⠀⠀


{lgn}Warning! This is a test reporter, and if you misuse this script
I will not be responsible{reset}
{cn}
[1] Report Account 
[2] Report Channel
[3] Join Telegram 
[0] Exit this tool

"""

re(banner)

number = input(f"{gn}Enter Number : {cn}")

if number == "1":
    os.system("python $PREFIX/lib/spider/report/report.py")
elif number == "2":
    os.system("python $PREFIX/lib/spider/report/reporter.py")
elif number == "3":
    os.system("xdg-open https://github.com/Vaizer0/zero-termux")
elif number == "0":
    re("Exiting from the script...")
    time.sleep(1)
    os.system("exit")
else:
    re("Invalid option selected...")
    time.sleep(1)
    os.system("exit")
