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
    
    _controlPTWave = [UIButton buttonWithType:UIButtonTypeCustom];
    [_controlPTWave setBackgroundColor:[UIColor colorWithString:@"#249FFF"]];
    [_controlPTWave setFrame:CGRectMake(0, _screenHeight - 80, _screenWidth / 2, 80)];
    [self.view addSubview:_controlPTWave];
    [_controlPTWave setTitle:@"Display CG-Wave" forState:UIControlStateNormal];
    [_controlPTWave setTitle:@"Hide CG-Wave" forState:UIControlStateSelected];
    [_controlPTWave setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_controlPTWave.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    [_controlPTWave addTarget:self action:@selector(_controlActionForPTWave:)
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
    [_recoder beginToGatherEnvorinmentAudio];
}

- (BOOL)_inChance:(float)chance
{
    return ((random() % 1000) / 1000.f) < chance;
}

- (void)_controlActionForPTWave:(id)sender
{
    _controlPTWave.selected = !_controlPTWave.selected;
    if ( _controlPTWave.selected ) {
        // Add new ptwave
        _wave = [PTWave object];
        [_wave setFrame:CGRectMake(0, 0, 320.f, ([UIScreen mainScreen].bounds.size.height - 80) / 2)];
        [_wave setCurveColor:[UIColor orangeColor]];
        [self.view.layer addSublayer:_wave];
    } else {
        [_wave removeFromSuperlayer];
        _wave = nil;
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
        [_glWave setCurveColor:[UIColor orangeColor]];
        [self.view.layer addSublayer:_glWave];
    } else {
        [_glWave removeFromSuperlayer];
        _glWave = nil;
    }
}

- (void)__doWave
{
    UInt16 _value = _recoder.currentWeightOfFirstChannel;
    if ( _wave != nil ) {
        [_wave appendNewAudioValue:_value];
    }
    if ( _glWave != nil ) {
        [_glWave appendNewAudioValue:_value];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
