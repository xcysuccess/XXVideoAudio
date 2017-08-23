//
//  XXFFmpegManagerD.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/27.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXFFmpegManagerD.h"
#ifdef __cplusplus
extern "C"
{
#endif
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libavutil/avstring.h"
    //#include "libavformat/url.h"
#include "x264.h"
#ifdef __cplusplus
};
#endif

int flush_encoderr(AVFormatContext *fmt_ctx,unsigned int stream_index){
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}



@implementation XXFFmpegManagerD

-(instancetype)init{
    if(self = [super init]){
//        yuvCodecToVideoH264(NULL);
//        [self test];
    }
    return self;
}

-(int) test{
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    
    const char *in_filename, *out_filename;
    int ret, i;
    
    in_filename = [[[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"] cStringUsingEncoding:NSASCIIStringEncoding];
    
    NSString *outFileNameStr = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tom.flv"];
    out_filename = [outFileNameStr cStringUsingEncoding:NSUTF8StringEncoding];
    if([[NSFileManager defaultManager] fileExistsAtPath:outFileNameStr]){
        [[NSFileManager defaultManager] removeItemAtPath:outFileNameStr error:nil];
    }
    
//    in_filename = "/Users/biezhihua/Downloads/biezhihua.mp4";
//    out_filename = "/Users/biezhihua/Downloads/biezhihua.flv";
    
    av_register_all();
    
    // Input
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        printf("Could not open input file");
        goto end;
    }
    
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf("Failed to retrieve input stream information");
        goto end;
    }
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    // Output
    avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    
    if (!ofmt_ctx) {
        printf("Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    
    ofmt = ofmt_ctx->oformat;
    
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVCodec *codec = avcodec_find_decoder(in_stream->codecpar->codec_id);
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, codec);
        if (!out_stream) {
            printf("Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        AVCodecContext *pCodecCtx = avcodec_alloc_context3(codec);
        ret = avcodec_parameters_to_context(pCodecCtx, in_stream->codecpar);
        if (ret < 0) {
            printf("Failed to copy context input to output stream codec context\n");
            goto end;
        }
        pCodecCtx->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER) {
            pCodecCtx->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
        ret = avcodec_parameters_from_context(out_stream->codecpar, pCodecCtx);
        if (ret < 0) {
            printf("Failed to copy context input to output stream codec context\n");
            goto end;
        }
    }
    
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    
    // Open output file
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("Could not open output file %s ", out_filename);
            goto end;
        }
    }
    
    // Write file header
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf("Error occurred when opening output file\n");
        goto end;
    }
    
    int frame_index = 0;
    while (1) {
        AVStream *in_stream, *out_stream;
        // Get an AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        
        in_stream = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        
        // Copy packet
        // Convert PTS/DTS
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base,
                                   AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base,
                                   AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        
        pkt.pos = -1;
        
        // Write
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        
        if (ret < 0) {
            printf("Error muxing packet\n");
            break;
        }
        
        printf("Write %8d frames to output file\n", frame_index);
        av_packet_unref(&pkt);
        frame_index++;
    }
    
    // Write file trailer
    av_write_trailer(ofmt_ctx);
    
end:
    avformat_close_input(&ifmt_ctx);
    
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE)) {
        avio_close(ofmt_ctx->pb);
    }
    
    avformat_free_context(ofmt_ctx);
    
    if (ret < 0 && ret != AVERROR_EOF) {
        printf("Error occurred.\n");
        return -1;
    }
    return 0;
}
@end

