#import "TMLOutlinedLabel.h"

#import "TMLTheme.h"

@interface TMLOutlinedLabel ()

@property (nonatomic, strong) UILabel *shadowLabel;
@property (nonatomic, strong) UILabel *mainLabel;

@end

@implementation TMLOutlinedLabel

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        _shadowLabel = [self makeSublabel];
        _shadowLabel.textColor = [UIColor colorWithWhite:0.0 alpha:0.85];

        _mainLabel = [self makeSublabel];
        _mainLabel.textColor = [UIColor whiteColor];

        [self addSubview:_shadowLabel];
        [self addSubview:_mainLabel];

        CGFloat offset = 1.5;
        [NSLayoutConstraint activateConstraints:@[
            [_mainLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_mainLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_mainLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_mainLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

            [_shadowLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:offset],
            [_shadowLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:offset],
            [_shadowLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:offset],
            [_shadowLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:offset],
        ]];

        self.font = [TMLTheme chalkboardFontOfSize:16.0];
        self.textAlignment = NSTextAlignmentLeft;
    }
    return self;
}

- (UILabel *)makeSublabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (void)setText:(nullable NSString *)text {
    _text = [text copy];
    self.mainLabel.text = text;
    self.shadowLabel.text = text;
}

- (void)setFont:(nullable UIFont *)font {
    _font = font;
    self.mainLabel.font = font;
    self.shadowLabel.font = font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    self.mainLabel.textAlignment = textAlignment;
    self.shadowLabel.textAlignment = textAlignment;
}

@end
