var exported = {
  'noflo': require('noflo'),
  'fbp-protocol-client': require('fbp-protocol-client'),
  'noflo-runtime-webrtc': require('./runtime/network.js'),
};

if (window) {
  window.require = function (moduleName) {
    if (exported[moduleName]) {
      return exported[moduleName];
    }
    throw new Error('Module ' + moduleName + ' not available');
  };
}
