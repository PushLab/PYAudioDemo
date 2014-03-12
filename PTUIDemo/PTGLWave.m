//
//  PTGLWave.m
//  PTUIDemo
//
//  Created by Push Chen on 2/10/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import "PTGLWave.h"

static NSString *__glslVertexShaderString =
    @"precision highp float;"
    @"uniform vec3 _p0;"
    @"uniform vec3 _p1;"
    @"uniform vec3 _p2;"
    @"uniform vec3 _p3;"
    @"uniform vec3 _p4;"
    @"uniform vec3 _p5;"
    @"attribute vec4 _curvePoints;"
    @"void main( void ) {"
    @"    float _t = (_curvePoints[0] + 1.0) / 2.0;"
    @"    float _1_t = 1.0 - _t;"
    @"    float _1_t_5 = _1_t * _1_t * _1_t * _1_t * _1_t;"
    @"    float _1_t_4 = _1_t * _1_t * _1_t * _1_t;"
    @"    float _1_t_3 = _1_t * _1_t * _1_t;"
    @"    float _1_t_2 = _1_t * _1_t;"
    @"    float _1_t_1 = _1_t;"
    @"    float _t_5 = _t * _t * _t * _t * _t;"
    @"    float _t_4 = _t * _t * _t * _t;"
    @"    float _t_3 = _t * _t * _t;"
    @"    float _t_2 = _t * _t;"
    @"    float _t_1 = _t;"
    @"    gl_Position = _curvePoints;"
    @"    gl_Position[1] = (_p0[1] * _1_t_5 * 1.0 + "
    @"                      _p1[1] * _1_t_4 * _t_1 * 5.0 + "
    @"                      _p2[1] * _1_t_3 * _t_2 * 10.0 + "
    @"                      _p3[1] * _1_t_2 * _t_3 * 10.0 + "
    @"                      _p4[1] * _1_t_1 * _t_4 * 5.0 + "
    @"                      _p5[1] * _t_5 * 1.0);"
    @"}";

static NSString *__glslFragmentShaderString =
    @"uniform highp vec4 _curveColor;"
    @"void main() {"
    @"    gl_FragColor = _curveColor;"
    @"}";

@implementation PTGLWave

#pragma mark --
#pragma mark Configuration
+ (CGFloat)topWaveDisplayDuration
{
    return .4f;
}

+ (NSUInteger)lingerWaveCount
{
    return 5;
}

+ (PTWaveAntiAliasingLevel)antiAliasingLevel
{
    return PTWaveAntiAliasing4x;
}

@synthesize curveColor = _curveColor;
- (void)setCurveColor:(UIColor *)aColor
{
    [self willChangeValueForKey:@"curveColor"];
    _curveColor = aColor;
    PYColorInfo _colorInfo = [_curveColor colorInfo];
    _glCurveColorInfo[0] = _colorInfo.red;
    _glCurveColorInfo[1] = _colorInfo.green;
    _glCurveColorInfo[2] = _colorInfo.blue;
    _glCurveColorInfo[3] = 1.f;
    [self didChangeValueForKey:@"curveColor"];
}
#pragma mark --
#pragma mark Load Shader
+ (GLuint)loadShader:(GLenum)type withString:(NSString *)sharderString
{
    GLuint _shader = glCreateShader(type);
    if ( _shader == 0 ) {
        PYLog(@"Error: Failed to create shader.");
        return 0;
    }
    
    // Load the shader source
    const char *_cShaderString = sharderString.UTF8String;
    glShaderSource(_shader, 1, &_cShaderString, NULL);
    
    // Compile the shader
    glCompileShader(_shader);
    
    // Check the compile status
    GLint _isCompiled = 0;
    glGetShaderiv(_shader, GL_COMPILE_STATUS, &_isCompiled);
    if ( !_isCompiled ) {
        GLint _infoLen = 0;
        glGetShaderiv( _shader, GL_INFO_LOG_LENGTH, &_infoLen );
        
        if ( _infoLen > 1 ) {
            char *_infoLog = malloc(sizeof(char) * _infoLen );
            glGetShaderInfoLog(_shader, _infoLen, NULL, _infoLog);
            PYLog(@"Failed to compile shader: %s", _infoLog);
            free(_infoLog);
        }
        glDeleteShader(_shader);
        _shader = 0;
    }
    return _shader;
}

