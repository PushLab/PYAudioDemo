//
//  PTWave.m
//  PTUIDemo
//
//  Created by Push Chen on 1/27/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import "PTWave.h"

@implementation PTWave

@synthesize controlPoints = _controlPoints;
@synthesize audioRate = _audioRate;
@synthesize curveColor = _curveColor;

- (void)setAudioRate:(CGFloat)rate __deprecated
{
    [self willChangeValueForKey:@"audioRate"];
    _audioRate = rate;
    [self didChangeValueForKey:@"audioRate"];
    [self setNeedsDisplay];
}
- (void)setControlPoints:(NSArray *)controlPoints __deprecated
{
    [self willChangeValueForKey:@"controlPoints"];
    NSMutableArray *_tempArray = [NSMutableArray arrayWithArray:controlPoints];
    CGPoint _lastPoint = (CGPoint){1.2, 0.5};
    [_tempArray addObject:[NSValue valueWithCGPoint:_lastPoint]];
    _controlPoints = [_tempArray copy];
    [self didChangeValueForKey:@"controlPoints"];
    [self setNeedsDisplay];
    //[self setNeedsLayout];
}

- (void)setCurveColor:(UIColor *)aColor
{
    [self willChangeValueForKey:@"curveColor"];
    _curveColor = aColor;
    _rgbCurveColorInfo = [_curveColor colorInfo];
    [self didChangeValueForKey:@"curveColor"];
}
- (void)_strokWaveWithOffset:(CGFloat)offset lineWidth:(CGFloat)width __deprecated
{
    CGFloat _halfHeight = self.bounds.size.height / 2;
    CGFloat _halfWidth = self.bounds.size.width / 2;
    UIBezierPath *_path = [UIBezierPath bezierPath];
    [_path moveToPoint:CGPointMake(0, _halfHeight)];
    
    [_path addLineToPoint:CGPointMake(5, _halfHeight)];
    [_path addCurveToPoint:CGPointMake(self.bounds.size.width - 10, _halfHeight)
             controlPoint1:CGPointMake(_halfWidth, _halfHeight - offset)
             controlPoint2:CGPointMake(_halfWidth, _halfHeight + offset)];

    [_path addLineToPoint:CGPointMake(self.bounds.size.width, _halfHeight)];
    
    [[UIColor whiteColor] setStroke];
    
    [_path setLineWidth:width];
    [_path setLineCapStyle:kCGLineCapRound];
    [_path stroke];
}

