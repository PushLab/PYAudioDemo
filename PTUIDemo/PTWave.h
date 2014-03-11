//
//  PTWave.h
//  PTUIDemo
//
//  Created by Push Chen on 1/27/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PTAudioWave.h"

@interface PTWave : PYStaticLayer <PTAudioWave>
{
    UInt16                      _audioValue[4];
    NSMutableArray              *_cachedBezierPath;
    CADisplayLink               *_displayLink;
    
    UIColor                     *_curveColor;
    PYColorInfo                 _rgbCurveColorInfo;
    
    // Configuration
    NSUInteger                  _lingerWaveCount;
    unsigned long               _topWaveDisplayDuration;
    unsigned long               _topWaveDuration_1_4;
    struct timeval              _lastAudioValueAddedTime;
    PTWaveAntiAliasingLevel     _antiAliasingLevel;
    NSUInteger                  _curveDrawCount;
    
    CGFloat             _audioRate __deprecated;
    NSArray             *_controlPoints __deprecated;
}

@property (nonatomic, strong)   UIColor     *curveColor;

@property (nonatomic, assign)   CGFloat     audioRate __deprecated;
@property (nonatomic, strong)   NSArray     *controlPoints __deprecated;

@end
