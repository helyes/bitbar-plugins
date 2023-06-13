#!/usr/bin/env bash

GITHUB_USER_NAME=helyes
GITHUB_PERSONAL_ACCESS_TOKEN=$(cat /Users/andras/work/helyes/bitbar-plugins/github/.secrets.github.env | grep GITHUB_PERSONAL_ACCESS_TOKEN | cut -d '=' -f2)

BITBAR_LABEL="PR"

# needed for populating $PATH
# you might want to change it according to shell you use
source "${HOME}/.bash_profile" 2>/dev/null 1>&2

# !!! if sth does not work, or not as intended, it might be a jq error
# jq output is redirected to /dev/null, so if it errors out, it does not show up in the menu
# it is required for normal payload processing as when therre are no pr-s for given user
# parsing and filtering github response by jq fails

# to dump the response into a file
# this is for testing purposes
function full() {
  curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/search/issues?q=is:pr%20is:open%20org:Shiftcare%20review-requested:${GITHUB_USER_NAME}" > ./complete_response.json 
}

REVIEWS=()

# pl stands for playgroud
# this is for testing purposes
function pl() {
  # cat ./complete_response.json | jq '.items | .[] |  .title + .user.login + " | href=\(.html_url)"'
  # cat ./complete_response.json | jq '.items | .[] | .title + " [" + .user.login + "] | href=\(.html_url)"'
  
  # $(cat ./complete_response.json | jq '.items | .[] | .title + " [" + .user.login + "] | href=\(.html_url)"')
  # IN=()
  while IFS='' read -r line; do REVIEWS+=("$line"); done < <(cat ./complete_response.json | jq '.items | .[] | .title + " [" + .user.login + "] | href=\(.html_url)"')

# echo "Array size: " ${#IN[@]}
# echo "Array elements: "${IN[*]}

 # done < <(cat ./complete_response.json | jq '.items | .[] | .title + " [" + .user.login + "] | href=\(.html_url)"')
 # curl -L \
 #        -H "Accept: application/vnd.github+json" \
 #        -H "Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" \
 #        -H "X-GitHub-Api-Version: 2022-11-28" \
        # "https://api.github.com/search/issues?q=is:pr%20is:open%20org:Shiftcare%20review-requested:${GITHUB_USER_NAME}" | jq [.items] | jq '.[] | .[] | .title + " | href=\(.html_url)"' 
# IFS=$'\n' read -ra ADDR <<< "$IN"
 # echo "!!!! ${IN}"
# for i in "${IN[@]}"; do
#   echo "elements: " # process "$i"
#   echo "$i"
# done
}

function fetch_review_requests () {
 while IFS='' read -r line; 
  do REVIEWS+=("$line"); 
  done < <(
     curl -L --silent \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/search/issues?q=is:pr%20is:open%20org:Shiftcare%20review-requested:${GITHUB_USER_NAME}" | jq '.items | .[] | .title + " [" + .user.login + "] | href=\(.html_url)"' 2>/dev/null \
          )
}
# pl

build_menu() {
  fetch_review_requests
    # pl
    # [ -n "${#REVIEWS[@]}" ] && COLOR="red" || COLOR="green"
    # echo "${BITBAR_LABEL}(${#REVIEWS[@]}) | color=${COLOR}"
  if [ "${#REVIEWS[@]}" -gt 0 ]; then
    echo "${BITBAR_LABEL}(${#REVIEWS[@]}) | color=red"
  else
    echo "${BITBAR_LABEL}(${#REVIEWS[@]}) | color=green"
  fi
  echo "---"
  for line in "${REVIEWS[@]}"; do
    # remove leading and trailing quotes
    echo "${line:1:${#line}-2}"
  done
}

# [ $# == 1 ] && { $1; exit 0; }

build_menu

# [ -f "${LOG_FILE}" ] && (tail -n 20 "${LOG_FILE}" | fold -w99) || echo "Logfile ${LOG_FILE} does not exist" 
echo "---"
echo "Refresh | terminal=false refresh=true"
