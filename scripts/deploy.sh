#!/bin/bash
SHA="$(git rev-parse HEAD)"

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
