//
//  VideoCoder.m
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "VideoCoder.h"
#import "libavutil/imgutils.h"

@implementation VideoCoder
-(instancetype)initWith:(int)width height:(int)height
{
    self = [super init];
    if (self) {
        codec = NULL;
        avctx = avcodec_alloc_context3(codec);
        
        avctx->width =  width;//编码解码尺寸
        avctx->height = height;
        avctx->codec_type = AVMEDIA_TYPE_VIDEO;

        //bufSize = avpicture_get_size(AV_PIX_FMT_YUV420P, avctx->width, avctx->height);
        bufSize = av_image_get_buffer_size(AV_PIX_FMT_YUV420P, avctx->width, avctx->height, 1);
        buf = (uint8_t*)av_malloc(bufSize);
    }
    return self;
}

-(int)width
{
    return avctx->width;
}

-(int)height
{
    return avctx->height;
}

-(void) dealloc
{
    avcodec_close(avctx);
    
    av_free(avctx);
    avctx = NULL;
    
    free(buf);
    buf =  NULL;
}
@end
