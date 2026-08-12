import os
import time
import platform
from telethon.sync import TelegramClient
from telethon.tl import types
from telethon import functions

def re(text):
    for char in text:
        print(char, end='', flush=True)
        time.sleep(0.001)

rd, gn, lgn, yw, lrd, be, pe = '\033[00;31m', '\033[00;32m', '\033[01;32m', '\033[01;33m', '\033[01;31m', '\033[94m', '\033[01;35m'
cn, k, g = '\033[00;36m', '\033[90m', '\033[38;5;130m'

t = """
1 Report Spam
2 Report Pornography
3 Report Violence
4 Report Child Abuse
5 Report Other
6 Report CopyRight
7 Report Fake
8 Report Geo Irrelevant
9 Report Illegal Drugs
10 Report Personal Details
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
|  _ < |  __/| |_) || (_) || |   | |_ |  __/| |    {cn}Account{k}
|_| \_\ \___|| .__/  \___/ |_|    \__| \___||_|
             |_|

        {lrd}[{lgn}+{lrd}] {gn}Channel : {lgn}@nullxvoid
"""

class TelegramReporter:
    def __init__(self):
        self.api_id = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter Api id account: {g}")
        self.api_hash = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter Api hash account: {g}")
        self.phone_number = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter phone account:{g} ")
        self.password = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter password account: (If you don't have it, press Enter) {g}")
        clear()
        re(account)
        print(f"{lrd}")
        print(t)
        self.method = input(f"{lrd}[{lgn}?{lrd}] {gn}Choose a method : {k}")
        self.scammer_id = input(f"{lrd}[{lgn}+{lrd}] {gn}Enter Username of the target: {k}")
        self.number = input(f"{lrd}[{lgn}+{lrd}] {gn}Number of reports: {k}")

    def report_spam(self):
        with TelegramClient('reporter', self.api_id, self.api_hash) as client:
            client.start(self.phone_number, self.password)

            try:
                user = client.get_entity(self.scammer_id)
                scammer_input_peer = types.InputPeerUser(user_id=user.id, access_hash=user.access_hash)
            except ValueError:
                print(f'{lrd}[{rd}!{lrd}] {k}No such person was found')
                client.disconnect()
                return
            
            report_reasons = {
                "1": types.InputReportReasonSpam(),
                "2": types.InputReportReasonPornography(),
                "3": types.InputReportReasonViolence(),
                "4": types.InputReportReasonChildAbuse(),
                "5": types.InputReportReasonOther(),
                "6": types.InputReportReasonCopyright(),
                "7": types.InputReportReasonFake(),
                "8": types.InputReportReasonGeoIrrelevant(),
                "9": types.InputReportReasonIllegalDrugs(),
                "10": types.InputReportReasonPersonalDetails()
            }
            
            report_messages = {
                "1": "A spam report has been sent",
                "2": "A Pornography report has been sent",
                "3": "A Violence report has been sent",
                "4": "A Child Abuse report has been sent",
                "5": "A Other report has been sent",
                "6": "A CopyRight report has been sent",
                "7": "A Fake report has been sent",
                "8": "A Geo Irrelevant report has been sent",
                "9": "A Illegal Drugs report has been sent",
                "10": "A Personal Details report has been sent"
            }
            
            if self.method == "5":
                message = input(f"{lrd}[{lgn}?{lrd}] {gn}Enter the report message : {k}")
            else:
                message = f"This user is suspected of {report_messages[self.method].split(' ', 2)[2]}"
            
            for i in range(int(self.number)):
                client(functions.account.ReportPeerRequest(
                    peer=scammer_input_peer,
                    reason=report_reasons[self.method],
                    message=message if self.method in ["4", "5", "6", "7", "8", "9", "10"] else ""
                ))
                print(f"{lrd}[{lgn}+{lrd}] {gn}{report_messages[self.method]} : {i+1}")

            client.disconnect()
        print(f'\n\n{lrd}[{rd}-{lrd}] {k}Your reports are finished!')

reporter = TelegramReporter()
reporter.report_spam()
