//
//  XXShaderTypes.h
//  XXAudioVideo
//
//  Created by tomxiang on 2018/12/26.
//  Copyright © 2018年 tomxiang. All rights reserved.
//

#ifndef XXShaderTypes_h
#define XXShaderTypes_h

#include <simd/simd.h>

typedef struct{
    vector_float4 position;
    vector_float2 textureCoordinate;
} QGVertex;

typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
} QGConvertMatrix;

typedef enum QGVertexInputIndex
{
    QGVertexInputIndexVertices     = 0,
    QGVertexInputIndexViewportSize = 1,
}QGVertexInputIndex;


typedef enum QGFragmentBufferIndex
{
    QGFragmentInputIndexMatrix     = 0,
}QGFragmentBufferIndex;


typedef enum QGFragmentTextureIndex
{
    QGFragmentTextureIndexTextureY     = 0,
    QGFragmentTextureIndexTextureUV     = 1,
}QGFragmentTextureIndex;


#endif /* XXShaderTypes_h */
