//
//  VideoDecoder.m
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "VideoDecoder.h"
#import "libavcodec/avcodec.h"

UIImage* imageFromAVPicture(AVPicture pict, int width,int height)
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

@implementation VideoDecoder
- (instancetype)initWith:(int)width height:(int)height
{
    self = [super initWith:width height:height];
    pFrame = av_frame_alloc();
    tempbuf = nil;
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, avctx->width, avctx->height);
    
    return self;
}

- (void)setData:(uint8_t *)bufRipe nLen:(NSInteger)nLen
{
    tempSize = nLen;
    tempbuf = bufRipe;
}

- (AVFrame*)getDecodeResult:(int*) nBytesOut
{
    *nBytesOut = m_nBytes;//the used bytes of buf
    return pFrame;
}

- (UIImage *)YUV2RGB2Image:(AVFrame*)yuvFrame
{
    if (yuvFrame->width != avctx->width ||
        yuvFrame->height != avctx->height) {
        return nil;
    }
    NSLog(@"TTTT-----------:%s",picture.data[0]);
    sws_scale(img_convert_ctx, yuvFrame->data, yuvFrame->linesize,
                          0, avctx->height,
                          picture.data, picture.linesize);    //convertFrameToRGB
    
    int iWidth = avctx->width;
    int iHeight = avctx->height;
    UIImage* image = imageFromAVPicture(picture, iWidth, iHeight);
    return image;
    
}

- (void)dealloc
{
    avpicture_free(&picture);
    av_free(pFrame);
    
    pFrame = NULL;
    sws_freeContext(img_convert_ctx);
    img_convert_ctx = NULL;
}
@end
