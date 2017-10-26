//
//  AACAudioState.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/26.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "AACAudioState.h"
#import <pthread/pthread.h>

@implementation AACAudioState

-(void) reset{
    _audioQueue = NULL;
    memset(_audioQueueBuffer, 0x0, sizeof(_audioQueueBuffer)/sizeof(_audioQueueBuffer[0]));
    memset(_packetDescs, 0x0, sizeof(_packetDescs)/sizeof(_packetDescs[0]));
    _fillBufferIndex = 0;
    _bytesFilled = 0;
    _packetsFilled = 0;
    memset(_inuse, 0x0, sizeof(_inuse)/sizeof(_inuse[0]));
    _playStarted = false;
    _queueStarted = false;
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
    pthread_cond_init(&_done, NULL);
}


@end
