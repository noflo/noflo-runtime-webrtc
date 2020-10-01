const Peer = require('simple-peer');
const Base = require('noflo-runtime-base');
const { v4: uuid } = require('uuid');
const { Signaller } = require('fbp-protocol-client');

const isBrowser = () => !((typeof process !== 'undefined') && process.execPath && (process.execPath.indexOf('node') !== -1));

class WebRTCRuntime extends Base {
  constructor(address, options, dontstart) {
    super(options);

    let signaller = 'wss://api.flowhub.io';
    let roomId = address;
    if (address && (address.indexOf('#') !== -1)) {
      [signaller, roomId] = address.split('#');
    }
    if (!roomId) {
      roomId = uuid();
    }
    this.signallerAddress = signaller;
    this.id = roomId;
    this.peers = {};

    if (!dontstart) {
      this.start();
    }
  }

  start() {
    const rtcOptions = {
      channelName: this.id,
      initiator: false,
    };
    if (!isBrowser()) {
      // eslint-disable-next-line
      rtcOptions.wrtc = require('wrtc');
    }
    this.signaller = new Signaller(uuid(), 'runtime', this.signallerAddress);
    this.signaller.connect();
    this.signaller.once('connected', () => {
      // Join the runtime ID room
      this.signaller.join(this.id);
    });
    this.signaller.on('join', (member) => {
      if (this.peers[member.id]) {
        return;
      }
      // Another peer has joined. Likely the runtime
      this.signaller.joinReply(member.id, this.id);
      this.connectPeer(member, rtcOptions);
    });
    this.signaller.on('signal', (data, member) => {
      // Getting signalling information for a peer
      const peer = this.peers[member.id];
      if (!peer && !peer.destroyed) {
        return;
      }
      peer.signal(data);
    });
    this.signaller.on('error', (err) => {
      this.emit('error', err);
      this.signaller = null;
    });
    this.signaller.on('disconnected', () => {
      this.signaller = null;
    });
  }

  connectPeer(member, rtcOptions) {
    const peer = new Peer(rtcOptions);
    peer.on('signal', (data) => {
      this.signaller.signal(member.id, data);
    });
    peer.on('data', (data) => {
      const msg = JSON.parse(data);
      this.receive(msg.protocol, msg.command, msg.payload, {
        peer: member.id,
      });
    });
    peer.on('close', () => {
      delete this.peers[member.id];
    });
    this.peers[member.id] = peer;
  }

  stop() {
    this.signaller.disconnect();
    this.signaller = null;
    Object.keys(this.peers).forEach((p) => {
      this.peers[p].destroy();
      delete this.peers[p];
    });
  }

  send(protocol, topic, payload, context) {
    const msg = {
      protocol,
      command: topic,
      payload,
    };
    const peer = this.peers[context.peer];
    if (!peer || peer.destroyed) {
      return;
    }
    peer.send(JSON.stringify(msg));
    super.send(protocol, topic, payload, context);
  }

  sendAll(protocol, topic, payload) {
    Object.keys(this.peers).forEach((p) => {
      this.send(protocol, topic, payload, {
        peer: p,
      });
    });
  }
}

module.exports = WebRTCRuntime;
