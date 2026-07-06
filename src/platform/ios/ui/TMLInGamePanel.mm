#import "TMLInGamePanel.h"

#import "TMLBackButton.h"
#import "TMLOutlinedLabel.h"
#import "TMLTheme.h"

@interface TMLInGamePanel ()

@property (nonatomic, strong) TMLOutlinedLabel *placeholderLabel;

@end

@implementation TMLInGamePanel

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self configureAppearance];
        [self configureContent];
    }
    return self;
}

- (void)configureAppearance {
    self.backgroundColor = [TMLTheme panelBackgroundColor];
    self.layer.cornerRadius = 14.0;
    self.layer.borderWidth = 3.5;
    self.layer.borderColor = [TMLTheme panelBorderColor].CGColor;
    self.clipsToBounds = YES;
}

- (void)configureContent {
    UIView *titlePill = [[UIView alloc] init];
    titlePill.translatesAutoresizingMaskIntoConstraints = NO;
    titlePill.backgroundColor = [TMLTheme titlePillColor];
    [self addSubview:titlePill];

    TMLOutlinedLabel *titleLabel = [[TMLOutlinedLabel alloc] init];
    titleLabel.text = @"TModLite";
    titleLabel.font = [TMLTheme chalkboardFontOfSize:20.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titlePill addSubview:titleLabel];

    // Noch keine echten In-Game-Features verdrahtet - siehe docs/roadmap.md.
    TMLOutlinedLabel *placeholderLabel = [[TMLOutlinedLabel alloc] init];
    placeholderLabel.text = @"Noch keine In-Game-Features";
    placeholderLabel.font = [TMLTheme chalkboardFontOfSize:15.0];
    placeholderLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:placeholderLabel];
    self.placeholderLabel = placeholderLabel;

    TMLBackButton *backButton = [[TMLBackButton alloc] init];
    __weak TMLInGamePanel *weakSelf = self;
    backButton.onTap = ^{
        if (weakSelf.onClose) {
            weakSelf.onClose();
        }
    };
    [self addSubview:backButton];

    [NSLayoutConstraint activateConstraints:@[
        [titlePill.topAnchor constraintEqualToAnchor:self.topAnchor constant:16.0],
        [titlePill.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [titlePill.heightAnchor constraintEqualToConstant:36.0],

        [titleLabel.leadingAnchor constraintEqualToAnchor:titlePill.leadingAnchor constant:24.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:titlePill.trailingAnchor constant:-24.0],
        [titleLabel.centerYAnchor constraintEqualToAnchor:titlePill.centerYAnchor],

        [placeholderLabel.topAnchor constraintEqualToAnchor:titlePill.bottomAnchor constant:32.0],
        [placeholderLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [placeholderLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],

        [backButton.topAnchor constraintEqualToAnchor:placeholderLabel.bottomAnchor constant:32.0],
        [backButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [backButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
    ]];
}

@end
