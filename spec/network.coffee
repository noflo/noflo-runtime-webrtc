
isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

{EventEmitter} = require 'events'

if isBrowser()
  uuid = require 'node-uuid'
else
  chai = require 'chai'
  uuid = require 'uuid'


Runtime = require 'noflo-runtime-webrtc'

describeIfBrowser = if isBrowser() then describe else describe.skip

apikey = '6qn1eox3jbawcdi' # FIXME: use envvar

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

  describe 'Running', () ->
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


