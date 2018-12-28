//
//  XXMetalView.m
//  XXAudioVideo
//
//  Created by tomxiang on 2018/12/26.
//  Copyright © 2018年 tomxiang. All rights reserved.
//

#import "XXMetalView.h"
#include "XXShaderTypes.h"

QGVertex quadVertices[] =
{   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
    { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
    { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
    { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
    
    { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
    { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
    { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
};

matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
    (simd_float3){1.0,    1.0,    1.0},
    (simd_float3){0.0,    -0.343, 1.765},
    (simd_float3){1.4,    -0.711, 0.0},
};

//这个是偏移
vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ 0, -0.5, -0.5};


@interface XXMetalView()
{
    id<MTLDevice> _device;//MTLDevice想象成连接到GPU的桥梁。创建的所有Metal对象都使用这个MTLDevice
    
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLCommandQueue> _commandQueue;
    id<MTLBuffer> _vertices;
    id<MTLBuffer> _convertMatrix;
    NSUInteger _numVertices;
    CVMetalTextureCacheRef _textureCache;
}

@end

@implementation XXMetalView
@synthesize pixelBuffer = _pixelBuffer;

-(CVPixelBufferRef) pixelBuffer
{
    return _pixelBuffer;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pb
{
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    _pixelBuffer = CVPixelBufferRetain(pb);
    
    int frameWidth = (int)CVPixelBufferGetWidth(_pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(_pixelBuffer);
    [self displayPixelBuffer:_pixelBuffer width:frameWidth height:frameHeight];
}

+ (Class)layerClass{
    return [CAMetalLayer class];
}
- (void)dealloc{
    if(_textureCache){
        CFRelease(_textureCache);
        _textureCache = NULL;
    }
}
- (void) destoryRenderAndFrameBuffer{
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setupLayer];
    [self setupPipeline];
    [self setupVertex];
    [self setupMatrix];
}

- (void)setupLayer{
    
    //1.创建一个MTLDevice,connect GPUDriver and GPUhardware directly
    _device = MTLCreateSystemDefaultDevice();
    CVMetalTextureCacheCreate(NULL, NULL, _device, NULL, &_textureCache); // TextureCache的创建

    //2.创建一个CAMetalLayer
    CAMetalLayer *layer = (CAMetalLayer*)self.layer;
    layer.opaque = YES;                //默认透明,不透明度是
    layer.device = _device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;//为Blue, Green, Red和Alpha提供8字节
    // this is the default but if we wanted to perform compute on the final rendering layer we could set this to no
    layer.framebufferOnly = YES;
}

- (void)setupPipeline{
    //3.创建一个Vertex Shader&&Fragment Shader
    id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id <MTLFunction> vertextProgram = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"samplingShader"];
    
    //4.创建渲染管线
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.vertexFunction = vertextProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    
    //5.GPU一次要执行的命令
    _commandQueue = [_device newCommandQueue];
}

// 设置顶点f
- (void)setupVertex {
    _vertices = [_device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared]; // 创建顶点缓存
    _numVertices = sizeof(quadVertices) / sizeof(QGVertex); // 顶点个数
}
- (void)setupMatrix { // 设置好转换的矩阵
    QGConvertMatrix matrix;
    // 设置参数
    matrix.matrix = kColorConversion601FullRangeMatrix;
    matrix.offset = kColorConversion601FullRangeOffset;
    
    _convertMatrix = [_device newBufferWithBytes:&matrix
                                          length:sizeof(QGConvertMatrix)
                                         options:MTLResourceStorageModeShared];
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer width:(uint32_t)frameWidth height:(uint32_t)frameHeight
{
    CAMetalLayer *layer = (CAMetalLayer*)self.layer;
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    //1.创建一个Render Pass Descriptor
    id<CAMetalDrawable> drawable = layer.nextDrawable;
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;//nextDrawable()方法，它会返回需要绘制的纹理，使其显示在屏幕上
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;//loadAction设置为清除，这意味着“在绘制之前，将纹理设置为透明色”
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.3f, 0.3f, 1.f);
    
    //2.创建一个Render Command Encoder
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
//    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setVertexBuffer:_vertices
                            offset:0
                           atIndex:QGVertexInputIndexVertices];
    
    [self setupTextureWithEncoder:renderEncoder buffer:pixelBuffer];
    [renderEncoder setFragmentBuffer:_convertMatrix
                              offset:0
                             atIndex:QGFragmentInputIndexMatrix];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:_numVertices];
    
    [renderEncoder endEncoding];
    
    //3.提交Command Buffer的内容
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}


// 设置纹理
- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder buffer:(CVPixelBufferRef)pixelBuffer {
    // textureY 设置
    CVMetalTextureRef yTextureRef;
    size_t ywidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t yheight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVReturn ystatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, ywidth, yheight, 0, &yTextureRef);

    // textureUV 设置
    CVMetalTextureRef uvTextureRef;
    size_t uvwidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t uvheight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    CVReturn uvStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatRG8Unorm, uvwidth, uvheight, 1, &uvTextureRef);
    
    if (ystatus != kCVReturnSuccess || uvStatus != kCVReturnSuccess) {
        return;
    }
    
    id <MTLTexture> yTexture = CVMetalTextureGetTexture(yTextureRef);
    id <MTLTexture> uvTexture = CVMetalTextureGetTexture(uvTextureRef);
    if(yTextureRef){
        CFRelease(yTextureRef);
    }
    if(uvTextureRef){
        CFRelease(uvTextureRef);
    }
    
    if (yTexture == nil || uvTexture == nil) {
        return;
    }

    [encoder setFragmentTexture:yTexture atIndex:QGFragmentTextureIndexTextureY]; // 设置纹理
    [encoder setFragmentTexture:uvTexture atIndex:QGFragmentTextureIndexTextureUV]; // 设置纹理
}

@end
