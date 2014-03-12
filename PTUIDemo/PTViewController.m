//
//  PTViewController.m
//  PTUIDemo
//
//  Created by Push Chen on 1/27/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import "PTViewController.h"
#import <GLKit/GLKit.h>

@interface PTViewController ()

@end

@implementation PTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(__doWave)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // Add Two control button
    CGFloat _screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat _screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    _recoderButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recoderButton setBackgroundColor:[UIColor colorWithString:@"#249FFF"]];
    [_recoderButton setFrame:CGRectMake(0, _screenHeight - 80, _screenWidth / 2, 80)];
    [self.view addSubview:_recoderButton];
    [_recoderButton setTitle:@"Start to record" forState:UIControlStateNormal];
    [_recoderButton setTitle:@"Stop recording" forState:UIControlStateSelected];
    [_recoderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_recoderButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    [_recoderButton addTarget:self action:@selector(_controlActionForRecorder:)
             forControlEvents:UIControlEventTouchUpInside];
    
    _controlGLWave = [UIButton buttonWithType:UIButtonTypeCustom];
    [_controlGLWave setBackgroundColor:[UIColor colorWithString:@"#CB1D5E"]];
    [_controlGLWave setFrame:CGRectMake(_screenWidth / 2, _screenHeight - 80, _screenWidth / 2, 80)];
    [self.view addSubview:_controlGLWave];
    [_controlGLWave setTitle:@"Display GL-Wave" forState:UIControlStateNormal];
    [_controlGLWave setTitle:@"Hide GL-Wave" forState:UIControlStateSelected];
    [_controlGLWave setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_controlGLWave.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    [_controlGLWave addTarget:self action:@selector(_controlActionForGLWave:)
             forControlEvents:UIControlEventTouchUpInside];
    
    // Start the audio recoder
    _recoder = [PTInnerAudioRecoder object];
    // [_recoder beginToGatherEnvorinmentAudio];
    
    // Change the audio session to record
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    // Active the audio session
    NSError *_audioError = nil;
    if ( ![[AVAudioSession sharedInstance] setActive:YES error:&_audioError] ) {
        PYLog(@"%@", _audioError);
    }
}

- (BOOL)_inChance:(float)chance
{
    return ((random() % 1000) / 1000.f) < chance;
}

- (void)_controlActionForRecorder:(id)sender
{
    _recoderButton.selected = !_recoderButton.selected;
    if ( _recoderButton.selected ) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if ( granted ) {
                [_recoder beginToGatherEnvorinmentAudio];
                if ( _recoder.lastError.code == 0 ) return;
            }
            _recoderButton.selected = NO;
            PYLog(@"Last Error for AudioQueue: %@", _recoder.lastError);
        }];
    } else {
        [_recoder stop];
    }
}

- (void)_controlActionForGLWave:(id)sender
{
    _controlGLWave.selected = !_controlGLWave.selected;
    if ( _controlGLWave.selected ) {
        // Add new glwave
        _glWave = [PTGLWave object];
        [_glWave setFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.height - 80) / 2,
                                     320, ([UIScreen mainScreen].bounds.size.height - 80) / 2)];
        [_glWave setCurveColor:[UIColor redColor]];
        [self.view.layer addSublayer:_glWave];
    } else {
        [_glWave removeFromSuperlayer];
        _glWave = nil;
    }
}

- (void)__doWave
{
    UInt16 _value = _recoder.currentWeightOfFirstChannel;
    if ( _glWave != nil ) {
        [_glWave appendNewAudioValue:_value];
        //[_glWave setCurveColor:[UIColor randomColor]];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
