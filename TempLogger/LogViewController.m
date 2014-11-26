//
//  LogViewController.m
//  TempLogger
//
//  Created by Stephen Schiffli on 10/16/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogViewController.h"

#import "JBLineChartView.h"
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBChartInformationView.h"

#import "MBProgressHUD.h"

@interface LogViewController () <JBBarChartViewDataSource, JBBarChartViewDelegate>

@property (nonatomic, strong) JBBarChartView *barChartView;
@property (nonatomic, strong) JBChartInformationView *informationView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *identifierLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *demoSwitch;
@property (nonatomic, strong) NSString *logFilename;
@property (nonatomic, strong) NSMutableArray *logData;
@property (nonatomic, strong) NSMutableArray *chartData;
@property (nonatomic, strong) NSMutableArray *timeData;

@end

// Bar chart size and position constants
CGFloat const BarChartViewControllerChartHeight = 260.0f;
CGFloat const BarChartViewControllerChartPadding = 10.0f;
CGFloat const BarChartViewControllerChartHeightPadding = 150.0f;
CGFloat const BarChartViewControllerChartHeaderHeight = 80.0f;
CGFloat const BarChartViewControllerChartHeaderPadding = 20.0f;
CGFloat const BarChartViewControllerChartFooterHeight = 25.0f;
CGFloat const BarChartViewControllerChartFooterPadding = 5.0f;
CGFloat const BarChartViewControllerBarPadding = 1.0f;
NSInteger const BarChartViewControllerNumBars = 30;
NSInteger const BarChartViewControllerMaxBarHeight = 100;
NSInteger const BarChartViewControllerMinBarHeight = 0;

@implementation LogViewController
@synthesize logFilename = _logFilename;

- (NSString *)logFilename
{
    if (!_logFilename) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *name = [NSString stringWithFormat:@"%@/logfile.txt", paths[0]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:name]) {
            [[NSFileManager defaultManager] createFileAtPath:name contents:nil attributes:nil];
        }
        _logFilename = name;
    }
    return _logFilename;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = ColorBarChartBackground;
    self.identifierLabel.text = self.device.identifier.UUIDString;
    self.statusLabel.text = @"Logging...";
    [self refreshPressed:self];
    
    // Creating bar chart and defining its properties
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = CGRectMake(BarChartViewControllerChartPadding, BarChartViewControllerChartHeightPadding, self.view.bounds.size.width - (BarChartViewControllerChartPadding * 2), BarChartViewControllerChartHeight);
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.headerPadding = BarChartViewControllerChartHeaderPadding;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = ColorBarChartBackground;
    
    // Setup title and header
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(BarChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(BarChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (BarChartViewControllerChartPadding * 2), BarChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = @"Temperature";
    headerView.subtitleLabel.text = @"Last 30 samples";
    headerView.separatorColor = ColorBarChartHeaderSeparatorColor;
    self.barChartView.headerView = headerView;
    
    // Setup view used to display temperature upon selection
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.barChartView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.barChartView.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame))];
    
    [self.view addSubview:self.informationView];
    [self.view addSubview:self.barChartView];
    
    [self readLog];
    
    [self.barChartView reloadData];
}

