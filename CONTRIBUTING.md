# Contributing Guide

This document outlines instructions for how to contribute to the library.

## Getting Started

### IDE

There is no IDE dependency, any IDE or text editor can be used. Intellij is commonly used due to built-in support for custom syntax highlighting which can be setup for BrightScript files.

### Install

You'll need to install the following tools to develop the library.

* [rooibosC](https://github.com/georgejecook/rooibos/blob/master/docs/index.md#rooibosC)
* [Go](https://golang.org)
* [brightscript-language](https://www.npmjs.com/package/brightscript-language)
* [go-junit-report](https://github.com/jstemmer/go-junit-report)
* [junit-viewer](https://www.npmjs.com/package/junit-viewer)

### Roku Device

You'll need a physical Roku device on your local network. If you are setting up a new device, follow the [Roku developer setup guide](https://blog.roku.com/developer/developer-setup-guide).

### Environment

It's recommended you create a file `env` at the root of the project with the following structure.

```sh
# For General Roku development:
## Enter the IP of the Roku device here.
export ROKU_DEV_TARGET=10.101.17.13
# Enter the development password of the Roku device here.
export ROKU_DEV_PASSWORD=rokudev

# For End to End testing the library:
## The writeKey of the segment project to send data to.
export SEGMENT_WRITE_KEY=<hidden>
## The username for the authentication required with the webhook server.
export WEBHOOK_AUTH_USERNAME=<secret>
## The webhook bucket the data is sent to.
export WEBHOOK_BUCKET=roku
```

Then import these variables with `source env`.

Optionally, you can also set these variable by hand.

### Development

Create dev build of the sample app and deploy on the device. No unit tests will be run.

```sh
make install
```

### Debugging

From terminal, telnet to the Roku device IP on port 8085:

```sh
telnet $ROKU_DEV_TARGET 8085
```

For debugging commands, check out [Roku debugging](https://sdkdocs.roku.com/display/sdkdoc/Debugging+Your+Application).

### Testing

Create dev build of the sample app, deploy on the device, and run all tests. Make sure you're not debugging (`telnet $ROKU_DEV_TARGET 8085`) else running the command will throw an error.

```sh
make test
```

## Builds

Create `SegmentAnalytics` folder and `SegmentAnalytics.zip` zip package with all of the library files. Afterwards build zip (`SegmentAnalytics.zip`).

```sh
make library
```

**This command will delete any existing `SegmentAnalytics` folder and `SegmentAnalytics.zip` file**

## Architecture

### Folder Structure

```sh
|-- components (scenegraph components)
|   |-- analytics (library components)
|   |-- tests (unit tests for components of the library)
|-- samples (a sample app)
|-- source (non sceneGraph component files)
|   |-- analytics (library files))
|   |-- tests (tests for non scenegraph component files of the library)
|-- tests
    |-- uatest (the end to end testing app)
```

## Libraries

* [SceneGraph](https://sdkdocs.roku.com/display/sdkdoc/SceneGraph+API+Reference)
