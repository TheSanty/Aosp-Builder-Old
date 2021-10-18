#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

# export sync start time
SYNC_START=$(date +"%s")


git config --global user.name "TheSanty"
git config --global user.email "sudhiryadav.igi@gmail.com"


# Git cookies
echo "${GIT_COOKIES}" > ~/git_cookies.sh
bash ~/git_cookies.sh


# SSH
rclone copy brrbrr:ssh/ssh_ci /tmp
sudo chmod 0600 /tmp/ssh_ci
sudo mkdir ~/.ssh && sudo chmod 0700 ~/.ssh
eval `ssh-agent -s` && ssh-add /tmp/ssh_ci
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts


# Rom repo sync & dt ( Add roms and update case functions )
rom_one(){
     repo init --depth=1 --no-repo-verify -u https://github.com/HyconOS/manifest -b eleven -g default,-device,-mips,-darwin,-notdefault
     git clone https://github.com/TheSanty/local_manifests.git -b $rom .repo/local_manifests
	 repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch aosp_whyred-user
}

rom_two(){
     repo init --depth=1 --no-repo-verify -u https://github.com/Corvus-R/android_manifest.git -b 11 -g default,-device,-mips,-darwin,-notdefault
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch corvus_whyred-user
}

rom_three(){
     repo init --depth=1 --no-repo-verify -u https://github.com/HyconOS/manifest -b eleven -g default,-device,-mips,-darwin,-notdefault
	 repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
	 git clone https://github.com/TheSanty/android_device_xiaomi_whyred.git device/xiaomi/whyred
     . build/envsetup.sh && lunch aosp_whyred-eng
}

rom_four(){
     repo init --depth=1 --no-repo-verify -u https://github.com/Evolution-X/manifest -b elle -g default,-device,-mips,-darwin,-notdefault
     git clone https://github.com/TheSanty/local_manifests.git -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch evolution_whyred-user
}

rom_five(){
     repo init --depth=1 --no-repo-verify -u https://github.com/KangOS-Snowcone/android_manifest -b snowcone -g default,-device,-mips,-darwin,-notdefault
     git clone https://github.com/TheSanty/local_manifests.git -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch fluid_whyred-eng
}

rom_six(){
     repo init --depth=1 --no-repo-verify -u https://github.com/TheSanty/android_manifest.git -b arrow-12.0 -g default,-device,-mips,-darwin,-notdefault
     git clone https://github.com/TheSanty/local_manifests.git -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     . build/envsetup.sh && lunch arrow_whyred-eng
}

rom_seven(){
     repo init --depth=1 --no-repo-verify -u https://github.com/PotatoProject/manifest -b frico-release -g default,-device,-mips,-darwin,-notdefault
     git clone https://github.com/TheSanty/local_manifests.git -b $rom .repo/local_manifests
     repo sync -c --no-clone-bundle --no-tags --optimized-fetch --force-sync -j$(nproc --all)
     rm -rf hardware/qcom-caf/wlan
     git clone https://github.com/aex-tmp/platform_hardware_qcom_wlan.git -b 12.x hardware/qcom-caf/wlan
     source build/envsetup.sh && lunch potato_whyred-userdebug
}

# setup TG message and build posts
telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
	-d "parse_mode=Markdown" \
	-d text="$1"
}


telegram_build() {
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
	-F chat_id="${CHATID}" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}


# Branch name & Head commit sha for ease of tracking
commit_sha() {
    for repo in device/xiaomi/${T_DEVICE} device/xiaomi/sdm660-common vendor/xiaomi kernel/xiaomi/sdm660
    do
	printf "[$(echo $repo | cut -d'/' -f1 )/$(git -C ./$repo/.git rev-parse --short=10 HEAD)]"
    done
}


# Function to be chose based on rom flag in .yml
case "${rom}" in
 "HyconOS") rom_one
    ;;
 "CorvusOS") rom_two
    ;;
 "Hycon") rom_three
    ;;
 "EvolutionOS") rom_four
    ;;
 "KangOS") rom_five
    ;;
 "ArrowOS") rom_six
    ;;
 "POSP") rom_seven
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


# export sync end time and diff with sync start
SYNC_END=$(date +"%s")
SDIFF=$((SYNC_END - SYNC_START))


# Send 'Build Triggered' message in TG along with sync time
telegram_message "
	*🌟 $rom Build Triggered 🌟*
	*Date:* \`$(date +"%d-%m-%Y %T")\`
	*✅ Sync finished after $((SDIFF / 60)) minute(s) and $((SDIFF % 60)) seconds*"  &> /dev/null


# export build start time
BUILD_START=$(date +"%s")


# setup ccache
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=true
export CCACHE_COMPRESSLEVEL=1
export CCACHE_LIMIT_MULTIPLE=0.9
export CCACHE_MAXSIZE=50G
ccache -z


# Build commands for each roms on basis of rom flag in .yml / an additional full build.log is kept.
case "${rom}" in
 "HyconOS") mka bacon -j18 2>&1 | tee build.log
    ;;
 "CorvusOS") make corvus -j18 2>&1 | tee build.log
    ;;
 "Hycon") mka bacon -j18 2>&1 | tee build.log
    ;;
 "EvolutionOS") mka evolution -j18 2>&1 | tee build.log
    ;;
 "KangOS") make bacon -j18 2>&1 | tee build.log
    ;;
 "ArrowOS") m bacon -j18 2>&1 | tee build.log
    ;;
 "POSP") m -j18 2>&1 | tee build.log
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac


ls -a $(pwd)/out/target/product/${T_DEVICE}/ # show /out contents
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))


# sorting final zip ( commonized considering ota zips, .md5sum etc with similiar names  in diff roms)
ZIP=$(find $(pwd)/out/target/product/${T_DEVICE}/ -maxdepth 1 -name "*${T_DEVICE}*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
ZIPNAME=$(basename ${ZIP})
ZIPSIZE=$(du -sh ${ZIP} |  awk '{print $1}')
echo "${ZIP}"


# Post Build finished with Time,duration,md5,size&Tdrive link OR post build_error&trimmed build.log in TG
telegram_post(){
 if [ -f $(pwd)/out/target/product/${T_DEVICE}/${ZIPNAME} ]; then
	rclone copy ${ZIP} brrbrr:rom -P
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	DWD=${TDRIVE}${ZIPNAME}
	telegram_message "
	*✅ Build finished after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*

	*ROM:* \`${ZIPNAME}\`
	*MD5 Checksum:* \`${MD5CHECK}\`
	*Download Link:* [Tdrive](${DWD})
	*Size:* \`${ZIPSIZE}\`

	*Commit SHA:* \`$(commit_sha)\`

	*Date:*  \`$(date +"%d-%m-%Y %T")\`" &> /dev/null
 else
	BUILD_LOG=$(pwd)/build.log
	tail -n 10000 ${BUILD_LOG} >> $(pwd)/buildtrim.txt
	LOG1=$(pwd)/buildtrim.txt
	echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
	LOG2=$(pwd)/out/build_error
	TRANSFER=$(curl --upload-file ${LOG1} https://transfer.sh/$(basename ${LOG1}))
	telegram_build ${LOG2} "
	*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	Build Log: ${TRANSFER}

	_Date:  $(date +"%d-%m-%Y %T")_" &> /dev/null
 fi
}

telegram_post
ccache -s
