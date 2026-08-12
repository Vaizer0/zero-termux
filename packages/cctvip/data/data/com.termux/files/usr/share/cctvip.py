import requests, re, os, sys, time
os.system("clear && figlet -f slant CCTVIP-CAM")
print("""\a\a
Cctv camera colection
new camaera s will be add rrgularly
""")
input("press emter to start the tool ")
#colorama.init()
print("""
\033[1;32m                                                                         
\033[1;32m1) \033[1;37mUnited States                \033[1;32m31) \033[1;37mMexico                \033[1;32m61) \033[1;37mMoldova
\033[1;32m2) \033[1;37mJapan                        \033[1;32m32) \033[1;37mFinland               \033[1;32m62) \033[1;37mNicaragua
\033[1;32m3) \033[1;37mItaly                        \033[1;32m33) \033[1;37mChina                 \033[1;32m63) \033[1;37mMalta
\033[1;32m4) \033[1;37mKorea                        \033[1;32m34) \033[1;37mChile                 \033[1;32m64) \033[1;37mTrinidad And Tobago
\033[1;32m5) \033[1;37mFrance                       \033[1;32m35) \033[1;37mSouth Africa          \033[1;32m65) \033[1;37mSoudi Arabia
\033[1;32m6) \033[1;37mGermany                      \033[1;32m36) \033[1;37mSlovakia              \033[1;32m66) \033[1;37mCroatia
\033[1;32m7) \033[1;37mTaiwan                       \033[1;32m37) \033[1;37mHungary               \033[1;32m67) \033[1;37mCyprus
\033[1;32m8) \033[1;37mRussian Federation           \033[1;32m38) \033[1;37mIreland               \033[1;32m68) \033[1;37mPakistan
\033[1;32m9) \033[1;37mUnited Kingdom               \033[1;32m39) \033[1;37mEgypt                 \033[1;32m69) \033[1;37mUnited Arab Emirates
\033[1;32m10) \033[1;37mNetherlands                 \033[1;32m40) \033[1;37mThailand              \033[1;32m70) \033[1;37mKazakhstan
\033[1;32m11) \033[1;37mCzech Republic              \033[1;32m41) \033[1;37mUkraine               \033[1;32m71) \033[1;37mKuwait
\033[1;32m12) \033[1;37mTurkey                      \033[1;32m42) \033[1;37mSerbia                \033[1;32m72) \033[1;37mVenezuela
\033[1;32m13) \033[1;37mAustria                     \033[1;32m43) \033[1;37mHong Kong             \033[1;32m73) \033[1;37mGeorgia
\033[1;32m14) \033[1;37mSwitzerland                 \033[1;32m44) \033[1;37mGreece                \033[1;32m74) \033[1;37mMontenegro
\033[1;32m15) \033[1;37mSpain                       \033[1;32m45) \033[1;37mPortugal              \033[1;32m75) \033[1;37mEl Salvador
\033[1;32m16) \033[1;37mCanada                      \033[1;32m46) \033[1;37mLatvia                \033[1;32m76) \033[1;37mLuxembourg
\033[1;32m17) \033[1;37mSweden                      \033[1;32m47) \033[1;37mSingapore             \033[1;32m77) \033[1;37mCuracao
\033[1;32m18) \033[1;37mIsrael                      \033[1;32m48) \033[1;37mIceland               \033[1;32m78) \033[1;37mPuerto Rico
\033[1;32m19) \033[1;37mIran                        \033[1;32m49) \033[1;37mMalaysia              \033[1;32m79) \033[1;37mCosta Rica
\033[1;32m20) \033[1;37mPoland                      \033[1;32m50) \033[1;37mColombia              \033[1;32m80) \033[1;37mBelarus
\033[1;32m21) \033[1;37mIndia                       \033[1;32m51) \033[1;37mTunisia               \033[1;32m81) \033[1;37mAlbania
\033[1;32m22) \033[1;37mNorway                      \033[1;32m52) \033[1;37mEstonia               \033[1;32m82) \033[1;37mLiechtenstein
\033[1;32m23) \033[1;37mRomania                     \033[1;32m53) \033[1;37mDominican Republic    \033[1;32m83) \033[1;37mBosnia And Herzegovia
\033[1;32m24) \033[1;37mViet Nam                    \033[1;32m54) \033[1;37mSloveania             \033[1;32m84) \033[1;37mParaguay
\033[1;32m25) \033[1;37mBelgium                     \033[1;32m55) \033[1;37mEcuador               \033[1;32m85) \033[1;37mPhilippines
\033[1;32m26) \033[1;37mBrazil                      \033[1;32m56) \033[1;37mLithuania             \033[1;32m86) \033[1;37mFaroe Islands
\033[1;32m27) \033[1;37mBulgaria                    \033[1;32m57) \033[1;37mPalestinian           \033[1;32m87) \033[1;37mGuatemala
\033[1;32m28) \033[1;37mIndonesia                   \033[1;32m58) \033[1;37mNew Zealand           \033[1;32m88) \033[1;37mNepal
\033[1;32m29) \033[1;37mDenmark                     \033[1;32m59) \033[1;37mBangladeh             \033[1;32m89) \033[1;37mPeru
\033[1;32m30) \033[1;37mArgentina                   \033[1;32m60) \033[1;37mPanama                \033[1;32m90) \033[1;37mUruguay
\033[1;32m91) \033[1;37mExtra                       \033[1;32m92) \033[1;37mAndorra               \033[1;32m93) \033[1;37mAntigua And Barbuda
\033[1;32m94) \033[1;37mArmenia                     \033[1;32m95) \033[1;37mAngola                \033[1;32m96) \033[1;37mAustralia
\033[1;32m97) \033[1;37mAruba                       \033[1;32m98) \033[1;37mAzerbaijan            \033[1;32m99) \033[1;37mBarbados
\033[1;32m100) \033[1;37mBonaire                    \033[1;32m101) \033[1;37mBahamas              \033[1;32m102) \033[1;37mBotswana
\033[1;32m103) \033[1;37mCongo                      \033[1;32m104) \033[1;37mIvory Coast          \033[1;32m105) \033[1;37mAlgeria
\033[1;32m106) \033[1;37mFiji                       \033[1;32m107) \033[1;37mGabon                \033[1;32m108) \033[1;37mGuernsey
\033[1;32m109) \033[1;37mGreenland                  \033[1;32m110) \033[1;37mGuadeloupe           \033[1;32m111) \033[1;37mGuam
\033[1;32m112) \033[1;37mGuyana                     \033[1;32m113) \033[1;37mHonduras             \033[1;32m114) \033[1;37mJersey
\033[1;32m115) \033[1;37mJamaica                    \033[1;32m116) \033[1;37mJordan               \033[1;32m117) \033[1;37mKenya
\033[1;32m118) \033[1;37mCambodia                   \033[1;32m119) \033[1;37mSaint Kitts          \033[1;32m120) \033[1;37mCayman Islands
\033[1;32m121) \033[1;37mLaos                       \033[1;32m122) \033[1;37mLebanon              \033[1;32m123) \033[1;37mSri Lanka
\033[1;32m124) \033[1;37mMorocco                    \033[1;32m125) \033[1;37mMadagascar           \033[1;32m126) \033[1;37mMacedonia
\033[1;32m127) \033[1;37mMongolia                   \033[1;32m128) \033[1;37mMacao                \033[1;32m129) \033[1;37mMartinique
\033[1;32m130) \033[1;37mMauritius                  \033[1;32m131) \033[1;37mNamibia              \033[1;32m132) \033[1;37mNew Caledonia
\033[1;32m133) \033[1;37mNigeria                    \033[1;32m134) \033[1;37mQatar                \033[1;32m135) \033[1;37mReunion
\033[1;32m136) \033[1;37mSudan                      \033[1;32m137) \033[1;37mSenegal              \033[1;32m138) \033[1;37mSuriname
\033[1;32m139) \033[1;37mSao Tome And Principe      \033[1;32m140) \033[1;37mSyria                \033[1;32m141) \033[1;37mTanzania
\033[1;32m142) \033[1;37mUganda                     \033[1;32m143) \033[1;37mUzbekistan           \033[1;32m144) \033[1;37mSaint Vincent And The Grenadines
\033[1;32m145) \033[1;37mBenin
""")

