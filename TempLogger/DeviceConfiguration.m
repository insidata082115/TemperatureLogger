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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
}

- (void)runOnDeviceBoot:(MBLMetaWear *)device
{
    device.temperature.units = MBLTemperatureUnitFahrenheit;
    device.temperature.samplePeriod = 30000;
    device.temperature.source = MBLTemperatureSourceInternal;
    // Uncomment the following lines if you are using an external thermistor
    // as setup here: http://projects.mbientlab.com/metawear-and-thermistor/
    //self.device.temperature.source = MBLTemperatureSourceThermistor;
    //self.device.temperature.thermistorReadPin = 0;
    //self.device.temperature.thermistorEnablePin = 1;
    [device.temperature.dataReadyEvent startLogging];
}

@end