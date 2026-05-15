#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuickControls2/QQuickStyle>

#include "src/services/PdfSplitService.h"

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Basic");

    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("PDF Studio Toolbox");
    QGuiApplication::setApplicationDisplayName("PDF Studio Toolbox");

    PdfSplitService pdfSplitService;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("pdfSplitService", &pdfSplitService);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Tools", "Main");

    return QGuiApplication::exec();
}
