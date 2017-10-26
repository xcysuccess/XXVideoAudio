//
//  AACAudioState.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/26.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libavutil/avstring.h"
#include "libswscale/swscale.h"
    
#ifdef __cplusplus
};
#endif

#define kNumberOfBuffers 3              //AudioQueueBuffer数量，一般指明为3
#define kAQMaxPacketDescs 512           //最大的AudioStreamPacketDescription个数
#define kAQBufSize 128 * 1024           //每个AudioQueueBuffer的大小

@interface AACAudioState : NSObject
{
@public
    AudioFileStreamID _audioFileStreamID;                                //文件类型的提示
    AudioStreamBasicDescription _dataFormat;                             //保存音频格式化相关信息
    AudioQueueBufferRef _audioQueueBuffer[kNumberOfBuffers];             //AudioQueueBuffer的引用数组
    AudioStreamPacketDescription _packetDescs[kAQMaxPacketDescs];        //最大的AudioStreamPacketDescription的个数
    AudioQueueRef _audioQueue;                                           //音频队列
    
    unsigned int _fillBufferIndex;        // the index of the audioQueueBuffer that is being filled
    UInt32 _bytesFilled;                  // how many bytes have been filled
    UInt32 _packetsFilled;                // how many packets have been filled
    
    bool _inuse[kNumberOfBuffers];                                       //标记当前AudioQueueBuffer是否在使用中
    
    bool _playStarted;                   //播放是否已经启动
    bool _queueStarted;                  //线程是否已经启动
    
    pthread_mutex_t _mutex;              // a mutex to protect the inuse flags
    pthread_cond_t _cond;                // a condition varable for handling the inuse flags
    pthread_cond_t _done;                // a condition varable for handling the inuse flags
}

-(void) reset;
@end
