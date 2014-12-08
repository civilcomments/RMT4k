/*
 
 Copyright (c) 2013-2014 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <UIKit/UIKit.h>
#import "BLE.h"
#import "GCDAsyncSocket.h"
#import "RBLProtocol.h"
#import "Config.h"

@interface MainViewController : UIViewController <BLEDelegate, ProtocolDelegate>
{
    IBOutlet UIActivityIndicatorView *activityScanning;
    IBOutlet UIButton *btnConnect;
    IBOutlet UIButton *socketConnect;
    IBOutlet UILabel *deviceStatus;
    IBOutlet UILabel *socketStatus;
    IBOutlet UILabel *lblVersion;
    BOOL showAlert;
    bool isFindingLast;
    GCDAsyncSocket *asyncSocket;
}

@property (strong, nonatomic) BLE *ble;
@property (strong, nonatomic) RBLProtocol *protocol;
@property (strong, nonatomic) NSMutableArray *mDevices;
@property (strong, nonatomic) NSMutableArray *mDevicesName;
@property(nonatomic, retain)UILabel* deviceStatus;
@property(nonatomic, retain)UILabel* socketStatus;
@property(nonatomic, retain)UIButton* btnConnect;
@property(nonatomic, retain)UIButton* socketConnect;



-(void) processData:(uint8_t *) data length:(uint8_t) length;

@end
