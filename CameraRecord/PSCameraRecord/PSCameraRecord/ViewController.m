//
//  ViewController.m
//  PSCameraRecord
//
//  Created by 梁鹏帅 on 2018/11/14.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import "ViewController.h"
#import "PSCameraRecorder.h"

@interface ViewController ()

@property (nonatomic, strong) PSCameraRecorder *cameraRecorder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _cameraRecorder = [[PSCameraRecorder alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_cameraRecorder startPreview];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_cameraRecorder stopPreview];
}

@end
