#!/usr/bin/env bash
# <bitbar.title>Runner</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Andras Helyes</bitbar.author>
# <bitbar.author.github>helyes</bitbar.author.github>
# <bitbar.desc>Starts script and tails its stdout</bitbar.desc>
# <bitbar.image>https://github.com/helyes/bitbar-plugins/raw/master/runner/bitbar-image-runner.sh.png</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/helyes/bitbar-plugins/blob/master/runner/runner.sh</bitbar.abouturl>

# this might be painful if any scripts loaded by .bash_profile or .bashrc has unbound variables
# set -o nounset # fail on unset variables

BITBAR_LABEL="WP"

SCRIPT_SHORTNAME="Webpack"
SCRIPT_FULL_PATH="${HOME}/work/sc/shiftcare/bin/webpacker-dev-server"
SCRIPT_EXECUTABLE=${SCRIPT_FULL_PATH##*/}
# the pattern to search by pgrep to check if the script is running
# most likely the name of the executable
EXECUTABLE_PGREP_PATTERN="webpack"
LOG_FILE="/tmp/bitbar-runner-${SCRIPT_EXECUTABLE%.*}.log"
# space separated list of directories to be inserted to PATH
# if nothiong to add: ADDITONAL_PATH_DIRECTORIES=()
ADDITONAL_PATH_DIRECTORIES=("/Users/andras/.local/share/rtx/installs/node/18.16.0/bin" "/Users/andras/.local/share/rtx/installs/ruby/3.0.5/bin")

# space separated list of dependencies to be checked before starting $SCRIPT_FULL_PATH
# leave it empty if no dependencies to check
DEPENDENCIES=("ruby" "node" "pbcopy")

# osascript notification title
NOTIFICATION_TITLE="${SCRIPT_SHORTNAME} bitbar"

# Steps to be executed before starting $SCRIPT_FULL_PATH
pre_start() {
    {
     echo "Script executable: ${SCRIPT_EXECUTABLE}"
     source "${HOME}/.bash_profile"
     echo "Setting up environment..."
    } >> "${LOG_FILE}" 2>&1

    for dir in "${ADDITONAL_PATH_DIRECTORIES[@]}"
    do
        echo "Adding ${dir} to PATH" >> "${LOG_FILE}"
        export PATH="${dir}:$PATH"
    done
    echo "Ruby version: $(ruby --version)" >> "${LOG_FILE}" 2>&1
    echo "Node version: $(node --version)" >> "${LOG_FILE}" 2>&1
}

# This function receives the pid file of ${SCRIPT_EXECUTABLE} as parameter on stop request
# Add any custom code here to gracefully stop it
# Most of the time it's enough to just kill the process
stop_executable() {
  kill -9 "$1"
}

######################################################
### Edit only below if you know what you are doing ###
######################################################
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

displayNotification() {
  # mac only, no linux support
	message=$1
	osascript -e "display notification \"${message}\" with title \"${NOTIFICATION_TITLE}\""
}

# Checks if given parameters are executable
#
# To check if aws and ls commands are installed, call it as 'checkInstalledDependencies aws ls'
checkInstalledDependencies () {
  numargs=$#
  for ((i=1 ; i <= numargs ; i++))
  do
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "Script requires '$1' but it's not installed. Aborting." >> "${LOG_FILE}"; exit 1; }
    shift
  done
}

getpid() {
    local pid
    pid=$(pgrep "${EXECUTABLE_PGREP_PATTERN}")
    echo "${pid}"
}

start() {
    echo -e "${GREEN}STARTING...${NO_COLOR}" >> "${LOG_FILE}"
    displayNotification "${SCRIPT_SHORTNAME} started"
    pre_start
    checkInstalledDependencies "${DEPENDENCIES[@]}"
    nohup "${SCRIPT_FULL_PATH}" >> "${LOG_FILE}" 2>&1 &
    echo -e "${GREEN}STARTED${NO_COLOR}" >> "${LOG_FILE}"
}

stop() {
    local pid
    pid=$(getpid)
    if [ -n "$pid" ]
    then
        echo "Killing $EXECUTABLE_PGREP_PATTERN [pid:$pid]: ${SCRIPT_FULL_PATH} instances..." >> "${LOG_FILE}"
        # ps -ef | grep "${SCRIPT_EXECUTABLE}" | grep -v grep | awk '{print $2}' | xargs -n1 kill -9  
        stop_executable "$pid"
        sleep 1
        displayNotification "${SCRIPT_SHORTNAME} stopped"
        echo -e "${GREEN}STOPPED${NO_COLOR}\n" >> "${LOG_FILE}"
    else
        echo "${SCRIPT_EXECUTABLE} not running. Nothing to stop" >> "${LOG_FILE}"
    fi
}

log_path_pbcopy() {
  echo -n "${LOG_FILE}" | pbcopy
	osascript -e "display notification \"Copied log file path to clipboard\" with title \"${NOTIFICATION_TITLE}\""
}

build_menu() {
    local pid
    pid=$(getpid)
    # echo "pid: ${pid}" >> "${LOG_FILE}"
    [ -z "$pid" ] && COLOR="red" || COLOR="green"
    echo "${BITBAR_LABEL} | color=${COLOR}"
    echo "---"
    if [ -z "$pid" ]
    then
        echo "Start | bash=$0 param1=start terminal=false refresh=true"
    else
        echo "Stop  | bash=$0 param1=stop terminal=false refresh=true"
    fi
}

[ $# == 1 ] && { $1; exit 0; }

build_menu

[ -f "${LOG_FILE}" ] && (tail -n 20 "${LOG_FILE}" | fold -w99) || echo "Logfile ${LOG_FILE} does not exist" 
echo "---"
echo "Refresh | terminal=false refresh=true"
echo "Copy log path to clipboard | bash=$0 param1=log_path_pbcopy terminal=false refresh=true"
