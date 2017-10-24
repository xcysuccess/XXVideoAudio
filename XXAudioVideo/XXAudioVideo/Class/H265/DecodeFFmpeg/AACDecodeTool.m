//
//  AACDecodeTool.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://msching.github.io/blog/2014/07/09/audio-in-ios-3/
//  http://blog.csdn.net/cairo123/article/details/53839980
//  http://blog.csdn.net/yuanya/article/details/17002097
//  https://developer.apple.com/library/content/samplecode/AudioFileStreamExample/Listings/afsclient_cpp.html

//  使用AudioQueue播放音乐，一般需要配合AudioFileStream一起，AudioFileStream负责解析音频数据，AudioQueue负责播放解析到的音频数据。
#import "AACDecodeTool.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <pthread/pthread.h>

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

    UInt32 _bytesFilled;                  // how many bytes have been filled
    
    bool _inuse[kNumberOfBuffers];                                       //标记当前AudioQueueBuffer是否在使用中
    
    bool _playStarted;                   //播放是否已经启动
    bool _queueStarted;                  //线程是否已经启动
    
    pthread_mutex_t mutex;              // a mutex to protect the inuse flags
    pthread_cond_t cond;                // a condition varable for handling the inuse flags
    pthread_cond_t done;                // a condition varable for handling the inuse flags
}

@end

@implementation AACDecodeTool


#pragma mark- AudioStream Listeners
//当一个缓冲区使用结束之后，AudioQueue将会调用之前由AudioQueueNewOutput设置的回调函数
static void XXAudioQueueOutputCallback(void* inClientData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer){
    
    AACDecodeTool* decodeTool = (__bridge AACDecodeTool*)inClientData;

    for (unsigned int i = 0; i < kNumberOfBuffers; ++i) {
        if (inBuffer == decodeTool->_audioQueueBuffer[i]){
            pthread_mutex_lock(&decodeTool->mutex);
            decodeTool->_inuse[i] = NO;
            pthread_cond_signal(&decodeTool->cond);
            pthread_mutex_unlock(&decodeTool->mutex);
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
    }else{
        decodeTool->_playStarted = YES;
        decodeTool->_queueStarted = YES;
    }
}

#pragma mark- 一个音频信息
//当在audio stream中找到一个property value
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
                                                  kAudioQueueProperty_IsRunning,
                                                  XXAudioQueueIsRunningCallback,//当AudioQueue启动或者是终止的时候
                                                  (__bridge void * _Nullable)(decodeTool));
            
            //大意是说magic cookie是附加在音频文件或者音频流中的一组不透明的元数据，而元数据给解码器提供了正确解码音频文件或音频流所必须的细节。我们可以通过Core Audio提供的相关函数读取或使用magic cookie。以下代码片段显示了如何获取和使用magic cookie。http://www.jianshu.com/p/2596663648b0
            
            //get the cookie size
            UInt32 cookieSize;
            Boolean writable;
            AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
            
            //get the cookie data
            void *cookieData = malloc(cookieSize);
            AudioFileStreamGetProperty(inAudioFileStream, kAudioQueueProperty_MagicCookie, &cookieSize, cookieData);
            
            //set the cookie on the queue
            error = AudioQueueSetProperty(decodeTool->_audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
            free(cookieData);
            if (error) {
                NSLog(@"Set magic data failed");
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
    AACDecodeTool *decodeTool = (__bridge AACDecodeTool *)inClientData;
    if (!decodeTool->_playStarted) {
        return;
    }
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
        SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
        
        size_t bufSpaceRemaining = kAQBufSize - decodeTool->_bytesFilled;
        //如果当前要填充缓冲区的大小的数据 大于 缓冲区的剩余大小
        //将当前未满的Buffer送进播放队列，指示当前帧放入到下一个Buffer
        if (packetSize > bufSpaceRemaining) {
            XXEnqueueBuffer(myData);
            XXWaitForFreeBuffer(myData);
        }
        
        // copy data to the audio queue buffer
        AudioQueueBufferRef fillBuf = _decodeTool->_audioQueueBuffer[_decodeTool->fillBufferIndex];
        memcpy((char*)fillBuf->mAudioData + decodeTool->_bytesFilled, (const char*)inInputData + packetOffset, packetSize);
        // fill out packet description
        decodeTool->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
        decodeTool->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
        // keep track of bytes filled and packets filled
        decodeTool->bytesFilled += packetSize;
        decodeTool->packetsFilled += 1;
        
        // if that was the last free packet description, then enqueue the buffer.
        size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
        if (packetsDescsRemaining == 0) {
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
    }
}

OSStatus MyEnqueueBuffer(AACDecodeTool *decodeTool)
{
    OSStatus err = noErr;
    myData->inuse[myData->fillBufferIndex] = true;        // set in use flag
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
    fillBuf->mAudioDataByteSize = myData->bytesFilled;
    err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
    if (err) { PRINTERROR("AudioQueueEnqueueBuffer"); myData->failed = true; return err; }
    
    StartQueueIfNeeded(myData);
    
    return err;
}


void WaitForFreeBuffer(AACDecodeTool *decodeTool)
{
    // go to next buffer
    if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
    myData->bytesFilled = 0;        // reset bytes filled
    myData->packetsFilled = 0;        // reset packets filled
    
    // wait until next buffer is not in use
    printf("->lock\n");
    pthread_mutex_lock(&myData->mutex);
    while (myData->inuse[myData->fillBufferIndex]) {
        printf("... WAITING ...\n");
        pthread_cond_wait(&myData->cond, &myData->mutex);
    }
    pthread_mutex_unlock(&myData->mutex);
    printf("<-unlock\n");
}

#pragma mark- 初始化
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
                            XXAudioFileStream_PropertyListenerProc,//当解析到一个音频信息时，将回调该方法
                            XXAudioStreamPacketsProc,              //当解析到一个音频帧时，将回调该方法
                            kAudioFileAAC_ADTSType,                //指明音频数据的格式，如果你不知道音频数据的格式，可以传0
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
