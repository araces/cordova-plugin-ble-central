//
//  BLECentralPlugin.m
    //  BLE Central Cordova Plugin
    //
//  (c) 2104-2016 Don Coleman
    //
// Licensed under the Apache License, Version 2.0 (the "License");
    // you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
    //
//     http://www.apache.org/licenses/LICENSE-2.0
    //
// Unless required by applicable law or agreed to in writing, software
    // distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
    // limitations under the License.

    #import "BLECentralPlugin.h"
#import "KeyMapping.h"
#import <Cordova/CDV.h>

    #define deviceService_version_1 @"ffe0"
#define deviceCharacteristic_version_1 @"ffe1"

#define deviceService_version_2 @"fd00"
#define deviceCharacteristic_version_2 @"fd01"

    @interface BLECentralPlugin() {
  NSDictionary *bluetoothStates;
  Boolean isWriteExtraDataMode;
  Boolean continueWriteData;
  NSString *dataServiceUUID;
  NSString *dataCharacteristicUUID;
  NSString *dataContent;
  NSString *isWord;
  NSString *deviceVersion;

  CBPeripheral *currentPeripheral;
  CBCharacteristic *currentCharacteristic;

  CDVInvokedUrlCommand *writeDataCommand;
}
    - (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)stopScanTimer:(NSTimer *)timer;
    @end

    @implementation BLECentralPlugin

    @synthesize manager;
    @synthesize peripherals;

- (void)pluginInitialize {

  NSLog(@"Cordova BLE Central Plugin");
NSLog(@"(c)2014-2016 Don Coleman");

[super pluginInitialize];

peripherals = [NSMutableSet set];
manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

isWriteExtraDataMode=NO;//是否发送特殊字段
continueWriteData=YES;//是否继续发送

connectCallbacks = [NSMutableDictionary new];
connectCallbackLatches = [NSMutableDictionary new];
readCallbacks = [NSMutableDictionary new];
writeCallbacks = [NSMutableDictionary new];
notificationCallbacks = [NSMutableDictionary new];
stopNotificationCallbacks = [NSMutableDictionary new];
bluetoothStates = [NSDictionary dictionaryWithObjectsAndKeys:
@"unknown", @(CBCentralManagerStateUnknown),
@"resetting", @(CBCentralManagerStateResetting),
@"unsupported", @(CBCentralManagerStateUnsupported),
@"unauthorized", @(CBCentralManagerStateUnauthorized),
@"off", @(CBCentralManagerStatePoweredOff),
@"on", @(CBCentralManagerStatePoweredOn),
nil];
readRSSICallbacks = [NSMutableDictionary new];

[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wirteDataToBleWithWordMode) name:@"foundCharacteristicAndSendTOBLE" object:nil];
}

#pragma mark - Cordova Plugin Methods

    - (void)connect:(CDVInvokedUrlCommand *)command {

  NSLog(@"connect");
NSString *uuid = [command.arguments objectAtIndex:0];

CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

if (peripheral) {
  NSLog(@"Connecting to peripheral with UUID : %@", uuid);

[connectCallbacks setObject:[command.callbackId copy] forKey:[peripheral uuidAsString]];
[manager connectPeripheral:peripheral options:nil];

} else {
  NSString *error = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
NSLog(@"%@", error);
CDVPluginResult *pluginResult = nil;
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

}

// disconnect: function (device_id, success, failure) {
  - (void)disconnect:(CDVInvokedUrlCommand*)command {
    NSLog(@"disconnect");

NSString *uuid = [command.arguments objectAtIndex:0];
CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

[connectCallbacks removeObjectForKey:uuid];

if (peripheral && peripheral.state != CBPeripheralStateDisconnected) {
[manager cancelPeripheralConnection:peripheral];
}

// always return OK
CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// read: function (device_id, service_uuid, characteristic_uuid, success, failure) {
  - (void)read:(CDVInvokedUrlCommand*)command {
    NSLog(@"read");

BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyRead];
if (context) {

  CBPeripheral *peripheral = [context peripheral];
CBCharacteristic *characteristic = [context characteristic];

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
[readCallbacks setObject:[command.callbackId copy] forKey:key];

[peripheral readValueForCharacteristic:characteristic];  // callback sends value
}

}

// write: function (device_id, service_uuid, characteristic_uuid, value, success, failure) {
  - (void)write:(CDVInvokedUrlCommand*)command {

    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyWrite];
NSData *message = [command.arguments objectAtIndex:3]; // This is binary
if (context) {

  if (message != nil) {

    CBPeripheral *peripheral = [context peripheral];
CBCharacteristic *characteristic = [context characteristic];

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
[writeCallbacks setObject:[command.callbackId copy] forKey:key];

// TODO need to check the max length
[peripheral writeValue:message forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];

    // response is sent from didWriteValueForCharacteristic

} else {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"message was null"];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
}

}

