
Base = require 'noflo-runtime-base'

class WebRTCRuntime extends Base
  constructor: (options) ->
    super options

  send: (protocol, topic, payload, context) ->
    return if not context.channel
    msg =
      protocol: protocol
      message: topic
      payload: payload
    m = JSON.stringify msg
    context.channel.send m

module.exports = (id, options) ->
  runtime = new WebRTCRuntime options

  rtcOptions =
    room: id
    debug: true
    channels:
      chat: true
    signaller: '//switchboard.rtc.io'
    capture: false
    constraints: false
    expectedLocalStreams: 0

  channels = []
  peer = RTC rtcOptions
  peer.on 'channel:opened:chat', (id, dc) ->
    channels.push dc
    dc.onmessage = (data) ->
      context =
        channel: dc
      msg = JSON.parse data.data
      runtime.receive msg.protocol, msg.message, msg.payload, context

  peer.on 'channel:closed:chat', (id, dc) ->
    dc.onmessage = null
    # TODO: remove from channels

  return runtime