- (void)willMoveToSuperLayer:(CALayer *)layer
{
    if ( layer == nil ) {
        // Remove from super layer
        [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        _displayLink = nil;
        [_cachedBezierPath removeAllObjects];
        _cachedBezierPath = nil;
    } else {
        // First time add to super layer
        _topWaveDisplayDuration = [[self class] topWaveDisplayDuration] * 1000000;
        _topWaveDuration_1_4 = _topWaveDisplayDuration / 4;
        _lastAudioValueAddedTime.tv_sec = 0;
        _lastAudioValueAddedTime.tv_usec = 0;
        
        // Clear & Initialize the buffer
        _lingerWaveCount = [[self class] lingerWaveCount];
        memset(_audioValue, 0, sizeof(UInt16) * 4);
        _cachedBezierPath = [NSMutableArray array];
        
        // Start the display link
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_renderBezierPaths)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // Update the draw count
    _antiAliasingLevel = [[self class] antiAliasingLevel];
    NSUInteger _allPointCountInScreen = ([UIScreen mainScreen].scale *
                                         frame.size.width);
    _curveDrawCount = (_allPointCountInScreen / PTWaveAntiAliasing4x) * _antiAliasingLevel;
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGFloat _alpha = 1.f / _lingerWaveCount;
    int _index = 0;
    for ( ; _index < _cachedBezierPath.count; ++_index ) {
        
        UIColor *_lingerColor = RGBACOLOR(_rgbCurveColorInfo.red * 255.f,
                                          _rgbCurveColorInfo.green * 255.f,
                                          _rgbCurveColorInfo.blue * 255.f,
                                          (_index + 1) * _alpha);
        CGPathRef _cPath = (__bridge CGPathRef)([_cachedBezierPath objectAtIndex:_index]);
        CGContextSetStrokeColorWithColor(ctx, _lingerColor.CGColor);
        CGContextSetLineWidth(ctx, 1.5f);
        CGContextAddPath(ctx, _cPath);
        CGContextStrokePath(ctx);
    }
}
- (void)_renderBezierPaths
{
    // Update the path list.
    CGPathRef _cPath = [self _genPathAtCurrentTimestamp];
    if ( _cPath != NULL ) {
        if ( [_cachedBezierPath count] >= _lingerWaveCount ) {
            CGPathRef _oldestPath = (__bridge CGPathRef)([_cachedBezierPath objectAtIndex:0]);
            CGPathRelease(_oldestPath);
            [_cachedBezierPath removeObjectAtIndex:0];
        }
        [_cachedBezierPath addObject:(__bridge id)(_cPath)];
    }
    
    // Draw all path.
    [self setNeedsDisplay];
}

+ (CGFloat)topWaveDisplayDuration
{
    return 1.5f;
}

+ (NSUInteger)lingerWaveCount
{
    return 4.f;
}

+ (PTWaveAntiAliasingLevel)antiAliasingLevel
{
    return PTWaveAntiAliasing1x;
}

// Use sin(x) to get the ratio, the usec must less than duration
- (CGFloat)_genFractionRatioWithXpoint:(CGFloat)x
{
//    if ( x < .15 ) return .001;
//    if ( x > .85 ) return .001;
    return sin(x * M_PI * 2.f);
}
- (CGFloat)_genOffsetForAudioValue:(UInt16)value atXpoint:(CGFloat)x
{
    if ( x < 0.2 ) return 0.f;
    if ( x > 0.8 ) return 0.f;
    CGFloat _fraction = (((float)value / (float)UINT16_MAX) *
                         sin(x * M_PI * 2.f));
    return self.bounds.size.height * sin(_fraction * M_PI * 2.0);
}

- (CGPoint)_genControlPointForAudioValue:(UInt16)value atUsec:(long)usec
{
    CGFloat _xPoint = ((float)usec / (float)_topWaveDisplayDuration);
    CGFloat _x = self.bounds.size.width * _xPoint;
    if ( _x < self.bounds.size.width * 0.2 ) _x = self.bounds.size.width * 0.2;
    if ( _x > self.bounds.size.width * 0.8 ) _x = self.bounds.size.width * 0.8;
    CGFloat _y = (self.bounds.size.height / 2 +
                  [self _genOffsetForAudioValue:value atXpoint:_xPoint]);
    return (CGPoint){_x, _y};
}

- (CGPathRef)_genPathAtCurrentTimestamp
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
    
    CGMutablePathRef _cPath = CGPathCreateMutable();
    // Get Control Points.
    CGPoint _p0 = (CGPoint){0, self.bounds.size.height / 2};
    CGPoint _p1 = [self _genControlPointForAudioValue:_audioValue[3]
                                               atUsec:_allDeltaUsec];
    CGPoint _p2 = [self _genControlPointForAudioValue:_audioValue[2]
                                               atUsec:(_allDeltaUsec + _topWaveDuration_1_4)];
    CGPoint _p3 = [self _genControlPointForAudioValue:_audioValue[1]
                                               atUsec:(_allDeltaUsec + _topWaveDuration_1_4 * 2)];
    CGPoint _p4 = [self _genControlPointForAudioValue:_audioValue[0]
                                               atUsec:(_allDeltaUsec + _topWaveDuration_1_4 * 3)];
    CGPoint _p5 = (CGPoint){self.bounds.size.width, self.bounds.size.height / 2};
    CGPathMoveToPoint(_cPath, NULL, _p0.x, _p0.y);
    for ( NSUInteger i = 0; i < _curveDrawCount; ++i ) {
        CGFloat _t = (float)i / (float)_curveDrawCount;
        CGFloat _1_t = 1 - _t;
        CGFloat _1_t_5 = _1_t * _1_t * _1_t * _1_t * _1_t;
        CGFloat _1_t_4 = _1_t * _1_t * _1_t * _1_t;
        CGFloat _1_t_3 = _1_t * _1_t * _1_t;
        CGFloat _1_t_2 = _1_t * _1_t;
        CGFloat _1_t_1 = _1_t;
        CGFloat _t_5 = _t * _t * _t * _t * _t;
        CGFloat _t_4 = _t * _t * _t * _t;
        CGFloat _t_3 = _t * _t * _t;
        CGFloat _t_2 = _t * _t;
        CGFloat _t_1 = _t;
        
        CGFloat _x = _t * self.bounds.size.width;
        CGFloat _y = (_p0.y * _1_t_5 * 1 +          // P0(1-t)^5
                      _p1.y * _1_t_4 * _t_1 * 5 +   // 5P1(1-t)^4 * t
                      _p2.y * _1_t_3 * _t_2 * 10 +  // 10P2(1-t)^3 * t^2
                      _p3.y * _1_t_2 * _t_3 * 10 +  // 10P3(1-t)^2 * t^3
                      _p4.y * _1_t_1 * _t_4 * 5 +   // 5P4(1-t) * t^4
                      _p5.y * _t_5 * 1);            // P5t^5
        CGPathAddLineToPoint(_cPath, NULL, _x, _y);
    }
    CGPathAddLineToPoint(_cPath, NULL, _p5.x, _p5.y);
    return _cPath;
}

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
