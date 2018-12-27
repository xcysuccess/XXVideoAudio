//
//  H265HwDecodeTool.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "H265HwDecodeTool.h"
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>

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
#import "H265DecodeModel.h"
@interface H265HwDecodeTool()
{
    VTDecompressionSessionRef session;
    CMFormatDescriptionRef description;
}
@end

@implementation H265HwDecodeTool

static void DecompressionOutputCallback(void *  decompressionOutputRefCon,
                                        void *  sourceFrameRefCon,
                                        OSStatus status,
                                        VTDecodeInfoFlags infoFlags,
                                        CVImageBufferRef pixelBuffer,
                                        CMTime presentationTimeStamp,
                                        CMTime presentationDuration)
{
    if (status != noErr) {
        assert(0);
        return;
    }
    addListBuffers(pixelBuffer, CMTimeGetSeconds(presentationTimeStamp),decompressionOutputRefCon);
    

}

static void addListBuffers(CVImageBufferRef pixelBuffer,
                           CGFloat pts,
                           void *  decompressionOutputRefCon){
    static NSMutableArray *arrayImageBuffers;
    if(!arrayImageBuffers){
        arrayImageBuffers = [NSMutableArray array];
    }
    H265DecodeModel* model = [H265DecodeModel new];
    model.pixelBuffer = pixelBuffer;
    model.pts = pts;
    [arrayImageBuffers addObject:model];
    
    NSArray *comparatorSortedArray = [arrayImageBuffers sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        H265DecodeModel *model1 = obj1;
        H265DecodeModel *model2 = obj2;
        
        CGFloat pts1 = model1.pts;
        CGFloat pts2 = model2.pts;
        
        if(pts1 < pts2){
            return (NSComparisonResult)NSOrderedAscending;
        } else if ( pts1 > pts2 ) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
    
    if(comparatorSortedArray.count == 6){
        H265DecodeModel *model = [comparatorSortedArray firstObject];
        H265HwDecodeTool *decoder = (__bridge H265HwDecodeTool *)decompressionOutputRefCon;
        if (decoder.delegate!=nil){
            NSLog(@"presentationTimeStampValue:%f",pts);
            [decoder.delegate displayH265DecodedFrame:model.pixelBuffer];
        }
        [arrayImageBuffers removeObjectsInRange:NSMakeRange(0, 1)];
    }
}

-(void) setParameters:(AVCodecParameters*) parameters{
    
    CFMutableDictionaryRef atoms = CFDictionaryCreateMutable(NULL,
                                                             0,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    
    CFDataRef extraData = CFDataCreate(kCFAllocatorDefault, parameters->extradata, parameters->extradata_size);
    CFDictionarySetValue(atoms, CFSTR("hvcC"), extraData);
    
    CFMutableDictionaryRef extensions = CFDictionaryCreateMutable(NULL,
                                                                  0,
                                                                  &kCFTypeDictionaryKeyCallBacks,
                                                                  &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(extensions, CFSTR ("SampleDescriptionExtensionAtoms"),
                         (CFTypeRef *) atoms);
    
    
    OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                     kCMVideoCodecType_HEVC,
                                                     parameters->width,
                                                     parameters->height,
                                                     extensions,
                                                     &description);
    
    CFRelease(extraData);
    CFRelease(extensions);
    
    if (status != noErr) {
        NSAssert(0, @"VideoFormat创建错误!");
    }
    
    NSDictionary *specification = @{AVVideoCodecKey: AVVideoCodecTypeHEVC};
    
    //指定基础属性
    OSType pix_fmt = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;// kCVPixelFormatType_32BGRA;//
    CFNumberRef cv_pix_fmt = CFNumberCreate(kCFAllocatorDefault,
                                            kCFNumberIntType,
                                            &pix_fmt);
    //    CFMutableDictionaryRef buffer_attributes = CFDictionaryCreateMutable(kCFAllocatorDefault,
    //                                                                         2,
    //                                                                         &kCFTypeDictionaryKeyCallBacks,
    //                                                                         &kCFTypeDictionaryValueCallBacks);
    //    CFDictionarySetValue(buffer_attributes,
    //                         kCVPixelBufferOpenGLESTextureCacheCompatibilityKey,
    //                         kCFBooleanTrue);
    //    CFDictionarySetValue(buffer_attributes,
    //                         kCVPixelBufferPixelFormatTypeKey,
    //                         cv_pix_fmt);
    //----end----
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = DecompressionOutputCallback;
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;;
    
    status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                          description,
                                          (__bridge CFDictionaryRef)specification,
                                          NULL,
                                          &callBackRecord,
                                          &session);
    VTSessionSetProperty(session, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
    VTSessionSetProperty(session, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    CFRelease(cv_pix_fmt);
    //    CFRelease(buffer_attributes);
}


-(void) hwDecodePacket:(AVPacket*) avPacket
{
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          avPacket->data,
                                                          avPacket->size,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          avPacket->size,
                                                          FALSE,
                                                          &blockBuffer);
    if (status != kCMBlockBufferNoErr) {
        CFRelease(blockBuffer);
        return;
    }
    
    
    CMSampleBufferRef sampleBuffer = NULL;
    size_t dataLen = avPacket->size;
    const size_t sampleSize = dataLen;
    
    CMSampleTimingInfo timingInfo;
    timingInfo.presentationTimeStamp = CMTimeMakeWithSeconds(avPacket->pts, 100000000);
    timingInfo.duration =  CMTimeMakeWithSeconds(avPacket->duration, 100000000);
    timingInfo.decodeTimeStamp = CMTimeMakeWithSeconds(avPacket->dts, 100000000);
    
    status = CMSampleBufferCreate(kCFAllocatorDefault,
                                  blockBuffer,
                                  true,
                                  NULL,
                                  NULL,
                                  description,
                                  1,
                                  1,
                                  &timingInfo,
                                  1,
                                  &sampleSize,
                                  &sampleBuffer);
    
    if (status == kCMBlockBufferNoErr && sampleBuffer) {
        VTDecodeFrameFlags flags = kVTDecodeFrame_EnableTemporalProcessing;
        VTDecodeInfoFlags flagOut = 0;
        
        OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(session,
                                                                  sampleBuffer,
                                                                  flags,
                                                                  NULL,
                                                                  &flagOut);
        VTDecompressionSessionWaitForAsynchronousFrames(session);
        
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

@end
