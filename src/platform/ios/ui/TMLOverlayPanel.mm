#import "TMLOverlayPanel.h"

#import "TMLBackButton.h"
#import "TMLOutlinedLabel.h"
#import "TMLSettingsRow.h"
#import "TMLTheme.h"

@implementation TMLOverlayModRow

+ (instancetype)rowWithName:(NSString *)name version:(NSString *)version enabled:(BOOL)enabled {
    TMLOverlayModRow *row = [[TMLOverlayModRow alloc] init];
    row->_name = [name copy];
    row->_version = [version copy];
    row->_enabled = enabled;
    return row;
}

@end

@interface TMLOverlayPanel ()

@property (nonatomic, strong) UIStackView *rowStack;

@end

@implementation TMLOverlayPanel

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self configureAppearance];
        [self configureContent];
        [self setModRows:@[]];
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

    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisVertical;
    rowStack.spacing = 10.0;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.rowStack = rowStack;
    [self addSubview:rowStack];

    TMLBackButton *backButton = [[TMLBackButton alloc] init];
    __weak TMLOverlayPanel *weakSelf = self;
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

        [rowStack.topAnchor constraintEqualToAnchor:titlePill.bottomAnchor constant:20.0],
        [rowStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [rowStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],

        [backButton.topAnchor constraintEqualToAnchor:rowStack.bottomAnchor constant:20.0],
        [backButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [backButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
    ]];
}

- (void)setModRows:(NSArray<TMLOverlayModRow *> *)modRows {
    for (UIView *rowView in self.rowStack.arrangedSubviews.copy) {
        [self.rowStack removeArrangedSubview:rowView];
        [rowView removeFromSuperview];
    }

    if (modRows.count == 0) {
        TMLOutlinedLabel *emptyLabel = [[TMLOutlinedLabel alloc] init];
        emptyLabel.text = @"Keine Mods geladen";
        emptyLabel.font = [TMLTheme chalkboardFontOfSize:15.0];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        [self.rowStack addArrangedSubview:emptyLabel];
        return;
    }

    [modRows enumerateObjectsUsingBlock:^(TMLOverlayModRow *row, NSUInteger index, BOOL *stop) {
        TMLSettingsRow *rowView = [[TMLSettingsRow alloc] initWithTitle:row.name enabled:row.enabled];
        __weak TMLOverlayPanel *weakSelf = self;
        rowView.onToggle = ^(BOOL isOn) {
            if (weakSelf.onToggleModAtIndex) {
                weakSelf.onToggleModAtIndex((NSInteger)index, isOn);
            }
        };
        [self.rowStack addArrangedSubview:rowView];
    }];
}

@end
