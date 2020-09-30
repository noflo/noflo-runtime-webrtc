# WebRTC-based transport for FBP runtime protocol

Allows an FBP client like [Flowhub](https://flowhub.io) to communicate with a [NoFlo](https://noflojs.org) runtime
over [WebRTC](https://en.wikipedia.org/wiki/WebRTC) using [FBP runtime protocol](http://flowbased.github.io/fbp-protocol/).

This allows to live debug and change NoFlo programs that run in a browser (client-side).
You can pass a Flowhub live-url from any device, to someone, and they can connect to it.

One should also be able to run [fbp-spec](https://github.com/flowbased/fbp-spec) tests over it.
