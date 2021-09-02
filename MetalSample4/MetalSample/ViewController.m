//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "ViewController.h"

#import "KKRenderer.h"

#import <MetalKit/MetalKit.h>

#define FPS 30
@interface ViewController ()
@property (nonatomic, weak) IBOutlet MTKView *metalView;
@property (weak) IBOutlet NSSlider *slider;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSSwitch *switchView;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) KKRenderer *renderer;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *_Nullable(NSEvent *_Nonnull event) {
        if ((event.keyCode == 123 || event.keyCode == 124) && self.switchView.state == NSControlStateValueOff) {
            [self keyDownHandler:event];
            return event;
        }
        return nil;
    }];
}

- (void)viewWillAppear {
    [super viewWillAppear];

    [self.view.window setFrame:NSMakeRect(0, 0, 360, 640) display:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window center];
        [self commonInit];
    });
}

- (void)viewDidAppear {
    [super viewDidAppear];

    self.view.window.movableByWindowBackground = YES;

    [self switchAction:self.switchView];
}

#pragma mark - commonInit
- (void)commonInit {

    self.metalView.device = MTLCreateSystemDefaultDevice();

    self.renderer = [[KKRenderer alloc] initWithView:self.metalView];
    self.metalView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.metalView.delegate = self.renderer;

    self.slider.maxValue = 4.0;
}

- (void)startTimer {
    if (self.timer) {
        return;
    }
    __block NSInteger fps = self.slider.floatValue * FPS;
    self.timer = [NSTimer timerWithTimeInterval:1.0 / FPS repeats:YES block:^(NSTimer *_Nonnull timer) {
        if (fps >= 4 * FPS) {
            self.slider.floatValue = 0;
            [self updateTime];
            fps = 0;
            return;
        }
        [self increase];
        fps++;
    }];

    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)increase {
    float value = fminf(self.slider.floatValue + 1.0 / FPS, 4.0);
    self.slider.floatValue = value;
    [self updateTime];
}

- (void)decrement {
    float value = fmaxf(self.slider.floatValue - 1.0 / FPS, 0.0);
    self.slider.floatValue = value;
    [self updateTime];
}

- (IBAction)silderAction:(NSSlider *)sender {
    [self updateTime];
}

- (IBAction)switchAction:(NSSwitch *)sender {
    if (sender.state == NSControlStateValueOff) {
        [self.timer invalidate];
        self.timer = nil;
        self.slider.enabled = YES;
    } else {
        if (self.slider.floatValue >= self.slider.maxValue) {
            self.slider.floatValue = 0;
        }
        [self startTimer];
        self.slider.enabled = NO;
    }
}

- (void)updateTime {
    float time = self.slider.floatValue;
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%f", time];
    [self.renderer updateTime:time];
}

- (void)keyDownHandler:(NSEvent *)event {
    if (event.keyCode == 124) {
        [self increase];
    } else if (event.keyCode == 123) {
        [self decrement];
    }
}
@end

