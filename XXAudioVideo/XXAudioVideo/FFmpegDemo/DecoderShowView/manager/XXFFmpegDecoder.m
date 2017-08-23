//
//  XXFFmpegDecoder.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/8/16.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://www.jianshu.com/p/72c2119a4136
//  https://my.oschina.net/u/555701/blog/56616
//  http://www.cnblogs.com/sunminmin/p/4469617.html
//  http://blog.csdn.net/leixiaohua1020/article/details/47072257
//  http://blog.csdn.net/MandyLover/article/details/52946083

#import "XXFFmpegDecoder.h"
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

@interface XXFFmpegDecoder()
{
    AVFormatContext *pFormatCtx;   //数据文件操作者,用于存储音视频封装格式中包含的信息。解封装格式的结构体
    AVCodecContext *pCodecCtx;     //视频的基本参数,例如宽高等，存入音频的基本参数，声道，采样率等
    AVPacket *pPacket;             //创建编码后的数据AVPacket来存储AVFrame编码后生成的数据
    
    AVCodec  *pCodec;
    AVFrame  *pFrame;
    AVFrame  *pFrameYUV;
    
    const char *in_filename;
    const char *out_filename;
}
@end

@implementation XXFFmpegDecoder

-(instancetype)init{
    if(self = [super init]){
        if (![self setEncode]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)setEncode
{
    avcodec_register_all();
    AVCodec *H264Codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    
    if (H264Codec == nil) {
        NSLog(@"/Users/tomxiang/private/XXAudioVideo/XXAudioVideo/XXAudioVideo/Class/FFmpeg/FFmpeg-iOS/manageothers/XXFFmpegRemuxer.h编解码器不支持");
        return  NO;
    }
    AVCodecContext *codecContext = avcodec_alloc_context3(H264Codec);
    if (codecContext == nil) {
        NSLog(@"初始化编解码环境失败");
        return NO;
    }
    codecContext -> width = 640;
    codecContext -> height = 480;
    codecContext->pix_fmt = AV_PIX_FMT_YUV420P;
    codecContext->time_base.den = 25;
    codecContext->time_base.num = 1;
    
    if(avcodec_open2(codecContext, H264Codec, NULL) < 0) {
        
        NSLog(@"打开编码器失败");
        return NO;
    }
    return YES;
}

-(void)initBasicInfo:(NSString*) filePath{
    in_filename = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    NSString *outFileNameStr = [NSTemporaryDirectory() stringByAppendingPathComponent:@"XXFFmpegDecoder.yuv"];
    out_filename = [outFileNameStr cStringUsingEncoding:NSUTF8StringEncoding];
    if([[NSFileManager defaultManager] fileExistsAtPath:outFileNameStr]){
        [[NSFileManager defaultManager] removeItemAtPath:outFileNameStr error:nil];
    }
}


-(void) decoderFile:(NSString*) filePath{
    [self initBasicInfo:filePath];
    int ret;
    unsigned char *out_buffer_video;
    FILE *fp_yuv;
    struct SwsContext *img_convert_ctx;
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
    pPacket = (AVPacket *) av_malloc(sizeof(AVPacket));//h264 data
    pCodecCtx = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(pCodecCtx, pFormatCtx->streams[videoindex]->codecpar);

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
    pFrame = av_frame_alloc();
    pFrameYUV = av_frame_alloc();
    
    //也可以使用avpicture_fill方法替换av_image_get_buffer_size，avpicture_fill为它的简单封装
    /**
     int avpicture_fill(AVPicture *picture, const uint8_t *ptr,
     enum AVPixelFormat pix_fmt, int width, int height)
     {
     return av_image_fill_arrays(picture->data, picture->linesize,
     ptr, pix_fmt, width, height, 1);
     }
     */
    out_buffer_video = (unsigned char*)av_malloc((size_t)av_image_get_buffer_size(AV_PIX_FMT_YUV420P,pCodecCtx->width,pCodecCtx->height,1));
    
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize, out_buffer_video, AV_PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height, 1);
    fp_yuv = fopen(out_filename, "wb+");
    
    int frame_cnt = 0;
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P,
                                     SWS_BICUBIC, NULL, NULL, NULL);
    av_dump_format(pFormatCtx, 0, in_filename, 0);       //打印: 输入格式的详细数据,例如时间,比特率,数据流,容器,元数据,辅助数据,编码,时间戳等

    while( av_read_frame(pFormatCtx, pPacket) >= 0 ) {
        if(pPacket->stream_index == videoindex){
            //Decode::http://xiacaojun.blog.51cto.com/12016059/1932665
            ret = avcodec_send_packet(pCodecCtx, pPacket);
            if(ret != 0){
                printf("Decode Error.\n");
                return;
            }
            while( avcodec_receive_frame(pCodecCtx, pFrame) == 0)
            {
                sws_scale(img_convert_ctx, (const uint8_t *const *) pFrame->data, pFrame->linesize,
                          0,
                          pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
                int y_size = pCodecCtx->width * pCodecCtx->height;
                fwrite(pFrameYUV->data[0], 1, y_size, fp_yuv);      //Y
                fwrite(pFrameYUV->data[1], 1, y_size / 4, fp_yuv);  //U
                fwrite(pFrameYUV->data[2], 1, y_size / 4, fp_yuv);  //V

                //Output info
                char pictype_str[10]={0};
                switch(pFrame->pict_type){
                    case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                    case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                    case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                    default:sprintf(pictype_str,"Other");break;
                }
                
                [self showtoOpenGLView];
                printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
                frame_cnt++;
            }
            av_packet_unref(pPacket);
        }
    }
        
    //flush decoder
    //FIX: Flush Frames remained in Codec
    while (1) {
        ret = avcodec_send_packet(pCodecCtx, pPacket);
        if (ret < 0)
            break;

        while( avcodec_receive_frame(pCodecCtx, pFrame) == 0){
            sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                      pFrameYUV->data, pFrameYUV->linesize);
            int y_size=pCodecCtx->width*pCodecCtx->height;
            fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
            fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
            fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
            //Output info
            char pictype_str[10]={0};
            switch(pFrame->pict_type){
                case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                default:sprintf(pictype_str,"Other");break;
            }
            
            [self showtoOpenGLView];
            printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
            frame_cnt++;
        }
    }

    sws_freeContext(img_convert_ctx);
    fclose(fp_yuv);
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);

    [self gotoEnd];
}


-(void) gotoEnd{
    
    int ret = 0;
    
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);

    if (ret < 0 && ret != AVERROR_EOF) {
        printf("Error occurred.\n");
        return;
    }
    NSLog(@"Finish decoder!");
    
}

-(void) showtoOpenGLView{
    char *buf = (char *)malloc(pFrame->width * pFrame->height * 3 / 2);
    int w, h;
    char *y, *u, *v;
    w = pFrame->width;
    h = pFrame->height;
    y = buf;
    u = y + w * h;
    v = u + w * h / 4;
    
    for (int i=0; i<h; i++)
        memcpy(y + w * i,pFrame->data[0] + pFrame->linesize[0] * i, w);
    for (int i=0; i<h/2; i++)
        memcpy(u + w / 2 * i, pFrame->data[1] + pFrame->linesize[1] * i, w / 2);
    for (int i=0; i<h/2; i++)
        memcpy(v + w / 2 * i, pFrame->data[2] + pFrame->linesize[2] * i, w / 2);
    
    if(self.delegate){
        [self.delegate setVideoSize:pFrame->width height:pFrame->height];
        [self.delegate displayYUV420pData:buf width:pFrame->width height:pFrame->height];
    }
    free(buf);
}

@end
