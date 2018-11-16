//
//  PSCameraRecorder.m
//  PSCameraRecord
//
//  Created by 梁鹏帅 on 2018/11/14.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import "PSCameraRecorder.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface PSCameraRecorder() <AVCaptureVideoDataOutputSampleBufferDelegate>

//相机session管理器
@property (nonatomic, strong) AVCaptureSession *captureSession;

//输入输入
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;

//视频输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;

@end

@implementation PSCameraRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initCaptureSession];
    }
    return self;
}

- (void)initCaptureSession
{
    _captureSession = [[AVCaptureSession alloc] init];
    
    //获取前置摄像头
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([device position] == AVCaptureDevicePositionFront) {
            captureDevice = device;
        }
    }
    //配置摄像input
    _captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
    
    //创建一个串行的队列来接收output的数据
    dispatch_queue_t cameraDataCallBackQueue;
    cameraDataCallBackQueue = dispatch_queue_create("cameraDataCallBackQueue", DISPATCH_QUEUE_SERIAL);
    _captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureOutput setSampleBufferDelegate:self queue: cameraDataCallBackQueue];
    
    if ([_captureSession canAddInput:_captureInput]) {
        [_captureSession addInput:_captureInput];
    }
    if ([_captureSession canAddOutput:_captureOutput]) {
        [_captureSession addOutput:_captureOutput];
    }
    //设置录制分辨率
    [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    //设置输出方向
    AVCaptureConnection *connection = [_captureOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation =  AVCaptureVideoOrientationPortrait;
    
}

- (void)startPreview
{
    [_captureSession startRunning];
}

- (void)stopPreview
{
    [_captureSession stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"I am dropping frame: %@", sampleBuffer);
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"I am receiving frame: %@", sampleBuffer);

}

@end
