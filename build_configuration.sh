#!/bin/bash
PROJECT_DIR=$PWD
EXCLUDE_SYSTEM="true"
EXCLUDE_STALE="true"
CONFIG_JSON="{\"projectDirectory\": \"$PROJECT_DIR\", \"excludeSystemResults\": $EXCLUDE_SYSTEM, \"excludeStaleResults\": $EXCLUDE_STALE}"
echo "$CONFIG_JSON" > "${PROJECT_DIR}/Tests/IndexStoreTests/Configurations/test_configuration.json"
echo "test_configuration.json created"