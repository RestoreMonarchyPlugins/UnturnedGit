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

if [ "${FRAMEWORK}" == "rocket" ] || [ "${FRAMEWORK}" == "openmod & rocket" ]; then
    if [ "${FRAMEWORK_AUTOUPDATE}" == "1" ] || [ ! -d "Modules/Rocket.Unturned" ]; then
        cp -r Extras/Rocket.Unturned Modules/
    fi
fi

if ([ "${FRAMEWORK}" == "openmod" ] || [ "${FRAMEWORK}" == "openmod & rocket" ]); then
    if [ "${FRAMEWORK_AUTOUPDATE}" == "1" ] || [ ! -d "Modules/OpenMod.Unturned" ]; then
        curl -s https://api.github.com/repos/openmod/OpenMod/releases/latest | jq -r '.assets[] | select(.name | contains("OpenMod.Unturned.Module")) | .browser_download_url' | wget -i -
        unzip -o -q OpenMod.Unturned.Module*.zip -d Modules && rm OpenMod.Unturned.Module*.zip
    fi    
fi

mkdir -p .steam/sdk64
cp -f steam/linux64/steamclient.so .steam/sdk64/steamclient.so

mkdir -p Unturned_Headless_Data/Plugins/x86_64
cp -f steam/linux64/steamclient.so Unturned_Headless_Data/Plugins/x86_64/steamclient.so

# git clone REPOSITORY_DIR to INSTALL_DIR from REPOSITORY_URL from REPOSITORY_BRANCH using REPOSITORY_ACCESS_TOKEN if set
# if [ -n "${REPOSITORY_URL}" ]; then
#     if [ -n "${REPOSITORY_ACCESS_TOKEN}" ]; then
#         git clone -b ${REPOSITORY_BRANCH} https://${REPOSITORY_ACCESS_TOKEN}@${REPOSITORY_URL} ${REPOSITORY_DIR}
#     else
#         git clone -b ${REPOSITORY_BRANCH} https://${REPOSITORY_URL} ${REPOSITORY_DIR}
#     fi
# fi

if [ -n "${REPOSITORY_URL}" ] && [ -n "${INSTALL_DIR}" ]; then
    TEMP_DIR="tmp/repo"

    # remove temp dir if exists
    if [ -d "${TEMP_DIR}" ]; then
        rm -rf ${TEMP_DIR}
        echo "Temporary directory ${TEMP_DIR} has been removed."
    fi

    # Log start of script
    echo "Starting repository clone script"

    # Clone the repository into a temporary directory
    echo "Cloning repository from ${REPOSITORY_URL} (branch: ${REPOSITORY_BRANCH}) into temporary directory ${TEMP_DIR}"
    if [ -n "${REPOSITORY_ACCESS_TOKEN}" ]; then
        git clone -b ${REPOSITORY_BRANCH} https://${REPOSITORY_ACCESS_TOKEN}@${REPOSITORY_URL} ${TEMP_DIR}
    else
        git clone -b ${REPOSITORY_BRANCH} https://${REPOSITORY_URL} ${TEMP_DIR}
    fi

    echo "Repository successfully cloned to ${TEMP_DIR}"

    # Delete directory if exists /Servers/unturned/Rocket/Plugins
    if [ -d "Servers/unturned/Rocket/Plugins" ]; then
        rm -rf Servers/unturned/Rocket/Plugins
        echo "Rocket plugins directory has been removed."
    fi

    # Delete directory if exists /Servers/unturned/Rocket/Libraries
    if [ -d "Servers/unturned/Rocket/Libraries" ]; then
        rm -rf Servers/unturned/Rocket/Libraries
        echo "Rocket libraries directory has been removed."
    fi

    # Create the INSTALL_DIR if it doesn't exist
    echo "Ensuring install directory ${INSTALL_DIR} exists"
    mkdir -p ${INSTALL_DIR}

    # Move the contents of the specified REPOSITORY_DIR to the INSTALL_DIR
    if [ -n "${REPOSITORY_DIR}" ]; then
        echo "Moving contents of ${TEMP_DIR}/${REPOSITORY_DIR} to ${INSTALL_DIR}"
        shopt -s dotglob
        cp -rf ${TEMP_DIR}/${REPOSITORY_DIR}/* ${INSTALL_DIR}/
        cp -rf ${TEMP_DIR}/${REPOSITORY_DIR}/.[!.]* ${INSTALL_DIR}/
        shopt -u dotglob
    else
        echo "REPOSITORY_DIR is not specified, moving all contents of ${TEMP_DIR} to ${INSTALL_DIR}"
        shopt -s dotglob
        cp -rf ${TEMP_DIR}/* ${INSTALL_DIR}/
        cp -rf ${TEMP_DIR}/.[!.]* ${INSTALL_DIR}/
        shopt -u dotglob
    fi

    # Clean up: remove the temporary directory
    echo "Cleaning up: removing temporary directory ${TEMP_DIR}"
    rm -rf ${TEMP_DIR}

    # Log success message
    echo "Repository contents successfully moved to ${INSTALL_DIR}"
    echo "Repository clone script completed successfully"
fi

ulimit -n 2048
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/Unturned_Headless_Data/Plugins/x86_64/

MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}