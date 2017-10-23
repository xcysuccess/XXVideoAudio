//
//  AACDecodeTool.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://msching.github.io/blog/2014/07/09/audio-in-ios-3/
//  http://blog.csdn.net/cairo123/article/details/53839980
//  http://blog.csdn.net/yuanya/article/details/17002097
//  使用AudioQueue播放音乐，一般需要配合AudioFileStream一起，AudioFileStream负责解析音频数据，AudioQueue负责播放解析到的音频数据。
#import "AACDecodeTool.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


#define kNumberOfBuffers 3              //AudioQueueBuffer数量，一般指明为3
#define kAQMaxPacketDescs 512           //最大的AudioStreamPacketDescription个数
#define kAQBufSize 128 * 1024           //每个AudioQueueBuffer的大小

@interface AACDecodeTool()
{
    AudioFileStreamID _audioFileStreamID;                                //文件类型的提示
    AudioStreamBasicDescription _dataFormat;                             //保存音频格式化相关信息
    AudioQueueBufferRef _audioQueueBuffer[kNumberOfBuffers];             //AudioQueueBuffer的引用数组
    AudioStreamPacketDescription _packetDescs[kAQMaxPacketDescs];        //最大的AudioStreamPacketDescription的个数
    AudioQueueRef _audioQueue;                                           //音频队列

    bool _inuse[kNumberOfBuffers];                                       //标记当前AudioQueueBuffer是否在使用中
    
    NSLock *_audioInUseLock;                                             //修改使用标记的锁
    
    bool _playStarted;                   //播放是否已经启动
    bool _queueStarted;                  //线程是否已经启动
}

@end

@implementation AACDecodeTool


#pragma mark - AudioStream Listeners
//当一个缓冲区使用结束之后，AudioQueue将会调用之前由AudioQueueNewOutput设置的回调函数
static void XXAudioQueueOutputCallback(void* inClientData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer){
    
    AACDecodeTool* decodeTool = (__bridge AACDecodeTool*)inClientData;

    for (unsigned int i = 0; i < kNumberOfBuffers; ++i) {
        if (inBuffer == decodeTool->_audioQueueBuffer[i]){
            [decodeTool->_audioInUseLock lock];
            decodeTool->_inuse[i] = NO;
            [decodeTool->_audioInUseLock unlock];
        }
    }
}

//当AudioQueue启动或者是终止的时候
static void XXAudioQueueIsRunningCallback(void *inClientData,
                                          AudioQueueRef inAQ,
                                          AudioQueuePropertyID inID) {
    AACDecodeTool* decodeTool = (__bridge AACDecodeTool*)inClientData;
    UInt32 isRunning, ioDataSize = sizeof(isRunning);
    OSStatus error = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &ioDataSize);
    if (error) {
        NSLog(@"get kAudioQueueProperty Is Running");
        return;
    };
    
    if (!isRunning) {
        decodeTool->_playStarted = NO;
        decodeTool->_queueStarted = NO;
        NSLog(@"Audio Queue stopped");
    }
    decodeTool->_playStarted = YES;
}

