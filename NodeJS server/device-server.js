var Chunker = require('chunked-stream');
var net     = require('net');

var server = net.createServer();
server.listen(4321);

var client = module.exports = new Chunker('\n');
client.connected = false;

server.on('connection', function(socket) {
  socket.setKeepAlive(true);
  console.log('device client connected!');
  promoteDevice(socket);

  socket.on('close', function() {
    console.log('device client disconnected');
    client.connected = false;
    client.emit('disconnection');
  });
});

function promoteDevice(socket) {
  if (client.connected == true) {
    return console.error('We already have a device!');
  }
  client.connected = true;
  client.socket = socket;
  socket.pipe(client, { end: false });

  client.on('data', function(data) {
    client.emit('angle', parseInt(data.replace('\r', ''), 10));
  });
  client.emit('connection', socket.remoteAddress);
}

client.sendCommand = function sendCommand(data, callback) {
  if (!client.connected) {
    return callback(new Error('No device to write to!'));
  }
  client.socket.write(JSON.stringify(data) + '\n', function() {
    callback(null, data);
  });
};

client.setAngle = function setAngle(data, callback) {
  this.sendCommand({
    command : 'angle',
    angle   : data
  }, callback);
};

client.restart = function restart(callback) {
  this.sendCommand({
    command : 'restart'
  }, callback);
  this.emit('Reconnecting servo...');
};
