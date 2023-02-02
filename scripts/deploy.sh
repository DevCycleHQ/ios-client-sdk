#!/bin/bash
SHA="$(git rev-parse HEAD)"
DEVCYCLE_PROD_SLEUTH_API_TOKEN="$(aws secretsmanager get-secret-value --secret-id=DEVCYCLE_PROD_SLEUTH_API_TOKEN | jq -r .SecretString )"

# make sure we're able to track this deployment
if [[ -z "$DEVCYCLE_PROD_SLEUTH_API_TOKEN" ]]; then
    echo "Sleuth.io deployment tracking token not found. Aborting."
    exit 1
fi

# fix watchOS simulators: https://github.com/CocoaPods/CocoaPods/issues/11558#issuecomment-1284573492
echo "Fixing watchOS Simulators"
xcrun simctl list --json > simulators.json
watch_os_udids=$(jq '.devices[] | map(select(.name | contains("Watch"))) | .[].udid' simulators.json -r)
paired_watch_udids=$(jq '.pairs | map(.watch) | .[].udid' simulators.json -r)

while IFS= read -r udid; do
    if [[ ! "${paired_watch_udids[*]}" =~ "${udid}" ]]; then
        xcrun simctl delete ${udid}
    fi
done <<< "$watch_os_udids"
rm simulators.json

# pod deploy
echo "Cocoapods publish"
pod trunk push DevCycle.podspec --allow-warnings

if [[ "$?" != 0 ]]; then
    echo "Publish failed. Aborting."
    exit 1
fi

curl -X POST \
    -d api_key=$DEVCYCLE_PROD_SLEUTH_API_TOKEN \
    -d environment=production \
    -d sha=$SHA https://app.sleuth.io/api/1/deployments/taplytics/ios-client-sdk/register_deploy
