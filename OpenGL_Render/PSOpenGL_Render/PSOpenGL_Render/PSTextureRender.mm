//
//  PSTextureRender.m
//  PSOpenGL_Render
//
//  Created by 梁鹏帅 on 2018/11/14.
//  Copyright © 2018 梁鹏帅. All rights reserved.
//

#import "PSTextureRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "rgba_frame.hpp"
#import "png_decoder.h"


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

//检测创建的显卡可执行程序是否成功
static inline BOOL validateProgram(GLuint prog)
{
    GLint status;
    
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
    
    return YES;
}

static inline GLuint compileShader(GLenum type, NSString *shaderString)
{
    GLint status;
    const GLchar *source = (GLchar *)shaderString.UTF8String;
    
    //根据传入的类型，创建着色器（GL_VERTEX_SHADER 或 GL_FRAGMENT_SHADER）
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        NSLog(@"failed to create shader type %u", type);
        return 0;
    }
    //为着色器添加自己编写的代码。
    glShaderSource(shader, 1, &source, NULL);
    //编译着色器
    glCompileShader(shader);
    //打印编译shader过程中的log
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    //shader是否编译成功
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
        NSLog(@"failed compile shader");
        return 0;
    }
    return shader;
}

NSString *const vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = position;
     v_texcoord = texcoord.xy;
 }
 );

NSString *const rgbFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D inputImageTexture;
 
 void main()
{
    gl_FragColor = texture2D(inputImageTexture, v_texcoord);
}
 );

@implementation PSTextureRender {
    NSInteger   frameWidth;
    NSInteger   frameHeight;
    GLuint      _inputTexture;
    
    GLuint      filterProgram;
    GLint       filterPositionAttribute;
    GLint       filterTextureCoordinatedAttribute;
    GLint       filterInputTextureUniform;
    
}

- (BOOL)prepareRender:(NSInteger)width height:(NSInteger)height
{
    frameWidth = width;
    frameHeight = height;
    if ([self buildProgram:vertexShaderString fragmentShader:rgbFragmentShaderString]) {
        //创建一个纹理对象，将创建的对象赋予 _inputTexture
        glGenTextures(1, &_inputTexture);
        
        //此步的目的是为了告诉opengl要操作哪个纹理
        glBindTexture(GL_TEXTURE_2D, _inputTexture);
        
        //下面两行是分别设置了当图片放大/缩小时像素填充策略，  GL_LINEAR 代表对临近的4个像素做线性插值算法做插值，目前是最主要的过滤方式，还有比较傻瓜的GL_NEAREST（最邻近过滤），选择最近的像素值，会产生锯齿效果。
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        //下面代码是将纹理坐标映射到S/T坐标轴，因为纹理坐标可能>1，这么设置后，所有超过1的坐标都设置成了1.
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        //下面代码是将png的数据传到纹理上，最后一位代表着具体的png数据，此处为预加载，因此为0；
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)frameWidth, (GLsizei)frameHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        
        //解绑纹理
        glBindTexture(GL_TEXTURE_2D, 0);
        return YES;
    }
    
    return NO;
}

- (BOOL)buildProgram:(NSString *)vertexShaderContent fragmentShader:(NSString *)fragmentShaderContent
{
    BOOL result = NO;
    //初始化顶点，片段着色器
    GLuint vertexShader = 0, fragmentShader = 0;
    
    //创建显卡的可执行程序，shader要加入到这个程序里才可以。
    filterProgram = glCreateProgram();
    
    vertexShader = compileShader(GL_VERTEX_SHADER, vertexShaderContent);
    if (!vertexShader) {
        goto exit;
    }
    fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentShaderContent);
    if (!fragmentShader) {
        goto exit;
    }
    
    //将着色器添加到刚才创建的程序里
    glAttachShader(filterProgram, vertexShader);
    glAttachShader(filterProgram, fragmentShader);
    
    glLinkProgram(filterProgram);
    
    //将手动创建的着色器程序的变量取出来，后续会用到
    filterPositionAttribute = glGetAttribLocation(filterProgram, "position");
    filterTextureCoordinatedAttribute = glGetAttribLocation(filterProgram, "texcoord");
    filterInputTextureUniform = glGetUniformLocation(filterProgram, "inputImageTexture");
    
    //检查添加到程序是否成功
    GLint status;
    glGetProgramiv(filterProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"failed link program");
    }
    
    result = validateProgram(filterProgram);
    
exit:
    if (vertexShader) {
        glDeleteShader(vertexShader);
    }
    if (fragmentShader) {
        glDeleteShader(fragmentShader);
    }
    if (result) {
        NSLog(@"setup gl program success");
    } else {
        glDeleteProgram(filterProgram);
        filterProgram = 0;
    }
    return result;
}

- (void)renderFrame:(uint8_t *)rgbaFrame
{
    glUseProgram(filterProgram);
    
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    
    //将png的数据传到纹理上，最后一位代表着具体的png数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)frameWidth, (GLsizei)frameHeight,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, rgbaFrame);
    
    //顶点坐标（左下， 右下， 左上， 右上）opengl坐标系是：中间为（0.0,0.0）
    static const GLfloat imageVertices[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0
    };
    
    //opengl纹理坐标，此坐标与计算机的屏幕坐标是上下翻转的。（纹理坐标如果y是0，那么计算机的y是1）
//    GLfloat noRotationTextureCoordinates[] = {
//        0.0f, 1.0f,
//        1.0f, 1.0f,
//        0.0f, 0.0f,
//        1.0f, 0.0f,
//    };
    
    //opengl纹理坐标，此坐标与计算机的屏幕坐标是上下翻转的。（纹理坐标如果y是0，那么计算机的y是1）
    GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    //设置物体坐标
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glEnableVertexAttribArray(filterPositionAttribute);
    
    //设置纹理坐标
    glVertexAttribPointer(filterTextureCoordinatedAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinatedAttribute);
    
    //将纹理对象传到我们上面费尽心思搞出来的纹理着色器上
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE0, _inputTexture);
    glUniform1i(filterInputTextureUniform, 0);
    
    //执行绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end
