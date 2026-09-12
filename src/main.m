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

static double MonthProgressFraction(NSDate *date) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *m = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
    NSDateComponents *startC = [[NSDateComponents alloc] init];
    startC.year = m.year; startC.month = m.month; startC.day = 1;
    NSDateComponents *endC = [[NSDateComponents alloc] init];
    endC.year = m.year; endC.month = m.month + 1; endC.day = 1;
    NSDate *start = [cal dateFromComponents:startC];
    NSDate *end = [cal dateFromComponents:endC];
    double total = [end timeIntervalSinceDate:start];
    double elapsed = [date timeIntervalSinceDate:start];
    double fraction = elapsed / total;
    if (fraction < 0) fraction = 0;
    if (fraction > 1) fraction = 1;
    return fraction;
}

static double DayProgressFraction(NSDate *date) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *d = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    NSDate *start = [cal dateFromComponents:d];
    NSDateComponents *oneDay = [[NSDateComponents alloc] init];
    oneDay.day = 1;
    NSDate *end = [cal dateByAddingComponents:oneDay toDate:start options:0];
    double total = [end timeIntervalSinceDate:start];
    double elapsed = [date timeIntervalSinceDate:start];
    double fraction = elapsed / total;
    if (fraction < 0) fraction = 0;
    if (fraction > 1) fraction = 1;
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

@class MenuContentView;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property (strong) NSStatusItem *statusItem;
@property (strong) NSTimer *timer;
@property (strong) MenuContentView *menuContent;
@end

static const CGFloat BarSquareSize = 11.0;
static const CGFloat BarSquareGap = 2.0;
static const NSInteger BarSquareCount = 20;

static const CGFloat MenuPad = 10.0;
static const CGFloat LabelWidth = 46.0;
static const CGFloat BarWidth = BarSquareCount * BarSquareSize + (BarSquareCount - 1) * BarSquareGap;
static const CGFloat PercentWidth = 38.0;
static const CGFloat ColumnGap = 8.0;
static const CGFloat RowHeight = 16.0;
static const CGFloat RowGap = 8.0;

@interface MenuContentView : NSView
@property (assign) double yearProgress;
@property (assign) double monthProgress;
@property (assign) double dayProgress;
@property (copy) NSString *daysText;
@end

@implementation MenuContentView

- (void)drawBarInRect:(NSRect)barRect progress:(double)progress {
    NSInteger filled = (NSInteger)(progress * BarSquareCount + 0.5);
    if (filled > BarSquareCount) filled = BarSquareCount;
    CGFloat y = NSMinY(barRect);
    for (NSInteger i = 0; i < BarSquareCount; i++) {
        CGFloat x = NSMinX(barRect) + i * (BarSquareSize + BarSquareGap);
        NSRect square = NSInsetRect(NSMakeRect(x, y, BarSquareSize, BarSquareSize), 1.0, 1.0);
        if (i < filled) {
            [[NSColor labelColor] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:square xRadius:2.0 yRadius:2.0] fill];
        } else {
            [[NSColor tertiaryLabelColor] setStroke];
            NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:square xRadius:2.0 yRadius:2.0];
            p.lineWidth = 1.0;
            [p stroke];
        }
    }
}

- (void)drawString:(NSString *)string
           atPoint:(NSPoint)point
          forWidth:(CGFloat)width
              font:(NSFont *)font
             color:(NSColor *)color {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByClipping;
    NSDictionary *attrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color,
        NSParagraphStyleAttributeName: style,
    };
    NSSize size = [string sizeWithAttributes:attrs];
    [string drawAtPoint:NSMakePoint(point.x, point.y + (RowHeight - size.height) / 2.0)
         withAttributes:attrs];
}

- (void)drawRect:(NSRect)dirtyRect {
    CGFloat contentWidth = LabelWidth + ColumnGap + BarWidth + ColumnGap + PercentWidth;

    NSArray *labels = @[@"Year", @"Month", @"Day"];
    NSArray *progresses = @[@(self.yearProgress), @(self.monthProgress), @(self.dayProgress)];
    NSFont *rowFont = [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightRegular];

    for (NSInteger i = 0; i < 3; i++) {
        CGFloat rowTop = MenuPad + i * (RowHeight + RowGap);
        double progress = [progresses[i] doubleValue];

        [self drawString:labels[i]
                 atPoint:NSMakePoint(MenuPad, rowTop)
                 forWidth:LabelWidth
                     font:rowFont
                  color:[NSColor secondaryLabelColor]];

        [self drawBarInRect:NSMakeRect(MenuPad + LabelWidth + ColumnGap, rowTop + 1.0, BarWidth, RowHeight - 2.0)
                   progress:progress];

        NSString *percentText = [NSString stringWithFormat:@"%.0f%%", floor(progress * 100)];
        [self drawString:percentText
                 atPoint:NSMakePoint(MenuPad + LabelWidth + ColumnGap + BarWidth + ColumnGap, rowTop)
                 forWidth:PercentWidth
                     font:rowFont
                  color:[NSColor labelColor]];
    }

    CGFloat daysTop = MenuPad + 3 * (RowHeight + RowGap);
    [self drawString:self.daysText
             atPoint:NSMakePoint(MenuPad, daysTop)
             forWidth:contentWidth
                 font:[NSFont systemFontOfSize:12]
              color:[NSColor secondaryLabelColor]];
}

+ (NSSize)contentSize {
    CGFloat width = MenuPad * 2 + LabelWidth + ColumnGap + BarWidth + ColumnGap + PercentWidth;
    CGFloat height = MenuPad * 2 + 3 * RowHeight + 2 * RowGap + RowHeight;
    return NSMakeSize(width, height);
}

- (BOOL)isFlipped {
    return YES;
}
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

    NSSize contentSize = [MenuContentView contentSize];
    self.menuContent = [[MenuContentView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];

    NSMenuItem *rowItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    rowItem.enabled = NO;
    rowItem.view = self.menuContent;
    [menu addItem:rowItem];

    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                  action:@selector(terminate:) keyEquivalent:@"q"];
    quit.target = NSApp;
    [menu addItem:quit];

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

    NSDate *now = [NSDate date];
    self.menuContent.yearProgress = fraction;
    self.menuContent.monthProgress = MonthProgressFraction(now);
    self.menuContent.dayProgress = DayProgressFraction(now);
    self.menuContent.daysText = [NSString stringWithFormat:@"%.0f days elapsed · %.0f days left", daysElapsed, daysRemaining];
    [self.menuContent setNeedsDisplay:YES];
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
