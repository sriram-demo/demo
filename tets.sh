gh workflow run trigger-test.yaml -f pod_id=mdmnext-prod-apse1 --repo sriram-demo/demo 
gh run watch $(gh run list -w trigger-test.yaml --repo sriram-demo/demo --json name,url --jq '.[] | select(.name=="Testing on mdmnext-prod-apse1") | .url' | head -n 1 | rev | cut -d '/' -f 1 | rev) --repo sriram-demo/demo
