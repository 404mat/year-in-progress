#import <AppKit/AppKit.h>

static double YearProgressFraction(NSDate *date, double *outDaysElapsed, double *outDaysRemaining) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *y = [cal components:NSCalendarUnitYear fromDate:date];
    NSDateComponents *startC = [[NSDateComponents alloc] init];
    startC.year = y.year; startC.month = 1; startC.day = 1;
    NSDateComponents *endC = [[NSDateComponents alloc] init];
    endC.year = y.year + 1; endC.month = 1; endC.day = 1;
    NSDate *start = [cal dateFromComponents:startC];
    NSDate *end = [cal dateFromComponents:endC];
    double total = [end timeIntervalSinceDate:start];
    double elapsed = [date timeIntervalSinceDate:start];
    double fraction = elapsed / total;
    if (fraction < 0) fraction = 0;
    if (fraction > 1) fraction = 1;
    // Show 100% for the final hour of the year
    if (total - elapsed <= 3600.0) fraction = 1.0;
    *outDaysElapsed = elapsed / 86400.0;
    *outDaysRemaining = (total - elapsed) / 86400.0;
    return fraction;
}

static NSImage *RingImage(double progress) {
    CGFloat size = 18.0;
    CGFloat lineWidth = 2.5;
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
    [image lockFocusFlipped:NO];
    NSRect rect = NSMakeRect(0, 0, size, size);
    CGFloat inset = lineWidth / 2.0 + 0.5;
    NSRect circleRect = NSInsetRect(rect, inset, inset);

    NSBezierPath *track = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    track.lineWidth = lineWidth;
    [[NSColor tertiaryLabelColor] setStroke];
    [track stroke];

    if (progress > 0.001) {
        NSBezierPath *arc = [NSBezierPath bezierPath];
        [arc appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(circleRect), NSMidY(circleRect))
                                        radius:circleRect.size.width / 2.0
                                    startAngle:90.0
                                      endAngle:90.0 - progress * 360.0
                                     clockwise:YES];
        arc.lineWidth = lineWidth;
        arc.lineCapStyle = NSLineCapStyleRound;
        [[NSColor labelColor] setStroke];
        [arc stroke];
    }
    [image unlockFocus];
    image.template = YES;
    return image;
}

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property (strong) NSStatusItem *statusItem;
@property (strong) NSTimer *timer;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSButton *button = self.statusItem.button;
    button.imagePosition = NSImageLeft;
    button.imageHugsTitle = YES;

    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    menu.autoenablesItems = NO;
    self.statusItem.menu = menu;

    [self update];

    self.timer = [NSTimer timerWithTimeInterval:60.0
                                         target:self
                                       selector:@selector(update)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self update];
}

- (void)update {
    double daysElapsed, daysRemaining;
    double fraction = YearProgressFraction([NSDate date], &daysElapsed, &daysRemaining);

    self.statusItem.button.image = RingImage(fraction);
    self.statusItem.button.title = [NSString stringWithFormat:@"%.0f%%", floor(fraction * 100)];

    NSMenu *menu = self.statusItem.menu;
    [menu removeAllItems];

    NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
    NSMenuItem *title = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%ld", (long)year]
                                                   action:nil keyEquivalent:@""];
    title.enabled = NO;
    [menu addItem:title];

    NSMutableString *bar = [NSMutableString string];
    NSInteger filled = (NSInteger)(fraction * 20 + 0.5);
    for (NSInteger i = 0; i < 20; i++) [bar appendString:(i < filled ? @"▮" : @"▯")];
    NSMenuItem *barItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@  %.1f%%", bar, floor(fraction * 1000) / 10.0]
                                                     action:nil keyEquivalent:@""];
    barItem.enabled = NO;
    [menu addItem:barItem];

    NSMenuItem *days = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%.0f days elapsed · %.0f days left", daysElapsed, daysRemaining]
                                                  action:nil keyEquivalent:@""];
    days.enabled = NO;
    [menu addItem:days];

    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                  action:@selector(terminate:) keyEquivalent:@"q"];
    quit.target = NSApp;
    [menu addItem:quit];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
