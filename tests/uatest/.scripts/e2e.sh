#!/bin/sh

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

exe="tester_darwin_amd64"
results="uatest-results.txt"

rm -f ${results}

if [ ! -f ${exe} ]; then
    echo "Tester not found! Downloading latest version."
    wget -O - https://raw.githubusercontent.com/segmentio/library-e2e-tester/master/.buildscript/get-latest-version.sh | bash -s ${exe}
    chmod +x ${exe}
fi

echo "Running end to end tests..."
./${exe} -segment-write-key="$SEGMENT_WRITE_KEY" -webhook-auth-username="$WEBHOOK_AUTH_USERNAME" -webhook-bucket="$WEBHOOK_BUCKET" -path="${script_dir}/../cli/analytics" --skip="page" -concurrency=5 -timeout=30s | tee ${results} || true
echo "End to end tests completed; test results written to ${results}."
