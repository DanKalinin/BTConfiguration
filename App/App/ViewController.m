//
//  ViewController.m
//  App
//
//  Created by Dan Kalinin on 22/10/16.
//  Copyright © 2016 Dan Kalinin. All rights reserved.
//

#import "ViewController.h"
#import <BTConfiguration/BTConfiguration.h>



@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property CBCentralManager *cm;
@property CBPeripheral *peripheral;

@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BTCentralConfiguration *configuration = [[BTCentralConfiguration alloc] initWithName:@"CentralConfiguration" bundle:nil];
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil configuration:configuration];
}

#pragma mark - Actions

- (IBAction)onConnect:(UIButton *)sender {
    [self.cm stopScan];
    [self.cm connectPeripheral:self.peripheral];
}

#pragma mark - Central manager

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [central scanForPeripherals];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([peripheral.name isEqualToString:@"RG-G1S"]) {
        self.peripheral = peripheral;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
}

@end
