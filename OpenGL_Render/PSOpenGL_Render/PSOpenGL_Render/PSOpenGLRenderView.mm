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
#import "rgba_frame.hpp"
#import "png_decoder.h"
#import "PSTextureRender.h"

@interface PSOpenGLRenderView()

@property (nonatomic, strong) NSLock *shouldEnableOpenGLLock;

@end

@implementation PSOpenGLRenderView {
    EAGLContext*        _context;
    dispatch_queue_t    _contextQueue;
    GLuint              _displayFrameBuffer;
    GLuint              _renderBuffer;
    GLint               _backingWidth;
    GLint               _backingHeight;
    RGBAFrame*          _frame;
    PSTextureRender*    _textureRender;

}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame filePath:(NSString *)path
{
    self = [super initWithFrame:frame];
    if (self) {
        _shouldEnableOpenGLLock = [NSLock new];
        
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
            self->_frame = [self getRGBAFrame:path];
            
            self->_textureRender = [[PSTextureRender alloc] init];
            [self->_textureRender prepareRender:self->_frame->width height:self->_frame->height];
        });
    }
    return self;
}

- (void)render
{
    dispatch_async(_contextQueue, ^{
        if (self->_frame) {
//            [EAGLContext setCurrentContext:self->_context];
//            glBindFramebuffer(GL_FRAMEBUFFER, self->_displayFrameBuffer);
            glViewport(0, self->_backingHeight-self->_frame->height, self->_frame->width, self->_frame->height);
            [self->_textureRender renderFrame:self->_frame->pixels];
            [self->_context presentRenderbuffer:GL_RENDERBUFFER];
        }
    });
}

- (EAGLContext *)createEAGLContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];   //选择OpenGL ES2版本
    return context;
}

- (BOOL)createFrameBuffer {
    glGenFramebuffers(1, &_displayFrameBuffer);   //创建帧缓冲区
    glGenRenderbuffers(1, &_renderBuffer);        //创建绘制缓冲区
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFrameBuffer);   //绑定帧缓冲区到渲染管线
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);     //绑定绘制缓冲区到管线
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

- (RGBAFrame *)getRGBAFrame:(NSString *)pngFilePath
{
    PngPicDecoder* decoder = new PngPicDecoder();
    char* pngPath = (char*)[pngFilePath cStringUsingEncoding:NSUTF8StringEncoding];
     decoder->openFile(pngPath);
    RawImageData data = decoder->getRawImageData();
    RGBAFrame* frame = new RGBAFrame();
    frame->width = data.width;
    frame->height = data.height;
    int exceptLength = data.width*data.height*4;    //rgba，每个像素需要4个字节，因此需要*4
    uint8_t * pixels = new uint8_t[exceptLength];   //每个字节需要8位
    memset(pixels, 0, sizeof(uint8_t)*exceptLength);
    int pixelLength = MIN(exceptLength, data.size);
    memcpy(pixels, (byte *)data.data, pixelLength);
    frame->pixels = pixels;
    decoder->releaseRawImageData(&data);
    decoder->closeFile();
    delete decoder;
    return frame;
}

@end
