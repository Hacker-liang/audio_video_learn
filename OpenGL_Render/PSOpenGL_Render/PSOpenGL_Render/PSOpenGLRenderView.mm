//
//  PSOpenGLRenderView.m
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/13.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import "PSOpenGLRenderView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation PSOpenGLRenderView {
    EAGLContext*        _context;
    dispatch_queue_t    _contextQueue;
    GLuint              _displayFrameBuffer;
    GLuint              _renderBuffer;
    GLint               _backingWidth;
    GLint               _backingHeight;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAEAGLLayer *glLayer = (CAEAGLLayer *)[self layer];  //替换成OPENGL的layer
        NSDictionary *dic = @{
                              kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:NO],
                              kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGB565
                              };
        [glLayer setOpaque:YES];
        [glLayer setDrawableProperties:dic];
        
        _contextQueue = dispatch_queue_create("com.videoRenderQueue", NULL);   //创建渲染的队列
        dispatch_async(_contextQueue, ^{
            self->_context = [self createEAGLContext];
            [EAGLContext setCurrentContext:self->_context];   //绑定context
            
            [self createFrameBuffer];   //创建帧缓冲区/绘制缓冲区
        });
    }
    return self;
}

- (EAGLContext *)createEAGLContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];   //选择OpenGL ES2版本
    return context;
}

- (BOOL)createFrameBuffer {
    glGenFramebuffers(1, &_displayFrameBuffer);   //创建帧缓冲区
    glGenRenderbuffers(1, &_renderBuffer);        //创建绘制缓冲区
    glBindBuffer(GL_FRAMEBUFFER, _displayFrameBuffer);   //绑定帧缓冲区到渲染管线
    glBindBuffer(GL_RENDERBUFFER, _renderBuffer);     //绑定绘制缓冲区到管线
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];   //为绘制缓冲区分配存储区，将self.layer作为缓冲区
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);    //获取绘制缓冲区的像素宽度(self.width ???)
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);    //获取绘制缓冲区的像素宽度(self.height ???)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);   //将绘制缓冲区绑定到帧缓冲区上
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);  //检查帧缓冲区的状态
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
        return NO;
    }
    
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        NSLog(@"failed to setup GL %x", glError);
        return FALSE;
    }

    return TRUE;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

@end
