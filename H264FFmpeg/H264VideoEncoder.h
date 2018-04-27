//
//  H264VideoEncoder.h
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol H264EncoderDelegate <NSObject>

- (void)didEncodedData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)didEncodedSps:(NSData *)sps pps:(NSData *)pps;
@optional
//???
- (void)didEncodedData1:(NSArray*)datas isKeyFrame:(BOOL)isKey;

@end

@interface H264VideoEncoder : NSObject
@property (nonatomic, weak) id<H264EncoderDelegate> delegate;

- (void)startWithSize:(CGSize)videoSize;
- (BOOL)encode:(CMSampleBufferRef)sampleBuffer;
- (void)stop;
@end