// writeWithoutResponse: function (device_id, service_uuid, characteristic_uuid, value, success, failure) {
  - (void)writeWithoutResponse:(CDVInvokedUrlCommand*)command {
    NSLog(@"writeWithoutResponse");

BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyWriteWithoutResponse];
NSData *message = [command.arguments objectAtIndex:3]; // This is binary

if (context) {
  CDVPluginResult *pluginResult = nil;
  if (message != nil) {
    CBPeripheral *peripheral = [context peripheral];
CBCharacteristic *characteristic = [context characteristic];

// TODO need to check the max length
[peripheral writeValue:message forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];

pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"message was null"];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
}

// success callback is called on notification
    // notify: function (device_id, service_uuid, characteristic_uuid, success, failure) {
  - (void)startNotification:(CDVInvokedUrlCommand*)command {
    NSLog(@"registering for notification");

BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyNotify]; // TODO name this better

if (context) {
  CBPeripheral *peripheral = [context peripheral];
CBCharacteristic *characteristic = [context characteristic];

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
NSString *callback = [command.callbackId copy];
[notificationCallbacks setObject: callback forKey: key];

[peripheral setNotifyValue:YES forCharacteristic:characteristic];

}

}

// stopNotification: function (device_id, service_uuid, characteristic_uuid, success, failure) {
  - (void)stopNotification:(CDVInvokedUrlCommand*)command {
    NSLog(@"registering for notification");

BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyNotify]; // TODO name this better

if (context) {
  CBPeripheral *peripheral = [context peripheral];
CBCharacteristic *characteristic = [context characteristic];

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
NSString *callback = [command.callbackId copy];
[stopNotificationCallbacks setObject: callback forKey: key];

[peripheral setNotifyValue:NO forCharacteristic:characteristic];
// callback sent from peripheral:didUpdateNotificationStateForCharacteristic:error:

}

}

- (void)isEnabled:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult = nil;
  int bluetoothState = [manager state];

  BOOL enabled = bluetoothState == CBCentralManagerStatePoweredOn;

  if (enabled) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:bluetoothState];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)scan:(CDVInvokedUrlCommand*)command {

  NSLog(@"scan");
discoverPeripherialCallbackId = [command.callbackId copy];

NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
NSNumber *timeoutSeconds = [command.arguments objectAtIndex:1];
NSMutableArray *serviceUUIDs = [NSMutableArray new];

for (int i = 0; i < [serviceUUIDStrings count]; i++) {
  CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
[serviceUUIDs addObject:serviceUUID];
}

[manager scanForPeripheralsWithServices:serviceUUIDs options:nil];

[NSTimer scheduledTimerWithTimeInterval:[timeoutSeconds floatValue]
target:self
selector:@selector(stopScanTimer:)
userInfo:[command.callbackId copy]
repeats:NO];

}

- (void)startScan:(CDVInvokedUrlCommand*)command {

  NSLog(@"startScan");
discoverPeripherialCallbackId = [command.callbackId copy];
NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
NSMutableArray *serviceUUIDs = [NSMutableArray new];

for (int i = 0; i < [serviceUUIDStrings count]; i++) {
  CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
[serviceUUIDs addObject:serviceUUID];
}

[manager scanForPeripheralsWithServices:serviceUUIDs options:nil];

}

- (void)startScanWithOptions:(CDVInvokedUrlCommand*)command {
  NSLog(@"startScanWithOptions");
discoverPeripherialCallbackId = [command.callbackId copy];
NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
NSMutableArray *serviceUUIDs = [NSMutableArray new];
NSDictionary *options = command.arguments[1];

for (int i = 0; i < [serviceUUIDStrings count]; i++) {
  CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
[serviceUUIDs addObject:serviceUUID];
}

NSMutableDictionary *scanOptions = [NSMutableDictionary new];
NSNumber *reportDuplicates = [options valueForKey: @"reportDuplicates"];
if (reportDuplicates) {
[scanOptions setValue:reportDuplicates
forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
}

[manager scanForPeripheralsWithServices:serviceUUIDs options:scanOptions];
}

- (void)stopScan:(CDVInvokedUrlCommand*)command {

  NSLog(@"stopScan");

[manager stopScan];

if (discoverPeripherialCallbackId) {
  discoverPeripherialCallbackId = nil;
}

CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}


- (void)isConnected:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult = nil;
  CBPeripheral *peripheral = [self findPeripheralByUUID:[command.arguments objectAtIndex:0]];

if (peripheral && peripheral.state == CBPeripheralStateConnected) {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not connected"];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startStateNotifications:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;

  if (stateCallbackId == nil) {
    stateCallbackId = [command.callbackId copy];
int bluetoothState = [manager state];
NSString *state = [bluetoothStates objectForKey:[NSNumber numberWithInt:bluetoothState]];
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:state];
[pluginResult setKeepCallbackAsBool:TRUE];
NSLog(@"Start state notifications on callback %@", stateCallbackId);
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"State callback already registered"];
}

