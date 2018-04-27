//
//  VideoWorker.m
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "VideoWorker.h"
#import "H264VideoDecoder.h"
#include <pthread/pthread.h>
#ifdef __cplusplus
extern "C"
{
#endif    // __cplusplus
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#ifdef __cplusplus
}
#endif    // __cplusplus
int lock_call_back(void ** mutex, enum AVLockOp op)
{
    switch(op)
    {
        case AV_LOCK_CREATE:
            *mutex = (pthread_mutex_t *) malloc(sizeof(pthread_mutex_t));
            pthread_mutex_init((pthread_mutex_t *)(*mutex), NULL);
            break;
        case AV_LOCK_OBTAIN:
            pthread_mutex_lock((pthread_mutex_t *)(*mutex));
            break;
        case AV_LOCK_RELEASE:
            pthread_mutex_unlock((pthread_mutex_t *)(*mutex));
            break;
        case AV_LOCK_DESTROY:
            pthread_mutex_destroy((pthread_mutex_t *)(*mutex));
            free(*mutex);
            break;
    }
    
    return 0;
}

@interface VideoWorker ()
@property (nonatomic, strong) H264VideoDecoder *decoder;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation VideoWorker
- (instancetype)init
{
    self = [super init];
    if (self) {
        avcodec_register_all();
        av_register_all();
        av_lockmgr_register(&lock_call_back);
        
        _decoder = [[H264VideoDecoder alloc] initWith:2000 height:2000];
    }
    return self;
}

- (void)configure:(UIImageView *)imageView
{
    _imageView = imageView;
}

-(void)safePlayEncodedBuffer:(uint8_t *)buffer bufferlen:(NSInteger)len
{
    @synchronized(self)
    {
        [self playEncodedBuffer:buffer bufferlen:len];
    }
}


-(void)playEncodedBuffer:(uint8_t *)buffer  bufferlen:(NSInteger)len
{
    if(len <= 0) return;
    
    [self.decoder setData:buffer nLen:len];
    [self.decoder decode];
    int nBytes = -2;
    AVFrame* pFrame = [self.decoder getDecodeResult:&nBytes];
    //NSLog(@"avframe = %p,nBytes = %d \n",pFrame,nBytes);
    if(nBytes>0 && NULL != pFrame)
    {
        UIImage* image = [self.decoder YUV2RGB2Image:pFrame];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    }
}

@end
