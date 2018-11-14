//
//  PSTextureRender.h
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/14.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface PSTextureRender : NSObject

- (void)renderFrame:(uint8_t *)rgbaFrame;

- (BOOL)prepareRender:(NSInteger)width height:(NSInteger)height;

@end

NS_ASSUME_NONNULL_END
