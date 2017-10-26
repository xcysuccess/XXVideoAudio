//
//  AACstate.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://msching.github.io/blog/2014/07/09/audio-in-ios-3/
//  http://blog.csdn.net/cairo123/article/details/53839980
//  https://github.com/kCFNull/AudioConverterExample http://www.jianshu.com/p/af806688fc7c
//  https://developer.apple.com/library/content/samplecode/AudioFileStreamExample/Listings/afsclient_cpp.html

//  使用AudioQueue播放音乐，一般需要配合AudioFileStream一起，AudioFileStream负责解析音频数据，AudioQueue负责播放解析到的音频数据。
#import "AACPlayer.h"
#import "AACAudioState.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <pthread/pthread.h>

@interface AACPlayer()
@property(nonatomic,strong) AACAudioState *state;
@end

@implementation AACPlayer

#pragma mark- 初始化
-(instancetype)init{
    if(self = [super init]){
        self.state = [[AACAudioState alloc] init];
        [self.state reset];
    }
    return self;
}

-(void) setParameters:(AVCodecParameters*) parameters{
    return;
}
-(void) start{
    if (!_state ->_playStarted) {
        [_state reset];
        //1.初始化AudioFileStream
        OSStatus status = AudioFileStreamOpen((__bridge void * _Nullable)(self),
                                              XXAudioFileStream_PropertyListenerProc,//当解析到一个音频信息时，将回调该方法
                                              XXAudioStreamPacketsProc,              //当解析到一个音频帧时，将回调该方法
                                              kAudioFileAAC_ADTSType,                //指明音频数据的格式，如果你不知道音频数据的格式，可以传0
                                              &_state->_audioFileStreamID);
        if (status) {
            NSLog(@"AudioFileStreamOpen fail");
        } else {
            _state->_playStarted = true;
        }
    }
}
-(void) hwDecodePacket:(AVPacket*) avPacket{
    [self start];
    //2.解析数据
    if (avPacket == NULL || avPacket->data == NULL)
        return;
    
    NSLog(@"Recieve packet");
    OSStatus status = AudioFileStreamParseBytes(_state->_audioFileStreamID,
                                                avPacket->size,
                                                avPacket->data,
                                                0);//本次的解析和上一次解析是否是连续的关系，如果是连续的传入0，否则传入kAudioFileStreamParseFlag_Discontinuity。
    if (status != noErr) {
        NSLog(@"AudioFileStreamParseBytes fail");
        return;
    }
}

#pragma mark- AudioStream Listeners
//当一个缓冲区使用结束之后，AudioQueue将会调用之前由AudioQueueNewOutput设置的回调函数
static void XXAudioQueueOutputCallback(void* inClientData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer){
    
    AACAudioState* state = (__bridge AACAudioState*)inClientData;

    for (unsigned int i = 0; i < kNumberOfBuffers; ++i) {
        if (inBuffer == state->_audioQueueBuffer[i]){
            pthread_mutex_lock(&state->_mutex);
            state->_inuse[i] = NO;
            pthread_cond_signal(&state->_cond);
            pthread_mutex_unlock(&state->_mutex);
        }
    }
}

//当AudioQueue启动或者是终止的时候
static void XXAudioQueueIsRunningCallback(void *inClientData,
                                          AudioQueueRef inAQ,
                                          AudioQueuePropertyID inID) {
    AACAudioState* state = (__bridge AACAudioState*)inClientData;
    UInt32 isRunning, ioDataSize = sizeof(isRunning);
    OSStatus error = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &ioDataSize);
    if (error) {
        NSLog(@"get kAudioQueueProperty Is Running");
        return;
    };
    
    if (!isRunning) {
        state->_playStarted = NO;
        state->_queueStarted = NO;
        NSLog(@"Audio Queue stopped");
    }else{
        state->_playStarted = YES;
        state->_queueStarted = YES;
    }
}

