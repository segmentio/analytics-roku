# User Acceptance Test App

## Overview

We run end to end tests for the Roku library to ensure functional correctness.

The tests use the [`library-e2e-tester`](https://github.com/segmentio/library-e2e-tester/) harness to produce fixtures and validate that the fixtures were delivered to a Segment source.

This requires a CLI to receive the fixtures, and invoke the corresponding library API methods. Since the Roku library runs only on a Roku device, it requires two components for this:

* [a CLI](https://github.com/segmentio/analytics-roku/tree/master/tests/uatest/cli) to receive events from the harness and forward to a Roku device.
* a [Roku app](https://github.com/segmentio/analytics-roku/tree/master/tests/uatest/app) receiving events from the CLI and invoking the corresponding library methods.

The Segment source used is the segment-libraries/roku, which is configured to send events to a webhook that can return the events it has received.

## Setup

To run the tests, make sure to read the contributing guide.
To run the tests, you’ll need the following:

* A macOS computer
* A Roku development environment
* A [Roku Device](https://blog.roku.com/developer/developer-setup-guide)
* analytics-roku tooling
  * [RooibosC](https://github.com/georgejecook/rooibos/blob/master/docs/index.md#rooibosC)
  * [brightscript linter](https://www.npmjs.com/package/brightscript-language)
* [Go](https://golang.org/doc/install)
  * [conf](github.com/segmentio/conf) - `go get` `github.com/segmentio/conf`
* [Node/NPM](https://nodejs.org/en/docs/guides/getting-started-guide/)
* E2E Test Tooling
  * [go-junit-report](https://github.com/jstemmer/go-junit-report)
  * [junit-viewer](https://www.npmjs.com/package/junit-viewer)

With your environment setup, run the following steps:

* clone the `analytics-roku` repo
* create a file called `env` with `touch env`
* source this file in to load variables

## Running Tests

With your environment setup, run the following steps:

* cd into the  `analytics-roku` repo
* run `source env`
* cd into `tests/uatest` directory
* run `make test`

When the tests are complete, open http://localhost:8888 in your browser, which shows a visual report of the passing and failing tests.

![report](https://cldup.com/VmBZoQTw-p.png)

There are two primary artifacts produced that can be shared:

* `uatest-results.txt`: a test report in Go test format.
* `report.xml`: a test report in JUnit format.
