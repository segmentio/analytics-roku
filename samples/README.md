# Building the sample app

* Set the `SEGMENT_WRITE_KEY` environment variable to your Segment source write key
* Run `make segment-config` which will add your write key to the manifest file and copy library files to the sample app

## Running the sample app

* Set up a Roku device in your local network
* Set up `ROKU_DEV_TARGET` and `ROKU_DEV_PASSWORD` to the IP address and the developmentpassword of your Roku device
* Run `make install-app`, which will build the app, side load it onto your Roku device and start it
* Press buttons on the remote and observe events streaming into your Segment source using the Debugger in the Segment app.