#pragma mark- 一个音频信息
//当在audio stream中找到一个property value
//时长 = (音频数据字节大小 * 8) / 采样率 = (kAudioFileStreamProperty_AudioDataByteCount * 8)/kAudioFileStreamProperty_BitRate
static void XXAudioFileStream_PropertyListenerProc(void *                     inClientData,
                                                   AudioFileStreamID          inAudioFileStream,
                                                   AudioFileStreamPropertyID  inPropertyID,
                                                   UInt32 *                    ioFlags) {
    AACAudioState *state = (__bridge AACAudioState *)inClientData;
    OSStatus error = noErr;

    switch (inPropertyID) {
        case kAudioFileStreamProperty_DataFormat:{
            if(state->_dataFormat.mSampleRate == 0){
                UInt32 ioPropertyDataSize = sizeof(state->_dataFormat);
                //get the stream format.
                error = AudioFileStreamGetProperty(inAudioFileStream,
                                           kAudioFileStreamProperty_DataFormat,
                                           &ioPropertyDataSize,
                                           &state->_dataFormat);
                NSLog(@"[Audio]:ioPropertyDataSize:%zd",ioPropertyDataSize);
                if(error){
                    NSLog(@"[Audio]:kAudioFileStreamProperty_DataFormat Failed");
                }
            }
        }
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:{//已经解析到完整的音频帧数据，准备产生音频帧
            //1.首先创建一个音频队列，用以播放音频，并为每个缓冲区分配空间
            error = AudioQueueNewOutput(&state->_dataFormat,
                                        XXAudioQueueOutputCallback,//该回调用于当AudioQueue已使用完一个缓冲区时通知用户，用户可以继续填充音频数据
                                        (__bridge void * _Nullable)(state),
                                        NULL,
                                        NULL,
                                        0,
                                        &state->_audioQueue);
            if(error){
                NSLog(@"[Audio]:kAudioFileStreamProperty_ReadyToProducePackets Failed");
            }
            
            for (int i = 0; i<kNumberOfBuffers; ++i) {
                error = AudioQueueAllocateBuffer(state->_audioQueue,
                                                 kAQBufSize,
                                                 &state->_audioQueueBuffer[i]);
                if(error){
                    NSLog(@"[Audio]:AudioQueueAllocateBuffer Failed");
                }
            }
            
            //2.监听kAudioQueue
            error = AudioQueueAddPropertyListener(state->_audioQueue,
                                                  kAudioQueueProperty_IsRunning,
                                                  XXAudioQueueIsRunningCallback,//当AudioQueue启动或者是终止的时候
                                                  (__bridge void * _Nullable)(state));
            
            //大意是说magic cookie是附加在音频文件或者音频流中的一组不透明的元数据，而元数据给解码器提供了正确解码音频文件或音频流所必须的细节。我们可以通过Core Audio提供的相关函数读取或使用magic cookie。以下代码片段显示了如何获取和使用magic cookie。http://www.jianshu.com/p/2596663648b0
            
            //get the cookie size
            UInt32 cookieSize;
            Boolean writable;
            AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
            
            //get the cookie data
            void *cookieData = malloc(cookieSize);
            AudioFileStreamGetProperty(inAudioFileStream, kAudioQueueProperty_MagicCookie, &cookieSize, cookieData);
            
            //set the cookie on the queue
            error = AudioQueueSetProperty(state->_audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
            free(cookieData);
            if (error) {
                NSLog(@"[Audio]:Set magic data failed");
                break;
            }
        }
            break;
    }
}

#pragma mark- 一个音频帧
//解析音频数据帧
static void XXAudioStreamPacketsProc(void *                          inClientData,
                                     UInt32                          inNumberBytes,
                                     UInt32                          inNumberPackets,
                                     const void *                    inInputData,
                                     AudioStreamPacketDescription    *inPacketDescriptions) {
    // this is called by audio file stream when it finds packets of audio
    AACAudioState *state = (__bridge AACAudioState *)inClientData;
    if (!state->_playStarted) {
        return;
    }
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
        SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
        
        size_t bufSpaceRemaining = kAQBufSize - state->_bytesFilled;
        //如果当前要填充缓冲区的大小的数据 大于 缓冲区的剩余大小
        //将当前未满的Buffer送进播放队列，指示当前帧放入到下一个Buffer
        if (packetSize > bufSpaceRemaining) {
            XXEnqueueBuffer(state);
            XXWaitForFreeBuffer(state);
        }
        
        // copy data to the audio queue buffer
        AudioQueueBufferRef fillBuf = state->_audioQueueBuffer[state->_fillBufferIndex];
        memcpy((char*)fillBuf->mAudioData + state->_bytesFilled, (const char*)inInputData + packetOffset, packetSize);
        // fill out packet description
        state->_packetDescs[state->_packetsFilled] = inPacketDescriptions[i];
        state->_packetDescs[state->_packetsFilled].mStartOffset = state->_bytesFilled;
        // keep track of bytes filled and packets filled
        state->_bytesFilled += packetSize;
        state->_packetsFilled += 1;

        // if that was the last free packet description, then enqueue the buffer.
        size_t packetsDescsRemaining = kAQMaxPacketDescs - state->_packetsFilled;
        if (packetsDescsRemaining == 0) {
            XXEnqueueBuffer(state);
            XXWaitForFreeBuffer(state);
        }
    }
}

static OSStatus XXStartQueueIfNeeded(AACAudioState *state)
{
    OSStatus err = noErr;
    if (!state->_queueStarted) {     // start the queue if it has not been started already
        err = AudioQueueStart(state->_audioQueue, NULL);
        if (err) {
            NSLog(@"[Audio]:Start AudioQueue failed");
            return err;
        }
        state->_queueStarted = true;
        NSLog(@"[Audio]:AudioQueue started");
    }
    return err;
}

OSStatus XXEnqueueBuffer(AACAudioState *state)
{
    OSStatus err = noErr;
    state->_inuse[state->_fillBufferIndex] = true;        // set in use flag
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = state->_audioQueueBuffer[state->_fillBufferIndex];
    fillBuf->mAudioDataByteSize = state->_bytesFilled;
    err = AudioQueueEnqueueBuffer(state->_audioQueue, fillBuf, state->_packetsFilled, state->_packetDescs);
    if (err) { NSLog(@"AudioQueueEnqueueBuffer"); return err; }
    
    XXStartQueueIfNeeded(state);
    
    return err;
}


void XXWaitForFreeBuffer(AACAudioState *state)
{
    // go to next buffer
    if (++state->_fillBufferIndex >= kNumberOfBuffers) state->_fillBufferIndex = 0;
    state->_bytesFilled = 0;          // reset bytes filled
    state->_packetsFilled = 0;        // reset packets filled
    
    // wait until next buffer is not in use
    NSLog(@"[Audio]:->lock");
    pthread_mutex_lock(&state->_mutex);
    while (state->_inuse[state->_fillBufferIndex]) {
        NSLog(@"[Audio]:... WAITING ...");
        pthread_cond_wait(&state->_cond, &state->_mutex);
    }
    pthread_mutex_unlock(&state->_mutex);
    NSLog(@"[Audio]:<-unlock");
}



@end
