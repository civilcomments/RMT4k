/*
 
 Copyright (c) 2013-2014 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "MainViewController.h"

@implementation MainViewController
@synthesize ble;
@synthesize protocol;

uint8_t total_pin_count  = 0;
uint8_t pin_mode[128]    = {0};
uint8_t pin_cap[128]     = {0};
uint8_t pin_digital[128] = {0};
uint16_t pin_analog[128]  = {0};
uint8_t pin_pwm[128]     = {0};
uint8_t pin_servo[128]   = {0};

uint8_t init_done = 0;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
    
    protocol = [[RBLProtocol alloc] init];
    protocol.delegate = self;
    protocol.ble = ble;
    
    self.mDevices = [[NSMutableArray alloc] init];
    self.mDevicesName = [[NSMutableArray alloc] init];
    
    [activityScanning startAnimating];
    [self.deviceStatus setText:[[NSString alloc]initWithFormat:@"Servo: Connecting..."]];
    [self.socketStatus setText:[[NSString alloc]initWithFormat:@"Socket: Not connected"]];
    [socketConnect setEnabled:true];
    [self performSelector:@selector(getPeripherals) withObject:nil afterDelay:3];
    [self performSelector:@selector(connectionTimer:) withObject:nil afterDelay:5];
    [self performSelector:@selector(getSocket) withObject:nil afterDelay:7];
    
    [protocol setPinMode:3 Mode:SERVO];
    
}

-(void)getPeripherals {
    NSLog(@"\n\nGetPeripherals\n\n");
    [ble findBLEPeripherals:3];
    NSLog(@"\n\nDone\n\n");
}

-(void)getSocket {
    NSString *socketHost = [Config getSocketHost];
    NSLog(@"host name: %@", socketHost);
    
    uint16_t socketPort = [Config getSocketPort];
    
    NSLog(@"host port: %hu", socketPort);
    
    NSError *err = nil;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    if (![asyncSocket connectToHost:socketHost onPort:socketPort withTimeout:-1 error:&err])
    {
        NSLog(@"Error connecting: %@", err);
        [self.socketStatus setText:[[NSString alloc]initWithFormat:@"Socket: Not connected"]];
        [socketConnect setEnabled:true];
    }
    
    NSLog(@"Ready");

    [asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

-(NSString *)getUUIDString:(CFUUIDRef)ref {
    NSString *str = [NSString stringWithFormat:@"%@", ref];
    return [[NSString stringWithFormat:@"%@", str] substringWithRange:NSMakeRange(str.length - 36, 36)];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [self.socketStatus setText:[[NSString alloc]initWithFormat:@"Socket: Connected"]];
    [socketConnect setEnabled:false];
    NSLog(@"I is connected to socket. Is you?");
    [sock performBlock:^{
        if ([sock enableBackgroundingOnSocket])
        {
            NSLog(@"Backgrounding enabled");
        } else
        {
            NSLog(@"Backgrounding NOT enabled");
        };
    }];
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
    NSError *e = nil;
    NSDictionary *JSON = [NSJSONSerialization
                          JSONObjectWithData: data
                          options: NSJSONReadingMutableContainers
                          error: &e];
    
    if ([JSON[@"command"] isEqual: @"restart"])
    {
        [self performSelector:@selector(reconnectDevice) withObject:nil];
    } else if ([JSON[@"command"] isEqual: @"angle"]) {
        int int_angle = [JSON[@"angle"] intValue];
        uint8_t pin = 3;
        NSLog(@"value: %d", int_angle);
        [protocol servoWrite:pin Value:int_angle];
    } else {
        NSLog(@"unknown command: %@", JSON);
    }
    NSString *msg = @"HELLO";

    NSData *dataOut = [msg dataUsingEncoding:NSASCIIStringEncoding];
    [asyncSocket writeData:dataOut withTimeout:-1 tag:1];
}

- (void)reconnectDevice {
    // First check to see if the power cord is plugged in.  If it's not, try to send a "not plugged in" message
    // Then disconnect the device and go through the finding/reconnecting process.
    NSLog(@"\n\nrestart\n\n");
    [self.deviceStatus setText:[[NSString alloc]initWithFormat:@"Servo: Not connected"]];
    [self performSelector:@selector(getPeripherals) withObject:nil afterDelay:3];
    [self performSelector:@selector(connectionTimer:) withObject:nil afterDelay:5];
    NSString *msg = @"RECONNECTING";
    NSData *dataOut = [msg dataUsingEncoding:NSASCIIStringEncoding];
    [asyncSocket writeData:dataOut withTimeout:-1 tag:1];
}

- (void)viewWillAppear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) connectionTimer:(NSTimer *)timer
{
    NSString *storedName = [Config getStoredName];
    showAlert = YES;
    [btnConnect setEnabled:YES];
    
    NSLog(@"\n\ncheck for peripherals\n\n");
    if (ble.peripherals.count > 0)
    {
        {
            NSLog(@"\n\ntrying to connect\n\n");
            int i;
            for (i = 0; i < ble.peripherals.count; i++)
            {
                CBPeripheral *p = [ble.peripherals objectAtIndex:i];
                NSLog(@"\n\Name of device: %@", p.name);
                if (p.name != NULL)
                {
                    //Comparing UUIDs and call connectPeripheral is matched
                    if([storedName isEqualToString:p.name])
                    {
                        showAlert = NO;
                        [ble connectPeripheral:p];
                    }
                }
            }
        }
    }
  
    if (showAlert == YES) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Is this thing plugged in?"
                                                       delegate:nil
                                              cancelButtonTitle:@"Yes"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [activityScanning stopAnimating];
}

- (IBAction)btnConnectClicked:(id)sender
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [activityScanning startAnimating];
    [btnConnect setEnabled:false];
    [ble findBLEPeripherals:3];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

- (IBAction)socketConnectClicked:(id)sender
{
    [socketConnect setEnabled:false];
    [self performSelector:@selector(getSocket) withObject:nil];    
}


-(void) bleDidConnect
{
    NSLog(@"->DidConnect");
    [self.deviceStatus setText:[[NSString alloc]initWithFormat:@"Servo: Connected"]];
    [self.btnConnect setTitle:@"Reconnect to Servo" forState:UIControlStateNormal];
    [activityScanning stopAnimating];
}

- (void)bleDidDisconnect
{
    NSLog(@"->DidDisconnect");
    [self.deviceStatus setText:[[NSString alloc]initWithFormat:@"Servo: Not connected"]];
    [self.btnConnect setTitle:@"Connect to Servo" forState:UIControlStateNormal];
    [activityScanning stopAnimating];
}

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    [self processData:data length:length];
}

-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
}

NSTimer *syncTimer;

-(void) syncTimeout:(NSTimer *)timer
{
    NSLog(@"Timeout: no response");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"No response from the BLE Controller sketch."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    // disconnect it
    [ble.CM cancelPeripheralConnection:ble.activePeripheral];
}



-(void) processData:(uint8_t *) data length:(uint8_t) length
{    
    [protocol parseData:data length:length];
}

-(void) protocolDidReceiveProtocolVersion:(uint8_t)major Minor:(uint8_t)minor Bugfix:(uint8_t)bugfix
{
    NSLog(@"protocolDidReceiveProtocolVersion: %d.%d.%d", major, minor, bugfix);
    
    // get response, so stop timer
    [syncTimer invalidate];
    
    uint8_t buf[] = {'B', 'L', 'E'};
    [protocol sendCustomData:buf Length:3];
    
    [protocol queryTotalPinCount];
}

-(void) protocolDidReceiveTotalPinCount:(UInt8) count
{
    NSLog(@"protocolDidReceiveTotalPinCount: %d", count);
    
    total_pin_count = count;
    [protocol queryPinAll];
}

-(void) protocolDidReceivePinCapability:(uint8_t)pin Value:(uint8_t)value
{
    NSLog(@"protocolDidReceivePinCapability");
    NSLog(@" Pin %d Capability: 0x%02X", pin, value);
    
    if (value == 0)
        NSLog(@" - Nothing");
    else
    {
        if (value & PIN_CAPABILITY_DIGITAL)
            NSLog(@" - DIGITAL (I/O)");
        if (value & PIN_CAPABILITY_ANALOG)
            NSLog(@" - ANALOG");
        if (value & PIN_CAPABILITY_PWM)
            NSLog(@" - PWM");
        if (value & PIN_CAPABILITY_SERVO)
            NSLog(@" - SERVO");
    }
    
    pin_cap[pin] = value;
}

-(void) protocolDidReceivePinData:(uint8_t)pin Mode:(uint8_t)mode Value:(uint8_t)value
{
    //    NSLog(@"protocolDidReceiveDigitalData");
    //    NSLog(@" Pin: %d, mode: %d, value: %d", pin, mode, value);
    
    uint8_t _mode = mode & 0x0F;
    
    pin_mode[pin] = _mode;
    if ((_mode == INPUT) || (_mode == OUTPUT))
        pin_digital[pin] = value;
    else if (_mode == ANALOG)
        pin_analog[pin] = ((mode >> 4) << 8) + value;
    else if (_mode == PWM)
        pin_pwm[pin] = value;
    else if (_mode == SERVO)
        pin_servo[pin] = value;
}

-(void) protocolDidReceivePinMode:(uint8_t)pin Mode:(uint8_t)mode
{
    NSLog(@"protocolDidReceivePinMode");
    
    if (mode == INPUT)
        NSLog(@" Pin %d Mode: INPUT", pin);
    else if (mode == OUTPUT)
        NSLog(@" Pin %d Mode: OUTPUT", pin);
    else if (mode == PWM)
        NSLog(@" Pin %d Mode: PWM", pin);
    else if (mode == SERVO)
        NSLog(@" Pin %d Mode: SERVO", pin);
    
    pin_mode[pin] = mode;
}

-(void) protocolDidReceiveCustomData:(UInt8 *)data length:(UInt8)length
{
    // Handle your customer data here.
    for (int i = 0; i< length; i++)
        printf("0x%2X ", data[i]);
    printf("\n");
}


@end
