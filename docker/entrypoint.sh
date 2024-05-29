#!/bin/bash
sleep 2

cd /home/container

if [ "${GAME_AUTOUPDATE}" == "1" ]; then
    ./steam/steamcmd.sh +@sSteamCmdForcePlatformBitness 64 +login anonymous +force_install_dir /home/container +app_update 1110390 +quit
fi

if [ "${FRAMEWORK}" == "vanilla" ]; then
    if [ -d "Modules/OpenMod.Unturned" ]; then
        rm -rf Modules/OpenMod.Unturned
        echo "OpenMod.Unturned has been removed from modules because Vanilla is selected as the framework."
    fi
    if [ -d "Modules/Rocket.Unturned" ]; then
        rm -rf Modules/Rocket.Unturned
        echo "Rocket.Unturned has been removed from modules because Vanilla is selected as the framework."
    fi
fi

if [ "${FRAMEWORK}" == "rocket" ] && [ -d "Modules/OpenMod.Unturned" ]; then
    rm -rf Modules/OpenMod.Unturned
    echo "OpenMod.Unturned has been removed from modules because Rocket is selected as the framework."
fi

if [ "${FRAMEWORK}" == "openmod" ] && [ -d "Modules/Rocket.Unturned" ]; then
    rm -rf Modules/Rocket.Unturned
    echo "Rocket.Unturned has been removed from modules because OpenMod is selected as the framework."
fi

if [ "${FRAMEWORK}" == "rocketmodfix" ] && [ -d "Modules/OpenMod.Unturned" ]; then
    rm -rf Modules/OpenMod.Unturned
    echo "OpenMod.Unturned has been removed from modules because Rocket is selected as the framework."
fi


if [ "${FRAMEWORK}" == "rocket" ] || [ "${FRAMEWORK}" == "openmod & rocket" ]; then
    if [ "${FRAMEWORK_AUTOUPDATE}" == "1" ] || [ ! -d "Modules/Rocket.Unturned" ]; then
        cp -r Extras/Rocket.Unturned Modules/
    fi
fi

if [[ "${FRAMEWORK}" == "rocketmodfix" ]] || [[ "${FRAMEWORK}" == "openmod & rocketmodfix" ]]; then
    if [[ -d "Modules/Rocket.Unturned" ]]; then
        rm -rf "Modules/Rocket.Unturned"
    fi
    if [[ "${FRAMEWORK_AUTOUPDATE}" == "1" ]]; then
         curl -s https://api.github.com/repos/RocketModFix/RocketModFix/releases/latest | jq -r '.assets[] | select(.name | contains("Rocket.Unturned.Module")) | .browser_download_url' | wget -i -
         unzip -o -q Rocket.Unturned.Module*.zip -d Modules && rm Rocket.Unturned.Module*.zip
    fi    
fi


if ([ "${FRAMEWORK}" == "openmod" ] || [ "${FRAMEWORK}" == "openmod & rocket" ] || [ "${FRAMEWORK}" == "openmod & rocketmodfix" ]); then
    if [ "${FRAMEWORK_AUTOUPDATE}" == "1" ] || [ ! -d "Modules/OpenMod.Unturned" ]; then
        curl -s https://api.github.com/repos/openmod/OpenMod/releases/latest | jq -r '.assets[] | select(.name | contains("OpenMod.Unturned.Module")) | .browser_download_url' | wget -i -
        unzip -o -q OpenMod.Unturned.Module*.zip -d Modules && rm OpenMod.Unturned.Module*.zip
    fi    
fi

mkdir -p .steam/sdk64
cp -f steam/linux64/steamclient.so .steam/sdk64/steamclient.so

mkdir -p Unturned_Headless_Data/Plugins/x86_64
cp -f steam/linux64/steamclient.so Unturned_Headless_Data/Plugins/x86_64/steamclient.so

# check if REPOSITORY_ENABLED is enabled
if [ "${REPOSITORY_ENABLED}" == "1" ]; then
    # run repo-sync.sh that is in the same place as entrypoint.sh which is root
    /repo-sync.sh
fi

ulimit -n 2048
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/Unturned_Headless_Data/Plugins/x86_64/

MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}