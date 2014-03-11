//
//  PTAudioWave.h
//  PTUIDemo
//
//  Created by Push Chen on 2/12/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PTWaveAntiAliasingLevel)
{
    PTWaveAntiAliasing1x        = 1,    // Default
    PTWaveAntiAliasing2x        = 2,
    PTWaveAntiAliasing4x        = 4
    /*PTWaveAntiAliasing8x        = 8*/
};

@protocol PTAudioWave <NSObject>

@required
// Default is 1.5, can be overrided.
+ (CGFloat)topWaveDisplayDuration;

// The linger wave count, default is 1.
+ (NSUInteger)lingerWaveCount;

// Default is PTWaveAntiAliasing4x
+ (PTWaveAntiAliasingLevel)antiAliasingLevel;

// Append new audio value.
- (void)appendNewAudioValue:(UInt16)value;

// The color for the wave curve
@property (nonatomic, strong)   UIColor     *curveColor;

@end
