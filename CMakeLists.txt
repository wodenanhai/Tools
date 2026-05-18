cmake_minimum_required(VERSION 3.16)

project(Tools VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appTools
    main.cpp
    src/services/PdfSplitService.cpp
    src/services/PdfSplitService.h
)

qt_add_qml_module(appTools
    URI Tools
    QML_FILES
        qml/pages/HomePage.qml
        Main.qml
        qml/pages/PdfMergePage.qml
        qml/pages/PdfCompressPage.qml
        qml/pages/PdfDeletePagesPage.qml
        qml/pages/PdfRotatePage.qml
        qml/pages/PdfReorderPage.qml
        qml/pages/PdfSplitPage.qml
        qml/pages/PdfToImagePage.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appTools PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appTools
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appTools
    PRIVATE Qt6::Quick
            Qt6::QuickControls2
)

install(TARGETS appTools
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
