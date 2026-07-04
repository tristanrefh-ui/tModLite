#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Reine Datenzeile fuers Panel, keine Core-Abhaengigkeit - Bootstrap.mm baut
// diese aus dem echten ModLoader-State.
@interface TMLOverlayModRow : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, assign, readonly) BOOL enabled;

+ (instancetype)rowWithName:(NSString *)name version:(NSString *)version enabled:(BOOL)enabled;

@end

// Panel mit Titel, Close-Button und einer einfachen Mod-Liste (Name +
// Toggle), im Terraria-anmutenden Holz-/Stein-Farbschema aus TMLTheme.
@interface TMLOverlayPanel : UIView

@property (nonatomic, copy, nullable) void (^onClose)(void);
@property (nonatomic, copy, nullable) void (^onToggleModAtIndex)(NSInteger index, BOOL enabled);

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)setModRows:(NSArray<TMLOverlayModRow *> *)modRows;

@end

NS_ASSUME_NONNULL_END
