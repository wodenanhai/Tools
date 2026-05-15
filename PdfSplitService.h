#pragma once

#include <QObject>

class PdfSplitService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit PdfSplitService(QObject *parent = nullptr);

    Q_INVOKABLE bool splitByPageRange(const QString &inputPdf,
                                      const QString &outputPdf,
                                      int startPage,
                                      int endPage);

    Q_INVOKABLE bool splitByPageExpression(const QString &inputPdf,
                                           const QString &outputPdf,
                                           const QString &pageExpression);

    Q_INVOKABLE bool splitEveryNPages(const QString &inputPdf,
                                      const QString &outputDir,
                                      int pagesPerFile);

    Q_INVOKABLE bool openFolder(const QString &folderPath);

    QString lastError() const;

signals:
    void lastErrorChanged();

private:
    QString resolveQpdfProgram() const;
    bool ensureQpdfExists(QString &errorMessage) const;
    bool runQpdfCommand(const QStringList &arguments, QString &errorMessage) const;
    void setLastError(const QString &error);

private:
    QString m_lastError;
};
