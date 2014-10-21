
isBrowser = ->
  !(typeof process isnt 'undefined' and process.execPath and process.execPath.indexOf('node') isnt -1)

if isBrowser()
  Peer = require('peerjs').Peer
  uuid = require 'node-uuid'
else
  chai = require 'chai'
  uuid = require 'uuid'

describeIfBrowser = if isBrowser() then describe else describe.skip

apikey = '6qn1eox3jbawcdi' # FIXME: use envvar

describeIfBrowser 'WebRTC communication', ->
  runtimePeer = null
  clientPeer = null
  runtimeId = uuid.v4()
  clientId = uuid.v4()

  before () ->
  after () ->

  describe 'Connecting client', ->
    it 'should open connection to runtime', (done) ->
      runtimePeer = new Peer runtimeId, { key: apikey }
      clientPeer = new Peer clientId, { key: apikey }
      runtimePeer.on 'connection', (runtimeConn) ->
        done()
      clientConn = clientPeer.connect runtimeId


