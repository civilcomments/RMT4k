#!/usr/local/bin/node

/**
 * Module dependencies.
 */

var device   = require('./device-server'),
    express  = require('express'),
    http     = require('http'),
    path     = require('path'),
    socketio = require('socket.io');

var app = express();

app.configure(function(){
  app.set('port', process.env.PORT || 1234);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.logger('dev'));
  app.use(app.router);
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

app.get('/', function(req, res, next) {
  res.render('index', { title: 'RMTK4k' });
});

var server = http.createServer(app);

server.listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});

var ip, angle;
var io = socketio.listen(server);
io.set('log level', 1);
io.sockets.on('connection', function (socket) {
  socket.on('angle', function (data) {
    device.setAngle(data, function(error) {
      socket.emit('status', error ? error.message : null);
    });
  });
  socket.on('restart', function() {
    device.restart(function(error) {
      socket.emit('status', error ? error.message : null);
    });
  });
  device.on('angle', function(data) {
    angle = data;
    socket.emit('angle', data);
  });
  device.on('connection', function(ip_address) {
    ip = ip_address;
    socket.emit('status', ip + ' connected');
  });
  device.on('disconnection', function() {
    socket.emit('status', ip + ' disconnected');
    ip = null;
  });
  if (ip) {
    socket.emit('status', ip + ' is connected');
  }
  if (angle) {
    socket.emit('angle', angle);
  }
});
