isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

Base = require 'noflo-runtime-base'
if isBrowser()
  uuid = require 'node-uuid'
else
  uuid = require 'uuid'

class WebRTCRuntime extends Base
  constructor: (address, options, dontstart) ->
    super options
    @channels = []

    if (address and address.indexOf('#') != -1)
      @signaller = address.split('#')[0]
      @id = address.split('#')[1]
    else
      @signaller = 'https://api.flowhub.io'
      @id = address
    @id = uuid.v4() if not @id

    @start() if not dontstart

  start: () ->
    rtcOptions =
      room: @id
      debug: true
      channels:
        chat: true
      signaller: @signaller
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

module.exports = (address, options, dontstart) ->
  runtime = new WebRTCRuntime address, options, dontstart
  return runtime
