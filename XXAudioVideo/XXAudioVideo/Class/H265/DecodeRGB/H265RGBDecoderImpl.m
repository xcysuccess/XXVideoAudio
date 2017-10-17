//
//  H265RGBDecoderImpl.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/15.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "H265RGBDecoderImpl.h"
#import "H265HwDecoderImpl.h"
#import "LAScreenEx.h"
#import "LASessionSize.h"
#import "LALiveConfiguration.h"
#import "VideoFileParser.h"

@import VideoToolbox;
@import AVFoundation;

@interface H265RGBDecoderImpl()
{
    uint8_t *_vps;
    NSInteger _vpsSize;
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}

@property (nonatomic, strong) LALiveConfiguration *configuration;
@property (nonatomic) NSInteger currentVideoBitRate;

@end

@implementation H265RGBDecoderImpl

- (instancetype) initWithConfiguration
{
    if(self = [super init]){
        BOOL hardwareDecodeSupported = VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC);
        if(hardwareDecodeSupported){
            NSLog(@"支持H265 Decode!!!!xxxxx");
        }else{
            NSLog(@"不支持H265 Decode!!!yyyyy");
        }
        
        _deocderSession = nil;
        _vps = NULL;
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
    if(_vps){
        free(_vps);
        _vps = NULL;
    }
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    if(_pps){
        free(_pps);
        _pps = NULL;
    }
    _vpsSize = _spsSize = _ppsSize = 0;
}


- (BOOL) initH265Decoder{
    if (_deocderSession) {
        return YES;
    }
    const uint8_t* const parameterSetPointers[3] = { _vps, _sps, _pps };
    const size_t parameterSetSizes[3] = { _vpsSize, _spsSize, _ppsSize };
    
    OSStatus status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                          3, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          NULL,
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        NSDictionary* destinationPixelBufferAttributes = @{
                                                           (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
                                                           //硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                                           //                                                           或者是kCVPixelFormatType_420YpCbCr8Planar
                                                           //因为iOS是  nv12  其他是nv21
//                                                           (id)kCVPixelBufferWidthKey : @([LASessionSize sharedInstance].h264outputWidth),
//                                                           (id)kCVPixelBufferHeightKey : @([LASessionSize sharedInstance].h264outputHeight),
                                                           //这里款高和编码反的
                                                           (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES]
                                                           };
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        NSDictionary *videoDecoderSpecification = @{AVVideoCodecKey: AVVideoCodecTypeHEVC};
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              (__bridge CFDictionaryRef)videoDecoderSpecification,
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
    H265HwDecoderImpl *decoder = (__bridge H265HwDecoderImpl *)decompressionOutputRefCon;
    if (decoder.delegate!=nil){
        NSLog(@"presentationTimeStampValue:%lld",CMTimeGetSeconds(presentationTimeStamp));
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
                                                          FALSE,
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
            VTDecodeFrameFlags flags = kVTDecodeFrame_EnableTemporalProcessing;
            VTDecodeInfoFlags flagOut = 0;
            
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            if(outputPixelBuffer == NULL){
                NSLog(@"outputPixelBuffer == NULL");
            }else{
                OSType pixelFormatType =  CVPixelBufferGetPixelFormatType(outputPixelBuffer);
                NSLog(@"outputPixelBuffer != NULL,pixelFormatType:%ud",pixelFormatType);
            }
            VTDecompressionSessionWaitForAsynchronousFrames(_deocderSession);
            
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
//http://www.jianshu.com/p/00a2ed58a77b
//http://blog.csdn.net/frd2009041510/article/details/41745045
-(void)decodeNalu:(uint8_t *)data withSize:(uint32_t)dataLen{
    int nalType = (data[4] & 0x7E)>>1;
    
    NALUnit *nalUnit = [NALUnit new];
    nalUnit.data = data;
    nalUnit.size = dataLen;
    nalUnit.type = nalType;
    
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
        case NAL_VPS:{//0x20
            _vpsSize = nalUnit.size - 4;
            _vps = malloc(_vpsSize);
            memcpy(_vps, nalUnit.data + 4, _vpsSize);
            
            if(_deocderSession) {
                VTDecompressionSessionInvalidate(_deocderSession);
                CFRelease(_deocderSession);
                _deocderSession = NULL;
            }
        }
            break;
        case NAL_SPS:{//0x21
            _spsSize = nalUnit.size - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, nalUnit.data + 4, _spsSize);
        }
            break;
        case NAL_PPS:{//0x22
            _ppsSize = nalUnit.size - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, nalUnit.data + 4, _ppsSize);
        }
            break;
        case NAL_TRAIL_N:
        case NAL_TRAIL_R:
        case NAL_TSA_N:
        case NAL_TSA_R:
        case NAL_STSA_N:
        case NAL_STSA_R:
        case NAL_RADL_N:
        case NAL_RADL_R:
        case NAL_RASL_N:
        case NAL_RASL_R:
        {
            if([self initH265Decoder]) {
                pixelBuffer = [self decode:nalUnit];
            }
        }
            break;
        default:{
            assert(0);
        }
            break;
    }
    
}

@end
