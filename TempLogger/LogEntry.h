//
//  LogEntry.h
//  TempLogger
//
//  Created by Stephen Schiffli on 11/26/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <MetaWear/MetaWear.h>

@interface LogEntry : NSObject <NSCoding>
@property (nonatomic, readonly) NSNumber *temperature;
@property (nonatomic, readonly) NSDate *timestamp;

@property (nonatomic, readonly) NSString *titleText;
@property (nonatomic, readonly) NSString *valueText;

- (instancetype)initWithTemperature:(NSNumber *)temperature timestamp:(NSDate *)timestamp;
@end
