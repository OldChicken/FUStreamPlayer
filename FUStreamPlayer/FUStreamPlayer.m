//
//  FUStreamPlayer.m
//  FUStaLiteDemo
//
//  Created by Lechech on 2019/7/9.
//  Copyright © 2019 ly-Mac. All rights reserved.
//
#import "FUStreamPlayer.h"

#define STREAM_PACKET_SIZE 5000

@interface FUStreamPlayer(){
    //Description
    AudioStreamBasicDescription audioDescription;
    //AudioQueue
    AudioQueueRef audioQueue;
    //AudioQueueBuffersArray
    AudioQueueBufferRef audioQueueBuffers[NUM_BUFFERS];
    //AudioQueueBuffersStatusArray
    BOOL audioQueueBufferUsed[NUM_BUFFERS];
}

@property (nonatomic,strong) NSOperationQueue *streamPcmQueue;
@property (nonatomic,assign) FUPlayStatus playStatus;

@end

@implementation FUStreamPlayer

- (instancetype)init {
    self = [super init];
    
    NSLog(@"===FUStreamPlayer=== PcmPlayer [%@] has init",self);

    self.playStatus = FUPlayStatusIdle;
    self.streamPcmQueue = [[NSOperationQueue alloc] init];
    self.streamPcmQueue.maxConcurrentOperationCount = 1;
  
    //audioDescription
    audioDescription.mSampleRate  = 16000;
    audioDescription.mFormatID    = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags =  kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame = 1;
    audioDescription.mFramesPerPacket  = 1;
    audioDescription.mBitsPerChannel   = 16;
    audioDescription.mBytesPerPacket   = 2;
    audioDescription.mBytesPerFrame    = 2;
    audioDescription.mReserved = 0;
    
    //AudioQueue
    AudioQueueNewOutput(&audioDescription, bufferCallback, (__bridge void *)(self), nil, nil, 0, &audioQueue);
    
    //AudioQueue Buffer
    OSStatus osState = 0;
    for (int i = 0; i < NUM_BUFFERS; i++) {
        audioQueueBufferUsed[i] = false;
        osState = AudioQueueAllocateBuffer(audioQueue, STREAM_PACKET_SIZE, &audioQueueBuffers[i]);
    }
    //volume
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    
    return self;
}

- (void)dealloc {
    NSLog(@"===FUStreamPlayer=== PcmPlayer [%@] has dealloc",self);
    audioQueue = nil;
}

-(void)playPcmData:(NSData *__nullable)pcmData{
    
    if (!pcmData || pcmData.length == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.streamPcmQueue addOperationWithBlock:^{
        Byte *byte = (Byte *)pcmData.bytes;
        long length = pcmData.length;
        if (length > STREAM_PACKET_SIZE) {
            int loopCount = (int)length/STREAM_PACKET_SIZE;
            int remainBufferLengt = length%STREAM_PACKET_SIZE;
            for (int i = 0; i<loopCount; i++) {
                if (self.playStatus == FUPlayStatusStop) {
                    return;
                }
                Byte *byte1 = byte+i*STREAM_PACKET_SIZE;
                [weakSelf process:byte1 length:STREAM_PACKET_SIZE];
            }
            if (remainBufferLengt != 0) {
                [weakSelf process:byte+loopCount*STREAM_PACKET_SIZE length:remainBufferLengt];
            }
        }else{
            [weakSelf process:byte length:length];
        }
    }];
}


-(void)process:(Byte *)byte length:(long)len {
    
    if (self.playStatus == FUPlayStatusStop) {
        return;
    }
    
    if(audioQueue)
    {
        int i = 0;
        while (true) {
            if (self.playStatus == FUPlayStatusStop) {
                return;
            }
            if (self.playStatus == FUPlayStatusPause) {
                continue;
            }
            if (!self->audioQueueBufferUsed[i]) {
                self->audioQueueBufferUsed[i] = true;
                break;
            }else {
                i++;
                if (i >= NUM_BUFFERS) {
                    i = 0;
                }
            }
        }
        self->audioQueueBuffers[i] -> mAudioDataByteSize = (unsigned int)len;
        //copy audio data to buffer
        memcpy(self->audioQueueBuffers[i] -> mAudioData, byte, len);
        //padding buffer to audio queue
        NSLog(@"===FUStreamPlayer=== number %d buffer become busy",i);
        AudioQueueEnqueueBuffer(self->audioQueue, self->audioQueueBuffers[i], 0, NULL);
    }
    if (self.playStatus == FUPlayStatusPlay || self.playStatus == FUPlayStatusIdle ) {
        [self start];
    }
    [NSThread sleepForTimeInterval:0.01];
    
}

- (void)start {
    self.playStatus = FUPlayStatusPlay;
    AudioQueueStart(audioQueue, NULL);
}


- (void)resume {
    if (self.playStatus == FUPlayStatusPause) {
        self.playStatus = FUPlayStatusPlay;
        AudioQueueStart(audioQueue, NULL);
    }
}

- (void)pause {
    if (self.playStatus == FUPlayStatusPlay) {
        self.playStatus = FUPlayStatusPause;
        AudioQueuePause(audioQueue);
    }
}

- (void)stop {
    [self.streamPcmQueue cancelAllOperations];
    self.playStatus = FUPlayStatusStop;
    AudioQueueStop(audioQueue, true);
}


- (void)reset {
    [self stop];
    [self.streamPcmQueue addOperationWithBlock:^{
        AudioQueueReset(self->audioQueue);
        self.playStatus = FUPlayStatusIdle;
    }];
}

//Callback
static void bufferCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef buffer) {
    FUStreamPlayer* player = (__bridge FUStreamPlayer*)inUserData;
    [player resetBufferState:inAQ and:buffer];
}

- (void)resetBufferState:(AudioQueueRef)audioQueueRef and:(AudioQueueBufferRef)audioQueueBufferRef {
    
    for (int i = 0; i < NUM_BUFFERS; i++) {
        //reset buffer status
        if (audioQueueBufferRef == audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = false;
            NSLog(@"===FUStreamPlayer=== number %d buffer queue become idle",i);
        }
    }
    
    BOOL isEmpty = YES;
    for (int i = 0; i < NUM_BUFFERS; i++) {
        if (audioQueueBufferUsed[i] == true) {
            isEmpty = NO;
        }
    }
    
    if (isEmpty) {
//        NSLog(@"===FUStreamPlayer=== Buffer queue is empty");
//        AudioQueueStop(self->audioQueue, false);
        [self pause];
    }
    
}


- (NSTimeInterval )currentTime {
    AudioTimeStamp timeStamp;
    AudioQueueGetCurrentTime(audioQueue, NULL, &timeStamp, NULL);
    NSTimeInterval currentTime = timeStamp.mSampleTime / audioDescription.mSampleRate;
    if (currentTime <= 0) {
        currentTime = 0;
    }
    return currentTime;
}

- (BOOL)isRunning {
    UInt32 running;
    UInt32 output = sizeof(running);
    OSStatus err = AudioQueueGetProperty(self->audioQueue, kAudioQueueProperty_IsRunning, &running, &output);
    if (err) {
        printf("===FUStreamPlayer=== Get play status error");
    }
    if (running) {
        return YES;
    }else {
        return NO;
    }
}

- (FUPlayStatus)currentStatus {
    return self.playStatus;
}

#pragma mark - FUStaEngineAudioPlay Datasource
- (double)currentPlayTime {
    double time = [self currentTime] < 0 ? 0 : [self currentTime];
    return time;
}


- (BOOL)playFinished {
    return ![self isRunning];
}

@end


