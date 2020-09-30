const Peer = require('simple-peer');
const Base = require('noflo-runtime-base');
const { v4: uuid } = require('uuid');
const { signaller: Signaller } = require('fbp-protocol-client');

const isBrowser = () => !((typeof process !== 'undefined') && process.execPath && (process.execPath.indexOf('node') !== -1));

class WebRTCRuntime extends Base {
  constructor(address, options, dontstart) {
    super(options);

    let signaller = 'ws://api.flowhub.io';
    let roomId = address;
    if (address && (address.indexOf('#') !== -1)) {
      [signaller, roomId] = address.split('#');
    }
    if (!roomId) {
      roomId = uuid();
    }
    this.signallerAddress = signaller;
    this.id = roomId;
    this.connected = false;

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
    this.signaller = new Signaller(this.signallerAddress, this.id);
    this.signaller.connect();
    this.signaller.once('connected', () => {
      this.signaller.announce(this.id);
      this.peer = new Peer(rtcOptions);
      this.subscribePeer();
    });
    this.signaller.on('signal', (data) => {
      if (!this.peer && !this.peer.destroyed) {
        return;
      }
      this.peer.signal(data);
    });
    this.signaller.on('error', (err) => {
      this.emit('error', err);
    });
  }

  subscribePeer() {
    this.peer.on('signal', (data) => {
      this.signaller.announce(this.id, data);
    });
    this.peer.on('connect', () => {
      this.connected = true;
    });
    this.peer.on('data', (data) => {
      const msg = JSON.parse(data);
      this.receive(msg.protocol, msg.command, msg.payload, {});
    });
    this.peer.on('close', () => {
      this.connected = false;
      // TODO: start anew?
    });
  }

  stop() {
    this.signaller.disconnect();
    this.signaller = null;
    this.peer.destroy();
    this.peer = null;
  }

  send(protocol, topic, payload, context) {
    if (!this.connected) {
      return;
    }
    const msg = {
      protocol,
      command: topic,
      payload,
    };
    this.peer.send(JSON.stringify(msg));
    super.send(protocol, topic, payload, context);
  }

  sendAll(protocol, topic, payload) {
    return this.send(protocol, topic, payload, {});
  }
}

module.exports = WebRTCRuntime;
