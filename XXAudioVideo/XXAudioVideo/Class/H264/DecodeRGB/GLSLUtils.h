//
//  GLSLUtils.h
//  OpenGLESFirstApp
//
//  Created by tomxiang on 2017/9/5.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface GLSLUtils : NSObject

+(instancetype) sharedInstance;

-(GLuint) loadProgramWithVertexFilePath:(NSString*) vertexFilePath
                       FragmentFilePath:(NSString*) fragmentFilePath;

@end
