//
//  PTAudioRecoder.m
//  PTUIDemo
//
//  Created by Push Chen on 2/13/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import "PTAudioRecoder.h"
#import "PTInnerAudioRecoder.h"

@implementation PTAudioRecoder

@synthesize displayWaveLayer;

- (id)init
{
    self = [super init];
    if ( self ) {
    }
    return self;
}

- (void)starToRecord
{
    // Start to record
}

- (void)stopRecordAndSaveToFile:(NSString *)filepath
{
    _saveDataPath = [filepath copy];
}

@end
