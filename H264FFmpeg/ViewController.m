//
//  ViewController.m
//  H264FFmpeg
//
//  Created by yanzhen on 2018/4/27.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "ViewController.h"
#import "H264VideoEncoder.h"
#import "VideoWorker.h"
#import <AVFoundation/AVFoundation.h>


/*
 1. header search path
 2. libz.tbd
 */

static int const frameRate = 12;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, H264EncoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *localView;
@property (weak, nonatomic) IBOutlet UIImageView *showView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t dataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureConnection *connect;
@property (nonatomic, assign) BOOL front;

@property (nonatomic, strong) H264VideoEncoder *encoder;
@property (nonatomic, strong) VideoWorker *worker;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _front = YES;
    _encoder = [[H264VideoEncoder alloc] init];
    _encoder.delegate = self;
    _worker = [[VideoWorker alloc] init];
    [_worker configure:_showView];
}


- (IBAction)start:(id)sender {
    if (self.session.isRunning) return;
    [_encoder startWithSize:CGSizeMake(480, 640)];
    [self start];
}

- (void)decoderData:(NSData *)data
{
    [_worker safePlayEncodedBuffer:data.bytes bufferlen:data.length];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [_encoder encode:sampleBuffer];
}
#pragma mark - H264EncoderDelegate
-(void)didEncodedData:(NSData *)data isKeyFrame:(BOOL)isKey
{
    const char bytes[] = "\x00\x00\x00\x01";//视频数据的前4个字节时 0x00 0x00 0x00 0x01
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [self decoderData:h264Data];
}

-(void)didEncodedSps:(NSData *)sps pps:(NSData *)pps
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    //    [_decoder decodeData:h264Data];
    [self decoderData:h264Data];
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    //    [_decoder decodeData:h264Data];
    [self decoderData:h264Data];
}

- (void)start{
    if (self.session.isRunning) return;
    
    AVCaptureDevice *camera = nil;
    camera = [self cameraWithPosition:_front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    
    NSError *error;
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    if (error) {
        NSLog(@"error %@",error.description);
    }
    
    [self.dataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
    
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
        
    }
    
    [_session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    _connect = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    [_connect setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [_session commitConfiguration];
    
    
    AVCaptureVideoPreviewLayer *previewLayer= [AVCaptureVideoPreviewLayer layerWithSession:_session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.backgroundColor = [UIColor clearColor].CGColor;
    previewLayer.frame = self.localView.bounds;
    [self.localView.layer addSublayer:previewLayer];
    
    [camera lockForConfiguration:nil];
    camera.activeVideoMinFrameDuration = CMTimeMake(1, frameRate);
    camera.activeVideoMaxFrameDuration = CMTimeMake(1, frameRate + 2);
    [camera unlockForConfiguration];
    //防抖模式，被称为影院级的视频防抖动
    if ([camera.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        [_connect setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeCinematic];
    }else if([camera.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeAuto]){
        [_connect setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.session startRunning];
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ( device.position == position )
            return device;
    return nil;
}

- (void)willResignActive
{
    //进入后台停止编码
    [_encoder stop];
}

- (void)didBecomeActive
{
    __weak ViewController* weakSelf = self;
    dispatch_async(self.dataOutputQueue, ^{
        //从后台返回，重新开始编码
        [weakSelf.encoder startWithSize:CGSizeMake(480, 640)];
    });
}
#pragma mark - lazy var
-(dispatch_queue_t)dataOutputQueue{
    if (!_dataOutputQueue) {
        _dataOutputQueue = dispatch_queue_create("com.video.queue", 0);
    }
    return _dataOutputQueue;
}

-(AVCaptureSession *)session{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureVideoDataOutput*)dataOutput
{
    if (!_dataOutput) {
        _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _dataOutput.alwaysDiscardsLateVideoFrames = YES;
#pragma mark - 1.0.2
        _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    }
    return _dataOutput;
}

@end
