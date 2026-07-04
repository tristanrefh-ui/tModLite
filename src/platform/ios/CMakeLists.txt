add_library(tml_ios_bootstrap SHARED
    Bootstrap.mm
    Il2CppBridge.mm
    ui/TMLTheme.mm
    ui/TMLOverlayButton.mm
    ui/TMLOverlayManager.mm
    ui/TMLOverlayPanel.mm
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
