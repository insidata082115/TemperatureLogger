//
//  DeviceConfiguration.m
//  TempLogger
//
//  Created by Stephen Schiffli on 2/3/15.
//  Copyright (c) 2015 MbientLab Inc. All rights reserved.
//

#import "DeviceConfiguration.h"

@implementation DeviceConfiguration

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.periodicTemperature = [aDecoder decodeObjectForKey:@"periodicTemperature"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.periodicTemperature forKey:@"periodicTemperature"];
}

- (void)runOnDeviceBoot:(MBLMetaWear *)device
{
    // The following lines show how to setup an external thermistor
    //MBLExternalThermistor *thermistor = device.temperature.externalThermistor;
    //thermistor.readPin = 0;
    //thermistor.enablePin = 1;
    
    // The internal temperature will always be available
    MBLData *temperature = device.temperature.internal;
    if (device.temperature.onboardThermistor) {
        // Use the more accurate thermistor if available
        temperature = device.temperature.onboardThermistor;
    }
    self.periodicTemperature = [temperature periodicReadWithPeriod:30000];
    [self.periodicTemperature startLogging];
}

@end
