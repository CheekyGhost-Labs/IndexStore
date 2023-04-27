#!/bin/bash
PROJECT_DIR=$PWD
CONFIG_JSON="{\"projectDirectory\": \"$PROJECT_DIR\"}"
CONFIG_PATH="${PROJECT_DIR}/Tests/IndexStoreTests/Configurations/test_configuration.json"
echo "" > "$CONFIG_PATH"
echo "$CONFIG_JSON" > "$CONFIG_PATH"
echo "test_configuration.json populated at '$CONFIG_PATH'"