try:
    print()
    countries = ["US", "JP", "IT", "KR", "FR", "DE", "TW", "RU", "GB", "NL",
                 "CZ", "TR", "AT", "CH", "ES", "CA", "SE", "IL", "PL", "IR",
                 "NO", "RO", "IN", "VN", "BE", "BR", "BG", "ID", "DK", "AR",
                 "MX", "FI", "CN", "CL", "ZA", "SK", "HU", "IE", "EG", "TH",
                 "UA", "RS", "HK", "GR", "PT", "LV", "SG", "IS", "MY", "CO",
                 "TN", "EE", "DO", "SI", "EC", "LT", "PS", "NZ", "BD", "PA",
                 "MD", "NI", "MT", "TT", "SA", "HR", "CY", "PK", "AE", "KZ",
                 "KW", "VE", "GE", "ME", "SV", "LU", "CW", "PR", "CR", "BY",
                 "AL", "LI", "BA", "PY", "PH", "FO", "GT", "NP", "PE", "UY",
                 "-" , "AD", "AG", "AM", "AO", "AU", "AW", "AZ", "BB",
                 "BQ", "BS", "BW", "CG", "CI", "DZ", "FJ", "GA", "GG", "GL",
                 "GP", "GU", "GY", "HN", "JE", "JM", "JO", "KE", "KH", "KN",
                 "KY", "LA", "LB", "LK", "MA", "MG", "MK", "MN", "MO", "MQ",
                 "MU", "NA", "NC", "NG", "QA", "RE", "SD", "SN", "SR", "ST",
                 "SY", "TZ", "UG", "UZ", "VC","BJ", ]
    headers = {"User-Agent": "Mozilla/5.0 (X11; Linux i686; rv:68.0) Gecko/20100101 Firefox/68.0"}

    num = int(input("OPTIONS : "))
    os.system("clear && figlet -f smslant Loading-Cctv-Cams")
    if num not in range(1, 145+1):
        raise IndexError
    country = countries[num-1]
    res = requests.get(f"http://www.insecam.org/en/bycountry/{country}", headers=headers)
    last_page = re.findall(r'pagenavigator\("\?page=", (\d+)', res.text)[0]

    for page in range(int(last_page)):
        res = requests.get(
            f"http://www.insecam.org/en/bycountry/{country}/?page={page}",
            headers=headers
        )
        find_ip = re.findall(r"http://\d+.\d+.\d+.\d+:\d+", res.text)
        for ip in find_ip:
            print("\033[1;32m", ip)
except:
    pass
finally:
    print("\033[1;37m")
    exit()
