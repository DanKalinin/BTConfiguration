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

static NSString *const BTErrorsTable = @"Errors";

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
        
        NSNumber *attempts = self.dictionary[BTConnection][BTAttempts];
        self.attempts = attempts ? attempts.unsignedIntegerValue : 1;
        
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

@property NSError *notAllServicesDiscoveredError;
@property NSError *notAllCharacteristicsDiscoveredError;

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

#pragma mark - Helpers

- (void)prepareServiceDictionaries {
    
    self.targetServices = self.centralManger.configuration.dictionary[BTServices];
    self.currentServices = self.targetServices.deepMutableCopy;
    
    NSString *serviceNameKeyPath;
    NSString *characteristicNameKeyPath;
    NSString *characteristicNotifyKeyPath;
    
    for (NSString *service in self.targetServices.allKeys) {
        
        serviceNameKeyPath = [NSString stringWithFormat:@"%@.%@", service, BTName];
        [self.currentServices setValue:nil forKeyPath:serviceNameKeyPath];
        
        NSDictionary *targetCharacteristics = self.targetServices[service][BTCharacteristics];
        for (NSString *characteristic in targetCharacteristics.allKeys) {
            
            characteristicNameKeyPath = [NSString stringWithFormat:@"%@.%@.%@.%@", service, BTCharacteristics, characteristic, BTName];
            characteristicNotifyKeyPath = [NSString stringWithFormat:@"%@.%@.%@.%@", service, BTCharacteristics, characteristic, BTNotify];
            [self.currentServices setValue:nil forKeyPath:characteristicNameKeyPath];
            NSNumber *notify = [self.targetServices valueForKeyPath:characteristicNotifyKeyPath];
            notify = notify ? @NO : nil;
            [self.currentServices setValue:notify forKeyPath:characteristicNotifyKeyPath];
        }
    }
}

- (BOOL)discoveryCompleted {
    BOOL completed = [self.currentServices isEqualToDictionary:self.targetServices];
    return completed;
}

- (void)didConnect:(NSError *)error {
    id <BTCentralManagerDelegate> delegate = (id)self.centralManger.delegate;
    [delegate centralManager:self.centralManger didConnectPeripheral:self error:error];
}

@end



@implementation BTPeripheralDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *key = NSStringFromSelector(@selector(notAllServicesDiscoveredError));
        NSString *description = [self.bundle localizedStringForKey:key value:key table:BTErrorsTable];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = description;
        self.notAllServicesDiscoveredError = [NSError errorWithDomain:BTErrorDomain code:0 userInfo:userInfo];
        
        key = NSStringFromSelector(@selector(notAllCharacteristicsDiscoveredError));
        description = [self.bundle localizedStringForKey:key value:key table:BTErrorsTable];
        userInfo[NSLocalizedDescriptionKey] = description;
        self.notAllCharacteristicsDiscoveredError = [NSError errorWithDomain:BTErrorDomain code:0 userInfo:userInfo];
    }
    return self;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    [peripheral prepareServiceDictionaries];
    
    if (peripheral.services.count != peripheral.targetServices.count) {
        error = self.notAllServicesDiscoveredError;
    }
    
    if (error) {
        [peripheral didConnect:error];
    } else {
        NSMutableDictionary *servicesByName = [NSMutableDictionary dictionary];
        for (CBService *service in peripheral.services) {
            NSArray *characheristics = [peripheral.centralManger.configuration characteristicsForService:service];
            [peripheral discoverCharacteristics:characheristics forService:service];
            
            NSString *name = [peripheral.centralManger.configuration nameForService:service];
            servicesByName[name] = service;
            
            peripheral.currentServices[service.UUID.UUIDString][BTName] = name;
        }
        peripheral.servicesByName = servicesByName;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    NSDictionary *targetCharacteristics = peripheral.targetServices[service.UUID.UUIDString][BTCharacteristics];
    
    if (service.characteristics.count != targetCharacteristics.count) {
        error = self.notAllCharacteristicsDiscoveredError;
    }
    
    if (error) {
        [peripheral didConnect:error];
    } else {
        NSMutableDictionary *characteristicsByName = [NSMutableDictionary dictionary];
        for (CBCharacteristic *characteristic in service.characteristics) {
            BOOL notify = [peripheral.centralManger.configuration notifyValueForCharacteristic:characteristic forService:service];
            if (notify) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            NSString *name = [peripheral.centralManger.configuration nameForCharacteristic:characteristic forService:service];
            characteristicsByName[name] = characteristic;
            
            peripheral.currentServices[service.UUID.UUIDString][BTCharacteristics][characteristic.UUID.UUIDString][BTName] = name;
        }
        service.characteristicsByName = characteristicsByName;
        
        if (peripheral.discoveryCompleted) {
            [peripheral didConnect:nil];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [peripheral didConnect:error];
    } else {
        peripheral.currentServices[characteristic.service.UUID.UUIDString][BTCharacteristics][characteristic.UUID.UUIDString][BTNotify] = @YES;
        if (peripheral.discoveryCompleted) {
            [peripheral didConnect:nil];
        }
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

@property NSError *timeoutExpirationError;

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
    peripheral.centralManger = self;
    [self connectPeripheral:peripheral timeout:self.configuration.timeout attempts:self.configuration.attempts];
}

- (NSArray<CBPeripheral *> *)connectedPeripherals {
    NSArray *peripherals = [self retrieveConnectedPeripheralsWithServices:self.configuration.services];
    return peripherals;
}

#pragma mark - Helpers

- (void)connectPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout attempts:(NSUInteger)attempts {
    
    [self connectPeripheral:peripheral options:self.configuration.connectionOptions];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.configuration.timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (peripheral.state == CBPeripheralStateConnected) return;
        
        [self cancelPeripheralConnection:peripheral];
        
        NSUInteger a = attempts - 1;
        if (a > 0) {
            [self connectPeripheral:peripheral timeout:timeout attempts:a];
        } else {
            [peripheral didConnect:self.centralManagerDelegate.timeoutExpirationError];
        }
    });
}

@end



@implementation BTCentralManagerDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *key = NSStringFromSelector(@selector(timeoutExpirationError));
        NSString *description = [self.bundle localizedStringForKey:key value:key table:BTErrorsTable];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = description;
        self.timeoutExpirationError = [NSError errorWithDomain:BTErrorDomain code:0 userInfo:userInfo];
    }
    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = nil;
    [peripheral discoverServices];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [peripheral didConnect:error];
}

@end