[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopStateNotifications:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;

  if (stateCallbackId != nil) {
// Call with NO_RESULT so Cordova.js will delete the callback without actually calling it
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
[self.commandDelegate sendPluginResult:pluginResult callbackId:stateCallbackId];
stateCallbackId = nil;
}

pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)onReset {
  stateCallbackId = nil;
}

    - (void)readRSSI:(CDVInvokedUrlCommand*)command {
  NSLog(@"readRSSI");
NSString *uuid = [command.arguments objectAtIndex:0];

CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

if (peripheral && peripheral.state == CBPeripheralStateConnected) {
[readRSSICallbacks setObject:[command.callbackId copy] forKey:[peripheral uuidAsString]];
[peripheral readRSSI];
} else {
  NSString *error = [NSString stringWithFormat:@"Need to be connected to peripheral %@ to read RSSI.", uuid];
NSLog(@"%@", error);
CDVPluginResult *pluginResult = nil;
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
}

#pragma mark - timers

    -(void)stopScanTimer:(NSTimer *)timer {
  NSLog(@"stopScanTimer");

[manager stopScan];

if (discoverPeripherialCallbackId) {
  discoverPeripherialCallbackId = nil;
}
}

#pragma mark - CBCentralManagerDelegate

    - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

[peripherals addObject:peripheral];
[peripheral setAdvertisementData:advertisementData RSSI:RSSI];

if (discoverPeripherialCallbackId) {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
NSLog(@"Discovered %@", peripheral.name);
[pluginResult setKeepCallbackAsBool:TRUE];
[self.commandDelegate sendPluginResult:pluginResult callbackId:discoverPeripherialCallbackId];
}

}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  NSLog(@"Status of CoreBluetooth central manager changed %ld %@", (long)central.state, [self centralManagerStateToString: central.state]);

if (central.state == CBCentralManagerStateUnsupported)
{
  NSLog(@"=============================================================");
NSLog(@"WARNING: This hardware does not support Bluetooth Low Energy.");
NSLog(@"=============================================================");
}

if (stateCallbackId != nil) {
  CDVPluginResult *pluginResult = nil;
  NSString *state = [bluetoothStates objectForKey:@(central.state)];
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:state];
[pluginResult setKeepCallbackAsBool:TRUE];
NSLog(@"Report Bluetooth state \"%@\" on callback %@", state, stateCallbackId);
[self.commandDelegate sendPluginResult:pluginResult callbackId:stateCallbackId];
}

// check and handle disconnected peripherals
for (CBPeripheral *peripheral in peripherals) {
  if (peripheral.state == CBPeripheralStateDisconnected) {
[self centralManager:central didDisconnectPeripheral:peripheral error:nil];
}
}
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

  NSLog(@"didConnectPeripheral");

peripheral.delegate = self;

    // NOTE: it's inefficient to discover all services
if(isWriteExtraDataMode)
{
  NSMutableArray<CBUUID *> *serviceUUIDs =[NSMutableArray<CBUUID *> new];
if([deviceVersion isEqualToString:@"1"])
{
[serviceUUIDs addObject:[CBUUID UUIDWithString:deviceService_version_1]];
}
else{
[serviceUUIDs addObject:[CBUUID UUIDWithString:deviceService_version_2]];
}
[peripheral discoverServices:serviceUUIDs];

}else
{
[peripheral discoverServices:nil];
}
// NOTE: not calling connect success until characteristics are discovered
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

  NSLog(@"didDisconnectPeripheral");

NSString *connectCallbackId = [connectCallbacks valueForKey:[peripheral uuidAsString]];
[connectCallbacks removeObjectForKey:[peripheral uuidAsString]];

if (connectCallbackId) {

  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[peripheral asDictionary]];

// add error info
[dict setObject:@"Peripheral Disconnected" forKey:@"errorMessage"];
if (error) {
[dict setObject:[error localizedDescription] forKey:@"errorDescription"];
}
// remove extra junk
[dict removeObjectForKey:@"rssi"];
[dict removeObjectForKey:@"advertising"];
[dict removeObjectForKey:@"services"];

CDVPluginResult *pluginResult = nil;
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict];
[self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];
}

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

  NSLog(@"didFailToConnectPeripheral");

