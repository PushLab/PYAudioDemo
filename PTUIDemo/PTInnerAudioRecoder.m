//
//  PTInnerAudioRecoder.m
//  PTUIDemo
//
//  Created by Push Chen on 2/13/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import "PTInnerAudioRecoder.h"

@interface PTInnerAudioRecoder (StaticHandler)

@property (nonatomic, readonly) AudioStreamBasicDescription    audioDataFormat;
@property (nonatomic, readonly) BOOL                    shouldWriteToFile;
@property (nonatomic, readonly) AudioFileID             audioFileId;
@property (nonatomic, readonly) UInt32                  audioBufferSize;
@property (nonatomic, readonly) AudioQueueBufferRef     lastAudioBuffer;
@property (nonatomic, assign)   SInt64                  currentPacketNumber;

- (void)setLastAudioBuffer:(AudioQueueBufferRef)buffer;

@end

static void __innerAudioRecoderInputHanlder (
    void                                *innerAudioRecorder,
    AudioQueueRef                       inAQ,
    AudioQueueBufferRef                 inBuffer,
    const AudioTimeStamp                *inStartTime,
    UInt32                              inNumPackets,
    const AudioStreamPacketDescription  *inPacketDesc
) {
    PTInnerAudioRecoder *_recorder = (__bridge PTInnerAudioRecoder *)innerAudioRecorder;

    // Calculate the packat count
    if ( inNumPackets == 0 && _recorder.audioDataFormat.mBytesPerPacket != 0 )
        inNumPackets = inBuffer->mAudioDataByteSize / _recorder.audioDataFormat.mBytesPerPacket;
    
    if ( _recorder.shouldWriteToFile ) {
        // Write to file
        if ( noErr == AudioFileWritePackets(_recorder.audioFileId,
                                            false,
                                            inBuffer->mAudioDataByteSize,
                                            inPacketDesc,
                                            _recorder.currentPacketNumber,
                                            &inNumPackets,
                                            inBuffer->mAudioData) ) {
            _recorder.currentPacketNumber += inNumPackets;
        }
    }
    
    [_recorder setLastAudioBuffer:inBuffer];
    if ( _recorder.isRecording == NO ) return;
    AudioQueueEnqueueBuffer(inAQ,
                            inBuffer,
                            0,
                            NULL);
}

