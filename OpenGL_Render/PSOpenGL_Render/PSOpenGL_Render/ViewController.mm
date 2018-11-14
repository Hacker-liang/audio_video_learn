//
//  ViewController.m
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/12.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import "ViewController.h"
#import "PSOpenGLRenderView.h"
#import "CommonUtil.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* pngFilePath = [CommonUtil bundlePath:@"1.png"];

    PSOpenGLRenderView *glView = [[PSOpenGLRenderView alloc] initWithFrame:self.view.bounds filePath:pngFilePath];
    [self.view addSubview: glView];
    [glView render];
}


@end
