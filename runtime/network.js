var Base = require('noflo-runtime-base');
var Peer = require('peer');

function WebRTCRuntime (options) {
  this.prototype.constructor.apply(this, arguments);
  this.receive = this.prototype.receive;
}
WebRTCRuntime.prototype = Base;
WebRTCRuntime.prototype.send = function (protocol, topic, payload, context) {
  if (!context.connection) {
    return;
  }
  context.connection.send(JSON.stringify({
    protocol: protocol,
    command: topic,
    payload: payload
  }));
};

module.exports = function (httpServer, options) {

  var runtime = new WebRTCRuntime(options);
  var handleMessage = function (data, connection) {
    if (message.type == 'utf8') {
      try {
        var contents = JSON.parse(data);
      } catch (e) {
        console.log(e);
        return;
      }
      runtime.receive(contents.protocol, contents.command, contents.payload, { connection: conn });
    }
  };

  var peer = new Peer({key: '6qn1eox3jbawcdi'});
  peer.on('open', function(id) {
    console.log("my peer ID is", id);
  })
  peer.on('connection', function(conn) {
    conn.on('data', function(data){
      handleMessage(data, conn);
    });
  }
};
