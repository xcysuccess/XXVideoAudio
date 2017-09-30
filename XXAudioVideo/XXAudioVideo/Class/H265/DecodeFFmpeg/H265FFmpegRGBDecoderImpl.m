//
//  H265FFmpegRGBDecoderImpl.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "H265FFmpegRGBDecoderImpl.h"
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
#define IS_FFMPEG_VERSION_1 (1)


@interface H265FFmpegRGBDecoderImpl()
{
    AVFormatContext *pFormatCtx;   //数据文件操作者,用于存储音视频封装格式中包含的信息。解封装格式的结构体
    AVCodecContext *pCodecCtx;     //视频的基本参数,例如宽高等，存入音频的基本参数，声道，采样率等
    AVPacket *pPacket;             //h265,h264
    
    AVCodec  *pCodec;
    
    const char *in_filename;
    
    VTDecompressionSessionRef session;
    CMFormatDescriptionRef description;
}
@end

@implementation H265FFmpegRGBDecoderImpl

-(instancetype)init{
    if(self = [super init]){

    }
    return self;
}


-(void)initBasicInfo:(NSString*) filePath{
    in_filename = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
}


-(void) decoderFile:(NSString*) filePath{
    [self initBasicInfo:filePath];
    int ret;
    
    pFormatCtx = avformat_alloc_context();
    
    //1.注册FFmpeg所有编解码器。
    av_register_all();
    avformat_network_init();
    
    //2.avformat_open_input
    if((ret = avformat_open_input(&pFormatCtx, in_filename, 0, 0))<0){
        printf("Could not open input file!");
        return;
    }
    //3.avformat_find_stream_info
    if((ret = avformat_find_stream_info(pFormatCtx, 0))<0){ //获取媒体信息
        printf("Failed to retrieve input stream information!");
        return;
    }
    av_dump_format(pFormatCtx, 0, in_filename, 0);       //打印: 输入格式的详细数据,例如时间,比特率,数据流,容器,元数据,辅助数据,编码,时间戳等
    
    //4.遍历inputFormatContext的stream,找到AVMEDIA_TYPE_VIDEO
    int videoindex = -1;
    for (int i = 0 ; i< pFormatCtx->nb_streams; ++i) {
        AVStream *in_stream = pFormatCtx->streams[i];
        AVCodec *codec = avcodec_find_decoder(in_stream->codecpar->codec_id);
        
        if(codec->type == AVMEDIA_TYPE_VIDEO){
            videoindex = i;
            break;
        }
    }
    if (videoindex == -1) {
        NSLog(@"Didn't find a video stream.\n");
        return;
    }
    pPacket = (AVPacket *) av_malloc(sizeof(AVPacket));//h265 data
    pCodecCtx = avcodec_alloc_context3(NULL);
    AVCodecParameters *codecPar = pFormatCtx->streams[videoindex]->codecpar;
    if(avcodec_parameters_to_context(pCodecCtx, codecPar) < 0){ //使用AVCodecParameters来填充AVCodecContext
        NSLog(@"avcodec_parameters_to_context Failed!");
    }
    
//    av_videotoolbox_default_init(pCodecCtx);
    
    [self setParameters:codecPar];
    
    //4.1.avcodec_find_encoder查找编码器
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (pCodec == NULL) {
        NSLog(@"Codec not found.\n");
        return;
    }
    
    //5.avcodec_open2
    pCodecCtx->codec_id = pCodec->id;
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        NSLog(@"Could not open codec.\n");
        return;
    }
    
    //6.av_read_frame
    av_dump_format(pFormatCtx, 0, in_filename, 0);       //打印: 输入格式的详细数据,例如时间,比特率,数据流,容器,元数据,辅助数据,编码,时间戳等
    
    while( av_read_frame(pFormatCtx, pPacket) >= 0 ) {
        if(pPacket->stream_index == videoindex){
            //Decode::http://xiacaojun.blog.51cto.com/12016059/1932665
            [self hwDecodePacket:pPacket];
        }
    }
    
    av_packet_unref(pPacket);
}

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

    H265FFmpegRGBDecoderImpl *decoder = (__bridge H265FFmpegRGBDecoderImpl *)decompressionOutputRefCon;
    if (decoder.delegate!=nil){
        [decoder.delegate displayH265DecodedFrame:pixelBuffer];
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
    
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {avPacket->size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           description ,
                                           1,
                                           0,
                                           NULL,
                                           1,
                                           sampleSizeArray,
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
}

@end

