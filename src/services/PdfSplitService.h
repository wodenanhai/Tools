#pragma once

#include <QObject>
#include <QStringList>

class PdfSplitService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool convertingImages READ convertingImages NOTIFY convertingImagesChanged)
    Q_PROPERTY(int convertProgress READ convertProgress NOTIFY convertProgressChanged)
    Q_PROPERTY(bool splittingPdf READ splittingPdf NOTIFY splittingPdfChanged)
    Q_PROPERTY(int splitProgress READ splitProgress NOTIFY splitProgressChanged)
    Q_PROPERTY(bool compressingPdf READ compressingPdf NOTIFY compressingPdfChanged)
    Q_PROPERTY(int compressProgress READ compressProgress NOTIFY compressProgressChanged)

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
    Q_INVOKABLE bool mergePdfs(const QStringList &inputPdfs,
                               const QString &outputPdf);
    Q_INVOKABLE bool compressPdf(const QString &inputPdf,
                                 const QString &outputPdf,
                                 const QString &quality);
    Q_INVOKABLE bool startCompressPdf(const QString &inputPdf,
                                      const QString &outputPdf,
                                      const QString &quality);
    Q_INVOKABLE bool startSplitEveryNPages(const QString &inputPdf,
                                           const QString &outputDir,
                                           int pagesPerFile);
    Q_INVOKABLE bool startSplitByPageExpression(const QString &inputPdf,
                                                const QString &outputDir,
                                                const QString &pageExpression);

    Q_INVOKABLE bool convertPdfToImages(const QString &inputPdf,
                                        const QString &outputDir,
                                        const QString &imageFormat,
                                        int dpi);
    Q_INVOKABLE bool startConvertPdfToImages(const QString &inputPdf,
                                             const QString &outputDir,
                                             const QString &imageFormat,
                                             int dpi);

    Q_INVOKABLE bool openFolder(const QString &folderPath);

    QString lastError() const;
    bool convertingImages() const;
    int convertProgress() const;
    bool splittingPdf() const;
    int splitProgress() const;
    bool compressingPdf() const;
    int compressProgress() const;

signals:
    void lastErrorChanged();
    void convertingImagesChanged();
    void convertProgressChanged();
    void convertCompleted(bool success, const QString &message, const QString &outputDir);
    void splittingPdfChanged();
    void splitProgressChanged();
    void splitCompleted(bool success, const QString &message, const QString &outputPath);
    void compressingPdfChanged();
    void compressProgressChanged();
    void compressCompleted(bool success, const QString &message, const QString &outputPdf);

private:
    QString resolveQpdfProgram() const;
    QString resolvePdftoppmProgram() const;
    QString resolveGhostscriptProgram() const;
    bool ensureQpdfExists(QString &errorMessage) const;
    bool ensurePdftoppmExists(QString &errorMessage) const;
    bool ensureGhostscriptExists(QString &errorMessage) const;
    bool runQpdfCommand(const QStringList &arguments, QString &errorMessage) const;
    bool runProcessCommand(const QString &program,
                           const QStringList &arguments,
                           QString &errorMessage,
                           int timeoutMs = 120000) const;
    void setLastError(const QString &error);
    void setConvertingImages(bool converting);
    void setConvertProgress(int progress);
    void setSplittingPdf(bool splitting);
    void setSplitProgress(int progress);
    void setCompressingPdf(bool compressing);
    void setCompressProgress(int progress);

private:
    QString m_lastError;
    bool m_convertingImages = false;
    int m_convertProgress = 0;
    class QProcess *m_convertProcess = nullptr;
    class QTimer *m_convertProgressTimer = nullptr;
    QString m_convertOutputDir;

    bool m_splittingPdf = false;
    int m_splitProgress = 0;
    class QProcess *m_splitProcess = nullptr;
    class QTimer *m_splitProgressTimer = nullptr;
    QString m_splitOutputPath;

    bool m_compressingPdf = false;
    int m_compressProgress = 0;
    class QProcess *m_compressProcess = nullptr;
    class QTimer *m_compressProgressTimer = nullptr;
    QString m_compressOutputPdf;
};
