//
//  LogEntry.m
//  TempLogger
//
//  Created by Stephen Schiffli on 11/26/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogEntry.h"

@interface LogEntry ()
@property (nonatomic) NSNumber *temperature;
@property (nonatomic) NSDate *timestamp;
@end

@implementation LogEntry

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.temperature = nil;
        self.timestamp = nil;
    }
    return self;
}

- (instancetype)initWithTemperature:(NSNumber *)temperature timestamp:(NSDate *)timestamp
{
    self = [super init];
    if (self) {
        self.temperature = temperature;
        self.timestamp = timestamp;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.temperature = [aDecoder decodeObjectForKey:@"temp"];
        self.timestamp = [aDecoder decodeObjectForKey:@"time"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.temperature forKey:@"temp"];
    [aCoder encodeObject:self.timestamp forKey:@"time"];
}

- (NSString *)titleText
{
    if (!self.temperature) {
        return @"Not Enough Data";
    } else {
        return [NSDateFormatter localizedStringFromDate:self.timestamp
                                              dateStyle:NSDateFormatterMediumStyle
                                              timeStyle:NSDateFormatterMediumStyle];
    }
}

- (NSString *)valueText
{
    if (!self.temperature) {
        return @"--°F";
    } else {
        return [NSString stringWithFormat:StringLabelDegreesFahrenheit, (int)(self.temperature.floatValue * 1.8) + 32, StringLabelDegreeSymbol];
    }
}


@end
