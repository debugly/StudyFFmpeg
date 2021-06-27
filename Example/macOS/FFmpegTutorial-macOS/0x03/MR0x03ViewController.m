//
//  MR0x03ViewController.m
//  FFmpegTutorial-macOS
//
//  Created by Matt Reach on 2021/4/15.
//

#import "MR0x03ViewController.h"
#import <FFmpegTutorial/FFPlayer0x03.h>
#import "MRRWeakProxy.h"

@interface MR0x03ViewController ()

@property (strong) FFPlayer0x03 *player;
@property (weak) IBOutlet NSTextField *inputField;
@property (assign) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSProgressIndicator *indicatorView;
@property (assign) NSInteger ignoreScrollBottom;
@property (weak) NSTimer *timer;

@end

@implementation MR0x03ViewController

- (void)dealloc
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (_player) {
        [_player stop];
        _player = nil;
    }
    
    _textView.delegate = nil;
    _textView = nil;
}

- (void)appendMsg:(NSString *)txt
{
    self.textView.string = [self.textView.string stringByAppendingFormat:@"\n%@",txt];
    [self.textView scrollToEndOfDocument:nil];
}

- (void)prepareTickTimerIfNeed
{
    if ([self.timer isValid]) {
        return;
    }
    MRRWeakProxy *weakProxy = [MRRWeakProxy weakProxyWithTarget:self];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:weakProxy selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
}

- (void)onTimer:(NSTimer *)sender
{
    [self appendMsg:[self.player peekPacketBufferStatus]];
//    if (self.ignoreScrollBottom > 0) {
//        self.ignoreScrollBottom --;
//    } else {
//        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 1)];
//    }
}

- (void)parserURL:(NSString *)url
{
    if (self.player) {
        [self.player stop];
        self.player = nil;
        [self.timer invalidate];
        self.timer = nil;
    }
    
    FFPlayer0x03 *player = [[FFPlayer0x03 alloc] init];
    player.contentPath = url;
    
    [self.indicatorView startAnimation:nil];
    __weakSelf__
    [player onError:^{
        __strongSelf__
        [self.indicatorView stopAnimation:nil];
        self.textView.string = [self.player.error localizedDescription];
        self.player = nil;
        [self.timer invalidate];
        self.timer = nil;
    }];
    
    [player onPacketBufferFull:^{
        __strongSelf__
        MR_sync_main_queue(^{
            [self.indicatorView stopAnimation:nil];
            [self prepareTickTimerIfNeed];
        });
    }];
    
    [player onPacketBufferEmpty:^{
        MR_sync_main_queue(^{
            __strongSelf__
            [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
            [self appendMsg:[self.player peekPacketBufferStatus]];
        });
    }];
    
    [player prepareToPlay];
    [player play];
    self.player = player;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.inputField.stringValue = KTestVideoURL1;
}

#pragma - mark actions

- (IBAction)go:(NSButton *)sender
{
    if (self.inputField.stringValue.length > 0) {
        [self parserURL:self.inputField.stringValue];
    } else {
        self.inputField.placeholderString = @"请输入视频地址";
    }
}

- (IBAction)onConsumePackets:(id)sender
{
    if (!self.player) {
        [self appendMsg:@"请先点击查看！"];
        return;
    }
    [self.player consumePackets];
    [self appendMsg:[self.player peekPacketBufferStatus]];
}

- (IBAction)onConsumeAllPackets:(id)sender
{
    if (!self.player) {
        [self appendMsg:@"请先点击查看！"];
        return;
    }
    [self.player consumeAllPackets];
    [self appendMsg:[self.player peekPacketBufferStatus]];
}

@end