//AVOutputFormat *guess_format(const char *short_name, const char *filename,
//                             const char *mime_type)
//{
//    AVOutputFormat *fmt = NULL, *fmt_found;
//    int score_max, score;
//
//    /* specific test for image sequences */
//#if CONFIG_IMAGE2_MUXER
//    if (!short_name && filename &&
//        av_filename_number_test(filename) &&
//        ff_guess_image2_codec(filename) != AV_CODEC_ID_NONE) {
//        return av_guess_format("image2", NULL, NULL);
//    }
//#endif
//    /* Find the proper file type. */
//    fmt_found = NULL;
//    score_max = 0;
//    while ((fmt = av_oformat_next(fmt))) {
//        score = 0;
//        if (fmt->name && short_name && av_match_name(short_name, fmt->name))
//            score += 100;
//        if (fmt->mime_type && mime_type && !strcmp(fmt->mime_type, mime_type))
//            score += 10;
//        if (filename && fmt->extensions &&
//            av_match_ext(filename, fmt->extensions)) {
//            score += 5;
//        }
//        if (score > score_max) {
//            score_max = score;
//            fmt_found = fmt;
//        }
//    }
//    return fmt_found;
//}
//
//
//AVOutputFormat *oformat_next(const AVOutputFormat *f)
//{
//    if (f)
//        return f->next;
//    else
//        return (AVOutputFormat *)malloc(sizeof(struct AVOutputFormat));
//}
//
//int amatch(const char *name, const char *names)
//{
//    const char *p;
//    int len, namelen;
//
//    if (!name || !names)
//        return 0;
//
//    namelen = (int)strlen(name);
//    while (*names) {
//        int negate = '-' == names[0];
//        p = strchr(names, ',');
//        if (!p)
//            p = names + strlen(names);
//        names += negate;
//        len = FFMAX((int)(p - names), namelen);
//        if (!strncasecmp(name, names, len) || !strncmp("ALL", names, FFMAX(3, p - names)))
//            return !negate;
//        names = p + (p[0] == ',');
//    }
//    return 0;
//}
//
//int strncasecmp(const char *a, const char *b, size_t n)
//{
//    const char *end = a + n;
//    uint8_t c1, c2;
//    do {
//        c1 = av_tolower(*a++);
//        c2 = av_tolower(*b++);
//    } while (a < end && c1 && c1 == c2);
//    return c1 - c2;
//
//
//}
//
//void yuvCodecToVideoH264(const char *input_file_name)
//{
//    AVFormatContext* pFormatCtx;
//    AVOutputFormat* fmt;
//    AVStream* video_st;
//    AVCodecContext* pCodecCtx;
//    AVCodec* pCodec;
//    AVPacket pkt;
//    uint8_t* picture_buf;
//    AVFrame* pFrame;
//    int picture_size;
//    int y_size;
//    int framecnt=0;
//    //FILE *in_file = fopen("src01_480x272.yuv", "rb"); //Input raw YUV data
//
//    const char *input_file = [[[NSBundle mainBundle] pathForResource:@"FFmpegTest" ofType:@"yuv"]  cStringUsingEncoding:NSUTF8StringEncoding];
//    FILE *in_file = fopen(input_file, "rb");   //Input raw YUV data
//    int in_w=480,in_h=272;                              //Input data's width and height
//    int framenum=100;                                   //Frames to encode
//    //const char* out_file = "src01.h264";              //Output Filepath
//    //const char* out_file = "src01.ts";
//    //const char* out_file = "src01.hevc";
//    const char* out_file = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"dash.h264"] cStringUsingEncoding:NSUTF8StringEncoding];
//
//    av_register_all();
//    //Method1.
//    pFormatCtx = avformat_alloc_context();
//
//    //Guess Format
//    fmt = av_guess_format(NULL, out_file, NULL);
//    pFormatCtx->oformat = fmt;
//
//    // Method 2.
//    // avformat_alloc_output_context2(&pFormatCtx, NULL, NULL, out_file);
//    // fmt = pFormatCtx->oformat;
//
//    //Open output URL
//    if (avio_open(&pFormatCtx->pb,out_file, AVIO_FLAG_READ_WRITE) < 0){
//        printf("Failed to open output file! \n");
//        return;
//    }
//
//    video_st = avformat_new_stream(pFormatCtx, 0);
//    video_st->time_base.num = 1;
//    video_st->time_base.den = 25;
//
//    if (video_st==NULL){
//        return ;
//    }
//    //Param that must set
//    pCodecCtx = video_st->codec;
//    //pCodecCtx->codec_id =AV_CODEC_ID_HEVC;
//    pCodecCtx->codec_id = fmt->video_codec;
//    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
//    pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
//    pCodecCtx->width = in_w;
//    pCodecCtx->height = in_h;
//    pCodecCtx->bit_rate = 400000;
//    pCodecCtx->gop_size=250;
//
//    pCodecCtx->time_base.num = 1;
//    pCodecCtx->time_base.den = 25;
//
//    //H264
//    //pCodecCtx->me_range = 16;
//    //pCodecCtx->max_qdiff = 4;
//    //pCodecCtx->qcompress = 0.6;
//    pCodecCtx->qmin = 10;
//    pCodecCtx->qmax = 51;
//
//    //Optional Param
//    pCodecCtx->max_b_frames=3;
//
//    // Set Option
//    AVDictionary *param = 0;
//    //H.264
//    if(pCodecCtx->codec_id == AV_CODEC_ID_H264) {
//        av_dict_set(&param, "preset", "slow", 0); // 通过--preset的参数调节编码速度和质量的平衡。
//        av_dict_set(&param, "tune", "zerolatency", 0); // 通过--tune的参数值指定片子的类型，是和视觉优化的参数，或有特别的情况。
//        // 零延迟，用在需要非常低的延迟的情况下，比如电视电话会议的编码
//        //av_dict_set(¶m, "profile", "main", 0);
//    }
//    //H.265
//    if(pCodecCtx->codec_id == AV_CODEC_ID_H265){
//        av_dict_set(&param, "preset", "ultrafast", 0);
//        av_dict_set(&param, "tune", "zero-latency", 0);
//    }
//
//    //Show some Information
//    av_dump_format(pFormatCtx, 0, out_file, 1);
//
//    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
//    if (!pCodec){
//        printf("Can not find encoder! \n");
//        return;
//    }
//    if (avcodec_open2(pCodecCtx, pCodec,&param) < 0){
//        printf("Failed to open encoder! \n");
//        return;
//    }
//
//
//    pFrame = av_frame_alloc();
//    picture_size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
//    picture_buf = (uint8_t *)av_malloc(picture_size);
//    avpicture_fill((AVPicture *)pFrame, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
//
//    //Write File Header
//    int ret = avformat_write_header(pFormatCtx,NULL);
//    if (ret < 0) {
//        printf("write header is failed");
//        return;
//    }
//
//    av_new_packet(&pkt,picture_size);
//
//    y_size = pCodecCtx->width * pCodecCtx->height;
//
//    for (int i=0; i<framenum; i++){
//        //Read raw YUV data
//        if (fread(picture_buf, 1, y_size*3/2, in_file) <= 0){
//            printf("Failed to read raw data! \n");
//            return ;
//        }else if(feof(in_file)){
//            break;
//        }
//        pFrame->data[0] = picture_buf;              // Y
//        pFrame->data[1] = picture_buf+ y_size;      // U
//        pFrame->data[2] = picture_buf+ y_size*5/4;  // V
//        //PTS
//        //pFrame->pts=i;
//        pFrame->pts=i*(video_st->time_base.den)/((video_st->time_base.num)*25);
//        int got_picture=0;
//        //Encode
//        int ret = avcodec_encode_video2(pCodecCtx, &pkt,pFrame, &got_picture);
//        if(ret < 0){
//            printf("Failed to encode! \n");
//            return ;
//        }
//        if (got_picture==1){
//            printf("Succeed to encode frame: %5d\tsize:%5d\n",framecnt,pkt.size);
//            framecnt++;
//            pkt.stream_index = video_st->index;
//            ret = av_write_frame(pFormatCtx, &pkt);
//            av_free_packet(&pkt);
//        }
//    }
//    //Flush Encoder
//    int ret2 = flush_encoderr(pFormatCtx,0);
//    if (ret2 < 0) {
//        printf("Flushing encoder failed\n");
//        return;
//    }
//
//    //Write file trailer
//    av_write_trailer(pFormatCtx);
//
//    //Clean
//    if (video_st){
//        avcodec_close(video_st->codec);
//        av_free(pFrame);
//        av_free(picture_buf);
//    }
//    avio_close(pFormatCtx->pb);
//    avformat_free_context(pFormatCtx);
//
//    fclose(in_file);
//    //
//    //    x264_param_t *xparam = malloc(sizeof(x264_param_t));
//    //    x264_param_default(xparam);
//    //    x264_param_default_preset(xparam, "slower", "zerolatency");
//}
//
//
//
//
//////3.打开输出文件,将输出文件中的数据读入到程序的 buffer 当中
////if(avio_open(&pFormatContext->pb, out_filename, AVIO_FLAG_READ_WRITE)<0){
////    printf("Failed to open output file! \n");
////    return;
////}
////
//////4.创建输出码流的AVStream。
////video_stream = avformat_new_stream(pFormatContext, 0);
//////设置25帧每秒,也就是fps为25
////video_stream->time_base.num = 1;
////video_stream->time_base.den = 25;
////if (video_stream==NULL){
////    return ;
////}
////
//////5.avcodec_find_encoder并设置编码格式
//////为输出文件设置编码所需要的参数和格式,一个AVStream对应一个AVCodecContext
////pCodec = avcodec_find_encoder(outputFormat->video_codec);    //音频为audio_codec
////if (!pCodec){
////    printf("Can not find encoder! \n");
////    return;
////}
////pCodeContext = avcodec_alloc_context3(pCodec);
////
////#if IS_FFMPEG_VERSION_1
////avcodec_parameters_from_context(video_stream->codecpar, pCodeContext);//将AVCodecContext的成员复制到AVCodecParameters结构体。前后两行不能调换顺序
////#else
////pCodeContext = video_stream->codec;
////#endif
////
////
////
////AVDictionary *param = 0;
////if(pCodeContext->codec_id == AV_CODEC_ID_H264){         //H.264
////    av_dict_set(&param, "preset", "slow", 0);           //通过--preset的参数调节编码速度和质量的平衡。
////    av_dict_set(&param, "tune", "zerolatency", 0);      //通过--tune的参数值指定片子的类型，是和视觉优化的参数，或有特别的情况
////
////}else if(pCodeContext->codec_id == AV_CODEC_ID_HEVC){   //H.265
////    av_dict_set(&param, "preset", "ultrafast", 0);
////    av_dict_set(&param, "tune", "zero-latency", 0);
////
////}
////
//////6.avcodec_open2
////if(avcodec_open2(pCodeContext, pCodec, &param) < 0){
////    printf("Failed to open encoder! \n");
////    return;
////}
////
//////7.avformat_write_header
////
//////设置原始数据 AVFrame
////pFrame = av_frame_alloc();
////
////int picture_size = av_image_get_buffer_size(pCodeContext->pix_fmt, pCodeContext->width, pCodeContext->height, 1);//通过像素格式(这里为 YUV)获取图片的真实大小，例如将 480 * 720 转换成 int 类型
////picture_buf = (unsigned char*)av_malloc(picture_size);// 将picture_size转换成字节数据，byte
////
////#if IS_FFMPEG_VERSION_1
////av_image_fill_arrays(pFrame->data, pFrame->linesize, picture_buf, AV_PIX_FMT_YUV420P, pCodeContext->width, pCodeContext->height, 1);    // 设置原始数据 AVFrame 的每一个frame 的图片大小，AVFrame 这里存储着 YUV 非压缩数据
////#else//旧版本
////avpicture_fill((AVPicture *)pFrame, picture_buf, pCodeContext->pix_fmt, pCodeContext->width, pCodeContext->height);
////#endif
////int ret = avformat_write_header(pFormatContext,NULL);
////if(ret < 0){
////    printf("write header is failed");
////    return;
////}
////
//////8.avcodec_encode_video2
////av_new_packet(&pPacket,picture_size);   //创建编码后的数据 AVPacket 结构体来存储 AVFrame 编码后生成的数据
////// 设置 yuv 数据中 y 图的宽高
////int y_size = pCodeContext->width * pCodeContext->height;
////FILE *in_file = fopen(inputFile, "rb");   //Input raw YUV data
////
////for(int i = 0;i < framenum; ++i){
////    //Read raw YUV data
////    if(fread(picture_buf, 1, y_size*3/2, in_file) <= 0){
////        printf("Failed to read raw data! \n");
////        return;
////    }else if(feof(in_file)){
////        break;
////    }
////    pFrame->data[0] = picture_buf;              //Y
////    pFrame->data[1] = picture_buf + y_size;     //U
////    pFrame->data[2] = picture_buf + y_size*5/4; //V
////
////    //PTS:设置这一帧的显示时间
////    //pFrame->pts = i;
////    pFrame->pts = i * (video_stream->time_base.den)/((video_stream->time_base.num) * 25);
////
////    int got_picture = 0;
////#if IS_FFMPEG_VERSION_1
////    //利用编码器进行编码，将 pFrame 编码后的数据传入pPacket中
////    int retSend = avcodec_send_frame(pCodeContext, pFrame);
////    int retAVCodec = avcodec_receive_packet(pCodeContext, &pPacket);
////    if(retSend < 0 || retAVCodec < 0){
////        printf("Failed to encode! \n");
////        return ;
////    }
////#else
////    int ret = avcodec_encode_video2(pCodeContext, &pPacket, pFrame, &got_picture);
////    if(ret < 0){
////        printf("Failed to encode! \n");
////        return ;
////    }
////#endif
////
////
////    //9.av_write_frame
////    //编写成功后写入AVPacket到输入输出数据操作者pFormatContext中,当然,记得释放内存
////    if(got_picture == 1){
////        printf("Succeed to encode frame: %5d\tsize:%5d\n",framecount,pPacket.size);
////        framecount++;
////        pPacket.stream_index = video_stream->index;
////        ret = av_write_frame(pFormatContext, &pPacket);
////        av_packet_unref(&pPacket);
////    }
////}
//
//@end
//        pCodeContext->codec_id = outputFormat->video_codec;  //设置编码器的id,每一个编码器都对应着自己的id
//        pCodeContext->codec_type = AVMEDIA_TYPE_VIDEO;       //视频编码类型
//        pCodeContext->pix_fmt =  AV_PIX_FMT_YUV420P;         //设置像素格式为yuv420
//        pCodeContext->width = videoWidth;
//        pCodeContext->height = videoHeight;
//        pCodeContext->bit_rate = 1400*1000;                  //码率
//        pCodeContext->gop_size = 250;                        //两个I帧之间的间隔,按照现在的设置,10秒只会出现一个关键帧
//        pCodeContext->time_base.num = 1;
//        pCodeContext->time_base.den = 25;                    //设置25帧每秒 ，也就是fps为25
//
//        pCodeContext->qmin = 10;                             //最小视频量化标度
//        pCodeContext->qmax = 51;                             //最大视频量化标度
//        pCodeContext->max_b_frames = 3;                      //B帧,压缩率最高，帧间预测,越多 B 帧的视频，越清晰，现在很多打视频网站的高清视频，就是采用多编码 B 帧去提高清晰度,但同时对于编解码的复杂度比较高，比较消耗性能与时间.两个非B帧之间允许插入的最大B帧的数目
//1.av_register_all()：注册FFmpeg所有编解码器。
//2.avformat_alloc_output_context2()：初始化输出码流的AVFormatContext。
//3.avio_open()：打开输出文件。
//4.av_new_stream()：创建输出码流的AVStream。
//5.avcodec_find_encoder()：查找编码器。
//6.avcodec_open2()：打开编码器。
//7.avformat_write_header()：写文件头（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）。
//8.avcodec_encode_video2()：编码一帧视频。即将AVFrame（存储YUV像素数据）编码为AVPacket（存储H.264等格式的码流数据）。
//9.av_write_frame()：将编码后的视频码流写入文件。
//10.flush_encoder()：输入的像素数据读取完成后调用此函数。用于输出编码器中剩余的AVPacket。
//11.av_write_trailer()：写文件尾（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）。
