//
//  PTAudioRecoder.h
//  PTUIDemo
//
//  Created by Push Chen on 2/13/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTAudioWave.h"

@class PTInternalAudioRecoder;

@interface PTAudioRecoder : NSObject <AVAudioRecorderDelegate>
{
    PTInternalAudioRecoder          *_innerRecoder;
    NSString                        *_saveDataPath;
    NSString                        *_tempFilePath;
}

@property (nonatomic, assign)   id<PTAudioWave>     displayWaveLayer;

// Start to record audio
- (void)starToRecord;
// Tell the recorder to stop and safe the audio data to specified file path.
- (void)stopRecordAndSaveToFile:(NSString *)filepath;

@end
