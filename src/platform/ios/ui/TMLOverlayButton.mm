#import "TMLOverlayButton.h"

#import "TMLTheme.h"

@interface TMLOverlayButton ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *trailingConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomConstraint;

@end

@implementation TMLOverlayButton

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        [self configureLabel];
        [self configureGestures];
    }
    return self;
}

- (void)configureLabel {
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = [TMLTheme outlinedTitleWithText:@"TModLite" fontSize:22.0];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.userInteractionEnabled = NO;
    [self addSubview:label];
    self.titleLabel = label;

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [label.topAnchor constraintEqualToAnchor:self.topAnchor],
        [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (void)configureGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handleTap)];
    [self addGestureRecognizer:tap];
}

- (void)handleTap {
    if (self.onTap) {
        self.onTap();
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    if (!self.superview || self.trailingConstraint) {
        return;
    }

    UILayoutGuide *safeArea = self.superview.safeAreaLayoutGuide;

    self.trailingConstraint = [safeArea.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:16.0];
    self.bottomConstraint = [safeArea.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:16.0];

    [NSLayoutConstraint activateConstraints:@[
        self.trailingConstraint,
        self.bottomConstraint,
    ]];
}

@end
