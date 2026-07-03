add_library(tml_ios_bootstrap SHARED
    Bootstrap.mm
)

target_link_libraries(tml_ios_bootstrap PRIVATE
    tml_core
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreGraphics"
)