+ (GLuint)loadShader:(GLenum)type withContentOfFile:(NSString *)filePath
{
    NSError *_error;
    NSString *_shaderString = [NSString
                               stringWithContentsOfFile:filePath
                               encoding:NSUTF8StringEncoding
                               error:&_error];
    if ( _error != nil ) {
        PYLog(@"Failed to load shader file: %@", _error.localizedDescription);
        return 0;
    }
    return [PTGLWave loadShader:type withString:_shaderString];
}

+ (GLuint)loadShader:(GLenum)type named:(NSString *)filename
{
    NSArray *_fileParts = [filename componentsSeparatedByString:@"."];
    NSString *_filePath = [[NSBundle mainBundle]
                           pathForResource:[_fileParts safeObjectAtIndex:0]
                           ofType:@"glsl"];
    return [PTGLWave loadShader:type withContentOfFile:_filePath];
}

#pragma mark --
#pragma mark Will Move To Super Layer Event
- (id<CAAction>)actionForKey:(NSString *)event
{
    if ( [event isEqualToString:kCAOnOrderIn] ) {
        [self willMoveToSuperLayer:self.superlayer];
    }
    if ( [event isEqualToString:kCAOnOrderOut] ) {
        [self willMoveToSuperLayer:nil];
    }
    return [super actionForKey:event];
}

- (void)willMoveToSuperLayer:(CALayer *)layer
{
    if ( layer == nil ) {
        [self uninstallGLWaveLayer];
    } else {
        [self setupGlWaveLayer];
    }
}

#pragma mark --
#pragma mark Setup/Uninstall
- (id)init
{
    self = [super init];
    if ( self ) {
        // Initialize the gl context
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_glContext];
    }
    return self;
}

