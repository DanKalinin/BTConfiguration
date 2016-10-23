//
//  UARTCentralManager.m
//  Framework
//
//  Created by Dan Kalinin on 22/10/16.
//  Copyright © 2016 Dan Kalinin. All rights reserved.
//

#import "BTConfiguration.h"
#import <Helpers/Helpers.h>
#import <objc/runtime.h>

@class BTCentralManagerDelegate, BTPeripheralDelegate;

NSString *const BTErrorDomain = @"BTErrorDomain";

static NSString *const BTInitialization = @"initialization";
static NSString *const BTShowPowerAlert = @"showPowerAlert";
static NSString *const BTRestoreIdentifier = @"restoreIdentifier";

static NSString *const BTScanning = @"scanning";
static NSString *const BTAllowDuplicates = @"allowDuplicates";
static NSString *const BTSolicitedServices = @"solicitedServices";

static NSString *const BTConnection = @"connection";
static NSString *const BTNotifyOnConnection = @"notifyOnConnection";
static NSString *const BTNotifyOnDisconnection = @"notifyOnDisconnection";
static NSString *const BTNotifyOnNotification = @"notifyOnNotification";
static NSString *const BTTimeout = @"timeout";
static NSString *const BTAttempts = @"attempts";

static NSString *const BTName = @"name";
static NSString *const BTServices = @"services";
static NSString *const BTCharacteristics = @"characteristics";
static NSString *const BTNotify = @"notify";










@interface BTConfiguration ()

@property NSDictionary *dictionary;

@end



@implementation BTConfiguration

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
    self = [super init];
    if (self) {
        NSString *selector = NSStringFromSelector(@selector(initWithName:bundle:));
        
        bundle = bundle ? bundle : [NSBundle mainBundle];
        NSURL *URL = [bundle URLForResource:name withExtension:JSONExtension];
        NSAssert(URL, selector);
        
        NSData *data = [NSData dataWithContentsOfURL:URL];
        NSAssert(data, selector);
        
        NSError *error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves) error:&error];
        NSAssert(object, error.localizedDescription);
        
        // TODO: Validation
        
        self.dictionary = object;
    }
    return self;
}

#pragma mark - Helpers

- (NSArray<CBUUID *> *)UUIDsWithStrings:(NSArray<NSString *> *)strings {
    NSMutableArray *UUIDs = strings.mutableCopy;
    for (NSUInteger index = 0; index < UUIDs.count; index++) {
        NSString *string = UUIDs[index];
        CBUUID *UUID = [CBUUID UUIDWithString:string];
        [UUIDs replaceObjectAtIndex:index withObject:UUID];
    }
    return UUIDs;
}

@end










@interface BTCentralConfiguration ()

@property NSDictionary *initializationOptions;
@property NSDictionary *scanningOptions;
@property NSDictionary *connectionOptions;

@property NSTimeInterval timeout;
@property NSUInteger attempts;
@property SEL completion;

@property NSArray<CBUUID *> *services;
- (NSString *)nameForService:(CBService *)service;

- (NSArray<CBUUID *> *)characteristicsForService:(CBService *)service;
- (NSString *)nameForCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service;
- (BOOL)notifyValueForCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service;

@end



