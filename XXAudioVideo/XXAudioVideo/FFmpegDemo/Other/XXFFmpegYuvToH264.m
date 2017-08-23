//
//  XXFFmpegYuvToH264.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/26.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://www.jianshu.com/p/1fa040249073
//  http://blog.csdn.net/leixiaohua1020/article/details/25430425
//  http://blog.csdn.net/MandyLover/article/details/52946083  FFMPEG新老接口问题的部分解决方案
//  http://allluckly.cn/ffmpeg/ffmpeg3
//  http://blog.csdn.net/leixiaohua1020/article/details/25422685
//  http://www.jianshu.com/p/73520393d794 转文件格式
//  http://blog.csdn.net/leixiaohua1020/article/details/25422685

#import "XXFFmpegYuvToH264.h"
#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libavutil/avstring.h"
    
#ifdef __cplusplus
};
#endif
#define IS_FFMPEG_VERSION_1 (1)

@interface XXFFmpegYuvToH264()
{
    AVFormatContext *pInFormatContext;  //数据文件操作者,用于存储音视频封装格式中包含的信息。解封装格式的结构体
    AVFormatContext *pOutFormatContext;
    AVOutputFormat *outputFormat;       //输出的格式,包括音频封装格式,视频封装格式,字幕封装格式,所有封装格式都在AVCodecID这个枚举类型上面
    
//    AVStream *inStream;                 //一个装载着视频/音频流信息的结构体,包括音视频流的长度,元数据信息，其中index属性用于表示视频/音频流
//    AVStream *outStream;

//    AVCodecContext *pCodeContext;       //视频的基本参数,例如宽高等，存入音频的基本参数，声道，采样率等
//    AVCodec *pCodec;                    //编码器,设置编码类型，像素格式，视频宽高,fps(每秒帧数),用于编解码音视频编码层使用
    
//    AVFrame* pFrame;                    //原始数据,视频:YUV,RGB。音频:PCM. 宏块类型表，QP表，运动矢量表等数据
    AVPacket pPacket;                   //创建编码后的数据AVPacket来存储AVFrame编码后生成的数据
    
//    int videoWidth;
//    int videoHeight;
//    int framenum;
    
    const char *in_filename;
    const char *out_filename;
    
//    unsigned char * picture_buf;
}
@end


@implementation XXFFmpegYuvToH264

-(instancetype)init{
    if(self = [super init]){
        if (![self setEncode]) {
            return nil;
        }
        [self initBasicInfo];
    }
    return self;
}

