var Chunker = require('chunked-stream');
var net     = require('net');
var servo   = require('./servo');

var chunker = new Chunker('\n');
var reconnectTimer;

function connect() {
  var client = net.connect(4321, 'ChangeThis.com', function() {
    console.log('connected to server');
    client.setKeepAlive(true);
    client.pipe(chunker);

    servo.on('position', updatePosition);
  });

  client.on('end', function() {
    servo.removeListener('position', updatePosition);
    console.log('disconnected from server; retrying in 2s');
    reconnectTimer = setTimeout(connect, 2000);
  });

  client.on('error', function(error) {
    console.log('error connecting; exiting');
    console.error(error);
    process.exit(1);
  });

  function updatePosition(position) {
    client.write(position + '\n');
  }
}

chunker.on('data', function(data) {
  data = JSON.parse(data.slice(0, -1));
  switch(data.command) {
    case 'angle':
      servo.moveSmoothly(data.angle);
      break;
    case 'restart':
      console.log('Received restart; exiting.');
      process.exit(0);
      break;
    default:
      console.log('I don\'t know how to handle:', data);
  }
});

connect();