@implementation BTCentralConfiguration

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
    self = [super initWithName:name bundle:bundle];
    if (self) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[CBCentralManagerOptionShowPowerAlertKey] = self.dictionary[BTInitialization][BTShowPowerAlert];
        options[CBCentralManagerOptionRestoreIdentifierKey] = self.dictionary[BTInitialization][BTRestoreIdentifier];
        self.initializationOptions = options;
        
        options = [NSMutableDictionary dictionary];
        options[CBCentralManagerScanOptionAllowDuplicatesKey] = self.dictionary[BTScanning][BTAllowDuplicates];
        NSArray *strings = self.dictionary[BTScanning][BTSolicitedServices];
        options[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = [self UUIDsWithStrings:strings];
        self.scanningOptions = options;
        
        options = [NSMutableDictionary dictionary];
        options[CBConnectPeripheralOptionNotifyOnConnectionKey] = self.dictionary[BTConnection][BTNotifyOnConnection];
        options[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = self.dictionary[BTConnection][BTNotifyOnDisconnection];
        options[CBConnectPeripheralOptionNotifyOnNotificationKey] = self.dictionary[BTConnection][BTNotifyOnNotification];
        self.connectionOptions = options;
        
        NSNumber *timeout = self.dictionary[BTConnection][BTTimeout];
        self.timeout = timeout ? timeout.doubleValue : DBL_MAX;
        
        NSNumber *attempts = self.dictionary[BTAttempts];
        self.attempts = attempts.unsignedIntegerValue;
        
        NSDictionary *services = self.dictionary[BTServices];
        self.services = [self UUIDsWithStrings:services.allKeys];
    }
    return self;
}

- (NSString *)nameForService:(CBService *)service {
    NSString *name = self.dictionary[BTServices][service.UUID.UUIDString][BTName];
    return name;
}

- (NSArray<CBUUID *> *)characteristicsForService:(CBService *)service {
    NSDictionary *characteristics = self.dictionary[BTServices][service.UUID.UUIDString][BTCharacteristics];
    return [self UUIDsWithStrings:characteristics.allKeys];
}

- (NSString *)nameForCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service {
    NSString *name = self.dictionary[BTServices][service.UUID.UUIDString][BTCharacteristics][characteristic.UUID.UUIDString][BTName];
    return name;
}

- (BOOL)notifyValueForCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service {
    NSNumber *notify = self.dictionary[BTServices][service.UUID.UUIDString][BTCharacteristics][characteristic.UUID.UUIDString][BTNotify];
    return notify.boolValue;
}

//// Initialization options
//
//- (BOOL)showPowerAlert {
//    NSNumber *showPowerAlert = self.configuration[NSStringFromSelector(@selector(showPowerAlert))];
//    return showPowerAlert.boolValue;
//}
//
//- (NSString *)restoreIdentifier {
//    return self.configuration[NSStringFromSelector(@selector(restoreIdentifier))];
//}
//
//// Scanning options
//
//- (BOOL)allowDuplicates {
//    NSNumber *allowDuplicates = self.configuration[NSStringFromSelector(@selector(allowDuplicates))];
//    return allowDuplicates.boolValue;
//}
//
//- (NSArray<CBUUID *> *)solicitedServices {
//    if (_solicitedServices) return _solicitedServices;
//    
//    NSArray *solicitedServices = self.configuration[NSStringFromSelector(@selector(solicitedServices))];
//    solicitedServices = [self UUIDsWithStrings:solicitedServices];
//    _solicitedServices = solicitedServices;
//    return solicitedServices;
//}
//
//// Connection options
//
//- (BOOL)notifyOnConnection {
//    NSNumber *notifyOnConnection = self.configuration[NSStringFromSelector(@selector(notifyOnConnection))];
//    return notifyOnConnection.boolValue;
//}
//
//- (BOOL)notifyOnDisconnection {
//    NSNumber *notifyOnDisconnection = self.configuration[NSStringFromSelector(@selector(notifyOnDisconnection))];
//    return notifyOnDisconnection.boolValue;
//}
//
//- (BOOL)notifyOnNotification {
//    NSNumber *notifyOnNotification = self.configuration[NSStringFromSelector(@selector(notifyOnNotification))];
//    return notifyOnNotification.boolValue;
//}

@end










#pragma mark - Service

@interface CBService (BTConfiguration)

@property NSDictionary *characteristicsByName;

@end



@implementation CBService (BTConfiguration)

- (void)setCharacteristicsByName:(NSDictionary *)characteristicsByName {
    objc_setAssociatedObject(self, @selector(characteristicsByName), characteristicsByName, OBJC_ASSOCIATION_RETAIN);
}

- (NSDictionary *)characteristicsByName {
    return objc_getAssociatedObject(self, @selector(characteristicsByName));
}

