//
//  THRecorderController.h
//  AVAudioRecorderDemo
//
//  Created by 袁俊晓 on 2018/2/4.
//  Copyright © 2018年 yuanjunxiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
typedef void (^THRecordingStopComletionHandler)(BOOL);
typedef void (^THRecordingSaveComletionHandler)(BOOL,id);

@protocol THRecorderControllerDelegate <NSObject>
- (void)interruptionBegan;
@end

@class THLevelPair;
@class THMemo;
@interface THRecorderController : NSObject
@property (nonatomic,readonly)NSString *formattedCurrentTime;

@property (nonatomic,weak)id <THRecorderControllerDelegate>delegate;

-(BOOL)record;
-(void)pause;
-(void)stopWithCompletionHandler:(THRecordingStopComletionHandler)hander;
-(void)saveRecordingWithName:(NSString *)name completionHander:(THRecordingSaveComletionHandler)hander;
-(BOOL)playbackMemo:(THMemo *)memo;
- (THLevelPair *)levels;
@end