NSString *connectCallbackId = [connectCallbacks valueForKey:[peripheral uuidAsString]];
[connectCallbacks removeObjectForKey:[peripheral uuidAsString]];

CDVPluginResult *pluginResult = nil;
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[peripheral asDictionary]];
[self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];

}

#pragma mark CBPeripheralDelegate

    - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

  NSLog(@"didDiscoverServices");

// save the services to tell when all characteristics have been discovered
NSMutableSet *servicesForPeriperal = [NSMutableSet new];
[servicesForPeriperal addObjectsFromArray:peripheral.services];
[connectCallbackLatches setObject:servicesForPeriperal forKey:[peripheral uuidAsString]];

if(isWriteExtraDataMode)
{
  for (CBService *service in peripheral.services) {

    NSString *serviceUUID = nil;
    NSString *characteristicUUID = nil;

    if([deviceVersion isEqualToString:@"1"])
{
  serviceUUID=deviceService_version_1;
  characteristicUUID =deviceCharacteristic_version_1;
}
else{
  serviceUUID=deviceService_version_2;
  characteristicUUID =deviceCharacteristic_version_2;
}

if([service.UUID.UUIDString isEqualToString:[CBUUID UUIDWithString:serviceUUID].UUIDString]){

  NSMutableArray<CBUUID *> *characteristicsUUIDs =[NSMutableArray<CBUUID *> new];
[characteristicsUUIDs addObject:[CBUUID UUIDWithString:characteristicUUID]];

[peripheral discoverCharacteristics:characteristicsUUIDs forService:service]; // discover all is slow
}
}
}
else
{
  for (CBService *service in peripheral.services) {
[peripheral discoverCharacteristics:nil forService:service]; // discover all is slow
}
}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

  NSLog(@"didDiscoverCharacteristicsForService");

if(isWriteExtraDataMode)
{
  for (CBCharacteristic *characteristic in service.characteristics) {

    NSString *characteristicUUID = nil;

    if([deviceVersion isEqualToString:@"1"])
{
  characteristicUUID =deviceCharacteristic_version_1;
}
else{
  characteristicUUID =deviceCharacteristic_version_2;
}

if([characteristic.UUID.UUIDString isEqualToString:[CBUUID UUIDWithString:characteristicUUID].UUIDString]){
  currentCharacteristic = characteristic;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"foundCharacteristicAndSendTOBLE" object:nil];
return;
}
}
}

NSString *peripheralUUIDString = [peripheral uuidAsString];
NSString *connectCallbackId = [connectCallbacks valueForKey:peripheralUUIDString];
NSMutableSet *latch = [connectCallbackLatches valueForKey:peripheralUUIDString];

[latch removeObject:service];

if ([latch count] == 0) {
// Call success callback for connect
if (connectCallbackId) {
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
[pluginResult setKeepCallbackAsBool:TRUE];
[self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];
}
[connectCallbackLatches removeObjectForKey:peripheralUUIDString];
}

NSLog(@"Found characteristics for service %@", service);



for (CBCharacteristic *characteristic in service.characteristics) {
  NSLog(@"Characteristic %@", characteristic);
}

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  NSLog(@"didUpdateValueForCharacteristic");

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
NSString *notifyCallbackId = [notificationCallbacks objectForKey:key];

if (notifyCallbackId) {
  NSData *data = characteristic.value; // send RAW data to Javascript

  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
  [pluginResult setKeepCallbackAsBool:TRUE]; // keep for notification
  [self.commandDelegate sendPluginResult:pluginResult callbackId:notifyCallbackId];
}

NSString *readCallbackId = [readCallbacks objectForKey:key];

if(readCallbackId) {
  NSData *data = characteristic.value; // send RAW data to Javascript

  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:readCallbackId];

  [readCallbacks removeObjectForKey:key];
}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

  NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
NSString *notificationCallbackId = [notificationCallbacks objectForKey:key];
NSString *stopNotificationCallbackId = [stopNotificationCallbacks objectForKey:key];

CDVPluginResult *pluginResult = nil;

    // we always call the stopNotificationCallbackId if we have a callback
    // we only call the notificationCallbackId on errors and if there is no stopNotificationCallbackId

if (stopNotificationCallbackId) {

  if (error) {
    NSLog(@"%@", error);
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId:stopNotificationCallbackId];
[stopNotificationCallbacks removeObjectForKey:key];
[notificationCallbacks removeObjectForKey:key];

} else if (notificationCallbackId && error) {

  NSLog(@"%@", error);
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
[self.commandDelegate sendPluginResult:pluginResult callbackId:notificationCallbackId];
}

}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
// This is the callback for write

NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
NSString *writeCallbackId = [writeCallbacks objectForKey:key];

