#!/bin/bash
PROJECT_DIR=$PWD
EXCLUDE_SYSTEM="true"
EXCLUDE_STALE="true"
CONFIG_JSON="{\"projectDirectory\": \"$PROJECT_DIR\", \"excludeSystemResults\": $EXCLUDE_SYSTEM, \"excludeStaleResults\": $EXCLUDE_STALE}"
CONFIG_PATH="${PROJECT_DIR}/Tests/IndexStoreTests/Configurations/test_configuration.json"
if [ -f "$CONFIG_PATH" ] ; then
    rm -rf "$CONFIG_PATH"
fi
touch "$CONFIG_PATH"
echo "$CONFIG_JSON" > "$CONFIG_PATH"
echo "test_configuration.json created at '$CONFIG_PATH'"