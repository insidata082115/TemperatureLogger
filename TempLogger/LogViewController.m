//
//  LogViewController.m
//  TempLogger
//
//  Created by Stephen Schiffli on 10/16/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogViewController.h"
#import "LogEntry.h"

#import "JBLineChartView.h"
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBChartInformationView.h"

#import "MBProgressHUD.h"

@interface LogViewController () <JBBarChartViewDataSource, JBBarChartViewDelegate>
@property (weak, nonatomic) IBOutlet JBChartHeaderView *headerView;
@property (weak, nonatomic) IBOutlet JBBarChartView *barChartView;
@property (weak, nonatomic) IBOutlet JBChartInformationView *informationView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *demoSwitch;

@property (nonatomic, strong) NSString *logFilename;
@property (nonatomic, strong) NSMutableArray *logData;
@property (nonatomic) BOOL doingReset;
@end

// Bar chart size and position constants
static const CGFloat    BarChartViewControllerBarPadding = 1.0f;
static const NSInteger  BarChartViewControllerNumBars = 30;
static const NSInteger  BarChartViewControllerMaxBarHeight = 100;
static const NSInteger  BarChartViewControllerMinBarHeight = 0;

@implementation LogViewController
@synthesize logFilename = _logFilename;

- (NSString *)logFilename
{
    if (!_logFilename) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (paths.count) {
            _logFilename = [NSString stringWithFormat:@"%@/archive_logfile", paths[0]];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot find documents directory, logging not supported" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            _logFilename = nil;
        }
    }
    return _logFilename;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = ColorBarChartBackground;
    self.statusLabel.text = @"Logging...";
    [self refreshPressed:self];
    
    // Creating bar chart and defining its properties
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = ColorBarChartBackground;
    
    // Setup title and header
    self.headerView.titleLabel.text = @"Temperature";
    self.headerView.subtitleLabel.text = @"Last 30 samples";
    self.headerView.separatorColor = ColorBarChartHeaderSeparatorColor;
    
    // Load saved values and display
    self.logData = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.logFilename] mutableCopy];
    if (!self.logData) {
        self.logData = [NSMutableArray arrayWithCapacity:BarChartViewControllerNumBars];
    }
    [self.barChartView reloadData];
}

- (IBAction)refreshPressed:(id)sender
{
    if (!self.device) {
        return;
    }
    
    if (self.demoSwitch.on) {
        return;
    }
    
    self.statusLabel.text = @"Connecting...";
    [self.device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot connect to logger, make sure it is charged and within range" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        
        self.device.temperature.units = MBLTemperatureUnitFahrenheit;
        if (!self.device.temperature.dataReadyEvent.isLogging) {
            NSLog(@"Programming Device");
            self.device.temperature.samplePeriod = 30000;
            self.device.temperature.source = MBLTemperatureSourceInternal;
            // Uncomment the following lines if you are using an external thermistor
            // as setup here: http://projects.mbientlab.com/metawear-and-thermistor/
            //self.device.temperature.source = MBLTemperatureSourceThermistor;
            //self.device.temperature.thermistorReadPin = 0;
            //self.device.temperature.thermistorEnablePin = 1;
            [self.device.temperature.dataReadyEvent startLogging];
        }
        
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.statusLabel.text = @"Syncing...";
        
        [self.device.temperature.dataReadyEvent downloadLogAndStopLogging:NO handler:^(NSArray *array, NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } else {
                for (MBLNumericData *temp in array) {
                    NSLog(@"Temp added: %@", temp);
                    [self.logData addObject:[[LogEntry alloc] initWithTemperature:temp.value timestamp:temp.timestamp]];
                    if (self.logData.count > BarChartViewControllerNumBars) {
                        [self.logData removeObjectAtIndex:0];
                    }
                }
                [NSKeyedArchiver archiveRootObject:self.logData toFile:self.logFilename];
                
                if (!self.doingReset) {
                    [self.barChartView reloadData];
                } else {
                    self.doingReset = NO;
                    [self clearLogPressed:nil];
                }
                self.progressBar.hidden = YES;
                self.statusLabel.text = @"Logging...";
            }
            
            // We have our data so get outta here
            [self.device disconnectWithHandler:nil];
        } progressHandler:^(float number, NSError *error) {
            [self.progressBar setProgress:number animated:YES];
        }];
    }];
}

- (IBAction)switchChanged:(id)sender
{
    if (self.demoSwitch.on) {
        // Create some random data
        self.logData = [NSMutableArray arrayWithCapacity:BarChartViewControllerNumBars];
        for (int i = 0; i < BarChartViewControllerNumBars; i++) {
            NSNumber *rand = [NSNumber numberWithFloat:MAX((BarChartViewControllerMinBarHeight), arc4random() % (BarChartViewControllerMaxBarHeight))];
            NSDate *timestamp = [NSDate dateWithTimeIntervalSinceNow:(BarChartViewControllerNumBars - i) * -30];
            [self.logData addObject:[[LogEntry alloc] initWithTemperature:rand timestamp:timestamp]];
        }
    } else {
        // Reload the real data
        self.logData = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.logFilename] mutableCopy];
    }
    [self.barChartView reloadData];
}

- (IBAction)clearLogPressed:(id)sender
{
    [[NSFileManager defaultManager] removeItemAtPath:self.logFilename error:nil];
    [self.logData removeAllObjects];
    [self.barChartView reloadData];
}

- (IBAction)resetDevicePressed:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.device connectWithHandler:^(NSError *error) {
        [self.device resetDevice];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.device connectWithHandler:^(NSError *error) {
                [hud hide:YES];
                self.doingReset = YES;
                // Reprogram and refresh the data.
                [self refreshPressed:nil];
            }];
        });
    }];
}


- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    // If there are not enough samples, then add zeros to the array until there are enough samples and give a warning message.
    if (self.logData.count < BarChartViewControllerNumBars) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Not enough samples, chart data will be limited." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        int emptyEntries = BarChartViewControllerNumBars - (int)self.logData.count;
        for (int i = 0; i < emptyEntries; i++){
            [self.logData insertObject:[[LogEntry alloc] init] atIndex:0];
        }
    }
    return BarChartViewControllerNumBars;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    LogEntry *entry = self.logData[index];
    [self.informationView setTitleText:entry.titleText];
    [self.informationView setValueText:entry.valueText unitText:nil];
    [self.informationView setHidden:NO animated:YES];
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    [self.informationView setHidden:YES animated:YES];
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    LogEntry *entry = self.logData[index];
    return entry.temperature.floatValue;
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index
{
    return (index % 2 == 0) ? ColorBarChartBarBlue : ColorBarChartBarGreen;
}

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor whiteColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return BarChartViewControllerBarPadding;
}

@end
