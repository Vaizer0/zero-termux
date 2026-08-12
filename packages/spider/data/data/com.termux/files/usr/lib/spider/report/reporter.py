import os
import time
import platform
from telethon.sync import TelegramClient
from telethon.tl import types
from telethon import functions
from prettytable import PrettyTable

def re(text):
    for char in text:
        print(char, end='', flush=True)
        time.sleep(0.001)

# Color definitions
rd, gn, lgn, yw, lrd, be, pe = '\033[00;31m', '\033[00;32m', '\033[01;32m', '\033[01;33m', '\033[01;31m', '\033[94m', '\033[01;35m'
cn, k, g = '\033[00;36m', '\033[90m', '\033[38;5;130m'

# Report options menu
t = """
1 Report Spam
2 Report Other
3 Report Violence
4 Report Pornography
5 Report Copyright
6 Report Fake
7 Report Geo Irrelevant
8 Report Illegal Drugs
9 Report Personal Details
"""

def clear():
    if 'Windows' in platform.uname():
        try:
            from colorama import init
        except ImportError:
            os.system("pip install colorama")
            from colorama import init
        init()
        os.system("cls")
    else:
        os.system("clear")

clear()

account = f"""{k}
 ____                             _               
|  _ \   ___  _ __    ___   _ __ | |_   ___  _ __ 
| |_) | / _ \| '_ \  / _ \ | '__|| __| / _ \| '__|
|  _ < |  __/| |_) || (_) || |   | |_ |  __/| |    {cn}Channel{k}
|_| \_\ \___|| .__/  \___/ |_|    \__| \___||_|   
             |_|	

    {lrd}[{lgn}+{lrd}] {gn}Channel : {lgn}@nullxvoid
"""

class TelegramReporter:
    def __init__(self):
        self.api_id = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter Api id account: {g}")
        self.api_hash = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter Api hash account: {g}")
        self.phone_number = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter phone account:{g} ")
        clear()
        re(account)
        print(f"{lrd}")
        print(t)
        self.method = input(f"{lrd}[{lgn}?{lrd}] {gn}Choose a method : {k}")
        self.channel_username = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter username channel {k}")
        self.number = input(f"{lrd}[{lgn}+{lrd}] {gn}Number of reports: {k}")
        self.client = TelegramClient('session', self.api_id, self.api_hash)

    def report_channel(self):
        with self.client as client:
            client.connect()
            if not client.is_user_authorized():
                client.send_code_request(self.phone_number)
                client.sign_in(self.phone_number, input('Enter the code: '))
            
            try:
                channel_entity = client.get_entity(self.channel_username)
            except Exception as e:
                print(f"{lrd}Username does not exist or cannot be accessed")
                return

            # Report configuration
            report_config = {
                "1": {
                    "reason": types.InputReportReasonSpam(),
                    "message": "This channel contains spam content.",
                    "success_msg": "A spam report has been sent"
                },
                "2": {
                    "reason": types.InputReportReasonOther(),
                    "message": input(f"{lrd}[{lgn}+{lrd}] {gn}Enter your message: {g}"),
                    "success_msg": "An Other report has been sent"
                },
                "3": {
                    "reason": types.InputReportReasonViolence(),
                    "message": "This channel contains violent content.",
                    "success_msg": "A Violence report has been sent"
                },
                "4": {
                    "reason": types.InputReportReasonPornography(),
                    "message": "This channel has pornographic content",
                    "success_msg": "A Pornography report has been sent"
                },
                "5": {
                    "reason": types.InputReportReasonCopyright(),
                    "message": "Block this channel due to copyright",
                    "success_msg": "A Copyright report has been sent"
                },
                "6": {
                    "reason": types.InputReportReasonFake(),
                    "message": "Block this channel due to scam and impersonation",
                    "success_msg": "A Fake report has been sent"
                },
                "7": {
                    "reason": types.InputReportReasonGeoIrrelevant(),
                    "message": "Block this channel due to irrelevant geo",
                    "success_msg": "A Geo Irrelevant report has been sent"
                },
                "8": {
                    "reason": types.InputReportReasonIllegalDrugs(),
                    "message": "Block this channel because of IllegalDrugs",
                    "success_msg": "An Illegal Drugs report has been sent"
                },
                "9": {
                    "reason": types.InputReportReasonPersonalDetails(),
                    "message": "Block this channel because of PersonalDetails",
                    "success_msg": "A Personal Details report has been sent"
                }
            }

            config = report_config.get(self.method)
            if not config:
                print(f"{lrd}Invalid report method selected")
                return

            for i in range(int(self.number)):
                result = client(functions.messages.ReportRequest(
                    peer=channel_entity,
                    id=[42],  # Using a dummy message ID
                    reason=config["reason"],
                    message=config["message"]
                ))
                print(f"{lrd}[{lgn}+{lrd}] {gn}{config['success_msg']} : {i+1}/{self.number}")

            print(f"\n\n{k}End of reports!")

reporter = TelegramReporter()
reporter.report_channel()
