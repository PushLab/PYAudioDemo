//
//  PTGLWave.h
//  PTUIDemo
//
//  Created by Push Chen on 2/10/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PTAudioWave.h"

typedef GLfloat PTGLVertex3[3];
typedef GLfloat PTGLVertex4[4];
typedef PTGLVertex3 PTGLControlPointGroup[6];

@interface PTGLWave : CAEAGLLayer <PTAudioWave>
{
    EAGLContext                 *_glContext;
    GLuint                      _glColorRenderBuffer;
    GLuint                      _glFrameBuffer;
    // Multisampling
    GLuint                      _glMSAAFrameBuffer;
    GLuint                      _glMSAARenderBuffer;
    GLuint                      _glMSAADepthBuffer;
    
    GLuint                      _glProgramHandler;
    GLuint                      _glCurveColorSlot;
    GLuint                      _glVertexShader;
    GLuint                      _glFragmentShader;

    // Control Points
    GLuint                      _glControlPointHandler[6];
    GLuint                      _glCurvePointsSlot;
    
    PTGLControlPointGroup       *_cachedControlPoints;
    PTGLVertex3                 *_allPoints;    // a base line
    UInt16                      _audioValue[4];
    CADisplayLink               *_displayLink;
    
    // Configuration
    UIColor                     *_curveColor;
    PTGLVertex4                 _glCurveColorInfo;
    
    NSUInteger                  _lingerWaveCount;
    unsigned long               _topWaveDisplayDuration;
    unsigned long               _topWaveDuration_1_4;
    struct timeval              _lastAudioValueAddedTime;
    PTWaveAntiAliasingLevel     _antiAliasingLevel;
    NSUInteger                  _curveDrawCount;
}

// Load the shader code.
+ (GLuint)loadShader:(GLenum)type withString:(NSString *)sharderString;
+ (GLuint)loadShader:(GLenum)type withContentOfFile:(NSString *)filePath;
+ (GLuint)loadShader:(GLenum)type named:(NSString *)filename;   // The file must in main bundle

// Will be add to/remove from super layer
- (void)willMoveToSuperLayer:(CALayer *)layer;

// Clear the layer's context
- (void)clearContext;

@property (nonatomic, strong)   UIColor     *curveColor;

@end