- (void)setupGlWaveLayer
{
    [self setBackgroundColor:[UIColor clearColor].CGColor];
    self.opaque = NO;
    
    // Create Program
    _glProgramHandler = glCreateProgram();
    
    // Attach shaders
    _glVertexShader = [PTGLWave loadShader:GL_VERTEX_SHADER
                                withString:__glslVertexShaderString];
    _glFragmentShader = [PTGLWave loadShader:GL_FRAGMENT_SHADER
                                  withString:__glslFragmentShaderString];
    glAttachShader(_glProgramHandler, _glVertexShader);
    glAttachShader(_glProgramHandler, _glFragmentShader);
    
    // Link program
    glLinkProgram(_glProgramHandler);
    
    // Use program
    glUseProgram(_glProgramHandler);
    
    // Get attribute slot from program
    _glCurvePointsSlot = glGetAttribLocation(_glProgramHandler, "_curvePoints");
    _glCurveColorSlot = glGetUniformLocation(_glProgramHandler, "_curveColor");
    
    for ( int i = 0; i < 6; ++i ) {
        NSString *_uniformName = [NSString stringWithFormat:@"_p%d", i];
        _glControlPointHandler[i] = glGetUniformLocation(_glProgramHandler, _uniformName.UTF8String);
    }
    
    // Configuration
    _topWaveDisplayDuration = [[self class] topWaveDisplayDuration] * 1000000;
    _topWaveDuration_1_4 = _topWaveDisplayDuration / 4;

    _lastAudioValueAddedTime = (struct timeval){0, 0};
    
    _lingerWaveCount = [[self class] lingerWaveCount];
    _cachedControlPoints = (PTGLControlPointGroup *)calloc(sizeof(PTGLControlPointGroup), _lingerWaveCount);
    memset(_audioValue, 0, sizeof(UInt16) * 4);

    [self clearContext];
    [self presentContext];
    
    if ( _allPoints == NULL ) {
        [self setFrame:self.frame];
    }
    
    // Set up display link
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_renderWavePaths)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)uninstallGLWaveLayer
{
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink = nil;
    
    if ( _allPoints != NULL ) {
        free(_allPoints);
        _allPoints = NULL;
    }
    if ( _cachedControlPoints != NULL ) {
        free(_cachedControlPoints);
        _cachedControlPoints = NULL;
    }
    if ( _glProgramHandler != 0 ) {
        glDetachShader(_glProgramHandler, _glFragmentShader);
        glDeleteShader(_glFragmentShader);
        glDetachShader(_glProgramHandler, _glVertexShader);
        glDeleteShader(_glVertexShader);
        glDeleteProgram(_glProgramHandler);
        _glProgramHandler = 0;
    }
    if ( _glColorRenderBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glColorRenderBuffer);
        _glColorRenderBuffer = 0;
    }
    if ( _glFrameBuffer != 0 ) {
        glDeleteFramebuffers(1, &_glFrameBuffer);
        _glFrameBuffer = 0;
    }
    
    if ( _glMSAARenderBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glMSAARenderBuffer);
        _glMSAARenderBuffer = 0;
    }
    if ( _glMSAADepthBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glMSAADepthBuffer);
        _glMSAADepthBuffer = 0;
    }
    if ( _glMSAAFrameBuffer != 0 ) {
        glDeleteFramebuffers(1, &_glMSAAFrameBuffer);
        _glMSAAFrameBuffer = 0;
    }
    if ( _cachedControlPoints != NULL ) {
        free(_cachedControlPoints);
        _cachedControlPoints = NULL;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if ( frame.size.width == 0.f ) return;
    
    frame.size.width *= [UIScreen mainScreen].scale;
    frame.size.height *= [UIScreen mainScreen].scale;

    // Set the contents scale
    self.contentsScale = [UIScreen mainScreen].scale;
    
    if ( _glColorRenderBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glColorRenderBuffer);
        _glColorRenderBuffer = 0;
    }
    if ( _glFrameBuffer != 0 ) {
        glDeleteFramebuffers(1, &_glFrameBuffer);
        _glFrameBuffer = 0;
    }
    
    // Create the render buffer
    glGenRenderbuffers(1, &_glColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glColorRenderBuffer);
    //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16,
    //                          self.frame.size.width * [UIScreen mainScreen].scale,
    //                          self.frame.size.height * [UIScreen mainScreen].scale);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
    
    // Create the frame buffer
    glGenFramebuffers(1, &_glFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _glColorRenderBuffer);
    
    if ( _allPoints != NULL ) {
        free(_allPoints);
        _allPoints = NULL;
    }
    
    _antiAliasingLevel = [[self class] antiAliasingLevel];
    NSUInteger _availablePixelCount = self.bounds.size.width * [UIScreen mainScreen].scale;
    _curveDrawCount = _availablePixelCount / 2;
    _allPoints = (PTGLVertex3 *)calloc(sizeof(PTGLVertex3), _curveDrawCount + 1);
    for ( size_t i = 0; i < _curveDrawCount; ++i ) {
        _allPoints[i][0] = 2.f * (((float)i) / _curveDrawCount) - 1.f;
        _allPoints[i][1] = 0.f;
        _allPoints[i][2] = 0.f;
    }
    // Set the last point
    _allPoints[_curveDrawCount][0] = 1.f;
    _allPoints[_curveDrawCount][1] = 0.f;
    _allPoints[_curveDrawCount][2] = 0.f;

    // Multisampling
    if ( _glMSAAFrameBuffer != 0 ) {
        glDeleteFramebuffers(1, &_glMSAAFrameBuffer);
        _glMSAAFrameBuffer = 0;
    }
    if ( _glMSAARenderBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glMSAARenderBuffer);
        _glMSAARenderBuffer = 0;
    }
    if ( _glMSAADepthBuffer != 0 ) {
        glDeleteRenderbuffers(1, &_glMSAADepthBuffer);
        _glMSAADepthBuffer = 0;
    }
    
    glGenFramebuffers(1, &_glMSAAFrameBuffer);
    glGenRenderbuffers(1, &_glMSAARenderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _glMSAAFrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glMSAARenderBuffer);
    
    GLint _maxSample;
    glGetIntegerv(GL_MAX_SAMPLES_APPLE, &_maxSample);
    _maxSample = MIN(_maxSample, _antiAliasingLevel);
    
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _maxSample, GL_RGBA8_OES,
                                          frame.size.width, frame.size.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _glMSAARenderBuffer);
    glGenRenderbuffers(1, &_glMSAADepthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glMSAADepthBuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _maxSample, GL_DEPTH_COMPONENT16,
                                          frame.size.width, frame.size.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, _glMSAADepthBuffer);
}