- (CBCharacteristic *)objectForKeyedSubscript:(NSString *)name {
    CBCharacteristic *characteristic = self.characteristicsByName[name];
    return characteristic;
}

@end










#pragma mark - Peripheral

@interface CBPeripheral (BTConfigurationSelectors)

@property (weak) CBCentralManager *centralManger;

@property SurrogateContainer *delegates;
@property BTPeripheralDelegate *peripheralDelegate;

@property NSDictionary *servicesByName;

@property NSDictionary *targetServices;
@property NSDictionary *currentServices;

@end



@interface BTPeripheralDelegate : NSObject <CBPeripheralDelegate>

@end










@implementation CBPeripheral (BTConfiguration)

+ (void)load {
    SEL swizzling = @selector(setDelegate:);
    SEL swizzled = @selector(swizzledSetDelegate:);
    [self swizzleInstanceMethod:swizzling with:swizzled];
}

- (void)swizzledSetDelegate:(id<CBPeripheralDelegate>)delegate {
    self.delegates = [SurrogateContainer new];
    self.peripheralDelegate = [BTPeripheralDelegate new];
    if (delegate) {
        self.delegates.objects = @[self.peripheralDelegate, delegate];
    } else {
        self.delegates.objects = @[self.peripheralDelegate];
    }
    [self swizzledSetDelegate:(id)self.delegates];
}

- (void)setCentralManger:(CBCentralManager *)centralManger {
    objc_setAssociatedObject(self, @selector(centralManger), centralManger, OBJC_ASSOCIATION_ASSIGN);
}

- (CBCentralManager *)centralManger {
    return objc_getAssociatedObject(self, @selector(centralManger));
}

- (void)setDelegates:(SurrogateContainer *)delegates {
    objc_setAssociatedObject(self, @selector(delegates), delegates, OBJC_ASSOCIATION_RETAIN);
}

- (SurrogateContainer *)delegates {
    return objc_getAssociatedObject(self, @selector(delegates));
}

- (void)setPeripheralDelegate:(BTPeripheralDelegate *)peripheralDelegate {
    objc_setAssociatedObject(self, @selector(peripheralDelegate), peripheralDelegate, OBJC_ASSOCIATION_RETAIN);
}

- (BTPeripheralDelegate *)peripheralDelegate {
    return objc_getAssociatedObject(self, @selector(peripheralDelegate));
}

- (void)setServicesByName:(NSDictionary *)servicesByName {
    objc_setAssociatedObject(self, @selector(servicesByName), servicesByName, OBJC_ASSOCIATION_RETAIN);
}

- (NSDictionary *)servicesByName {
    return objc_getAssociatedObject(self, @selector(servicesByName));
}

- (void)setTargetServices:(NSDictionary *)targetServices {
    objc_setAssociatedObject(self, @selector(targetServices), targetServices, OBJC_ASSOCIATION_RETAIN);
}

- (NSDictionary *)targetServices {
    return objc_getAssociatedObject(self, @selector(targetServices));
}

- (void)setCurrentServices:(NSDictionary *)currentServices {
    objc_setAssociatedObject(self, @selector(currentServices), currentServices, OBJC_ASSOCIATION_RETAIN);
}

- (NSDictionary *)currentServices {
    return objc_getAssociatedObject(self, @selector(currentServices));
}

- (void)discoverServices {
    [self discoverServices:self.centralManger.configuration.services];
}

- (CBService *)objectForKeyedSubscript:(NSString *)name {
    CBService *service = self.servicesByName[name];
    return service;
}

@end