//信息解析的回调，每解析出一帧数据都会进行一次回调；
//时长 = (音频数据字节大小 * 8) / 采样率 = (kAudioFileStreamProperty_AudioDataByteCount * 8)/kAudioFileStreamProperty_BitRate
static void XXAudioFileStream_PropertyListenerProc(void *                     inClientData,
                                                   AudioFileStreamID          inAudioFileStream,
                                                   AudioFileStreamPropertyID  inPropertyID,
                                                   UInt32 *                    ioFlags) {
    AACDecodeTool *decodeTool = (__bridge AACDecodeTool *)inClientData;
    OSStatus error = noErr;

    switch (inPropertyID) {
        case kAudioFileStreamProperty_DataFormat:{
            if(decodeTool->_dataFormat.mSampleRate == 0){
                UInt32 ioPropertyDataSize = sizeof(decodeTool->_dataFormat);
                //get the stream format.
                error = AudioFileStreamGetProperty(inAudioFileStream,
                                           kAudioFileStreamProperty_DataFormat,
                                           &ioPropertyDataSize,
                                           &decodeTool->_dataFormat);
                NSLog(@"[Audio]:ioPropertyDataSize:%zd",ioPropertyDataSize);
                if(error){
                    NSLog(@"[Audio]:kAudioFileStreamProperty_DataFormat Failed");
                }
            }
        }
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:{//已经解析到完整的音频帧数据，准备产生音频帧
            //1.首先创建一个音频队列，用以播放音频，并为每个缓冲区分配空间
            error = AudioQueueNewOutput(&decodeTool->_dataFormat,
                                        XXAudioQueueOutputCallback,//该回调用于当AudioQueue已使用完一个缓冲区时通知用户，用户可以继续填充音频数据
                                        (__bridge void * _Nullable)(decodeTool),
                                        NULL,
                                        NULL,
                                        0,
                                        &decodeTool->_audioQueue);
            if(error){
                NSLog(@"[Audio]:kAudioFileStreamProperty_ReadyToProducePackets Failed");
            }
            
            for (int i = 0; i<kNumberOfBuffers; ++i) {
                error = AudioQueueAllocateBuffer(decodeTool->_audioQueue,
                                                 kAQBufSize,
                                                 &decodeTool->_audioQueueBuffer[i]);
                if(error){
                    NSLog(@"[Audio]:AudioQueueAllocateBuffer Failed");
                }
            }
            
            //2.监听kAudioQueue
            error = AudioQueueAddPropertyListener(decodeTool->_audioQueue,
                                                  kAudioQueueProperty_IsRunning,//当AudioQueue启动或者是终止的时候
                                                  XXAudioQueueIsRunningCallback,
                                                  decodeTool);
        }
            
            break;
        case <#expression#>:
    }
//        case kAudioFileStreamProperty_ReadyToProducePackets: {
//            UInt32 asbdSize = sizeof(state.dataFormat);
//            error = AudioFileStreamGetProperty(inAudioFileStream,
//                                               kAudioFileStreamProperty_DataFormat,
//                                               &asbdSize,
//                                               &state.dataFormat);
//            if (error) {
//                NSLog(@"Failed to fetch description from stream");
//                break;
//
//        }
//            break;
//    }
//    UInt32 bitRate;
//    UInt32 bitRateSize = sizeof(bitRate);
//    OSStatus status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_BitRate, &bitRateSize, &bitRate);
//    if (status != noErr){
//        //错误处理
//    }
    
}

//分离帧的回调，每解析出一部分帧就会进行一次回调
static void XXAudioStreamPacketsProc(void *                          inClientData,
                                     UInt32                          inNumberBytes,
                                     UInt32                          inNumberPackets,
                                     const void *                    inInputData,
                                     AudioStreamPacketDescription    *inPacketDescriptions) {
    
    
}

-(instancetype)init{
    if(self = [super init]){
        _audioInUseLock = [[NSLock alloc] init];
        _playStarted = NO;
        _queueStarted = NO;
    }
    return self;
}

-(void) setParameters:(AVCodecParameters*) parameters{
    return;
}

-(void) hwDecodePacket:(AVPacket*) avPacket{
    if (_audioFileStreamID == NULL) {
        //1.初始化AudioFileStream
        AudioFileStreamOpen((__bridge void * _Nullable)(self),
                            XXAudioFileStream_PropertyListenerProc,
                            XXAudioStreamPacketsProc,
                            kAudioFileAAC_ADTSType,
                            &_audioFileStreamID);
    }
    
    //2.解析数据
    if (avPacket == NULL || avPacket->data == NULL)
        return;
    
    NSLog(@"Recieve packet");
    OSStatus status = AudioFileStreamParseBytes(_audioFileStreamID,
                                                avPacket->size,
                                                avPacket->data,
                                                0);//本次的解析和上一次解析是否是连续的关系，如果是连续的传入0，否则传入kAudioFileStreamParseFlag_Discontinuity。
    if (status != noErr) {
        NSLog(@"AudioFileStreamParseBytes fail");
        return;
    }
}


@end