- (BOOL)setEncode
{
    avcodec_register_all();
    AVCodec *H264Codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    if (H264Codec == nil) {
        NSLog(@"编解码器不支持");
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

-(void)initBasicInfo{
    in_filename = [[[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"] cStringUsingEncoding:NSASCIIStringEncoding];

    NSString *outFileNameStr = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mov2flv.flv"];
    out_filename = [outFileNameStr cStringUsingEncoding:NSUTF8StringEncoding];
    if([[NSFileManager defaultManager] fileExistsAtPath:outFileNameStr]){
        [[NSFileManager defaultManager] removeItemAtPath:outFileNameStr error:nil];
    }
}
//1.avformat_open_input()：打开输入文件，初始化输入视频码流的AVFormatContext。
//2.av_read_frame()：从输入文件中读取一个AVPacket。
//3.avformat_alloc_output_context2()：初始化输出视频码流的AVFormatContext。
//4.avformat_new_stream()：创建输出码流的AVStream。
//avcodec_copy_context()：拷贝输入视频码流的AVCodecContex的数值t到输出视频的AVCodecContext。
//5.avio_open()：打开输出文件。
//6.avformat_write_header()：写文件头（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）。
//7.av_interleaved_write_frame()：将AVPacket（存储视频压缩码流数据）写入文件。
//8.av_write_trailer()：写文件尾（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）。
//
//作者：H_Liuju
//链接：http://www.jianshu.com/p/73520393d794
//來源：简书
//著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

-(void) yuvCodecToVideoH264{
    int ret;

//1.注册FFmpeg所有编解码器。
    av_register_all();
    
//2.avformat_open_input
    if((ret = avformat_open_input(&pInFormatContext, in_filename, 0, 0))<0){
        printf("Could not open input file!");
        [self gotoEnd];
        return;
    }
//2.2.avformat_find_stream_info
    if((ret = avformat_find_stream_info(pInFormatContext, 0))<0){
        printf("Failed to retrieve input stream information!");
        [self gotoEnd];
        return;
    }
    av_dump_format(pInFormatContext, 0, in_filename, 0);       //输入格式的详细数据,例如时间,比特率,数据流,容器,元数据,辅助数据,编码,时间戳等

//3.初始化输出码流的AVFormatContext。
    avformat_alloc_output_context2(&pOutFormatContext, NULL, NULL, out_filename);
    if (!pOutFormatContext) {
        printf("Failed avformat_alloc_output_context2");
        [self gotoEnd];
        return;
    }
    outputFormat = pOutFormatContext->oformat;
    
//4.遍历inputFormatContext的stream，复制到pCodeContext中
    for (int i = 0 ; i< pInFormatContext->nb_streams; ++i) {
        AVStream *in_stream = pInFormatContext->streams[i];
//4.1.avcodec_find_encoder查找编码器
        AVCodec *codec = avcodec_find_decoder(in_stream->codecpar->codec_id);
//4.2.avformat_new_stream,创建输出码流的AVStream。
        AVStream *out_stream = avformat_new_stream(pOutFormatContext, codec);
        if (!out_stream) {
            printf("Failed allocating output stream\n");
            [self gotoEnd];
            return;
        }
//4.3.为输出文件设置编码所需要的参数和格式,一个AVStream对应一个AVCodecContext
        AVCodecContext *pCodeContext = avcodec_alloc_context3(codec);
        ret = avcodec_parameters_to_context(pCodeContext, in_stream->codecpar);
//        ret = avcodec_parameters_from_context(in_stream->codecpar, pCodeContext);//将AVCodecContext的成员复制到AVCodecParameters结构体。前后两行不能调换顺序
        if (ret < 0) {
            printf("Failed to copy context input to output stream codec context\n");
            [self gotoEnd];
            return;
        }

        pCodeContext->codec_tag = 0;
        if (pOutFormatContext->oformat->flags & AVFMT_GLOBALHEADER) {
            pCodeContext->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
        
        ret = avcodec_parameters_from_context(out_stream->codecpar, pCodeContext);
        if (ret < 0) {
            printf("Failed to copy context input to output stream codec context\n");
            [self gotoEnd];
            return;
        }
    }
    av_dump_format(pOutFormatContext, 0, out_filename, 1);       //输出格式的详细数据,例如时间,比特率,数据流,容器,元数据,辅助数据,编码,时间戳等
    
//5.avio_open 打开输出文件,将输出文件中的数据读入到程序的 buffer 当中
    if (!(outputFormat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&pOutFormatContext->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("Could not open output file %s ", out_filename);
            [self gotoEnd];
            return;
        }
    }
    
//6.avformat_write_header
    ret = avformat_write_header(pOutFormatContext, NULL);
    if (ret < 0) {
        printf("Error occurred when opening output file\n");
        [self gotoEnd];
        return;
    }

//7.av_interleaved_write_frame]
    int frame_index = 0;
    while (1) {
        AVStream *in_stream,*out_stream;
        
//7.1.av_read_frame Get an AVPacket 从输入文件中读取一个AVPacket
        ret = av_read_frame(pInFormatContext, &pPacket);
        if (ret < 0) {
            printf("Error av_read_frame\n");
            break;
        }
        in_stream = pInFormatContext->streams[pPacket.stream_index];
        out_stream = pOutFormatContext->streams[pPacket.stream_index];
//7.2.Copy packet Convert PTS/DTS
        pPacket.pts = av_rescale_q_rnd(pPacket.pts, in_stream->time_base, out_stream->time_base,
                                       AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        
        pPacket.dts = av_rescale_q_rnd(pPacket.dts, in_stream->time_base, out_stream->time_base,
                                       AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        
        pPacket.duration = av_rescale_q(pPacket.duration, in_stream->time_base, out_stream->time_base);
        pPacket.pos = -1;
        
//7.3
        ret = av_interleaved_write_frame(pOutFormatContext, &pPacket);

        if(ret < 0){
            printf("Error muxing packet\n");
            break;
        }
        
        printf("Write %8d frames to output file\n",frame_index);
        av_packet_unref(&pPacket);
        frame_index ++;
    }
    
    
//8.av_write_trailer
    av_write_trailer(pOutFormatContext);

    [self gotoEnd];
}

-(void) gotoEnd{
    
    int ret = 0;
    
    avformat_close_input(&pInFormatContext);
    
    if (pOutFormatContext && !(pOutFormatContext->flags & AVFMT_NOFILE)) {
        avio_close(pOutFormatContext->pb);
    }
    avformat_free_context(pOutFormatContext);
    
    if (ret < 0 && ret != AVERROR_EOF) {
        printf("Error occurred.\n");
        return;
    }
}


@end