#pragma mark --
#pragma mark Algorithm

- (void)_shiftInNewControlPointsGroup:(const PTGLControlPointGroup *)group __deprecated
{
    for ( int i = 0; i < (_lingerWaveCount - 1); ++i ) {
        memcpy(_cachedControlPoints[i],
               _cachedControlPoints[i + 1],
               sizeof(PTGLControlPointGroup));
    }
    memcpy(_cachedControlPoints[_lingerWaveCount - 1],
           group, sizeof(PTGLControlPointGroup));
}

- (CGPoint)_genControlPointForAudioValue:(UInt16)value atUsec:(long)usec
{
    CGFloat _viewX = ((float)usec / (float)_topWaveDisplayDuration);
    CGFloat _x = _viewX * 2.f - 1.f;
//    if ( _x < self.bounds.size.width * 0.2 ) _x = self.bounds.size.width * 0.2;
//    if ( _x > self.bounds.size.width * 0.8 ) _x = self.bounds.size.width * 0.8;
    CGFloat _fraction = (((float)value / (float)UINT16_MAX) *
                         sin(_viewX * M_PI * 2.f));
    CGFloat _y = sin(_fraction * M_PI * 2.f);
    return (CGPoint){_x, _y};
}

- (void)_genControlPointsGroupAtCurrentTime
{
    struct timeval _ctv;
    gettimeofday(&_ctv, NULL);
    unsigned long _deltaSec = (_ctv.tv_sec - _lastAudioValueAddedTime.tv_sec);
    unsigned long _deltaUsec = (_ctv.tv_usec - _lastAudioValueAddedTime.tv_usec);
    unsigned long _allDeltaUsec = _deltaSec * 1000000 + _deltaUsec;
    if ( _allDeltaUsec > _topWaveDuration_1_4 ) {
        [self _appendNewAudioValueInternal:0 atTimestamp:_ctv];
        _allDeltaUsec = 0;
    }
    
    for ( int _line = 0; _line < _lingerWaveCount; ++_line ) {
        PTGLControlPointGroup _currentGroup;
        
        // P0
        _currentGroup[0][0] = -1.f;
        _currentGroup[0][1] = 0.f;
        _currentGroup[0][2] = 0.f;
        
        // P1 - P4
        for ( int i = 1; i < 5; ++i ) {
            CGPoint _p = [self
                          _genControlPointForAudioValue:(_audioValue[4 - i] / (_lingerWaveCount - _line))
                          atUsec:(_allDeltaUsec + _topWaveDuration_1_4 * (i - 1))];
            _currentGroup[i][0] = _p.x;
            _currentGroup[i][1] = _p.y;
            _currentGroup[i][2] = 0.f;
        }
        
        // P5
        _currentGroup[5][0] = 1.f;
        _currentGroup[5][1] = 0.f;
        _currentGroup[5][2] = 0.f;
        
        memcpy(_cachedControlPoints[_line], _currentGroup, sizeof(PTGLControlPointGroup));
    }
}

#pragma mark --
#pragma mark Display
- (void)_renderWavePaths
{
    // Generate current control points group
    [self _genControlPointsGroupAtCurrentTime];
    
    // Refresh the view
    [self setNeedsDisplay];
}

