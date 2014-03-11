//
//  PTInnerAudioRecoder.h
//  PTUIDemo
//
//  Created by Push Chen on 2/13/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <Foundation/Foundation.h>

static const int kInnerAudioBufferNumbers           = 3;

@interface PTInnerAudioRecoder : NSObject
{
    AudioStreamBasicDescription         _aqAudioDataFormat;
    AudioQueueRef                       _aqAudioQueue;
    AudioQueueBufferRef                 _aqAudioBufferList[kInnerAudioBufferNumbers];
    AudioFileID                         _aqAudioFile;
    UInt32                              _aqAudioBufferByteSize;
    SInt64                              _currentPacket;
    int                                 _lastUsedBuffer;
    BOOL                                _isRecording;
    BOOL                                _shouldWriteToFile;
    
    // Meter Table
    // Copy from Apple's Speak Here
    float                               _meterMinDecibels;
	float                               _meterDecibelResolution;
	float                               _meterScaleFactor;
	float                               *_meterTable;
}

@property (nonatomic, readonly) BOOL        isRecording;

// Get the first channel's audio weight.
@property (nonatomic, readonly) UInt16      currentWeightOfFirstChannel;

// Start the audio queue to record the audio.
// This operator will not save any data.
- (void)beginToGatherEnvorinmentAudio;

// If the audio queue has not been started, then start it.
// Otherwise just write the recorded buffer to the specified file.
- (void)recordToFile:(NSString *)filepath;

// Stop record, this will also stop the envorinment audio gathering.
- (void)stop;

@end
