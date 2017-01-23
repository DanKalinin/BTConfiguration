//
//  UARTCentralManager.h
//  Framework
//
//  Created by Dan Kalinin on 22/10/16.
//  Copyright © 2016 Dan Kalinin. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

FOUNDATION_EXPORT double BTConfigurationVersionNumber;
FOUNDATION_EXPORT const unsigned char BTConfigurationVersionString[];

extern NSString *const BTErrorDomain;

typedef NS_ENUM(NSInteger, BTError) {
    BTErrorNotAllServicesDiscovered = 0,
    BTErrorNotAllCharacteristicsDiscovered = 1,
    BTErrorConnectionTimedOut = 2
};










#pragma mark - Configuration

@interface BTConfiguration : NSObject

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle;

@end










@interface BTCentralConfiguration : BTConfiguration

@end










#pragma mark - Central manager

@interface CBCentralManager (BTConfiguration)

@property (readonly) BTCentralConfiguration *configuration;
@property (readonly) NSArray<CBPeripheral *> *connectedPeripherals;

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue configuration:(BTCentralConfiguration *)configuration;
- (void)scanForPeripherals;
- (void)connectPeripheral:(CBPeripheral *)peripheral;

@end












@interface CBPeripheral (BTConfiguration)

- (void)discoverServices;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic;

- (CBService *)objectForKeyedSubscript:(NSString *)name;

@end










@interface CBService (BTConfiguration)

- (CBCharacteristic *)objectForKeyedSubscript:(NSString *)name;

@end










@protocol BTCentralManagerDelegate <CBCentralManagerDelegate>

@optional
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end










@protocol BTPeripheralDelegate <CBPeripheralDelegate>

@optional
- (void)peripheral:(CBPeripheral *)peripheral didDisconnectWithError:(NSError *)error;

@end