- (void)readLog
{
    // Read the log file that already exists and parse it into array format so we can add to it later
    NSString *file = [NSString stringWithContentsOfFile:self.logFilename encoding:NSUTF8StringEncoding error:nil];
    self.logData = [[file componentsSeparatedByString:@"\n"] mutableCopy];
    if ([[self.logData lastObject] isEqualToString:@""]) {
        [self.logData removeLastObject];
    }
    
    // If there are not enough samples, then add zeros to the array until there are enough samples and give a warning message.
    if (self.logData.count < BarChartViewControllerNumBars) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Not enough samples, chart data will be limited." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        int x = (BarChartViewControllerNumBars-(int)self.logData.count);
        for (int i = 0; i < x; i++){
            [self.logData insertObject:@"0,0" atIndex:0];
        }
    }
    
    // Parse the last BarChartViewControllerNumBars number of entries of the logData array into a data and time array since the Bar Chart expects separate arrays with only 1 dimension.
    
    self.chartData = [[NSMutableArray alloc] init];
    self.timeData = [[NSMutableArray alloc] init];
    
    for (int i = ((int)self.logData.count-BarChartViewControllerNumBars); i < self.logData.count; i++)
    {
        NSString *line = self.logData[i];
        NSArray *csv =[line componentsSeparatedByString:@","];
        NSString *time = [csv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *data = [csv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.chartData addObject:data];
        [self.timeData addObject:time];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)initFakeData
{
    NSMutableArray *mutableChartData = [NSMutableArray array];
    for (int i=0; i<BarChartViewControllerNumBars; i++)
    {
        [mutableChartData addObject:[NSNumber numberWithFloat:MAX((BarChartViewControllerMinBarHeight), arc4random() % (BarChartViewControllerMaxBarHeight))]];
        
    }
    _chartData = mutableChartData;
}

- (IBAction)refreshPressed:(id)sender
{
    if (!self.device) {
        return;
    }
    
    if(self.demoSwitch.on) {
        return;
    }
    
    self.statusLabel.text = @"Connecting...";
    [self.device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot connect to logger, make sure it is charged and within range" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        if (!self.device.temperature.dataReadyEvent.isLogging) {
            self.device.temperature.samplePeriod = 30000;
            self.device.temperature.source = MBLTemperatureSourceInternal;
            self.device.temperature.thermistorReadPin = 0;
            self.device.temperature.thermistorEnablePin = 1;
            [self.device.temperature.dataReadyEvent startLogging];
        }
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.statusLabel.text = @"Syncing...";
        
        [self.device.temperature.dataReadyEvent downloadLogAndStopLogging:NO handler:^(NSArray *array, NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } else {
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:self.logFilename];
                [handle seekToEndOfFile];
                for (MBLNumericData *temp in array) {
                    NSLog(@"Temp added: %@", temp);
                    NSString *line = [NSString stringWithFormat:@"%f,%.2f\n", temp.timestamp.timeIntervalSince1970, temp.value.floatValue];
                    NSArray *csv =[line componentsSeparatedByString:@","];
                    NSString *time = [csv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *data = [csv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    [self.chartData addObject:data];
                    [self.timeData addObject:time];
                    [self.chartData removeObjectAtIndex:0];
                    [self.timeData removeObjectAtIndex:0];
                    
                    [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                }
                [handle closeFile];
                if (self.chartData.count) {
                    [self.barChartView reloadData];
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
    if(self.demoSwitch.on)
    {
        [self initFakeData];
        [self.barChartView reloadData];
    }
    else
    {
        [self readLog];
        [self refreshPressed:self];
        [self.barChartView reloadData];
    }
}

- (IBAction)clearLogPressed:(id)sender
{
    [[NSFileManager defaultManager] createFileAtPath:self.logFilename contents:nil attributes:nil];
    [self.chartData removeAllObjects];
    [self readLog];
    [self.barChartView reloadData];
}

- (IBAction)resetDevicePressed:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.device resetDevice];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.device connectWithHandler:^(NSError *error) {
            [self.device.temperature.dataReadyEvent downloadLogAndStopLogging:YES handler:^(NSArray *array, NSError *error) {
                [hud hide:YES];
                [self refreshPressed:nil];
            } progressHandler:nil];
        }];
    });
}


- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    return BarChartViewControllerNumBars;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    NSString *temp = self.timeData[index];
    if ([temp doubleValue] == 0) {
        [self.informationView setTitleText:@"Not Enough Data"];
    }
    else {
        NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[temp doubleValue]];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:timestamp
                                                             dateStyle:NSDateFormatterMediumStyle
                                                             timeStyle:NSDateFormatterMediumStyle];
        [self.informationView setTitleText:dateString];
    }
    NSNumber *valueNumber = [self.chartData objectAtIndex:index];
    [self.informationView setValueText:[NSString stringWithFormat:StringLabelDegreesFahrenheit, [valueNumber intValue], StringLabelDegreeSymbol] unitText:nil];
    [self.informationView setHidden:NO animated:YES];
    
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    [self.informationView setHidden:YES animated:YES];
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    return [[self.chartData objectAtIndex:index] floatValue];
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
