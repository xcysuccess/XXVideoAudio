//
//  XXRGBOpenGLView.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/7.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXRGBOpenGLView.h"
#import "GLSLUtils.h"

#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

GLfloat vertices[] = {
    //     ---- 位置 ----       ---- 颜色 ----    - 纹理坐标 -
    0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   // 右上
    0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   // 右下
    -0.5f, -0.5f, 0.0f,  0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   // 左下
    -0.5f,  0.5f, 0.0f,  1.0f, 1.0f, 0.0f,   0.0f, 1.0f    // 左上
};

unsigned int indices[] = {
    0, 1, 3, // first triangle
    1, 2, 3  // second triangle
};

@interface XXRGBOpenGLView()
{
    EAGLContext *_context;      //渲染上下文，管理所有使用OpenGL ES 进行描绘的状态、命令以及资源信息
    GLuint _colorRenderBuffer;  //颜色渲染缓存
    GLuint _frameBuffer;        //帧缓存
    
    GLuint _programHandle;      //着色器程序
    GLuint _positionSlot;
    GLuint _inputColorSlot;
    GLuint _texCoordSlot;
    
    GLuint _VAO;
}
@end

@implementation XXRGBOpenGLView
@synthesize pixelBuffer = _pixelBuffer;

-(CVPixelBufferRef) pixelBuffer
{
    return _pixelBuffer;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pb
{
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = CVPixelBufferRetain(pb);
    
    int frameWidth = (int)CVPixelBufferGetWidth(_pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(_pixelBuffer);
    [self displayPixelBuffer:_pixelBuffer width:frameWidth height:frameHeight];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void) destoryRenderAndFrameBuffer{
    if(_frameBuffer){
        glDeleteBuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if(_colorRenderBuffer) {
        glDeleteBuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    
    glDeleteProgram(_programHandle);
    
    glDeleteVertexArraysOES(1, &_VAO);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setupLayer];
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    [self setupGLProgram];
    [self setupVAOVBOEBO];
}

#pragma mark- Setup
- (void) setupLayer{
    CAEAGLLayer *layer = (CAEAGLLayer*)self.layer;
    layer.opaque = YES;                //默认透明,不透明度是
    
    //kEAGLDrawablePropertyRetainedBacking:表示是否要保持呈现的内容不变，默认为NO
    //设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                                 kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                 };
}

- (void) setupContext{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if(!_context){
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    //设置成当前上下文
    if(![EAGLContext setCurrentContext:_context]){
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

//缓冲区分为三种-1.模板缓冲区 2.颜色缓冲区 3.深度缓冲区 ，RenderBuffer是指颜色缓冲区
- (void) setupRenderBuffer{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //为color分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
}

- (void) setupFrameBuffer{
    glGenRenderbuffers(1, &_frameBuffer);
    //设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    //将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void) setupGLProgram{
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    
    //Create Program, attach shaders,compile and link program
    _programHandle = [[GLSLUtils sharedInstance] loadProgramWithVertexFilePath:vertexShaderPath FragmentFilePath:fragmentShaderPath];
    if(_programHandle == 0){
        NSLog(@" >> Error: Failed to setup program.");
        return;
    }
    //Get attribute slot from program
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    _inputColorSlot = glGetAttribLocation(_programHandle, "vInputColor");
    _texCoordSlot = glGetAttribLocation(_programHandle, "vTexCoord");
}

- (void)setupVAOVBOEBO {
    GLuint VBO,EBO;
    glGenVertexArraysOES(1, &_VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    //1. 绑定VAO
    glBindVertexArrayOES(_VAO);
    //2. 把顶点数组复制到缓冲中供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //3. 设置顶点属性指针
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_inputColorSlot, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(3* sizeof(float)));
    glEnableVertexAttribArray(_inputColorSlot);
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(6* sizeof(float)));
    glEnableVertexAttribArray(_texCoordSlot);
    
    glBindVertexArrayOES(0);
}


#pragma mark- Draw
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer width:(uint32_t)frameWidth height:(uint32_t)frameHeight
{
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        return;
    }
    
    if(pixelBuffer == NULL) {
        NSLog(@"Pixel buffer is null");
        return;
    }
    
    CVReturn err;

    CVOpenGLESTextureCacheRef _videoTextureCache;
    err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    glActiveTexture(GL_TEXTURE0);
    
    CVOpenGLESTextureRef textureRef = NULL;

    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &textureRef);
    
    GLuint texture = CVOpenGLESTextureGetName(textureRef);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    // Setup viewport
    glClearColor(0.2, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    // bind Texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glUseProgram(_programHandle);
    glBindVertexArrayOES(_VAO);
    glUniform1i(glGetUniformLocation(_programHandle, "ourTexture"), 0);
    
    // Draw triangle
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    CFRelease(textureRef);
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }

}
@end