- (void)presentContext
{
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}
- (void)clearContext
{
    // Clear the screen
    
    [EAGLContext setCurrentContext:_glContext];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _glMSAAFrameBuffer);
    // Set up view port
    self.contentsScale = [UIScreen mainScreen].scale;
    
    glViewport(0, 0,
               self.bounds.size.width * self.contentsScale,
               self.bounds.size.height * self.contentsScale);
    glClearColor(0.f, 0.f, 0.f, 0.f);   // Clear Color
    glClear(GL_COLOR_BUFFER_BIT );
    glEnable(GL_ALPHA);
}

- (void)display
{
    if ( _allPoints != NULL ) {
        [EAGLContext setCurrentContext:_glContext];
        
        glBindFramebuffer(GL_FRAMEBUFFER, _glMSAAFrameBuffer);
        // Set up view port
        glViewport(0, 0,
                   self.bounds.size.width * self.contentsScale,
                   self.bounds.size.height * self.contentsScale);
        // Clear
        glClearColor(0.f, 0.f, 0.f, 0.f);   // Clear Color
        glClear(GL_COLOR_BUFFER_BIT );
        
        glEnable(GL_ALPHA);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        
        GLfloat _alpha = 1.f / _lingerWaveCount;
        int _index = 0;
        for ( ; _index < _lingerWaveCount; ++_index ) {
            _glCurveColorInfo[3] = (_index + 1) * _alpha;   // Line alpha
            glVertexAttribPointer(_glCurvePointsSlot, 3, GL_FLOAT, GL_FALSE, 0, _allPoints);
            glEnableVertexAttribArray(_glCurvePointsSlot);
            //glVertexAttribPointer(_glCurveColorSlot, 4, GL_FLOAT, GL_FALSE, 0, &_glCurveColorInfo);
            glUniform4fv(_glCurveColorSlot, 1, _glCurveColorInfo);
            
            for ( int i = 0; i < 6; ++i ) {
                glUniform3fv(_glControlPointHandler[i], 1, _cachedControlPoints[_index][i]);
            }
            
            glLineWidth(2.5 / ( _lingerWaveCount - _index) );
            
            //glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_curveDrawCount + 1);
            glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)(_curveDrawCount + 1));
            //glDrawArrays(GL_POINTS, 0, (GLsizei)_curveDrawCount);
            glDisableVertexAttribArray(_glCurvePointsSlot);
        }
        
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _glMSAAFrameBuffer);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _glFrameBuffer);
        glResolveMultisampleFramebufferAPPLE();
        
        GLenum attachments[] = { GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT };
        glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 2, attachments);
        
        glBindRenderbuffer(GL_RENDERBUFFER, _glColorRenderBuffer);
        
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

#pragma mark --
#pragma mark Api Operation
- (void)_appendNewAudioValueInternal:(UInt16)value atTimestamp:(struct timeval)tv
{
    // Shift to left.
    for ( NSUInteger i = 0; i < 3; ++i ) {
        _audioValue[i] = _audioValue[i + 1];
    }
    _audioValue[3] = value;
    
    // Update the last audio value added time.
    _lastAudioValueAddedTime = tv;
}

- (void)appendNewAudioValue:(UInt16)value
{
    struct timeval _ctv;
    gettimeofday(&_ctv, NULL);
    unsigned long _deltaSec = (_ctv.tv_sec - _lastAudioValueAddedTime.tv_sec);
    unsigned long _deltaUsec = (_ctv.tv_usec - _lastAudioValueAddedTime.tv_usec);
    unsigned long _allDeltaUsec = _deltaSec * 1000000 + _deltaUsec;
    // If delta is big enough, add it. Otherwise, omit it.
    if ( _allDeltaUsec >= _topWaveDuration_1_4 ) {
        [self _appendNewAudioValueInternal:value atTimestamp:_ctv];
    }
}

@end