static void __deriveBufferSize (
    AudioQueueRef audioQueue,
    AudioStreamBasicDescription *ASBDescription,
    Float64 seconds,
    UInt32 *outBufferSize )
{
    static const int maxBufferSize = 0x50000;
    int _maxPacketSize = ASBDescription->mBytesPerPacket;
    if ( _maxPacketSize == 0 ) {
        UInt32 _maxVBRPacketSize = sizeof(_maxPacketSize);
        AudioQueueGetProperty (
                audioQueue,
                kAudioQueueProperty_MaximumOutputPacketSize,
                &_maxPacketSize,
                &_maxVBRPacketSize
        );
    }
    Float64 numBytesForTime = ASBDescription->mSampleRate * _maxPacketSize * seconds;
    *outBufferSize = (UInt32)(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
}

static OSStatus SetMagicCookieForFile (
    AudioQueueRef inQueue,
    AudioFileID   inFile
) {
    OSStatus result = noErr;
    UInt32 cookieSize;
    if (
            AudioQueueGetPropertySize (
                inQueue,
                kAudioQueueProperty_MagicCookie,
                &cookieSize
            ) == noErr
    ) {
        char* magicCookie = (char *)malloc(cookieSize);
        if (
                AudioQueueGetProperty (
                    inQueue,
                    kAudioQueueProperty_MagicCookie,
                    magicCookie,
                    &cookieSize
                ) == noErr
        ) {
            result = AudioFileSetProperty (
                        inFile,
                        kAudioFilePropertyMagicCookieData,
                        cookieSize,
                        magicCookie
                     );
        }
        free (magicCookie);
    }
    return result;
}

static char *FormatError(char *str, OSStatus error)
{
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    return str;
}

@implementation PTInnerAudioRecoder

@synthesize isRecording = _isRecording;

- (id)init
{
    self = [super init];
    if ( self ) {
        // Initialize the meter table
        _meterMinDecibels = -80.f;
        _meterDecibelResolution = _meterMinDecibels / (400 - 1);
        _meterScaleFactor = 1.f / _meterDecibelResolution;
        
#define __dbToAmp(d)    pow(10.f, 0.05 * d)
        _meterTable = (float *)malloc(400 * sizeof(float));
        
        double minAmp = __dbToAmp(_meterMinDecibels);
        double ampRange = 1. - minAmp;
        double invAmpRange = 1. / ampRange;
        
        double rroot = 1. / 2.f;
        for (size_t i = 0; i < 400; ++i) {
            double decibels = i * _meterDecibelResolution;
            double amp = __dbToAmp(decibels);
            double adjAmp = (amp - minAmp) * invAmpRange;
            _meterTable[i] = pow(adjAmp, rroot);
        }
#undef __dbToAmp
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    free(_meterTable);
}

@dynamic lastError;
- (NSError *)lastError
{
    char _errMsg[6];
    FormatError(_errMsg, _lastError);
    NSString *_errStr = [NSString stringWithUTF8String:_errMsg];
    return [self errorWithCode:_lastError message:_errStr];
    //return [NSError errorWithDomain:NSOSStatusErrorDomain code:_lastError userInfo:nil];
}

@dynamic currentWeightOfFirstChannel;
- (UInt16)currentWeightOfFirstChannel
{
    if ( _isRecording == NO ) return 0;
    static AudioQueueLevelMeterState   _chan_lvls[2];
    
    UInt32 data_sz = sizeof(AudioQueueLevelMeterState) * 2;
    OSStatus status = AudioQueueGetProperty(
                                            _aqAudioQueue,
                                            kAudioQueueProperty_CurrentLevelMeterDB,
                                            &(_chan_lvls[0]),
                                            &data_sz);
    if (status != noErr) return 0;

    Float32 _allPower = 0;
    for (int i = 0; i < 2; i++) {
        if (_chan_lvls) {
            _allPower += _chan_lvls[i].mPeakPower;
        }
    }
    if ( _allPower < _meterMinDecibels ) return 0.f;
    if ( _allPower >= 0.f ) return UINT16_MAX;
    int _index = (int)(_allPower * _meterScaleFactor);
    return (Uint16)(65535.f * _meterTable[_index]);
}

- (void)beginToGatherEnvorinmentAudio
{
    if ( _isRecording ) return;
    
    // Set the audio queue format.
    _aqAudioDataFormat.mFormatID            = kAudioFormatLinearPCM;
    _aqAudioDataFormat.mSampleRate          = 44100.0;
    _aqAudioDataFormat.mChannelsPerFrame    = 2;
    _aqAudioDataFormat.mBitsPerChannel      = 16;
    _aqAudioDataFormat.mBytesPerFrame       = _aqAudioDataFormat.mChannelsPerFrame * sizeof(SInt16);
    _aqAudioDataFormat.mFramesPerPacket     = 1;
    _aqAudioDataFormat.mBytesPerPacket      = _aqAudioDataFormat.mBytesPerFrame * _aqAudioDataFormat.mFramesPerPacket;
    
    // AudioFileTypeID fileType                = kAudioFileAIFFType;
    _aqAudioDataFormat.mFormatFlags         = //kAudioFormatFlagsCanonical;
    (
        kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
    );
    
    // Create the new audio queue
    _lastError = AudioQueueNewInput(
                                    &_aqAudioDataFormat,
                                    __innerAudioRecoderInputHanlder,
                                    ((__bridge void *)self),
                                    NULL,
                                    kCFRunLoopCommonModes,
                                    0,
                                    &_aqAudioQueue
                       );
    if ( _lastError != noErr ) return;
    
    // Get Buffer Size
    __deriveBufferSize(_aqAudioQueue, &_aqAudioDataFormat, 0.5, &_aqAudioBufferByteSize);
    for ( int i = 0; i < kInnerAudioBufferNumbers; ++i ) {
        // Allocate the buffer
        _lastError = AudioQueueAllocateBuffer(_aqAudioQueue, _aqAudioBufferByteSize, &_aqAudioBufferList[i]);
        if ( _lastError != noErr ) {
            for ( int f = i - 1; f >= 0; --f ) {
                AudioQueueFreeBuffer(_aqAudioQueue, _aqAudioBufferList[f]);
            }
            AudioQueueDispose(_aqAudioQueue, true);
            return;
        }
        
        // Enqueue the buffer
        _lastError = AudioQueueEnqueueBuffer(_aqAudioQueue, _aqAudioBufferList[i], 0, NULL);
        if ( _lastError != noErr ) {
            for ( int f = i; f >= 0; --f ) {
                AudioQueueFreeBuffer(_aqAudioQueue, _aqAudioBufferList[f]);
            }
            AudioQueueDispose(_aqAudioQueue, true);
            return;
        }
    }
    
    // Set Metering
    UInt32 _val = 1;
    _lastError = AudioQueueSetProperty(
                                       _aqAudioQueue,
                                       kAudioQueueProperty_EnableLevelMetering,
                                       &_val,
                                       sizeof(UInt32));
    if ( _lastError != noErr ) {
        for ( int i = 0; i < kInnerAudioBufferNumbers; ++i ) {
            AudioQueueFreeBuffer(_aqAudioQueue, _aqAudioBufferList[i]);
        }
        AudioQueueDispose(_aqAudioQueue, true);
        return;
    }
    
//    int _retryTimes = 3;
//    do {
        _lastError = AudioQueueStart(_aqAudioQueue, NULL);
//        if ( _lastError == noErr ) break;
//        _retryTimes -= 1;
//    } while ( _retryTimes > 0 );
    if ( _lastError != noErr ) {
        for ( int i = 0; i < kInnerAudioBufferNumbers; ++i ) {
            AudioQueueFreeBuffer(_aqAudioQueue, _aqAudioBufferList[i]);
        }
        AudioQueueDispose(_aqAudioQueue, true);
        return;
    }
    _currentPacket = 0;
    _isRecording = YES;
}

- (void)recordToFile:(NSString *)filepath
{
    // Set the file path, create the audio file, and set the flag to write to file.
}

- (void)stop
{
    if ( _isRecording == NO ) return;
    // Stop the queue
    AudioQueueStop(_aqAudioQueue, true);
    // Dispose data
    AudioQueueDispose(_aqAudioQueue, true);
    // Close file
    _isRecording = NO;
}

@end

@implementation PTInnerAudioRecoder (StaticHandler)

@dynamic audioDataFormat;
- (AudioStreamBasicDescription)audioDataFormat
{
    return _aqAudioDataFormat;
}

@dynamic shouldWriteToFile;
- (BOOL)shouldWriteToFile
{
    return _shouldWriteToFile;
}

@dynamic audioFileId;
- (AudioFileID)audioFileId
{
    return _aqAudioFile;
}

@dynamic audioBufferSize;
- (UInt32)audioBufferSize
{
    return _aqAudioBufferByteSize;
}

@dynamic lastAudioBuffer;
- (AudioQueueBufferRef)currentAudioBuffer
{
    return _aqAudioBufferList[_lastUsedBuffer];
}

- (void)setLastAudioBuffer:(AudioQueueBufferRef)buffer
{
    for ( int i = 0; i < kInnerAudioBufferNumbers; ++i ) {
        if ( _aqAudioBufferList[i] == buffer ) {
            _lastUsedBuffer = i;
            break;
        }
    }
}

@dynamic currentPacketNumber;
- (SInt64)currentPacketNumber
{
    return _currentPacket;
}

@end
