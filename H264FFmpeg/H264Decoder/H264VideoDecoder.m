//
//  H264VideoDecoder.m
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "H264VideoDecoder.h"

@implementation H264VideoDecoder
-(instancetype)initWith:(int)width height:(int)height
{
    self = [super initWith:width height:height];
    if (self) {
        avctx->codec_id = AV_CODEC_ID_H264;
        avctx->bit_rate = 400*1000;
        avctx->time_base.den = 10;
        avctx->time_base.num = 1;
        avctx->dct_algo = 0;
        avctx->gop_size = 10; //80
        avctx->me_pre_cmp=2;
//        avctx->me_method =7;
        avctx->qblur = 0.5;
        avctx->nsse_weight = 8;
        avctx->i_quant_factor = (float)0.7;
        avctx->b_quant_factor = 1.25;
        avctx->b_quant_offset = 1.25;
        avctx->pix_fmt = AV_PIX_FMT_YUV420P;//当前YUV420P
        avctx->frame_number = 1;
        avctx->thread_count = 1;
        avctx->thread_type = 0;
        //avctx->flags |= CODEC_FLAG_QSCALE;//CODEC_FLAG_GLOBAL_HEADER;
        
        avctx->me_range = 16;
        avctx->max_qdiff = 4;
        avctx->qmin = 23; //10;
        avctx->qmax = 51; //53
        avctx->qcompress = 0.6;
        codec = avcodec_find_decoder(avctx->codec_id);
        if(!codec)
        {
            NSLog(@"could not find the decoder.");
        }
        AVDictionary* opts = NULL;
        int nRet;
        nRet = avcodec_open2(avctx, codec, &opts);
        
        if (nRet < 0)
        {
            NSLog(@"decode:could not open codec\n");
        }
        [self setupScaler];
    }
    return self;
}

-(NSInteger)decode
{
    m_nBytes = 0;
    
    got_picture_ptr=0;
    int w = avctx->width;
    int h = avctx->height;
    //Decodes a video frame from buf(avpkt) into pFrame. return On error a negative value is returned, otherwise the number of bytes used or zero if no frame could be decompressed.
    AVPacket avpkt;
    av_init_packet(&avpkt);
    avpkt.size = (int)tempSize;
    avpkt.data = tempbuf;
    
    
//    avcodec_send_packet(avctx, &avpkt);
//    m_nBytes = avcodec_receive_frame(avctx, pFrame);
    
    m_nBytes = avcodec_decode_video2(avctx, pFrame, &got_picture_ptr,&avpkt);
    
    if(m_nBytes < 0)
    {
        NSLog(@"decode failed.解码器是：%@(%d*%d)。数据长度：%ld",self.name,self.width,self.height,(long)tempSize);
        
    }
    else
    {
        if (w != avctx->width || h !=avctx->height ) {
            [self setupScaler];
        }
    }
    
    return m_nBytes ;
}

- (void)setupScaler
{
    
    static int sws_flags =  SWS_FAST_BILINEAR;
    if(img_convert_ctx != NULL){
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
    }
    img_convert_ctx = sws_getContext(avctx->width,
                                     avctx->height,
                                     avctx->pix_fmt,
                                     avctx->width,
                                     avctx->height,
                                     AV_PIX_FMT_RGB24,
                                     sws_flags, NULL, NULL, NULL);
    
}
@end
