//
//  THRecorderController.m
//  AVAudioRecorderDemo
//
//  Created by 袁俊晓 on 2018/2/4.
//  Copyright © 2018年 yuanjunxiao. All rights reserved.
//

#import "THRecorderController.h"
#import "THMemo.h"
#import "THLevelPair.h"
#import "THMeterTable.h"
@interface THRecorderController()<AVAudioRecorderDelegate>

@property (nonatomic,strong)AVAudioPlayer *Player;
@property (nonatomic,strong)AVAudioRecorder *recorder;
@property (nonatomic,strong)THRecordingStopComletionHandler completionHander;
@property (strong, nonatomic) THMeterTable *meterTable;

@end
@implementation THRecorderController

-(instancetype)init{
    self =[super init];
    if (self) {
        // 1.写入文件的本地URL
        NSString *tmpDir =NSTemporaryDirectory();
        NSString *filePath =[tmpDir stringByAppendingPathComponent:@"memo.caf"];
        NSURL *fileUrl =[NSURL fileURLWithPath:filePath];
        // 2.配置录音会话键值得NSDictionary对象
        NSDictionary *settings =@{
                                  // 音频格式
                                 AVFormatIDKey:@(kAudioFormatAppleIMA4),
                                 // 采样率
                                 AVSampleRateKey:@44100.0f,
                                   // 通道数
                                 AVNumberOfChannelsKey:@1,
                                  // 位深
                                 AVEncoderBitDepthHintKey:@16,
                                 // 音频质量
                                 AVEncoderAudioQualityKey:@(AVAudioQualityMedium)
                                 };
        // 3.捕捉初始化阶段各种错误的NSError指针
        NSError *error;
        self.recorder =[[AVAudioRecorder alloc]initWithURL:fileUrl settings:settings error:&error];
        if (self.recorder) {
            self.recorder.delegate =self;
            // 制作音柱效果时千万注意打开
            self.recorder.meteringEnabled = YES;
            [self.recorder prepareToRecord];
            
        }else{
            NSLog(@"error:%@",[error localizedDescription]);
        }
        _meterTable = [[THMeterTable alloc] init];

    }
    return self;
}
-(BOOL)record{
    return [self.recorder record];
}
-(void)pause{
    return [self.recorder pause];
}
-(void)stopWithCompletionHandler:(THRecordingStopComletionHandler)hander{
    self.completionHander = hander;
    [self.recorder stop];
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (self.completionHander) {
        self.completionHander(flag);
    }
}


-(void)saveRecordingWithName:(NSString *)name completionHander:(THRecordingSaveComletionHandler)hander{
    NSTimeInterval timestamp =[NSDate timeIntervalSinceReferenceDate];
    NSString *filename =[NSString stringWithFormat:@"%@-%f.caf",name,timestamp];
    NSString *docDir =[self documentsDirectory];
    NSString *destpath =[docDir stringByAppendingPathComponent:filename];
    NSURL *srcUrl =self.recorder.url;
    NSURL *destUrl =[NSURL fileURLWithPath:destpath];
    
    NSError *error;
    BOOL success =[[NSFileManager defaultManager] copyItemAtURL:srcUrl toURL:destUrl error:&error];
    
    if (success) {
        hander(YES,[THMemo memoWithTitle:name url:destUrl]);
        [self.recorder prepareToRecord];
    }
}
-(NSString *)documentsDirectory{
    
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
    
    
}
-(BOOL)playbackMemo:(THMemo *)memo{
    [self.Player stop];
    NSLog(@"memo.url=%@",memo.url);
    self.Player =[[AVAudioPlayer alloc]initWithContentsOfURL:memo.url error:nil];
    if (self.Player) {
        [self.Player play];
        return YES;
    }
    return NO;
}


- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    if (self.delegate) {
        [self.delegate interruptionBegan];
    }
}
//时间展示
-(NSString *)formattedCurrentTime{
    
    NSUInteger time =(NSUInteger)self.recorder.currentTime;
    NSInteger hours =(time  / 3600);
    NSInteger  minutes =(time / 60)%60;
    NSInteger seconds =time%60;
    NSString *format =@"%02i:%02i:%02i";
    return [NSString stringWithFormat:format,hours,minutes,seconds];
    
}

- (THLevelPair *)levels {
    [self.recorder updateMeters];
    float avgPower = [self.recorder averagePowerForChannel:0];
    float peakPower = [self.recorder peakPowerForChannel:0];
    float linearLevel = [self.meterTable valueForPower:avgPower];
    float linearPeak = [self.meterTable valueForPower:peakPower];
    return [THLevelPair levelsWithLevel:linearLevel peakLevel:linearPeak];
}









@end
