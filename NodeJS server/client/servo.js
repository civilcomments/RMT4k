var arduino = require('duino'),
    async   = require('async');

arduino.Servo.prototype.position = 90;
arduino.Servo.prototype.destination = 90;
arduino.Servo.prototype.detachTimeout = null;
arduino.Servo.prototype.moveSmoothly = function moveSmoothly(position) {
  var servo = this;
  servo.destination = position;

  if (servo.moving) return;
  if (servo.attached) {
    servo.performMove();
    clearTimeout(servo.detachTimeout);
  } else {
    servo.once('attached', servo.performMove.bind(servo));
    servo.attach();
  }
};

arduino.Servo.prototype.performMove= function performMove() {
  var servo = this;
  async.until(
    function() {
      return servo.position == servo.destination;
    },
    function(callback) {
      servo.moving = true;
      if (servo.position > servo.destination) {
        servo.position--;
      } else {
        servo.position++;
      }
      servo.write(servo.position);
      servo.emit('position', servo.position);
      setTimeout(callback, 25);
    },
    function() {
      servo.moving = false;
      servo.detachTimeout = setTimeout(function() {
        servo.detach();
      }, 5000);
    }
  );
};

var board = new arduino.Board({
  debug: false,
  baudrate: 115200
});

board.on('error', function(error) {
  console.error('no board found. Exiting');
  process.exit(1);
});

board.on('ready', function() {
  console.log('board ready');
});

var servo = module.exports = new arduino.Servo({
  board: board,
  pin: 9
});

var initializing = true;
servo.on('attached', function() {
  console.log('attached');
  servo.attached = true;
  servo.read();
  if (initializing) {
    initializing = false;
    setTimeout(servo.detach.bind(servo), 500);
  }
});

servo.on('detached', function() {
  console.log('detached');
  servo.attached = false;
});

servo.on('read', function(error, position) {
  this.position = parseInt(position, 10);
  this.emit('position', this.position);
  console.log('position:', this.position);
});