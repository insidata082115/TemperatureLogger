//
//  ColorConstants.h
//  TempLogger
//
//  Created by Yu Suo on 11/5/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#ifndef TempLogger_ColorConstants_h
#define TempLogger_ColorConstants_h

#endif

#define UIColorFromHex(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

#pragma mark - Navigation

#define ColorNavigationBarTint UIColorFromHex(0x0D0D0D)
#define ColorNavigationTint UIColorFromHex(0x34AADC)
#define ColorNavigationTitle UIColorFromHex(0x34AADC)

#pragma mark - Bar Chart

#define ColorBarChartControllerBackground UIColorFromHex(0x313131)
#define ColorBarChartBackground UIColorFromHex(0x1F1F1F)
#define ColorBarChartBarGreen UIColorFromHex(0x52EDC7)
#define ColorBarChartBarBlue UIColorFromHex(0x5AC8FB)
#define ColorBarChartBarRed UIColorFromHex(0xFF5E3A)
#define ColorBarChartHeaderSeparatorColor UIColorFromHex(0x686868)

#pragma mark - Tooltips

#define ColorTooltipColor [UIColor colorWithWhite:1.0 alpha:0.9]
#define ColorTooltipTextColor UIColorFromHex(0x313131)