if (writeCallbackId) {
  CDVPluginResult *pluginResult = nil;
  if (error) {
    NSLog(@"%@", error);
pluginResult = [CDVPluginResult
resultWithStatus:CDVCommandStatus_ERROR
messageAsString:[error localizedDescription]
];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId:writeCallbackId];
[writeCallbacks removeObjectForKey:key];
}

}

- (void)peripheralDidUpdateRSSI:(CBPeripheral*)peripheral error:(NSError*)error {
[self peripheral: peripheral didReadRSSI: [peripheral RSSI] error: error];
}

- (void)peripheral:(CBPeripheral*)peripheral didReadRSSI:(NSNumber*)rssi error:(NSError*)error {
  NSLog(@"didReadRSSI %@", rssi);
NSString *key = [peripheral uuidAsString];
NSString *readRSSICallbackId = [readRSSICallbacks objectForKey: key];
if (readRSSICallbackId) {
  CDVPluginResult* pluginResult = nil;
  if (error) {
    NSLog(@"%@", error);
pluginResult = [CDVPluginResult
resultWithStatus:CDVCommandStatus_ERROR
messageAsString:[error localizedDescription]];
} else {
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
messageAsInt: [rssi integerValue]];
}
[self.commandDelegate sendPluginResult:pluginResult callbackId: readRSSICallbackId];
[readRSSICallbacks removeObjectForKey:readRSSICallbackId];
}
}

#pragma mark - internal implemetation

    - (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid {

  CBPeripheral *peripheral = nil;

  for (CBPeripheral *p in peripherals) {

    NSString* other = p.identifier.UUIDString;

    if ([uuid isEqualToString:other]) {
  peripheral = p;
  break;
}
}
return peripheral;
}

// RedBearLab
    -(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
  for(int i = 0; i < p.services.count; i++)
  {
    CBService *s = [p.services objectAtIndex:i];
if ([self compareCBUUID:s.UUID UUID2:UUID])
return s;
}

return nil; //Service not found on this peripheral
}

// Find a characteristic in service with a specific property
    -(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service prop:(CBCharacteristicProperties)prop
{
  NSLog(@"Looking for %@ with properties %lu", UUID, (unsigned long)prop);
for(int i=0; i < service.characteristics.count; i++)
{
  CBCharacteristic *c = [service.characteristics objectAtIndex:i];
if ((c.properties & prop) != 0x0 && [c.UUID.UUIDString isEqualToString: UUID.UUIDString]) {
  return c;
}
}
return nil; //Characteristic with prop not found on this service
}

// Find a characteristic in service by UUID
    -(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
  NSLog(@"Looking for %@", UUID);
for(int i=0; i < service.characteristics.count; i++)
{
  CBCharacteristic *c = [service.characteristics objectAtIndex:i];
if ([c.UUID.UUIDString isEqualToString: UUID.UUIDString]) {
  return c;
}
}
return nil; //Characteristic not found on this service
}

// RedBearLab
    -(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
  char b1[16];
  char b2[16];
  [UUID1.data getBytes:b1];
  [UUID2.data getBytes:b2];

  if (memcmp(b1, b2, UUID1.data.length) == 0)
return 1;
else
return 0;
}

// expecting deviceUUID, serviceUUID, characteristicUUID in command.arguments
    -(BLECommandContext*) getData:(CDVInvokedUrlCommand*)command prop:(CBCharacteristicProperties)prop {
  NSLog(@"getData");

CDVPluginResult *pluginResult = nil;

NSString *deviceUUIDString = [command.arguments objectAtIndex:0];
NSString *serviceUUIDString = [command.arguments objectAtIndex:1];
NSString *characteristicUUIDString = [command.arguments objectAtIndex:2];

CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDString];
CBUUID *characteristicUUID = [CBUUID UUIDWithString:characteristicUUIDString];

CBPeripheral *peripheral = [self findPeripheralByUUID:deviceUUIDString];

if (!peripheral) {

  NSLog(@"Could not find peripherial with UUID %@", deviceUUIDString);

NSString *errorMessage = [NSString stringWithFormat:@"Could not find peripherial with UUID %@", deviceUUIDString];
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

return nil;
}

CBService *service = [self findServiceFromUUID:serviceUUID p:peripheral];

if (!service)
{
  NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
serviceUUIDString,
peripheral.identifier.UUIDString);


NSString *errorMessage = [NSString stringWithFormat:@"Could not find service with UUID %@ on peripheral with UUID %@",
serviceUUIDString,
peripheral.identifier.UUIDString];
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

return nil;
}

CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service prop:prop];

// Special handling for INDICATE. If charateristic with notify is not found, check for indicate.
    if (prop == CBCharacteristicPropertyNotify && !characteristic) {
  characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service prop:CBCharacteristicPropertyIndicate];
}

