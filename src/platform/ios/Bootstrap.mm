#include <cstddef>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "ui/TMLOverlayManager.h"
#import "ui/TMLOverlayPanel.h"

#include "GameContext.hpp"
#include "ModLoader.hpp"
#include "Runtime.hpp"

__attribute__((constructor))
static void tml_ios_bootstrap() {
    static tml::Runtime runtime;

    tml::GameContext& context = runtime.context();
    context.player.name = "PlaceholderPlayer";
    context.world.name = "PlaceholderWorld";

    runtime.start();

    // NSLog statt printf: unbuffered, landet garantiert im System-Log auch
    // wenn stdout des Prozesses (nicht-interaktiv) voll gepuffert ist.
    // Build-Zeitstempel zum Abgleich, ob wirklich der neueste Build laeuft.
    NSLog(@"[iOS Bootstrap] TModLite geladen und gestartet (Build: %s %s)", __DATE__, __TIME__);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        tml::ModLoader& modLoader = runtime.modLoader();

        NSMutableArray<TMLOverlayModRow *>* rows = [NSMutableArray array];
        for (std::size_t i = 0; i < modLoader.modCount(); ++i) {
            TMLOverlayModRow* row = [TMLOverlayModRow
                rowWithName:[NSString stringWithUTF8String:modLoader.modName(i).c_str()]
                     version:[NSString stringWithUTF8String:modLoader.modVersion(i).c_str()]
                     enabled:modLoader.isModEnabled(i)];
            [rows addObject:row];
        }

        [[TMLOverlayManager sharedManager] presentOverlayWithModRows:rows
                                                    onToggleModAtIndex:^(NSInteger index, BOOL enabled) {
            runtime.modLoader().setModEnabled(static_cast<std::size_t>(index), enabled);
        }];
    });
}
