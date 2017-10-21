//
//  H265FFmpegRGBDecoderImpl.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "FileFFmpegRemuxTool.h"
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import "H265HwDecodeTool.h"
#import "AACDecodeTool.h"

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


@interface FileFFmpegRemuxTool()
{
    AVFormatContext *pFormatCtx;   //数据文件操作者,用于存储音视频封装格式中包含的信息。解封装格式的结构体
    AVCodecContext *pCodecCtx;     //视频的基本参数,例如宽高等，存入音频的基本参数，声道，采样率等
    AVPacket *pPacket;             //h265,h264
    
    AVCodec  *pCodec;
    
    const char *in_filename;
    
    H265HwDecodeTool *_h265HwDecodeTool;
    AACDecodeTool *_aacDecodeTool;
}
@end

@implementation FileFFmpegRemuxTool

-(instancetype)init{
    if(self = [super init]){
        _h265HwDecodeTool = [[H265HwDecodeTool alloc] init];
        _aacDecodeTool = [[AACDecodeTool alloc] init];
    }
    return self;
}

-(void)setDelegate:(id<H265FFmpegRGBDecoderImplDelegate>)delegate{
    _h265HwDecodeTool.delegate = delegate;
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
    int video_stream_id = -1;
    int audio_stream_id = -1;
    
    for (int i = 0 ; i< pFormatCtx->nb_streams; ++i) {
        AVStream *in_stream = pFormatCtx->streams[i];
        AVCodec *codec = avcodec_find_decoder(in_stream->codecpar->codec_id);
        if (!codec) {
            continue;
        }
        if(codec->type == AVMEDIA_TYPE_VIDEO){
            video_stream_id = i;
        }else if(codec->type == AVMEDIA_TYPE_AUDIO) {
            audio_stream_id = i;
        }
    }
    if (video_stream_id == -1) {
        NSLog(@"Didn't find a video stream.\n");
        return;
    }
    if (audio_stream_id == -1) {
        NSLog(@"Didn't find a audio stream.\n");
        return;
    }
    pPacket = (AVPacket *) av_malloc(sizeof(AVPacket));//h265 data
    pCodecCtx = avcodec_alloc_context3(NULL);
    
    AVCodecParameters *video_codec_par = pFormatCtx->streams[video_stream_id]->codecpar;
    if(avcodec_parameters_to_context(pCodecCtx, video_codec_par) < 0){ //使用AVCodecParameters来填充AVCodecContext
        NSLog(@"avcodec_parameters_to_context Failed!");
    }
    [_h265HwDecodeTool setParameters:video_codec_par];
    
    AVCodecParameters *audio_codec_par = pFormatCtx->streams[audio_stream_id]->codecpar;
    if(avcodec_parameters_to_context(pCodecCtx, audio_codec_par) < 0){ //使用AVCodecParameters来填充AVCodecContext
        NSLog(@"avcodec_parameters_to_context Failed!");
    }
    [_aacDecodeTool setParameters:audio_codec_par];
//    av_videotoolbox_default_init(pCodecCtx);
    
    
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
        if(pPacket->stream_index == video_stream_id){
            //Decode::http://xiacaojun.blog.51cto.com/12016059/1932665
            [_h265HwDecodeTool hwDecodePacket:pPacket];
        }else if(pPacket->stream_index == audio_stream_id){
            [_aacDecodeTool hwDecodePacket:pPacket];
        }
    }
    
    av_packet_unref(pPacket);
}



@end