// As a last resort, try and find ANY characteristic with this UUID, even if it doesn't have the correct properties
if (!characteristic) {
  characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
}

if (!characteristic)
{
  NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
characteristicUUIDString,
serviceUUIDString,
peripheral.identifier.UUIDString);

NSString *errorMessage = [NSString stringWithFormat:
@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
characteristicUUIDString,
serviceUUIDString,
peripheral.identifier.UUIDString];
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

return nil;
}

BLECommandContext *context = [[BLECommandContext alloc] init];
[context setPeripheral:peripheral];
[context setService:service];
[context setCharacteristic:characteristic];
return context;

}

-(NSString *) keyForPeripheral: (CBPeripheral *)peripheral andCharacteristic:(CBCharacteristic *)characteristic {
  return [NSString stringWithFormat:@"%@|%@", [peripheral uuidAsString], [characteristic UUID]];
}

#pragma mark - this is a BLE keyboard sender


    - (void)writeExtraData:(CDVInvokedUrlCommand *)command{

  NSString *deviceUuid = [command.arguments objectAtIndex:0];
dataServiceUUID =[command.arguments objectAtIndex:1];
dataCharacteristicUUID =[command.arguments objectAtIndex:2];
dataContent =[command.arguments objectAtIndex:3];
isWord = [command.arguments objectAtIndex:4];
deviceVersion =[command.arguments objectAtIndex:5];

writeDataCommand = command;

isWriteExtraDataMode = YES;

currentPeripheral = [self findPeripheralByUUID:deviceUuid];

if (currentPeripheral) {
  NSLog(@"Connecting to peripheral with UUID : %@", deviceUuid);

[manager connectPeripheral:currentPeripheral options:nil];
}
else{
  NSString *error = @"找不到硬件";
NSLog(@"%@", error);
CDVPluginResult *pluginResult = nil;
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
}


#pragma -mark- ble string encoder


    -(void) wirteDataToBleWithWordMode{
  NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runWithThreadToSendBLE) object:nil];
[thread start];
}

-(void) runWithThreadToSendBLE{

  if([isWord isEqualToString:@"1"]){
[self convertToUTF8KeyCodeData];
}
else{
[self convertToKeyCodeData];
}

}
/*!

@abstract 转换NSData到16进制字符

    @discussion

    @param data 传入的NSString转换成的NSData

    @result NSString

    */
- (NSString *)convertDataToHexStr:(NSData *)data {
  if (!data || [data length] == 0) {
  return @"";
}
NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];

[data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
  unsigned char *dataBytes = (unsigned char *) bytes;
  for (NSInteger i = 0; i < byteRange.length; i++) {
    NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
if ([hexStr length] == 2) {
[string appendString:hexStr];
} else {
[string appendFormat:@"0%@", hexStr];
}
}
}];

return string;
}


/*!

@abstract 把字符串转换成USB Hid Code

    @discussion 根据KeyCode编码表转换字符到USB Hid键盘序列

    @param content 传入的NSString

    @result

    */
- (void)convertToKeyCodeData{
  unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);

  NSData *data = [dataContent dataUsingEncoding:encode];
  NSString *gb18030String = [[NSString alloc] initWithData:data encoding:encode];

NSLog(@"convertToKeyCodeData start");

NSUInteger wordlength = gb18030String.length;


for (int i = 0; i < gb18030String.length; i++) {

  int progress = i*100.0/(float)wordlength;

  [self updateProgress:progress];

  if(!continueWriteData){

    if (currentPeripheral && currentPeripheral.state != CBPeripheralStateDisconnected) {
[manager cancelPeripheralConnection:currentPeripheral];
}

CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"发送已中断"];
[self.commandDelegate sendPluginResult:pluginResult callbackId:writeDataCommand.callbackId];

return;
}


NSString *sigleCharacter = [gb18030String substringWithRange:NSMakeRange(i, 1)];

NSUInteger sigleCharacterLen = [sigleCharacter dataUsingEncoding:encode].length;

