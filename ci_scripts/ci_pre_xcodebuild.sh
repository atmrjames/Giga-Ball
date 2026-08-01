#!/bin/sh
set -e

# Xcode Cloud assigns its own build number, starting from 1 for a new workflow.
# Builds up to 82 were already uploaded to App Store Connect from local archives,
# and CFBundleVersion must strictly increase within a version train — so offset
# the Xcode Cloud counter past everything already used.
#
#   Xcode Cloud build 1 -> CFBundleVersion 83
#   Xcode Cloud build 2 -> CFBundleVersion 84   ...and so on
#
# Raise BUILD_OFFSET if a higher build number is ever uploaded by other means.

BUILD_OFFSET=82
NEW_BUILD=$((CI_BUILD_NUMBER + BUILD_OFFSET))

echo "Xcode Cloud build ${CI_BUILD_NUMBER} -> CFBundleVersion ${NEW_BUILD}"

cd "$CI_PRIMARY_REPOSITORY_PATH"
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" \
    Megaball.xcodeproj/project.pbxproj

grep -m1 "CURRENT_PROJECT_VERSION" Megaball.xcodeproj/project.pbxproj
