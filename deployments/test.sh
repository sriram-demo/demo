#!/bin/bash

REPO_NAME="sriram-demo/demo"
TEST_ACTION_FILE="trigger-test.yaml"
POD_ID="mdmnext-prod-apse1"
TEST_ACTION_FILTER_QUERY="Testing on $POD_ID"
POD_ID=${POD_ID}

red=$(tput setaf 1) && export red
green=$(tput setaf 2) && export green
yellow=$(tput setaf 3) && export yellow
purple=$(tput setaf 125) && export purple
reset=$(tput sgr0) && export reset
purple=$(tput setaf 125)

echo "Triggering test"
sleep 5
gh workflow run $TEST_ACTION_FILE -f pod_id=$POD_ID --repo $REPO_NAME
if [[ $? -eq 0 ]]; then
    echo "Test Triggered successfully"
    sleep 10
    test_workflow_url=$(gh run list -w $TEST_ACTION_FILE --repo $REPO_NAME --json name,url | jq -r --arg actionName "$TEST_ACTION_FILTER_QUERY" '.[] | select(.name == $actionName ) | .url' | head -n 1 )
    echo "Action Log can be viewed here $test_workflow_url"
    test=$(gh run watch $(echo $test_workflow_url | rev | cut -d '/' -f 1 | rev) --repo $REPO_NAME)
    
else
    echo "Failed to trigger test"
    exit 1
fi
