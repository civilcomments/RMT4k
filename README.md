# The Rotate-Mo-Tron 4000

A DIY tabletop telepresence robot built for the TED office, using an iPad to maintain an open socket between a Node.js server
and RedBearLab Blend Micro board.

![rmt4k](https://cloud.githubusercontent.com/assets/6831826/5333726/917b75e4-7e34-11e4-9007-18bf10c01885.gif)


This project was built for fun, to learn more about the different hardware and software tools involved.
Much of the code is amateur-level, and these files are meant to be used as a starting point only.
Improvements via pull requests are more than welcome!

Many thanks to [Mark](https://github.com/bog) for help/advice with the websocket and scripting (and for putting up with
soldering equipment on the dining table), to the folks at [RedBearLab](http://redbearlab.com) for the awesome Blend Micro and
BLEController example app, to Dave and Andy at [SuperFab](http://www.superfabpdx.com) for the CNC routing, and, of course, to the wonderful people at [TED](http://www.ted.com),
for encouraging all kinds of making.

## Whoa, this is complicated!

So yeah, this was a fun learning project for me.  If you're not fired up to build this from scratch, which is probably a sign of good mental health,
[Revolve Robotics](https://revolverobotics.com) sells a commercial tabletop product that looks pretty great, for $500 plus tablet.

## Hardware overview

![glueup](https://cloud.githubusercontent.com/assets/6831826/5333724/916c4bb4-7e34-11e4-8423-f72a072a5b8f.jpg) ![innards](https://cloud.githubusercontent.com/assets/6831826/5333725/91712e72-7e34-11e4-8498-31dcf3cf930d.jpg)

* Cut pieces for the iPad stand, glue up base and neck, sand and apply your favorite finish
* Drill and place hanger bolt to hold the iPad using a [Grifiti Nootle tripod mount](http://www.amazon.com/gp/product/B007EICZTU/ref=oh_aui_detailpage_o00_s00?ie=UTF8&psc=1)
* Find center of circle for gear placement and lazy susan attachments (this part is really tricky; can anyone suggest a good method that doesn't involve trial and error?)
* Attach neck to circle, attach 6" lazy susan to circle and base (this was hard and took forever).
* Mount servo and gears (it took some hand-routing to bring the servo mount to the right depth, and getting the gears lined up in there was tricky).  I used a standard Futaba servo that I forget the part number for, but [something like this](https://www.servocity.com/html/s3001_precision_ball_bearing.html#.VITmGlY0Oi8), and [two 1" gears](https://www.servocity.com/html/32_pitch_futaba_servo_gears.html#.VITmUVY0Oi8)
* Splice a few good-quality micro USB cables to provide 5v power to the iPad, servo, and Blend Micro.  I used micro USB with [Apple's micro USB to Lightning adapter](http://store.apple.com/us/product/MD820ZM/A/lightning-to-micro-usb-adapter) because Lightning cables are horrible to hack.  Splicing different brands of USB cables didn't work; the iPad was very sensitive to the signal coming in, and only allowed a proper charge when I made good splices using matching, quality USB cables (and made sure to hook up the green and white data wires).
* Solder and heat-shrink the connections
* Use a strain relief connector to prevent the USB cable from being yanked out
* Mount the Blend Micro and use cable clips to keep the wires organized
* Attach the bottom door with a single hinge (two hinges are harder to line up) and some clasps, attach the feet.

## Software overview

* Install Node.js and put the Node_server files on a web server that you have ssh access to (I'm using an EC2 micro instance, free for this level of use).
* Open two unique ports (in this example, '4321' for the socket, and '1234' for the web app)
* Change line 9 of client.js and line 5 of device-server.js to use your server URL and socket port number
* Change line 16 of app.js to use your web app port number
* Launch app.js with Node - I haven't figured out how to set it up as a daemon yet, so I just run "nohup node app.js &" to keep it running.  That's not the right way to do it, though.
* You should be able to load the app at yourserver.com:1234 and see the slider.
* Follow the RedBearLab instructions for setting up the Blend Micro with the Arduino IDE
* Test your hardware by downloading and running the BLEController app and matching Arduino sketch.  You should be able to rotate the servo from the iOS app.
* Load the RMT4k Arduino sketch onto the Blend Micro
* Install everything you need to be able to run XCode and CocoaPods (do you need a Mac for this?  I don't know.)
* Open the RMT4k.xcworkspace file (not the .xcodeproj file).  Edit the RMTController/Config.h file to match your Node server and port.
* Build the project to your (Bluetooth 4, see below) iPad (this requires either the $99 ADC account, which I already had, or jailbreaking your iPad.  I can't just put this app on the App Store, because it uses backgrounding in a way that would get rejected).
* Power up the Arduino and servo, launch the app, load up yourserver.com:1234.  You should be able to rotate the stand left and right.

## iPad compatibility

This assumes you're using an iPad with Bluetooth 4, to interface with the Blend Micro's onboard BLE chip.
If you're using a pre-BLE iPad, you're going to need to use a different Arudino product, and rewrite
the iOS/Arduino software to match the different hardware.


## DISCLAIMER

THESE FILES ARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE FILES OR THE USE
OR OTHER DEALINGS IN THE FILES.
