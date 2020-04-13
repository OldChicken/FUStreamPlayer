//
//  ViewController.m
//  Test
//
//  Created by Lechech on 2020/4/7.
//  Copyright © 2020 Faceunity. All rights reserved.
//

#import "ViewController.h"
#import "FUStreamPlayer.h"
@interface ViewController ()

@property (nonatomic,strong) FUStreamPlayer *pcmPlayer;


@property (nonatomic,strong) NSOperationQueue *testQueue;
@property (nonatomic,strong) NSRecursiveLock *testLock;
@property (nonatomic,strong) CADisplayLink *displayLink;                                //渲染定时器
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UILabel *currentStatus;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pcmPlayer = [[FUStreamPlayer alloc] init];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
        if (@available(iOS 10.0, *)) {
            //一秒render30次
            self.displayLink.preferredFramesPerSecond = 30;
        } else {
            //两系统帧render一次
            NSInteger frameInterval = 60/30;
            self.displayLink.frameInterval = frameInterval;
        }
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)render {
//    if (self.pcmPlayer.currentStatus == FUPlayStatusPlay) {
//        float currentTime = self.pcmPlayer.currentTime;
//        NSLog(@"currentPlayTime:%f",currentTime);
//    }
    self.currentTime.text = [NSString stringWithFormat:@"%f",self.pcmPlayer.currentTime];
    
    
    switch (self.pcmPlayer.currentStatus) {
        case FUPlayStatusPlay:
            self.currentStatus.text = @"FUPlayStatusPlay";
            break;
            
        case FUPlayStatusIdle:
            self.currentStatus.text = @"FUPlayStatusIdle";
            break;
            
        case FUPlayStatusStop:
            self.currentStatus.text = @"FUPlayStatusStop";
            break;
            
        case FUPlayStatusPause:
            self.currentStatus.text = @"FUPlayStatusPause";
            break;
            
        default:
            break;
    }

}

- (IBAction)reset:(id)sender {
    [self.pcmPlayer reset];
}

- (IBAction)play:(id)sender {
    NSData *pcmData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"test.pcm" ofType:nil]];
    [self.pcmPlayer playPcmData:pcmData];
}

- (IBAction)stop:(id)sender {
    [self.pcmPlayer stop];
}

- (IBAction)pause:(id)sender {
    [self.pcmPlayer pause];
}

- (IBAction)resume:(id)sender {
    [self.pcmPlayer resume];
}



@end
