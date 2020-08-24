//
//  FUStreamPlayer.h
//  FUStaLiteDemo
//
//  Created by Lechech on 2019/7/9.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
//#import "FUStaEngine.h"

#define NUM_BUFFERS_LIMIT 3

typedef NS_ENUM(NSUInteger, FUPlayStatus) {
    FUPlayStatusIdle,
    FUPlayStatusStop,
    FUPlayStatusPause,
    FUPlayStatusPlay,
};

@interface FUStreamPlayer : NSObject
//流式播放pcm音频
-(void)playPcmData:(NSData *__nullable)pcmData;
//重置
-(void)reset;
//停止播放
-(void)stop;
//恢复播放
-(void)resume;
//暂停
-(void)pause;
//获取当前播放进度
- (NSTimeInterval)currentTime;
//当前是否正在运行
- (BOOL)isRunning;
//获取当前状态
- (FUPlayStatus)currentStatus;
@end


