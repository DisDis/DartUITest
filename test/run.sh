#!/bin/bash
# sudo apt-get install ttf-kochi-gothic ttf-kochi-mincho ttf-dejavu-core 
#DART_SDK="/home/dis/bin/dart_stable/dart-sdk"
DART_SDK="/home/dis/bin/dart/dart-sdk"
TEST_WEB_PORT=8889
# Checking content_shell
CS_PATH=$(ls -d drt-*)
if [ -z "$CS_PATH" ]; then
 echo "Not found content_shell dir"
else
 PATH=$CS_PATH:$PATH
 echo "content_shell detect"
fi

# Checking content_shell
which content_shell
if [[ $? -ne 0 ]]; then
  $DART_SDK/../chromium/download_contentshell.sh
  unzip content_shell-linux-x64-release.zip

  CS_PATH=$(ls -d drt-*)
  PATH=$CS_PATH:$PATH
fi

echo "content_shell -> '$CS_PATH'"
echo "Please run dart ./bin/test.dart"
exit 0

# Static type analysis....
results=$($DART_SDK/bin/dartanalyzer lib/*.dart 2>&1)
echo "$results"
if [[ "$results" != *"No issues found"* ]]
then
    exit 1
fi
echo "Looks good!"

$DART_SDK/bin/pub serve test --port $TEST_WEB_PORT &
pub_pid=$!

# Wait for server to build elements and spin up...
sleep 3

# Run a set of Dart Unit tests
results=$(content_shell --dump-render-tree --allow-file-access-from-files test/index.html http://localhost:$TEST_WEB_PORT)
echo -e "$results"

kill $pub_pid
