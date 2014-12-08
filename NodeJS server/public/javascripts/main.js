var socket = io.connect();
socket.on('status', function (message) {
  if (message) {
    $('#log').val($('#log').val() + message + '\n');
  }
});
socket.on('angle', function(data) {
  var angle = parseInt(data, 10);
  if (angle != NaN) {
    $('#position').val(angle);
  } else {
    $('#log').val($('#log').val() + data + '\n');
  }
});


$(function() {
  $('#rotator').change(function(event) {
    socket.emit('angle', this.value);
  });
  $('#restart').click(function(event) {
    event.preventDefault();
    socket.emit('restart');
  });
});