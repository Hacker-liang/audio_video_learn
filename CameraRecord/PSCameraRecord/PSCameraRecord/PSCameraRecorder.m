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

@interface PSCameraRecorder()

//相机session管理器
@property (nonatomic, strong) AVCaptureSession *captureSession;

//输入输入
@property (nonatomic, strong) AVCaptureInput *captureInput;

//视频输出
@property (nonatomic, strong) AVCaptureOutput *captureOutput;

@end

@implementation PSCameraRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)initCaptureSession
{
    _captureSession = [[AVCaptureSession alloc] init];
    
}

@end