@implementation BTPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    peripheral.targetServices = peripheral.centralManger.configuration.dictionary[BTServices];
    peripheral.targetServices = peripheral.targetServices.copy;
    if (peripheral.services.count != peripheral.targetServices.count) {
        // TODO: Set error
    }
    
    if (error) {
        // TODO: Handle error
    } else {
        NSMutableDictionary *servicesByName = [NSMutableDictionary dictionary];
        NSMutableDictionary *currentServices = [NSMutableDictionary dictionary];
        for (CBService *service in peripheral.services) {
            NSArray *characheristics = [peripheral.centralManger.configuration characteristicsForService:service];
            [peripheral discoverCharacteristics:characheristics forService:service];
            
            NSString *name = [peripheral.centralManger.configuration nameForService:service];
            servicesByName[name] = service;
            
            currentServices[service.UUID.UUIDString] = [NSMutableDictionary dictionary];
            currentServices[service.UUID.UUIDString][BTName] = peripheral.targetServices[service.UUID.UUIDString][BTName];
        }
        peripheral.servicesByName = servicesByName;
        peripheral.currentServices = currentServices;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        // TODO: Handle error
    } else {
        NSMutableDictionary *characteristicsByName = [NSMutableDictionary dictionary];
        for (CBCharacteristic *characteristic in service.characteristics) {
            BOOL notify = [peripheral.centralManger.configuration notifyValueForCharacteristic:characteristic forService:service];
            if (notify) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            NSString *name = [peripheral.centralManger.configuration nameForCharacteristic:characteristic forService:service];
            characteristicsByName[name] = characteristic;
            
        }
        service.characteristicsByName = characteristicsByName;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        
    } else {
        
    }
}

@end










#pragma mark - Central manager

@interface CBCentralManager (BTConfigurationSelectors)

@property BTCentralConfiguration *configuration;

@property SurrogateContainer *delegates;
@property BTCentralManagerDelegate *centralManagerDelegate;

@end



@interface BTCentralManagerDelegate : NSObject <BTCentralManagerDelegate>

@end










@implementation CBCentralManager (BTConfiguration)

+ (void)load {
    SEL swizzling = @selector(setDelegate:);
    SEL swizzled = @selector(swizzledSetDelegate:);
    [self swizzleInstanceMethod:swizzling with:swizzled];
}

- (void)swizzledSetDelegate:(id<CBCentralManagerDelegate>)delegate {
    self.delegates = [SurrogateContainer new];
    self.centralManagerDelegate = [BTCentralManagerDelegate new];
    if (delegate) {
        self.delegates.objects = @[self.centralManagerDelegate, delegate];
    } else {
        self.delegates.objects = @[self.centralManagerDelegate];
    }
    [self swizzledSetDelegate:(id)self.delegates];
}

- (void)setConfiguration:(BTCentralConfiguration *)configuration {
    objc_setAssociatedObject(self, @selector(configuration), configuration, OBJC_ASSOCIATION_RETAIN);
}

- (BTCentralConfiguration *)configuration {
    return objc_getAssociatedObject(self, @selector(configuration));
}

- (void)setDelegates:(SurrogateContainer *)delegates {
    objc_setAssociatedObject(self, @selector(delegates), delegates, OBJC_ASSOCIATION_RETAIN);
}

- (SurrogateContainer *)delegates {
    return objc_getAssociatedObject(self, @selector(delegates));
}

- (void)setCentralManagerDelegate:(BTCentralManagerDelegate *)centralManagerDelegate {
    objc_setAssociatedObject(self, @selector(centralManagerDelegate), centralManagerDelegate, OBJC_ASSOCIATION_RETAIN);
}

- (BTCentralManagerDelegate *)centralManagerDelegate {
    return objc_getAssociatedObject(self, @selector(centralManagerDelegate));
}

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue configuration:(BTCentralConfiguration *)configuration {
    self = [self initWithDelegate:delegate queue:queue options:configuration.initializationOptions];
    if (self) {
        self.configuration = configuration;
    }
    return self;
}

- (void)scanForPeripherals {
    [self scanForPeripheralsWithServices:self.configuration.services options:self.configuration.scanningOptions];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    [self connectPeripheral:peripheral options:self.configuration.connectionOptions];
}

@end



@implementation BTCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.centralManger = central;
    peripheral.delegate = nil;
    [peripheral discoverServices];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

@end
