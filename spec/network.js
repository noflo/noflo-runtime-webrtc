const { getTransport } = require('fbp-protocol-client');
const chai = require('chai');
const { v4: uuid } = require('uuid');
const noflo = require('noflo');
const Runtime = require('../runtime/network');

const Client = getTransport('webrtc');

describe('WebRTC runtime', () => {
  describe('Instantiating without ID', () => {
    it('should generate an ID', () => {
      const runtime = new Runtime(null, {}, true);
      chai.expect(runtime.id).to.be.a('string');
      chai.expect(runtime.id).to.have.length.within(10, 60);
    });
  });
  describe('Instantiating with ID', () => {
    it('should respect that ID', () => {
      const name = 'myfunckycustomid11';
      const runtime = new Runtime(name, {}, true);
      chai.expect(runtime.id).to.equal(name);
      chai.expect(runtime.signallerAddress).to.equal('ws://api.flowhub.io');
    });
  });
  describe('Instantiating with signaller#ID', () => {
    it('should respect that ID', () => {
      const signaller = 'http://myrtc.com';
      const id = 'myfunckycustomid11';
      const address = `${signaller}#${id}`;
      const runtime = new Runtime(address, {}, true);
      chai.expect(runtime.id).to.equal(id);
      chai.expect(runtime.signallerAddress).to.equal(signaller);
    });
  });
  describe('Instantiating with a graph', () => {
    it('should create a network', (done) => {
      const file = "'18' -> IN rep(core/Repeat)";
      noflo.graph.loadFBP(file, (err, graph) => {
        if (err) {
          done(err);
          return;
        }
        chai.expect(graph).to.be.a('object');
        const runtime = new Runtime(null, {
          defaultGraph: graph,
          baseDir,
        }, true);
        runtime.once('error', done);
        runtime.once('ready', () => {
          chai.expect(Object.keys(runtime.network.networks)).to.have.length(1);
          done();
        });
      });
    });
  });

  describe('Running', () => {
    let ui = null;
    let runtime = null;
    const options = {};
    const address = `ws://api.flowhub.io#${uuid()}`;
    it('connecting UI emits connected', (done) => {
      runtime = new Runtime(address, options, true);
      ui = new Client({
        protocol: 'webrtc',
        address,
      });
      runtime.start();
      ui.once('connected', () => done());
      ui.connect();
    });
    it('sending getruntime returns runtime info', function (done) {
      if (!ui.isConnected()) {
        this.skip();
      }
      ui.once('message', (msg) => {
        chai.expect(msg.protocol).to.equal('runtime');
        chai.expect(msg.command).to.equal('runtime');
        chai.expect(msg.payload).to.include.keys('capabilities');
        done();
      });
      ui.send('runtime', 'getruntime', null);
    });
  });
});
