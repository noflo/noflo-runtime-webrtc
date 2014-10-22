
isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

noflo = require 'noflo'
{EventEmitter} = require 'events'
Runtime = require 'noflo-runtime-webrtc'

if isBrowser()
  #
else
  chai = require 'chai'

describeIfBrowser = if isBrowser() then describe else describe.skip
describeIfWebRTC = if (isBrowser() and not window.callPhantom) then describe else describe.skip


class FakeClient extends EventEmitter
  constructor: () ->
    @peer = null
    @channel = null

  connect: (id) ->
    options =
      room: id
      debug: true
      channels:
        chat: true
      signaller: '//switchboard.rtc.io'
      capture: false
      constraints: false
      expectedLocalStreams: 0

    @peer = RTC options
    @peer.on 'channel:opened:chat', (id, dc) =>
      @channel = dc
      @channel.onmessage = (data) =>
        msg = JSON.parse data.data
        @emit 'message', msg
      @emit 'connected'

  send: (protocol, topic, payload) ->
    msg =
      protocol: protocol
      message: topic
      payload: payload
    @channel.send JSON.stringify msg
        

describeIfBrowser 'WebRTC runtime', ->

  before () ->
  after () ->

  describe 'Instantiating without ID', ->
    it 'should generate an ID', ->
      runtime = new Runtime null, {}
      chai.expect(runtime.id).to.be.a 'string'
      chai.expect(runtime.id).to.have.length.within 10,60
  describe 'Instantiating with ID', ->
    it 'should respect that ID', ->
      name = 'myfunckycustomid11'
      runtime = new Runtime name, {}
      chai.expect(runtime.id).to.equal name
  describe 'Instantiating with a graph', ->
    it 'should emit network:addnetwork', (done) ->
      file = "'18' -> IN rep(core/Repeat)"
      noflo.graph.loadFBP file, (graph) ->
        console.log graph.id
        graph.id = 'default/main'
        graph.baseDir = 'noflo-runtime-webrtc'
        chai.expect(graph).to.be.a 'object'
        runtime = new Runtime null, { defaultGraph: graph, baseDir: graph.baseDir }
        runtime.network.on 'addnetwork', () ->
          chai.expect(Object.keys(runtime.network.networks)).to.have.length 1
          done()

  describeIfWebRTC 'Running', () ->
    ui = null
    runtime = null
    options = {}
    it 'connecting UI emits connected', (done) ->
      @timeout 10000
      runtime = new Runtime null, options
      ui = new FakeClient
      ui.on 'connected', () ->
        done()
      ui.connect runtime.id
    it 'sending getruntime returns runtime info', (done) ->
      ui.once 'message', (msg) ->
        chai.expect(msg.protocol).to.equal 'runtime'
        chai.expect(msg.message).to.equal 'runtime'
        chai.expect(msg.payload).to.include.keys 'capabilities'
        done()
      ui.send 'runtime', 'getruntime', null


