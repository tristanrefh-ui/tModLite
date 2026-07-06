# Dobby (third_party/dobby/) wird hier bewusst NICHT mehr gelinkt: der
# einzige Konsument (HookTest.mm, Inline-Hook auf NPC.UpdateNPC) ist nach
# experimental/ verschoben, weil der Testlauf auf echtem Geraet fehlgeschlagen
# ist - siehe docs/technical-limitations.md und experimental/README.md fuer
# das Re-Aktivieren (Lib bleibt vendored liegen, falls das Thema spaeter
# nochmal aufgegriffen wird).

add_library(tml_ios_bootstrap SHARED
    Bootstrap.mm
    Il2CppBridge.mm
    PlayerLoopTest.mm
    ui/TMLTheme.mm
    ui/TMLOutlinedLabel.mm
    ui/TMLSegmentedToggle.mm
    ui/TMLSettingsRow.mm
    ui/TMLBackButton.mm
    ui/TMLOverlayButton.mm
    ui/TMLOverlayManager.mm
    ui/TMLOverlayPanel.mm
    ui/TMLInGamePanel.mm
    ui/TMLOverlayWindow.mm
    ui/TMLOverlayViewController.mm
)

target_link_libraries(tml_ios_bootstrap PRIVATE
    tml_core
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreGraphics"
    "-framework QuartzCore"
)

# ENABLE_ARC im Toolchain-File setzt nur das Xcode-Build-Attribut; unter dem
# hier verwendeten Makefiles-Generator muss ARC explizit erzwungen werden.
target_compile_options(tml_ios_bootstrap PRIVATE -fobjc-arc)