if (sigleCharacterLen > 1) {
  NSString *hex = [self convertDataToHexStr:[sigleCharacter dataUsingEncoding:encode]]; //convert to hex

UInt64 octCode = strtoul([hex UTF8String], 0, 16); // convert to oct

NSString *keyCodeTmp = [NSString stringWithFormat:@"%lld", octCode];

for (int j = 0; j < keyCodeTmp.length; j++) {

  NSString *num = [keyCodeTmp substringWithRange:NSMakeRange(j, 1)];

NSData *data = nil;

if([deviceVersion isEqualToString:@"1"]){
  data = [self convertToDeviceVersionOne:num];
}
else{
  data = [self convertToDeviceVersionTwo:num forIndex:j];
}

[currentPeripheral writeValue:data forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];
}

NSMutableData *endMark = [NSMutableData new];
uint8_t releaseAll[1] = {0x00};
[endMark appendBytes:&releaseAll length:1];

[currentPeripheral writeValue:endMark forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

} else {
  NSMutableData *keyCode = [NSMutableData new];

NSString *hex = [self convertDataToHexStr:[sigleCharacter dataUsingEncoding:encode]]; //convert to hex

UInt64 octCode = strtoul([hex UTF8String], 0, 16); // convert to oct

NSData *assciToCode = [[KeyMapping sharedInstance].mapping objectForKey:@(octCode)];

[keyCode appendBytes:assciToCode.bytes length:assciToCode.length];

[currentPeripheral writeValue:keyCode forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

NSMutableData *endMark = [NSMutableData new];
uint8_t releaseAll[1] = {0x00};
[endMark appendBytes:&releaseAll length:1];

[currentPeripheral writeValue:endMark forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

}

}

if (currentPeripheral && currentPeripheral.state != CBPeripheralStateDisconnected) {
[manager cancelPeripheralConnection:currentPeripheral];
}



CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:100];
[self.commandDelegate sendPluginResult:pluginResult callbackId:writeDataCommand.callbackId];


}

-(NSData *)convertToDeviceVersionOne:(NSString *) num{

  NSMutableData *keyCode =[NSMutableData new];

NSData *altKeyCode = [[KeyMapping sharedInstance].mapping objectForKey:@(131)];
[keyCode appendData:altKeyCode];

NSData *numCode = [[KeyMapping sharedInstance].mapping objectForKey:@([num integerValue] + 200)];

uint8_t b1 = 0x80 + 0x02 + 0x01;
[keyCode appendBytes:&b1 length:1]; //set first byte

uint8_t b2 = 0x04;
[keyCode appendBytes:&b2 length:1];// set second byte

uint8_t b3 = 0x00;
[keyCode appendBytes:&b3 length:1];// set third byte

[keyCode appendBytes:numCode.bytes length:1];

return keyCode;
}

-(NSData *)convertToDeviceVersionTwo:(NSString *)num forIndex:(int) index{

  Byte keyString[] = {0x88,0x04,0,0,0,0,0,0,0};


  if([num isEqualToString:@"0"]){
  num = @"10";
}

NSInteger  numCode=[num integerValue] + 88;

keyString[index+3]=numCode;

return  [[NSData alloc]initWithBytes:&keyString length:9];
}

///////DOC

    -(NSData *)convertToDocDeviceVersionOne:(NSData *) num{

  Byte keyString[] = {0x88,0,0,0};


  Byte *byteData = (Byte *)num.bytes;

  if(sizeof(byteData) ==4)
  {
    keyString[3] = byteData[3];
  }
  else{
    keyString[3] = byteData[0];
  }

  return  [[NSData alloc]initWithBytes:&keyString length:4];
}

-(NSData *)convertToDocDeviceVersionTwo:(NSData *)num forIndex:(int) index{

  Byte keyString[] = {0x88,0,0,0,0,0,0,0,0};


  Byte *byteData = (Byte *)num.bytes;

  if(sizeof(byteData) ==4)
  {
    keyString[index+3] = byteData[3];
  }
  else{
    keyString[index+3] = byteData[0];
  }
  return  [[NSData alloc]initWithBytes:&keyString length:9];
}



/*!

@abstract 把字符串转换成USB Hid Code

    @discussion word的编码不一致，需要用utf-16 big endien编码的16进制格式，然后快捷键alt+x

    @param content 传入的NSString

    @result

    */
- (void)convertToUTF8KeyCodeData{
  unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF16BE);
  unsigned long encodeGB = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);

  NSData *data = [dataContent dataUsingEncoding:encode];
  NSString *gb18030String = [[NSMutableString alloc] initWithData:data encoding:encode];

NSUInteger wordlength = gb18030String.length;


for (int i = 0; i < gb18030String.length; i++) {
  NSString *sigleCharacter = [gb18030String substringWithRange:NSMakeRange(i, 1)];

int progress = i*100.0/(float)wordlength;

[self updateProgress:progress];

if(!continueWriteData){

  if (currentPeripheral && currentPeripheral.state != CBPeripheralStateDisconnected) {
[manager cancelPeripheralConnection:currentPeripheral];
}

CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"发送已中断"];
[self.commandDelegate sendPluginResult:pluginResult callbackId:writeDataCommand.callbackId];

return;
}

NSUInteger sigleCharacterLen = [sigleCharacter dataUsingEncoding:encodeGB].length;

