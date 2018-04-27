//
//  VideoCoder.h
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
extern "C"
{
#endif
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/pixfmt.h"
#ifdef __cplusplus
}
#endif    // __cplusplus

@interface VideoCoder : NSObject {
    AVCodecContext *avctx;
    AVCodec* codec;
    uint8_t *buf;
    int bufSize;
    
    NSInteger tempSize;//理论上（正常情况）m_nBytes和它相等
    int m_nBytes;//buf的有效字节数
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;

-(instancetype)initWith:(int)width height:(int)height;
@end
