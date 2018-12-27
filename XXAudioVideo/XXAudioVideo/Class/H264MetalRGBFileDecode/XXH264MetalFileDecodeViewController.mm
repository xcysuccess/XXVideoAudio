//
//  XXH264RGBFileDecodeViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/7.
//  Copyright © 2017年 tomxiang. All rights reserved.
//


#import "XXH264MetalFileDecodeViewController.h"
#include <inttypes.h>
#include <math.h>
#include <limits.h>
#include <signal.h>
#include <stdint.h>
#import "XXMetalView.h"

extern "C" {
#include "libavutil/avstring.h"
#include "libavutil/eval.h"
#include "libavutil/mathematics.h"
#include "libavutil/pixdesc.h"
#include "libavutil/imgutils.h"
#include "libavutil/dict.h"
#include "libavutil/parseutils.h"
#include "libavutil/samplefmt.h"
#include "libavutil/avassert.h"
#include "libavutil/time.h"
#include "libavformat/avformat.h"
#include "libavdevice/avdevice.h"
#include "libswscale/swscale.h"
#include "libavutil/opt.h"
#include "libavcodec/avfft.h"
#include "libswresample/swresample.h"
#include <assert.h>
}
#define AVSUCCESS 0

@interface XXH264MetalFileDecodeViewController ()
@property (nonatomic,assign) BOOL playing;
@end

@implementation XXH264MetalFileDecodeViewController {
    XXMetalView *_playLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _playing = NO;
    _playLayer = [[XXMetalView alloc] initWithFrame:self.view.bounds];
    _playLayer.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_playLayer];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [playBtn setFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 60 ) / 2, CGRectGetHeight(self.view.frame) - 220 , 60, 44)];
    [playBtn setTitle:@"Play" forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playBtnEventHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playBtnEventHandler:(UIButton *)sender
{
    if (!_playing) {
        [self play];
    }else {
        [self stop];
    }
    _playing = !_playing;
}

- (void)play
{
    NSLog(@"call play");
    const char *filename =  [[[NSBundle mainBundle] pathForResource:@"720P" ofType:@"mp4"] UTF8String];
    
    AVFormatContext *formatCtx;
    
    av_register_all();
    avformat_network_init();
    
    formatCtx = avformat_alloc_context();
    //detect stream type
    int flag = avformat_open_input(&formatCtx, filename, NULL, NULL);
    if ( flag < 0) {
        NSLog(@"[Error] Open stream failed");
        return;
    }
    
    //detect valid stream info
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        NSLog(@"[Error] Couldn't find stream information.");
        return;
    }
    
    //dump information about the stream
    av_dump_format(formatCtx, 0, filename, 0);
    
    //detect codedec type
    int videoIndex = -1;
    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoIndex = i;
            break;
        }
    }
    
    if (videoIndex == -1) {
        NSLog(@"[Error]Cannot find a video stream!");
        return;
    }
    
    AVCodecParameters *codecPar;
    codecPar = formatCtx->streams[videoIndex]->codecpar;
    
    AVCodec *codec;
    codec = avcodec_find_decoder(codecPar->codec_id);
    if (codec == NULL) {
        NSLog(@"[Error]Cannot find a decoder for stream!");
        return;
    }
    
    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    
    if (avcodec_parameters_to_context(codecCtx, codecPar) < AVSUCCESS) {
        NSLog(@"[Warnning fill codec parameters failed!");
    }
    
    if (avcodec_open2(codecCtx, codec, NULL) < 0) {
        NSLog(@"[Error]Cannot open codec");
        return;
    }
    
    
    AVPacket *packet = av_packet_alloc();
    while(av_read_frame(formatCtx, packet) >= 0) {
        //        printf("Stream Index: %d\n", packet->stream_index);
        
        if(packet->stream_index == videoIndex) {
            
            //            _hwDecoder->DecodePacket(packet);
            //            return;
            
            
            int ret = avcodec_send_packet(codecCtx, packet);
            if (ret != AVSUCCESS) {
                NSLog(@"[Error]Send Packet Failed!");
                continue;
            }
            
            AVFrame *frame  = av_frame_alloc();
            while (avcodec_receive_frame(codecCtx, frame) == AVSUCCESS) {
                NSLog(@"got frame!");
                CVPixelBufferRef pixBuffer = [self converCVPixelBufferRefFromAVFrame:frame];
                [_playLayer setPixelBuffer:pixBuffer];
                if(pixBuffer) {
                    CVPixelBufferRelease(pixBuffer);
                }
                [NSThread sleepForTimeInterval:0.05];
            }
            av_frame_free(&frame);
        } else if(packet->stream_index == 1) {
            
        }
    }
    NSLog(@"end!");
    av_packet_unref(packet);
}

- (CVPixelBufferRef)converCVPixelBufferRefFromAVFrame:(AVFrame *)avframe
{
    if (!avframe || !avframe->data[0]) {
        return NULL;
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             
                             @(avframe->linesize[0]), kCVPixelBufferBytesPerRowAlignmentKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
                             [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    
    
    if (avframe->linesize[1] != avframe->linesize[2]) {
        return  NULL;
    }
    
    size_t srcPlaneSize = avframe->linesize[1]*avframe->height/2;
    size_t dstPlaneSize = srcPlaneSize *2;
    uint8_t *dstPlane = (uint8_t *)malloc(dstPlaneSize);
    
    // interleave Cb and Cr plane
    for(size_t i = 0; i<srcPlaneSize; i++){
        dstPlane[2*i  ]=avframe->data[1][i];
        dstPlane[2*i+1]=avframe->data[2][i];
    }
    
    // printf("srcFrame  width____%d   height____%d \n",avframe->width,avframe->height);
    AVFrame *srcFrame = avframe;
    int ret = CVPixelBufferCreate(kCFAllocatorDefault,
                                  srcFrame->width,
                                  srcFrame->height,
                                  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                  (__bridge CFDictionaryRef)(options),
                                  &outputPixelBuffer);
    
    CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
    
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 1);
    
    void* base =  CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
    memcpy(base, srcFrame->data[0], bytePerRowY*srcFrame->height);
    
    base = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
    memcpy(base, dstPlane, bytesPerRowUV*srcFrame->height/2);
    
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
    
    free(dstPlane);
    
    if(ret != kCVReturnSuccess)
    {
        NSLog(@"CVPixelBufferCreate Failed");
        return NULL;
    }
    
    return outputPixelBuffer;
}

- (void)stop
{
    NSLog(@"call stop");
}
@end
