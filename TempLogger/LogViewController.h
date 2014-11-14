//
//  LogViewController.h
//  TempLogger
//
//  Created by Stephen Schiffli on 10/16/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetaWear/MetaWear.h>
#import "JBBaseChartViewController.h"

@interface LogViewController : JBBaseChartViewController
@property (nonatomic, strong) MBLMetaWear *device;
@end