if (sigleCharacterLen > 1) {
  NSString *hex = [self convertDataToHexStr:[sigleCharacter dataUsingEncoding:encode]]; //convert to hex

NSString *keyCodeTmp = hex;



if(i>0){
  NSString *preSigleCharacter = [gb18030String substringWithRange:NSMakeRange(i-1, 1)];
NSUInteger preSigleCharacterLen = [preSigleCharacter dataUsingEncoding:encodeGB].length;

if (sigleCharacterLen>1 && preSigleCharacterLen == 1) {
  NSData *spaceKeyCode = [[KeyMapping sharedInstance].mapping objectForKey:@(32)];
NSData *space =nil;

if([deviceVersion isEqualToString:@"1"])
{
  space = [self convertToDocDeviceVersionOne:spaceKeyCode];
}
else{
  space = [self convertToDocDeviceVersionTwo:spaceKeyCode forIndex:0];
}
[currentPeripheral writeValue:space forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];

[NSThread sleepForTimeInterval:0.04f];
}
}


for (int j = 0; j < keyCodeTmp.length; j++) {

  NSMutableData *keyCode = [NSMutableData new];

NSString *num = [keyCodeTmp substringWithRange:NSMakeRange(j, 1)];
int asciiCode = [num characterAtIndex:0];
NSData *numCode = [[KeyMapping sharedInstance].mapping objectForKey:@(asciiCode)];
[keyCode appendBytes:numCode.bytes length:4];

NSData *keyCodeFinal = nil;

if([deviceVersion isEqualToString:@"1"])
{
  keyCodeFinal = [self convertToDocDeviceVersionOne:keyCode];
}
else{
  keyCodeFinal = [self convertToDocDeviceVersionTwo:keyCode forIndex:j];
}
[currentPeripheral writeValue:keyCodeFinal forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];

[NSThread sleepForTimeInterval:0.04f];

NSMutableData *endMark = [NSMutableData new];
uint8_t releaseAll[1] = {0x00};
[endMark appendBytes:&releaseAll length:1];

[currentPeripheral writeValue:endMark forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];
}


NSData *altKeyCode = [[KeyMapping sharedInstance].mapping objectForKey:@(132)];

[currentPeripheral writeValue:altKeyCode forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

NSMutableData *endMark1 = [NSMutableData new];
uint8_t releaseAll1[1] = {0x00};
[endMark1 appendBytes:&releaseAll1 length:1];

[currentPeripheral writeValue:endMark1 forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

} else {

  NSString *hex = [self convertDataToHexStr:[sigleCharacter dataUsingEncoding:encodeGB]]; //convert to hex

UInt64 octCode = strtoul([hex UTF8String], 0, 16); // convert to oct

NSData *assciToCode = [[KeyMapping sharedInstance].mapping objectForKey:@(octCode)];

[currentPeripheral writeValue:assciToCode forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

NSMutableData *endMark = [NSMutableData new];
uint8_t releaseAll[1] = {0x00};
[endMark appendBytes:&releaseAll length:1];

[currentPeripheral writeValue:endMark forCharacteristic:currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
[NSThread sleepForTimeInterval:0.04f];

}

}

if (currentPeripheral && currentPeripheral.state != CBPeripheralStateDisconnected) {
[manager cancelPeripheralConnection:currentPeripheral];
}


CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:100];
[self.commandDelegate sendPluginResult:pluginResult callbackId:writeDataCommand.callbackId];

}


-(void)updateProgress:(int) progress{

  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:progress];
  [pluginResult setKeepCallbackAsBool:TRUE];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:writeDataCommand.callbackId];

}


    - (void)stopSendingtoBle:(CDVInvokedUrlCommand *)command{
  continueWriteData = false;
  NSLog(@"good lucky for break");
}




#pragma mark - util

    - (NSString*) centralManagerStateToString: (int)state
{
  switch(state)
  {
    case CBCentralManagerStateUnknown:
        return @"State unknown (CBCentralManagerStateUnknown)";
    case CBCentralManagerStateResetting:
        return @"State resetting (CBCentralManagerStateUnknown)";
    case CBCentralManagerStateUnsupported:
        return @"State BLE unsupported (CBCentralManagerStateResetting)";
    case CBCentralManagerStateUnauthorized:
        return @"State unauthorized (CBCentralManagerStateUnauthorized)";
    case CBCentralManagerStatePoweredOff:
        return @"State BLE powered off (CBCentralManagerStatePoweredOff)";
    case CBCentralManagerStatePoweredOn:
        return @"State powered up and ready (CBCentralManagerStatePoweredOn)";
    default:
        return @"State unknown";
  }

  return @"Unknown state";
}

    @end
