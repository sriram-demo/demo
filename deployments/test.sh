#!/usr/bin/env bash

REPO_NAME="sriram-demo/demo"
POD_ID="mdmnext-prod-apse1"
#test dispatch variables
TEST_ACTION_FILE="trigger-test.yaml"
TEST_ACTION_FILTER_QUERY="Testing on $POD_ID"

#feature toggle dispatch varibales
FT_ACTION_FILE="trigger-ft.yaml"
FT_ACTION_FILTER_QUERY="Feature Toggle Dispatch on $POD_ID"

POD_ID=${POD_ID}

wf_to_run=$1

red=$(tput setaf 1) && export red
green=$(tput setaf 2) && export green
yellow=$(tput setaf 3) && export yellow
purple=$(tput setaf 125) && export purple
reset=$(tput sgr0) && export reset


function logError() {
  echo "${red}ERROR: ${1}${reset}"
}

function logWarn() {
  echo "${yellow}WARN: ${1}${reset}"
}

function logInfo() {
  echo "${green}${1}${reset}"
}

function logLink() {
  echo "${purple}${1}${reset}"
}

function triggerTest(){
  echo "Triggering c360,rdm,shm test on $POD_ID"
  sleep 5
  gh workflow run $TEST_ACTION_FILE -f pod_id=$POD_ID --repo $REPO_NAME
  if [[ $? -eq 0 ]]; then
      logInfo "Test Triggered successfully on $POD_ID"
      sleep 10
      test_workflow_url=$(gh run list -w $TEST_ACTION_FILE --repo $REPO_NAME --json name,url | jq -r --arg actionName "$TEST_ACTION_FILTER_QUERY" '.[] | select(.name == $actionName ) | .url' | head -n 1 )
      echo "Action Log can be viewed here $(logLink $test_workflow_url)"
      test=$(gh run watch $(echo $test_workflow_url | rev | cut -d '/' -f 1 | rev) --repo $REPO_NAME)
      gh run watch $(echo $test_workflow_url | rev | cut -d '/' -f 1 | rev) --repo $REPO_NAME --exit-status
      if [[ $? -eq 0 ]]; then
          logInfo "All Test passed successfully."
      else
          logWarn 'Test Job Failed' 
          echo "please check the logs here $(logLink $test_workflow_url)"
      fi
      
  else
      logError "Failed to trigger test"
      exit 1
  fi
}

function triggerFT(){
  gh label delete $PR --confirm
  PR=$(echo $PR | rev | cut -d '/' -f 1 | rev)
  logInfo "Merging PR $PR to master branch"
  sleep 2
  gh pr merge $PR -d -m --repo $REPO_NAME
  if [[ $? -eq 0 ]]; then
    echo "Triggering Feature Toggle Dispatch on $POD_ID"
    sleep 5
    gh workflow run $FT_ACTION_FILE -f pod_id=$POD_ID --repo $REPO_NAME
    if [[ $? -eq 0 ]]; then
        logInfo "Feature Toggle Dispatch Triggered successfully on $POD_ID"
        sleep 10
        ft_workflow_url=$(gh run list -w $FT_ACTION_FILE --repo $REPO_NAME --json name,url | jq -r --arg actionName "$FT_ACTION_FILTER_QUERY" '.[] | select(.name == $actionName ) | .url' | head -n 1 )
        echo "Action Log can be viewed here $(logLink $ft_workflow_url)"
        ft=$(gh run watch $(echo $ft_workflow_url | rev | cut -d '/' -f 1 | rev) --repo $REPO_NAME)
        gh run watch $(echo $ft_workflow_url | rev | cut -d '/' -f 1 | rev) --repo $REPO_NAME --exit-status
        if [[ $? -eq 0 ]]; then
            logInfo "Feature Toggle changes are updated successfully to the consul"
        else
            logWarn 'FT Job Failed' 
            echo "please check the logs here $(logLink $ft_workflow_url)"
        fi
        
    else
        logError "Failed to trigger feature toggle dispatch"
        exit 1
    fi
  else
    logError "Unable to merge the PR $PR. Please merge it manually"
  fi
}

if [ "${wf_to_run}" == "test" ]; then
  triggerTest 
elif [ "${wf_to_run}" == "ft_dispatch" ]; then
  triggerFT
else
  logError "No valid action called"
fi
