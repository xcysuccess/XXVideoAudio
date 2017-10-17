//
//  H264RGBDecoderImpl.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "H264RGBDecoderImpl.h"
#import "LAScreenEx.h"
#import "VideoFileParser.h"
#import "LASessionSize.h"

@import VideoToolbox;
@import AVFoundation;

@interface H264RGBDecoderImpl()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}
@end

@implementation H264RGBDecoderImpl

- (instancetype) initWithConfiguration
{
    if(self = [super init]){
        _deocderSession = nil;
        _sps = NULL;
        _pps = NULL;
    }
    return self;
}
-(void)dealloc{
    [self stopDecoder];
}

- (void) stopDecoder{
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    if(_pps){
        free(_pps);
        _pps = NULL;
    }
    _spsSize = _ppsSize = 0;
}


- (BOOL) initH264Decoder{
    if (_deocderSession) {
        return YES;
    }
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    if(status == noErr) {
        NSDictionary* destinationPixelBufferAttributes = @{
                                                           (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
                                                           //硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                                           //                                                           或者是kCVPixelFormatType_420YpCbCr8Planar
                                                           //因为iOS是  nv12  其他是nv21
                                                           (id)kCVPixelBufferWidthKey : @([LASessionSize sharedInstance].h264outputWidth),
                                                           (id)kCVPixelBufferHeightKey : @([LASessionSize sharedInstance].h264outputHeight),
                                                           //这里款高和编码反的
                                                           (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES]
                                                           };
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL,
                                              (__bridge CFDictionaryRef)destinationPixelBufferAttributes,
                                              &callBackRecord,
                                              &_deocderSession);
        
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
        VTSessionSetProperty(_deocderSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
    H264RGBDecoderImpl *decoder = (__bridge H264RGBDecoderImpl *)decompressionOutputRefCon;
    if (decoder.delegate!=nil){
        NSLog(@"presentationTimeStampValue:%f",CMTimeGetSeconds(presentationTimeStamp));
        [decoder.delegate displayDecodedFrame:pixelBuffer];
    }
    
}

-(CVPixelBufferRef) decode:(NALUnit *) nalUnit{
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)nalUnit.data,
                                                          nalUnit.size,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          nalUnit.size,
                                                          0,
                                                          &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
//        const size_t sampleSizeArray[] = {nalUnit.size};
//        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
//                                           blockBuffer,
//                                           _decoderFormatDescription ,
//                                           1,
//                                           0,
//                                           NULL,
//                                           1,
//                                           sampleSizeArray,
//                                           &sampleBuffer);
        status = CMSampleBufferCreate(NULL, blockBuffer, TRUE, 0, 0, _decoderFormatDescription, 1, 0, NULL, 0, NULL, &sampleBuffer);

        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            if(outputPixelBuffer == NULL){
                NSLog(@"H264::outputPixelBuffer == NULL");
            }else{
                OSType pixelFormatType =  CVPixelBufferGetPixelFormatType(outputPixelBuffer);
                NSLog(@"H264::outputPixelBuffer != NULL,pixelFormatType:%ud",pixelFormatType);
            }
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

-(void)decodeNalu:(uint8_t *)data withSize:(uint32_t)dataLen{
    int nalType = data[4] & 0x1F;
    
    NALUnit *nalUnit = [NALUnit new];
    nalUnit.data = data;
    nalUnit.size = dataLen;
    nalUnit.type = nalType;
    NSLog(@"testNALUH264->size:%zd,type:%zd",dataLen,nalType);

    //真实长度,需要把前四个字节 替换成 数据长度，
    //sps和pps的前四字节没有长度信息，所以需要_spsSize=nalUnit.size-4.
    uint32_t nalSize = (uint32_t)(dataLen- 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    nalUnit.data[0] = *(pNalSize + 3);
    nalUnit.data[1] = *(pNalSize + 2);
    nalUnit.data[2] = *(pNalSize + 1);
    nalUnit.data[3] = *(pNalSize);
    
    
    CVPixelBufferRef pixelBuffer = NULL;
    //传输的时候。关键帧不能丢数据 否则绿屏   B/P可以丢  这样会卡顿
    switch (nalType){
        case NALUTypeSPS:{//0x07
            _spsSize = nalUnit.size - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, nalUnit.data + 4, _spsSize);
        }
            break;
        case NALUTypePPS:{//0x08
            _ppsSize = nalUnit.size - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, nalUnit.data + 4, _ppsSize);
        }
            break;
        case NALUTypeBPFrame:{//0x01
            NSLog(@"Nal type is B/P frame");
            pixelBuffer = [self decode:nalUnit];
        }
            break;
        case NALUTypeIFrame:{//0x05
            NSLog(@"Nal type is I frame");
            if([self initH264Decoder]) {
                pixelBuffer = [self decode:nalUnit];
            }
        }
            break;
    }
    
}

@end
