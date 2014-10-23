isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

Base = require 'noflo-runtime-base'
if isBrowser()
  uuid = require 'node-uuid'
else
  uuid = require 'uuid'

class WebRTCRuntime extends Base
  constructor: (id, options) ->
    super options
    @channels = []
    @id = id
    @id = uuid.v4() if not id

    rtcOptions =
      room: @id
      debug: true
      channels:
        chat: true
      signaller: '//switchboard.rtc.io'
      capture: false
      constraints: false
      expectedLocalStreams: 0

    peer = RTC rtcOptions
    peer.on 'channel:opened:chat', (id, dc) =>
      @channels.push dc
      dc.onmessage = (data) =>
        context =
          channel: dc
        msg = JSON.parse data.data
        @receive msg.protocol, msg.command, msg.payload, context

    peer.on 'channel:closed:chat', (id, dc) =>
      dc.onmessage = null
      return if (runtime.connections.indexOf(connection) == -1)
      runtime.connections.splice runtime.connections.indexOf(connection), 1

  send: (protocol, topic, payload, context) ->
    return if not context.channel
    msg =
      protocol: protocol
      command: topic
      payload: payload
    m = JSON.stringify msg
    context.channel.send m

  sendAll: (protocol, topic, payload) ->
    msg =
      protocol: protocol
      command: topic
      payload: payload
    m = JSON.stringify msg
    for channel in @channels
      channel.send m

module.exports = (id, options) ->
  runtime = new WebRTCRuntime id, options
  return runtime
