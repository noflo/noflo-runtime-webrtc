# WebRTC-based transport for FBP runtime protocol

Allows an FBP client like [Flowhub](https://flowhub.io) to communicate with a [NoFlo](https://noflojs.org) runtime
over [WebRTC](https://en.wikipedia.org/wiki/WebRTC) using [FBP runtime protocol](http://flowbased.github.io/fbp-protocol/).

This allows to live debug and change NoFlo programs that run in a browser (client-side).
You can pass a Flowhub live-url from any device, to someone, and they can connect to it.

One should also be able to run [fbp-spec](https://github.com/flowbased/fbp-spec) tests over it.

## Changes

* 0.13.0 (2020-12-14)
  - Updated to NoFlo 1.4.0 model
* 0.12.0 (2020-11-25)
  - Updated to NoFlo 1.3.0 model
* 0.11.1 (2020-10-01)
  - Added safety when runtime is sending to nobody in particular
* 0.11.0 (2020-10-01)
  - Updated for NoFlo 1.2
  - WebRTC runtime is now usable in both Node.js and the browser
