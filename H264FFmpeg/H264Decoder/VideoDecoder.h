//
//  VideoDecoder.h
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "VideoCoder.h"
#include "libswscale/swscale.h"

@interface VideoDecoder : VideoCoder{
    AVFrame* pFrame;
    AVPicture picture;
    int got_picture_ptr;
    struct SwsContext *img_convert_ctx;
    uint8_t* tempbuf;
}
- (void)setData:(uint8_t *)bufRipe nLen:(NSInteger)nLen;
- (AVFrame *)getDecodeResult:(int *)nBytesOut;
- (UIImage *)YUV2RGB2Image:(AVFrame *)yuvFrame;
@end
