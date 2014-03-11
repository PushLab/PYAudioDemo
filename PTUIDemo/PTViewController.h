//
//  PTViewController.h
//  PTUIDemo
//
//  Created by Push Chen on 1/27/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTWave.h"
#import "PTGLWave.h"
#import "PTInnerAudioRecoder.h"

@interface PTViewController : UIViewController
{
    PTWave                  *_wave;
    PTGLWave                *_glWave;
    
    CADisplayLink           *_displayLink;
    
    UIButton                *_controlPTWave;
    UIButton                *_controlGLWave;
    
    PTInnerAudioRecoder     *_recoder;
}
@end
