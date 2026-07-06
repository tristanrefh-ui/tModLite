#include <cstddef>
#include <string>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "ui/TMLOverlayManager.h"
#import "ui/TMLOverlayPanel.h"

#include "GameContext.hpp"
#include "Il2CppBridge.h"
#include "ModLoader.hpp"
#include "PlayerLoopTest.h"
#include "Runtime.hpp"

// Legt manifest.json fuer einen Test-Mod im Documents/mods-Ordner an, falls
// er noch fehlt - nur fuer den ersten Geraetetest, damit man die Beispiel-
// Mods nicht manuell per Dateien-App aufs Geraet kopieren muss.
static void TML_EnsureSeedMod(NSString* modsPath, NSString* modName, NSString* manifestJSON) {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* modDir = [modsPath stringByAppendingPathComponent:modName];
    NSString* manifestPath = [modDir stringByAppendingPathComponent:@"manifest.json"];

    if ([fileManager fileExistsAtPath:manifestPath]) {
        return;
    }

    NSError* error = nil;
    [fileManager createDirectoryAtPath:modDir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"[iOS Bootstrap] Konnte Ordner fuer Seed-Mod %@ nicht anlegen: %@", modName, error);
        return;
    }

    BOOL wrote = [manifestJSON writeToFile:manifestPath
                                 atomically:YES
                                   encoding:NSUTF8StringEncoding
                                      error:&error];
    if (!wrote || error) {
        NSLog(@"[iOS Bootstrap] Konnte manifest.json fuer Seed-Mod %@ nicht schreiben: %@", modName, error);
        return;
    }

    NSLog(@"[iOS Bootstrap] Seed-Mod angelegt: %@", manifestPath);
}

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
        // Schritt A (reines Lesen, keine Mutation) des PlayerLoop-
        // Experiments - siehe PlayerLoopTest.h. Laeuft automatisch beim
        // Start, unabhaengig vom ModLoader/Overlay-Code unten.
        TML_LogCurrentPlayerLoop();

        tml::ModLoader& modLoader = runtime.modLoader();

        // Mods leben (noch) in einem "mods"-Ordner im App-Documents-
        // Verzeichnis - der einzige auf einem echten Geraet ohne Jailbreak
        // beschreib- und erreichbare Ort (z.B. ueber Dateien-App/iTunes-
        // Freigabe). Ein relativer Pfad wie "mods/" wuerde hier ins Leere
        // laufen, da die dylib im Arbeitsverzeichnis von Terrarias Prozess
        // laeuft, nicht in unserem Projektordner. TML_EnsureSeedMod legt die
        // zwei Beispiel-Mods automatisch an, falls sie fehlen.
        NSArray<NSString *>* documentsPaths =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* modsPath = [documentsPaths.firstObject stringByAppendingPathComponent:@"mods"];
        NSLog(@"[iOS Bootstrap] Mods-Verzeichnis (absoluter Pfad): %@", modsPath);

        // Fuer den ersten Geraetetest: Beispiel-Mods automatisch anlegen,
        // falls sie fehlen - kein manuelles Kopieren per Dateien-App noetig.
        TML_EnsureSeedMod(modsPath, @"QuickHeal",
                          @"{\n  \"name\": \"QuickHeal\",\n  \"version\": \"1.0\",\n  \"enabled\": true\n}\n");
        TML_EnsureSeedMod(modsPath, @"InfiniteAmmo",
                          @"{\n  \"name\": \"InfiniteAmmo\",\n  \"version\": \"1.0\",\n  \"enabled\": false\n}\n");

        std::size_t foundCount = modLoader.scanDirectory(modsPath.UTF8String);
        NSLog(@"[iOS Bootstrap] ModLoader::scanDirectory(%@) -> %lu Mods gefunden", modsPath,
              (unsigned long)foundCount);

        NSMutableArray<TMLOverlayModRow *>* rows = [NSMutableArray array];
        for (std::size_t i = 0; i < modLoader.modCount(); ++i) {
            std::string name = modLoader.modName(i);
            bool enabled = modLoader.isModEnabled(i);
            TMLOverlayModRow* row =
                [TMLOverlayModRow rowWithName:[NSString stringWithUTF8String:name.c_str()]
                                       version:[NSString stringWithUTF8String:modLoader.modVersion(i).c_str()]
                                       enabled:enabled];
            [rows addObject:row];

            // QuickHeal ist der erste Fake-Mod mit echter Wirkung: sein
            // Toggle-Zustand steuert den God-Mode-Poll-Timer der IL2CPP-
            // Bruecke. Initialzustand beim Start synchronisieren, nicht nur
            // bei spaeteren Toggles.
            if (name == "QuickHeal" && enabled) {
                TML_SetGodMode(true);
            }
        }

        [[TMLOverlayManager sharedManager] presentOverlayWithModRows:rows
                                                    onToggleModAtIndex:^(NSInteger index, BOOL enabled) {
            tml::ModLoader& modLoaderRef = runtime.modLoader();
            std::string name = modLoaderRef.modName(static_cast<std::size_t>(index));
            modLoaderRef.toggleMod(name);

            // enabled kommt nur, weil onChange bereits einen echten
            // Zustandswechsel bestaetigt hat (siehe TMLSegmentedToggle) -
            // toggleMod(name) landet also garantiert auf genau diesem Wert.
            if (name == "QuickHeal") {
                TML_SetGodMode(enabled);
            }
        }];
    });
}
