#import "TMLOverlayPanel.h"

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

@property (nonatomic, strong) UIStackView *modListStack;

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
    self.backgroundColor = [TMLTheme woodDarkColor];
    self.layer.cornerRadius = 12.0;
    self.layer.borderWidth = 2.5;
    self.layer.borderColor = [TMLTheme woodLightColor].CGColor;
    self.clipsToBounds = YES;
}

- (void)configureContent {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.attributedText = [TMLTheme outlinedTitleWithText:@"TModLite" fontSize:18.0];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setAttributedTitle:[TMLTheme outlinedTitleWithText:@"x" fontSize:18.0]
                            forState:UIControlStateNormal];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton addTarget:self action:@selector(handleClose) forControlEvents:UIControlEventTouchUpInside];

    UIView *headerSeparator = [[UIView alloc] init];
    headerSeparator.backgroundColor = [TMLTheme woodLightColor];
    headerSeparator.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *modListStack = [[UIStackView alloc] init];
    modListStack.axis = UILayoutConstraintAxisVertical;
    modListStack.spacing = 10.0;
    modListStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.modListStack = modListStack;

    [self addSubview:titleLabel];
    [self addSubview:closeButton];
    [self addSubview:headerSeparator];
    [self addSubview:modListStack];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:14.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],

        [closeButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12.0],
        [closeButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:titleLabel.trailingAnchor constant:8.0],

        [headerSeparator.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12.0],
        [headerSeparator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [headerSeparator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],
        [headerSeparator.heightAnchor constraintEqualToConstant:1.0],

        [modListStack.topAnchor constraintEqualToAnchor:headerSeparator.bottomAnchor constant:14.0],
        [modListStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [modListStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],
        [modListStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],

        [self.widthAnchor constraintEqualToConstant:260.0],
    ]];
}

- (void)handleClose {
    if (self.onClose) {
        self.onClose();
    }
}

- (void)setModRows:(NSArray<TMLOverlayModRow *> *)modRows {
    for (UIView *rowView in self.modListStack.arrangedSubviews.copy) {
        [self.modListStack removeArrangedSubview:rowView];
        [rowView removeFromSuperview];
    }

    if (modRows.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"Keine Mods geladen";
        emptyLabel.font = [TMLTheme bodyFont];
        emptyLabel.textColor = [TMLTheme textMutedColor];
        [self.modListStack addArrangedSubview:emptyLabel];
        return;
    }

    [modRows enumerateObjectsUsingBlock:^(TMLOverlayModRow *row, NSUInteger index, BOOL *stop) {
        UIView *rowView = [self buildRowViewForMod:row atIndex:(NSInteger)index];
        [self.modListStack addArrangedSubview:rowView];
    }];
}

- (UIView *)buildRowViewForMod:(TMLOverlayModRow *)row atIndex:(NSInteger)index {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = [NSString stringWithFormat:@"%@ (%@)", row.name, row.version];
    nameLabel.font = [TMLTheme bodyFont];
    nameLabel.textColor = [TMLTheme textLightColor];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.on = row.enabled;
    toggle.onTintColor = [TMLTheme accentGoldColor];
    toggle.tag = index;
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [toggle addTarget:self action:@selector(handleToggleChanged:) forControlEvents:UIControlEventValueChanged];

    [container addSubview:nameLabel];
    [container addSubview:toggle];

    [NSLayoutConstraint activateConstraints:@[
        [nameLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [nameLabel.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],

        [toggle.topAnchor constraintEqualToAnchor:container.topAnchor],
        [toggle.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [toggle.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [toggle.leadingAnchor constraintGreaterThanOrEqualToAnchor:nameLabel.trailingAnchor constant:8.0],
    ]];

    return container;
}

- (void)handleToggleChanged:(UISwitch *)sender {
    if (self.onToggleModAtIndex) {
        self.onToggleModAtIndex(sender.tag, sender.isOn);
    }
}

@end
