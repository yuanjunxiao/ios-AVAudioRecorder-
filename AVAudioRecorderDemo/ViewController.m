//
//  ViewController.m
//  AVAudioRecorderDemo
//
//  Created by 袁俊晓 on 2018/2/4.
//  Copyright © 2018年 yuanjunxiao. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "THRecorderController.h"
#import "THMemo.h"
#import "THMemoCell.h"
#import "THLevelMeterView.h"
#import "THLevelPair.h"
#define CANCEL_BUTTON    0
#define OK_BUTTON        1

#define MEMO_CELL        @"memoCell"
#define MEMOS_ARCHIVE    @"memos.archive"
@interface ViewController ()<THRecorderControllerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)NSMutableArray *memos;
@property (nonatomic,strong)CADisplayLink *levelTimer;
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,strong)THRecorderController *controller;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet THLevelMeterView *levelMeterView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _controller = [[THRecorderController alloc] init];
    _controller.delegate = self;
    self.stopButton.enabled = NO;
    _memos = [NSMutableArray array];

    UIImage *recordImage = [[UIImage imageNamed:@"record"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *pauseImage = [[UIImage imageNamed:@"pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *stopImage = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [self.recordButton setImage:recordImage forState:UIControlStateNormal];
    [self.recordButton setImage:pauseImage forState:UIControlStateSelected];
    [self.stopButton setImage:stopImage forState:UIControlStateNormal];
    
    NSData *data = [NSData dataWithContentsOfURL:[self archiveURL]];
    if (!data) {
        _memos = [NSMutableArray array];
    } else {
        _memos = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    _tableView.delegate       = self;
    _tableView.dataSource     = self;//设置代理
    _tableView.backgroundColor = [UIColor colorWithRed:242/255.f green:242/255.f blue:242/255.f alpha:1.0];
    //允许多项选择 默认是no；默认是单选
    _tableView.allowsMultipleSelection = YES;
    //取消多余的cell
    _tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];//取消多余行数
    //nib类
    [_tableView registerNib:[UINib nibWithNibName:@"THMemoCell" bundle:nil] forCellReuseIdentifier:@"THMemoCell"];

    
}


- (IBAction)record:(id)sender {
    //判断是否正在录音暂停
    self.stopButton.enabled = YES;
    if (![sender isSelected]) {
        [self startMeterTimer];
        [self startTimer];
        [self.controller record];
    } else {
        [self stopMeterTimer];
        [self stopTimer];
        [self.controller pause];
    }
    [sender setSelected:![sender isSelected]];
}
- (IBAction)stopRecording:(id)sender {
    [self stopMeterTimer];
    self.recordButton.selected = NO;
    self.stopButton.enabled = NO;
    [self.controller stopWithCompletionHandler:^(BOOL result) {
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self showSaveDialog];
        });
    }];
}

- (void)interruptionBegan {
    self.recordButton.selected = NO;
    [self stopMeterTimer];
    [self stopTimer];
}
-(void)startTimer{
    [self.timer invalidate];
    self.timer =[NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updataTimeDisplay) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
-(void)stopTimer{
    [self.timer invalidate];
    self.timer = nil;
}
-(void)updataTimeDisplay{
     self.timeLabel.text = self.controller.formattedCurrentTime;
}

- (void)showSaveDialog {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"保存录音"
                                          message:@"请填写本次录音的名称"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"My Recording", @"Login");
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *filename = [alertController.textFields.firstObject text];
        NSLog(@"filename:=%@=",filename);
        [self.controller saveRecordingWithName:filename completionHander:^(BOOL success, id object) {
            if (success) {
                NSLog(@"object:=%@=",object);
                [self.memos addObject:object];
                NSLog(@"memos:%@",self.memos);
                [self saveMemos];
                [self.tableView reloadData];
            } else {
                NSLog(@"Error saving file: %@", [object localizedDescription]);
            }
        }];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Memo Archiving

- (void)saveMemos {
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:self.memos];
    [fileData writeToURL:[self archiveURL] atomically:YES];
}

- (NSURL *)archiveURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    NSString *archivePath = [docsDir stringByAppendingPathComponent:MEMOS_ARCHIVE];
    return [NSURL fileURLWithPath:archivePath];
}


#pragma mark - UITableView Datasource and Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.memos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    THMemoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"THMemoCell" forIndexPath:indexPath];
    THMemo *memo = self.memos[indexPath.row];
    cell.titleLabel.text = memo.title;
    cell.dateLabel.text = memo.dateString;
    cell.timeLabel.text = memo.timeString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
      [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    THMemo *memo = self.memos[indexPath.row];
    [self.controller playbackMemo:memo];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
    //    return 400;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        THMemo *memo = self.memos[indexPath.row];
        [memo deleteMemo];
        [self.memos removeObjectAtIndex:indexPath.row];
        [self saveMemos];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Level Metering

- (void)startMeterTimer {
    [self.levelTimer invalidate];
    self.levelTimer = [CADisplayLink displayLinkWithTarget:self
                                                  selector:@selector(updateMeter)];
    self.levelTimer.frameInterval = 5;
    [self.levelTimer addToRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSRunLoopCommonModes];
}

- (void)stopMeterTimer {
    [self.levelTimer invalidate];
    self.levelTimer = nil;
    [self.levelMeterView resetLevelMeter];
}

- (void)updateMeter {
    THLevelPair *levels = [self.controller levels];
    self.levelMeterView.level = levels.level;
    self.levelMeterView.peakLevel = levels.peakLevel;
    [self.levelMeterView setNeedsDisplay];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}








@end
