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

static NSString *const BTServices = @"services";










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

@property NSArray<CBUUID *> *services;

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
        self.dictionary = options;
        
        NSDictionary *services = self.dictionary[BTServices];
        self.services = [self UUIDsWithStrings:services.allKeys];
    }
    return self;
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










#pragma mark - Central manager

@interface CBCentralManager (BTConfigurationSelectors)

@property BTCentralConfiguration *configuration;

@end



@implementation CBCentralManager (BTConfiguration)

- (void)setConfiguration:(BTCentralConfiguration *)configuration {
    objc_setAssociatedObject(self, @selector(configuration), configuration, OBJC_ASSOCIATION_RETAIN);
}

- (BTCentralConfiguration *)configuration {
    return objc_getAssociatedObject(self, @selector(configuration));
}

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue configuration:(BTCentralConfiguration *)configuration {
    self = [self initWithDelegate:delegate queue:queue options:configuration.initializationOptions];
    self.configuration = configuration;
    return self;
}

- (void)scanForPeripherals {
    [self scanForPeripheralsWithServices:self.configuration.services options:self.configuration.scanningOptions];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    [self connectPeripheral:peripheral options:self.configuration.connectionOptions];
}

@end
