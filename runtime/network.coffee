isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

Base = require 'noflo-runtime-base'
uuid = require 'uuid'

class WebRTCRuntime extends Base
  constructor: (address, options, dontstart) ->
    @channels = []
    @debug = false

    if (address and address.indexOf('#') != -1)
      @signaller = address.split('#')[0]
      @id = address.split('#')[1]
    else
      @signaller = 'https://api.flowhub.io'
      @id = address
    @id = uuid.v4() if not @id

    @start() if not dontstart

    super options

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
        console.log 'message', msg if @debug
        @receive msg.protocol, msg.command, msg.payload, context

    peer.on 'channel:closed:chat', (id, dc) =>
      dc.onmessage = null
      return if (@channels.indexOf(dc) == -1)
      @channels.splice @channels.indexOf(dc), 1

  send: (protocol, topic, payload, context) ->
    return if not context.channel
    msg =
      protocol: protocol
      command: topic
      payload: payload
    m = JSON.stringify msg
    console.log 'send', msg if @debug
    context.channel.send m
    super protocol, topic, payload, context

  sendAll: (protocol, topic, payload) ->
    msg =
      protocol: protocol
      command: topic
      payload: payload
    m = JSON.stringify msg
    console.log 'sendAll', msg if @debug
    for channel in @channels
      try
        channel.send m
      catch e
        #

module.exports = (address, options, dontstart) ->
  runtime = new WebRTCRuntime address, options, dontstart
  return runtime
