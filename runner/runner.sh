#!/usr/bin/env bash
# <bitbar.title>Runner</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Andras Helyes</bitbar.author>
# <bitbar.author.github>helyes</bitbar.author.github>
# <bitbar.desc>Starts script and tails its stdout</bitbar.desc>
# <bitbar.image>https://github.com/helyes/bitbar-plugins/raw/master/runner/bitbar-image-runner.sh.png</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/helyes/bitbar-plugins/blob/master/runner/runner.sh</bitbar.abouturl>

BITBAR_LABEL="WP"

SCRIPT_SHORTNAME="Webpack"
SCRIPT_FULL_PATH="${HOME}/work/sc/shiftcare/bin/webpack-dev-server"
#SCRIPT_FULL_PATH=/Users/andras/tmp/sleeper.sh
SCRIPT_EXECUTABLE=${SCRIPT_FULL_PATH##*/}
LOG_FILE="/tmp/bitbar-runner-${SCRIPT_EXECUTABLE%.*}.log"


NOTIFICATION_TITLE="${SCRIPT_SHORTNAME} bitbar"

# Anything to be executed before starting given executable
pre_start() {
    echo "SCRIPT_EXECUTABLE: ${SCRIPT_EXECUTABLE}" >> "${LOG_FILE}"
    source ${HOME}/.bash_profile >> "${LOG_FILE}" 2>&1
    echo "Initializing nvm..." >> "${LOG_FILE}"
    export NVM_DIR="${HOME}/.nvm" >> "${LOG_FILE}" 2>&1
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >> "${LOG_FILE}" 2>&1
    echo "Setting node 12.16 ..." >> "${LOG_FILE}"
    nvm use 12.16 >> "${LOG_FILE}" 2>&1
    #env >> "${LOG_FILE}"
}


### Edit only if you know what you are doing ###

displayNotification() {
	message=$1
	osascript -e "display notification \"${message}\" with title \"${NOTIFICATION_TITLE}\""
}

start() {
    echo "*STARTING*" >> "${LOG_FILE}"
    displayNotification "${SCRIPT_SHORTNAME} started"
    pre_start
    nohup "${SCRIPT_FULL_PATH}" >> ${LOG_FILE} 2>&1 &
    echo "*STARTED*" >> "${LOG_FILE}"    
}


stop() {
    NO_OF_INSTANCES=$(ps -ef | grep "${SCRIPT_EXECUTABLE}" | grep -v grep | wc -l | tr -d "[:blank:]")
    if [ "$NO_OF_INSTANCES" -gt 0 ] 
    then
        echo "Killing: ${NO_OF_INSTANCES} ${SCRIPT_FULL_PATH} instances..." >> "${LOG_FILE}"
        ps -ef | grep "${SCRIPT_EXECUTABLE}" | grep -v grep | awk '{print $2}' | xargs -n1 kill -9  
        sleep 1
        displayNotification "${SCRIPT_SHORTNAME} stopped"
        echo "*STOPPED*" >> "${LOG_FILE}"
    else
        echo "${SCRIPT_EXECUTABLE} not running. Nothing to stop" >> ${LOG_FILE}
    fi
}


build_menu() {
    PID=$(ps -ef | grep "${SCRIPT_EXECUTABLE}" | grep -v grep)
    [ -z "$PID" ] && COLOR="red" || COLOR="green"
    echo "${BITBAR_LABEL} | color=${COLOR}"
    echo "---"
    if [ -z "$PID" ]
    then
        echo "Start | bash=$0 param1=start terminal=false refresh=true"
    else
        echo "Stop  | bash=$0 param1=stop terminal=false refresh=true"
    fi
}

[ $# == 1 ] && { $1; exit 0; }

build_menu

[ -f ${LOG_FILE} ] && tail -n 10 "${LOG_FILE}" || echo "Logfile ${LOG_FILE} does not exist" 
echo "Refresh | terminal=false refresh=true"