#!/bin/bash

sleep 117m

telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
	-d "parse_mode=Markdown" \
	-d text="$1"
}

if [ -f $(pwd)/rom/out/target/product/${T_DEVICE}/${ZIPNAME} ]; then
       telegram_message "
              	*✅ Build Finished No Loop Required ✅*"  &> /dev/null
else
       git clone https://github.com/TheSanty/GitLol loop
       cd loop || exit 1
       echo $(( RANDOM - ( RANDOM % RANDOM ) )) > builds.txt
       git add builds.txt
       git commit -m "Build : Loop"
       git push -q https://${TOKEN}@github.com/TheSanty/GitLol HEAD:main
       telegram_message "
              	*🌟 $rom Build Loop 🌟*"  &> /dev/null
fi

