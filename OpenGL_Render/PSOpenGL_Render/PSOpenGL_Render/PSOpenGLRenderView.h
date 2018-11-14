//
//  PSOpenGLRenderView.h
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/13.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PSOpenGLRenderView : UIView

- (instancetype)initWithFrame:(CGRect)frame filePath:(NSString *)path;

- (void)render;

@end

NS_ASSUME_NONNULL_END
