#import "TMLSettingsRow.h"

#import "TMLOutlinedLabel.h"
#import "TMLSegmentedToggle.h"
#import "TMLTheme.h"

@interface TMLSettingsRow ()

@property (nonatomic, strong) TMLSegmentedToggle *toggle;

@end

@implementation TMLSettingsRow

- (instancetype)initWithTitle:(NSString *)title enabled:(BOOL)enabled {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [TMLTheme rowBackgroundColor];
        self.layer.cornerRadius = 10.0;
        self.clipsToBounds = YES;

        TMLOutlinedLabel *titleLabel = [[TMLOutlinedLabel alloc] init];
        titleLabel.text = title;
        titleLabel.font = [TMLTheme chalkboardFontOfSize:16.0];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:titleLabel];

        TMLSegmentedToggle *toggle = [[TMLSegmentedToggle alloc] init];
        toggle.on = enabled;
        __weak TMLSettingsRow *weakSelf = self;
        toggle.onChange = ^(BOOL isOn) {
            if (weakSelf.onToggle) {
                weakSelf.onToggle(isOn);
            }
        };
        [self addSubview:toggle];
        self.toggle = toggle;

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14.0],
            [titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-8.0],

            [toggle.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10.0],
            [toggle.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

            [self.heightAnchor constraintEqualToConstant:48.0],
        ]];
    }
    return self;
}

- (void)setToggleOn:(BOOL)on animated:(BOOL)animated {
    [self.toggle setOn:on animated:animated];
}

@end
