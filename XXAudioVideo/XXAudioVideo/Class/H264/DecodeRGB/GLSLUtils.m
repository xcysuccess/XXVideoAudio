//
//  GLSLUtils.m
//  OpenGLESFirstApp
//
//  Created by tomxiang on 2017/9/5.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "GLSLUtils.h"

@interface GLSLUtils()
-(GLuint) loadShader:(GLenum) type withFilePath:(NSString*) shaderFilePath;

/**
 通过加载glsl的字符串返回指定的Shader
 
 @param type GL_VERTEX_SHADER、GL_FRAGMENT_SHADER
 @param shaderString 需要加载的shader字符串
 @return shader
 */
-(GLuint) loadShader:(GLenum) type withString:(NSString*) shaderString;
@end

@implementation GLSLUtils

+(instancetype) sharedInstance{
    static GLSLUtils *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLSLUtils alloc] init];
    });
    return sharedInstance;
}

-(GLuint) loadProgramWithVertexFilePath:(NSString*) vertexFilePath
                       FragmentFilePath:(NSString*) fragmentFilePath{
    
    // Load the vertex/fragment shaders
    GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER
                              withFilePath:vertexFilePath];
    if(vertexShader == 0){
        return 0;
    }
    
    GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER
                                withFilePath:fragmentFilePath];
    if(fragmentShader == 0){
        return 0;
    }
    
    // Create the program object
    GLuint programHandle = glCreateProgram();
    if(programHandle == 0){
        return 0;
    }
    
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    
    // Link the program
    glLinkProgram(programHandle);
    
    // Check the link status
    GLint linked;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linked);
    
    if(!linked){
        GLint infoLen = 0;
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &infoLen);
        
        if (infoLen > 1) {
            char *infoLog = malloc(sizeof(char) * infoLen);
            glGetShaderInfoLog(programHandle, infoLen, NULL, infoLog);
            NSLog(@"Error linking program:\n%s\n", infoLog);
            free(infoLog);
        }
        
        glDeleteShader(programHandle);
        return 0;
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return programHandle;
}

-(GLuint) loadShader:(GLenum) type withFilePath:(NSString*) shaderFilePath{
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error: loading shader file: %@ %@", shaderFilePath, error.localizedDescription);
        return 0;
    }
    return [self loadShader:type withString:shaderString];
}

-(GLuint) loadShader:(GLenum) type withString:(NSString*) shaderString{
    //1. Create the shader object
    GLuint shader = glCreateShader(type);
    if (shader == 0) {
        NSLog(@"Error : failed to create shader.");
        return 0;
    }
    //2. Load the shader source
    const char * shaderStringUTF8 = [shaderString UTF8String];
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    
    //3. Compile the shader
    glCompileShader(shader);
    
    // Check Compile Status
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen );
        if(infoLen){
            char *infoLog = malloc(sizeof(char) * infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            NSLog(@"Error compiling shader:\n%s\n", infoLog );
            
            free(infoLog);
        }
        
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}


@end
