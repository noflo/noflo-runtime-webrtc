
isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

noflo = require 'noflo'
{EventEmitter} = require 'events'
Runtime = require 'noflo-runtime-webrtc'

chai = require 'chai' unless chai
uuid = require 'uuid'

describeIfBrowser = if isBrowser() then describe else describe.skip
describeIfWebRTC = if (isBrowser() and not window.callPhantom) then describe else describe.skip


class FakeClient extends EventEmitter
  constructor: (address) ->
    @peer = null
    @channel = null
    @address = address

  connect: () ->
    address = @address
    if (address.indexOf('#') != -1)
      signaller = address.split('#')[0]
      id = address.split('#')[1]
    else
      signaller = 'https://api.flowhub.io'
      id = address

    options =
      room: id
      debug: true
      channels:
        chat: true
      signaller: signaller
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
      command: topic
      payload: payload
    @channel.send JSON.stringify msg
        

describeIfBrowser 'WebRTC runtime', ->

  before () ->
  after () ->

  describe 'Instantiating without ID', ->
    it 'should generate an ID', ->
      runtime = new Runtime null, {}, true
      chai.expect(runtime.id).to.be.a 'string'
      chai.expect(runtime.id).to.have.length.within 10,60
  describe 'Instantiating with ID', ->
    it 'should respect that ID', ->
      name = 'myfunckycustomid11'
      runtime = new Runtime name, {}, true
      chai.expect(runtime.id).to.equal name
      chai.expect(runtime.signaller).to.equal 'https://api.flowhub.io'
  describe 'Instantiating with signaller#ID', ->
    it 'should respect that ID', ->
      signaller = 'http://myrtc.com'
      id = 'myfunckycustomid11'
      address = signaller+'#'+id
      runtime = new Runtime address, {}, true
      chai.expect(runtime.id).to.equal id
      chai.expect(runtime.signaller).to.equal signaller
  describe 'Instantiating with a graph', ->
    it 'should emit network:addnetwork', (done) ->
      file = "'18' -> IN rep(core/Repeat)"
      noflo.graph.loadFBP file, (err, graph) ->
        chai.expect(err).to.not.exist
        console.log graph.id
        graph.id = 'default/main'
        graph.baseDir = 'noflo-runtime-webrtc'
        chai.expect(graph).to.be.a 'object'
        runtime = new Runtime null, { defaultGraph: graph, baseDir: graph.baseDir }, true
        runtime.network.on 'addnetwork', () ->
          chai.expect(Object.keys(runtime.network.networks)).to.have.length 1
          done()

  describeIfWebRTC 'Running', () ->
    ui = null
    runtime = null
    options = {}
    address = 'http://switchboard.rtc.io#'+uuid.v4()
    it 'connecting UI emits connected', (done) ->
      @timeout 10000
      runtime = new Runtime address, options
      ui = new FakeClient address
      ui.on 'connected', () ->
        done()
      ui.connect()
    it 'sending getruntime returns runtime info', (done) ->
      ui.once 'message', (msg) ->
        chai.expect(msg.protocol).to.equal 'runtime'
        chai.expect(msg.command).to.equal 'runtime'
        chai.expect(msg.payload).to.include.keys 'capabilities'
        done()
      ui.send 'runtime', 'getruntime', null


