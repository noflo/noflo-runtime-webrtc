
isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

if isBrowser()
  uuid = require 'node-uuid'
else
  chai = require 'chai'
  uuid = require 'uuid'

describeIfBrowser = if isBrowser() then describe else describe.skip

apikey = '6qn1eox3jbawcdi' # FIXME: use envvar

describeIfBrowser 'WebRTC communication', ->
  runtimePeer = null
  clientPeer = null
  runtimeChannel = null
  clientChannel = null

  before () ->
  after () ->

  describe 'Connecting client', ->
    it 'should open connection to runtime', (done) ->
      @timeout 10000
      options =
        room: uuid.v4()
        debug: true
        channels:
          chat: true
        signaller: '//switchboard.rtc.io'
        capture: false
        constraints: false
        expectedLocalStreams: 0

      runtimeOpen = false
      clientOpen = false

      runtimePeer = RTC options
      runtimePeer.on 'channel:opened:chat', (id, dc) ->
        #console.log 'runtime opened', runtimeOpen, clientOpen
        runtimeChannel = dc
        runtimeOpen = true
        if runtimeOpen and clientOpen
          done()
          runtimeOpen = false
          clientOpen = false
      clientPeer = RTC options
      clientPeer.on 'channel:opened:chat', (id, dc) ->
        #console.log 'client opened', runtimeOpen, clientOpen
        clientChannel = dc
        clientOpen = true
        if runtimeOpen and clientOpen
          done() 
          runtimeOpen = false
          clientOpen = false
    it 'sending from client to runtime', (done) ->
      input = 'sjeje1'
      runtimeChannel.onmessage = (data) =>
        chai.expect(data.data).to.equal input
        runtimeChannel.onmessage = null
        done()
      clientChannel.send input
    it 'sending from runtime to client', (done) ->
      input = 'sjeje2'
      clientChannel.onmessage = (data) =>
        chai.expect(data.data).to.equal input
        clientChannel.onmessage = null
        done()
      runtimeChannel.send input


