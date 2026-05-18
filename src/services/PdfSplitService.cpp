#include "PdfSplitService.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QDesktopServices>
#include <QTimer>
#include <QUrl>
#include <algorithm>

PdfSplitService::PdfSplitService(QObject *parent)
    : QObject(parent)
{
}

QString PdfSplitService::lastError() const
{
    return m_lastError;
}

bool PdfSplitService::convertingImages() const
{
    return m_convertingImages;
}

int PdfSplitService::convertProgress() const
{
    return m_convertProgress;
}

bool PdfSplitService::splittingPdf() const
{
    return m_splittingPdf;
}

int PdfSplitService::splitProgress() const
{
    return m_splitProgress;
}

bool PdfSplitService::compressingPdf() const
{
    return m_compressingPdf;
}

int PdfSplitService::compressProgress() const
{
    return m_compressProgress;
}

bool PdfSplitService::mergingPdf() const
{
    return m_mergingPdf;
}

int PdfSplitService::mergeProgress() const
{
    return m_mergeProgress;
}

void PdfSplitService::setConvertingImages(bool converting)
{
    if (m_convertingImages == converting) {
        return;
    }
    m_convertingImages = converting;
    emit convertingImagesChanged();
}

void PdfSplitService::setConvertProgress(int progress)
{
    progress = qBound(0, progress, 100);
    if (m_convertProgress == progress) {
        return;
    }
    m_convertProgress = progress;
    emit convertProgressChanged();
}

void PdfSplitService::setSplittingPdf(bool splitting)
{
    if (m_splittingPdf == splitting) {
        return;
    }
    m_splittingPdf = splitting;
    emit splittingPdfChanged();
}

void PdfSplitService::setSplitProgress(int progress)
{
    progress = qBound(0, progress, 100);
    if (m_splitProgress == progress) {
        return;
    }
    m_splitProgress = progress;
    emit splitProgressChanged();
}

void PdfSplitService::setCompressingPdf(bool compressing)
{
    if (m_compressingPdf == compressing) {
        return;
    }
    m_compressingPdf = compressing;
    emit compressingPdfChanged();
}

void PdfSplitService::setCompressProgress(int progress)
{
    progress = qBound(0, progress, 100);
    if (m_compressProgress == progress) {
        return;
    }
    m_compressProgress = progress;
    emit compressProgressChanged();
}

void PdfSplitService::setMergingPdf(bool merging)
{
    if (m_mergingPdf == merging) {
        return;
    }
    m_mergingPdf = merging;
    emit mergingPdfChanged();
}

void PdfSplitService::setMergeProgress(int progress)
{
    progress = qBound(0, progress, 100);
    if (m_mergeProgress == progress) {
        return;
    }
    m_mergeProgress = progress;
    emit mergeProgressChanged();
}

bool PdfSplitService::openFolder(const QString &folderPath)
{
    if (folderPath.trimmed().isEmpty()) {
        setLastError("输出目录不能为空");
        return false;
    }

    const QFileInfo fi(folderPath);
    const QString absPath = fi.absoluteFilePath();
    if (!fi.exists() || !fi.isDir()) {
        setLastError("输出目录不存在：" + absPath);
        return false;
    }

    const bool ok = QDesktopServices::openUrl(QUrl::fromLocalFile(absPath));
    if (!ok) {
        setLastError("无法打开输出目录：" + absPath);
        return false;
    }

    setLastError(QString());
    return true;
}

QString PdfSplitService::resolveQpdfProgram() const
{
    QString program = QStandardPaths::findExecutable("qpdf");
    if (!program.isEmpty()) {
        return program;
    }

    const QStringList fallbackPaths = {
        "/opt/homebrew/bin/qpdf",   // Apple Silicon Homebrew
        "/usr/local/bin/qpdf"       // Intel Homebrew
    };

    for (const QString &path : fallbackPaths) {
        if (QFileInfo::exists(path)) {
            return path;
        }
    }

    return QString();
}

QString PdfSplitService::resolvePdftoppmProgram() const
{
    QString program = QStandardPaths::findExecutable("pdftoppm");
    if (!program.isEmpty()) {
        return program;
    }

    const QStringList fallbackPaths = {
        "/opt/homebrew/bin/pdftoppm",
        "/usr/local/bin/pdftoppm",
        "/opt/homebrew/opt/poppler/bin/pdftoppm",
        "/usr/local/opt/poppler/bin/pdftoppm"
    };

    for (const QString &path : fallbackPaths) {
        if (QFileInfo::exists(path)) {
            return path;
        }
    }
    return QString();
}

QString PdfSplitService::resolveGhostscriptProgram() const
{
    QString program = QStandardPaths::findExecutable("gs");
    if (!program.isEmpty()) {
        return program;
    }

    const QStringList fallbackPaths = {
        "/opt/homebrew/bin/gs",
        "/usr/local/bin/gs"
    };

    for (const QString &path : fallbackPaths) {
        if (QFileInfo::exists(path)) {
            return path;
        }
    }
    return QString();
}

void PdfSplitService::setLastError(const QString &error)
{
    if (m_lastError == error) {
        return;
    }
    m_lastError = error;
    emit lastErrorChanged();
}

bool PdfSplitService::splitByPageRange(const QString &inputPdf,
                                       const QString &outputPdf,
                                       int startPage,
                                       int endPage)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.isEmpty() || outputPdf.isEmpty()) {
        errorMessage = "输入或输出路径不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (startPage <= 0 || endPage <= 0 || startPage > endPage) {
        errorMessage = "页码范围无效";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    const QString range = QString::number(startPage) + "-" + QString::number(endPage);
    const QStringList arguments = {
        "--empty",
        "--pages", inputPdf, range,
        "--", outputPdf
    };

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::splitByPageExpression(const QString &inputPdf,
                                            const QString &outputPdf,
                                            const QString &pageExpression)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.isEmpty() || outputPdf.isEmpty()) {
        errorMessage = "输入或输出路径不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }

    const QString expr = pageExpression.trimmed();
    if (expr.isEmpty()) {
        errorMessage = "页码表达式不能为空";
        setLastError(errorMessage);
        return false;
    }

    // 支持格式：1-3,5,8-10
    static const QRegularExpression validExpr(R"(^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$)");
    if (!validExpr.match(expr).hasMatch()) {
        errorMessage = "页码格式无效，示例：1-3,5";
        setLastError(errorMessage);
        return false;
    }

    const QStringList parts = expr.split(',', Qt::SkipEmptyParts);
    for (const QString &rawPart : parts) {
        const QString part = rawPart.trimmed();
        if (part.contains('-')) {
            const QStringList seg = part.split('-', Qt::SkipEmptyParts);
            if (seg.size() != 2) {
                errorMessage = "页码区间格式无效";
                setLastError(errorMessage);
                return false;
            }
            bool ok1 = false;
            bool ok2 = false;
            const int s = seg[0].toInt(&ok1);
            const int e = seg[1].toInt(&ok2);
            if (!ok1 || !ok2 || s <= 0 || e <= 0 || s > e) {
                errorMessage = "页码区间无效（起始页不能大于结束页）";
                setLastError(errorMessage);
                return false;
            }
        } else {
            bool ok = false;
            const int p = part.toInt(&ok);
            if (!ok || p <= 0) {
                errorMessage = "页码必须为正整数";
                setLastError(errorMessage);
                return false;
            }
        }
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QStringList arguments;
    // qpdf 的 --pages 语法中，同一输入文件的页码列表应作为一个 page-range 参数传入，
    // 例如: "1-3,5"。若拆成 "1-3" "5"，第二段会被当成下一个输入文件路径。
    arguments << "--empty" << "--pages" << inputPdf << expr;
    arguments << "--" << outputPdf;

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::deletePagesByExpression(const QString &inputPdf,
                                              const QString &outputPdf,
                                              const QString &deleteExpression)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入或输出路径不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }

    const QString expr = deleteExpression.trimmed();
    if (expr.isEmpty()) {
        errorMessage = "删除页码不能为空";
        setLastError(errorMessage);
        return false;
    }

    static const QRegularExpression validExpr(R"(^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$)");
    if (!validExpr.match(expr).hasMatch()) {
        errorMessage = "页码格式无效，示例：1,2,3 或 1-3";
        setLastError(errorMessage);
        return false;
    }

    // 读取总页数
    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }
    const QString qpdfProgram = resolveQpdfProgram();
    QProcess pageCountProc;
    pageCountProc.start(qpdfProgram, {"--show-npages", inputPdf});
    if (!pageCountProc.waitForStarted(3000) || !pageCountProc.waitForFinished(5000)
        || pageCountProc.exitStatus() != QProcess::NormalExit || pageCountProc.exitCode() != 0) {
        errorMessage = "无法读取PDF总页数";
        setLastError(errorMessage);
        return false;
    }

    bool okPages = false;
    const int totalPages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
    if (!okPages || totalPages <= 0) {
        errorMessage = "PDF总页数无效";
        setLastError(errorMessage);
        return false;
    }

    QVector<bool> removeFlags(totalPages + 1, false);
    const QStringList parts = expr.split(',', Qt::SkipEmptyParts);
    for (const QString &rawPart : parts) {
        const QString part = rawPart.trimmed();
        if (part.contains('-')) {
            const QStringList seg = part.split('-', Qt::SkipEmptyParts);
            if (seg.size() != 2) {
                errorMessage = "页码区间格式无效";
                setLastError(errorMessage);
                return false;
            }
            bool ok1 = false;
            bool ok2 = false;
            const int s = seg[0].toInt(&ok1);
            const int e = seg[1].toInt(&ok2);
            if (!ok1 || !ok2 || s <= 0 || e <= 0 || s > e || e > totalPages) {
                errorMessage = "删除页码超出范围";
                setLastError(errorMessage);
                return false;
            }
            for (int p = s; p <= e; ++p) {
                removeFlags[p] = true;
            }
        } else {
            bool ok = false;
            const int p = part.toInt(&ok);
            if (!ok || p <= 0 || p > totalPages) {
                errorMessage = "删除页码超出范围";
                setLastError(errorMessage);
                return false;
            }
            removeFlags[p] = true;
        }
    }

    QStringList keepRanges;
    int i = 1;
    while (i <= totalPages) {
        while (i <= totalPages && removeFlags[i]) ++i;
        if (i > totalPages) break;
        const int start = i;
        while (i <= totalPages && !removeFlags[i]) ++i;
        const int end = i - 1;
        if (start == end) {
            keepRanges << QString::number(start);
        } else {
            keepRanges << (QString::number(start) + "-" + QString::number(end));
        }
    }

    if (keepRanges.isEmpty()) {
        errorMessage = "删除后没有剩余页面";
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QStringList arguments;
    arguments << "--empty" << "--pages" << inputPdf << keepRanges.join(',') << "--" << outputPdf;

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::rotatePdf(const QString &inputPdf,
                                const QString &outputPdf,
                                int angle)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入或输出路径不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }
    if (angle != 90 && angle != -90 && angle != 180 && angle != -180) {
        errorMessage = "旋转角度仅支持 ±90 或 180";
        setLastError(errorMessage);
        return false;
    }
    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QString rotateArg;
    if (angle == 90) {
        rotateArg = "+90";
    } else if (angle == -90) {
        rotateArg = "-90";
    } else {
        rotateArg = "180";
    }

    QStringList arguments;
    arguments << "--rotate=" + rotateArg + ":1-z" << inputPdf << outputPdf;

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

QString PdfSplitService::generatePdfFirstPagePreview(const QString &inputPdf)
{
    QString errorMessage;
    if (inputPdf.trimmed().isEmpty()) {
        errorMessage = "输入PDF不能为空";
        setLastError(errorMessage);
        return QString();
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return QString();
    }
    if (!ensurePdftoppmExists(errorMessage)) {
        setLastError(errorMessage);
        return QString();
    }

    const QString program = resolvePdftoppmProgram();
    if (program.isEmpty()) {
        setLastError("未检测到 pdftoppm。请先安装：brew install poppler");
        return QString();
    }

    const QFileInfo fi(inputPdf);
    const QString outDirPath = QDir::temp().filePath("pdf_studio_toolbox_preview");
    QDir().mkpath(outDirPath);
    const QString prefix = QDir(outDirPath).filePath(fi.completeBaseName() + "_preview");

    QStringList arguments;
    arguments << "-f" << "1" << "-singlefile" << "-png" << inputPdf << prefix;

    const bool ok = runProcessCommand(program, arguments, errorMessage, 120000);
    if (!ok) {
        setLastError(errorMessage);
        return QString();
    }

    const QString imagePath = prefix + ".png";
    if (!QFileInfo::exists(imagePath)) {
        setLastError("预览图生成失败");
        return QString();
    }

    setLastError(QString());
    return imagePath;
}

QStringList PdfSplitService::generatePdfAllPagePreviews(const QString &inputPdf)
{
    QString errorMessage;
    if (inputPdf.trimmed().isEmpty()) {
        setLastError("输入PDF不能为空");
        return {};
    }
    if (!QFileInfo::exists(inputPdf)) {
        setLastError("输入PDF不存在");
        return {};
    }
    if (!ensurePdftoppmExists(errorMessage)) {
        setLastError(errorMessage);
        return {};
    }

    const QString program = resolvePdftoppmProgram();
    if (program.isEmpty()) {
        setLastError("未检测到 pdftoppm。请先安装：brew install poppler");
        return {};
    }

    const QFileInfo fi(inputPdf);
    const QString outDirPath = QDir::temp().filePath("pdf_studio_toolbox_preview_all");
    QDir outDir(outDirPath);
    if (!outDir.exists()) {
        QDir().mkpath(outDirPath);
    }

    const QString prefixName = fi.completeBaseName() + "_preview_all";
    const QString prefixPath = outDir.filePath(prefixName);

    // 清理旧文件
    const QStringList oldFiles = outDir.entryList({prefixName + "-*.png"}, QDir::Files);
    for (const QString &f : oldFiles) {
        outDir.remove(f);
    }

    QStringList arguments;
    arguments << "-png" << inputPdf << prefixPath;
    if (!runProcessCommand(program, arguments, errorMessage, 300000)) {
        setLastError(errorMessage);
        return {};
    }

    QStringList files = outDir.entryList({prefixName + "-*.png"}, QDir::Files, QDir::Name);
    // 按页码数字排序
    std::sort(files.begin(), files.end(), [](const QString &a, const QString &b) {
        const int pa = a.section('-', -1).section('.', 0, 0).toInt();
        const int pb = b.section('-', -1).section('.', 0, 0).toInt();
        return pa < pb;
    });

    QStringList fullPaths;
    fullPaths.reserve(files.size());
    for (const QString &f : files) {
        fullPaths << outDir.filePath(f);
    }

    if (fullPaths.isEmpty()) {
        setLastError("未生成任何预览页");
        return {};
    }

    setLastError(QString());
    return fullPaths;
}

bool PdfSplitService::rotatePdfByPageAngles(const QString &inputPdf,
                                            const QString &outputPdf,
                                            const QVariantList &pageAngles)
{
    QString errorMessage;
    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        setLastError("输入或输出路径不能为空");
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        setLastError("输入PDF不存在");
        return false;
    }
    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    const QString qpdfProgram = resolveQpdfProgram();
    QProcess pageCountProc;
    pageCountProc.start(qpdfProgram, {"--show-npages", inputPdf});
    if (!pageCountProc.waitForStarted(3000) || !pageCountProc.waitForFinished(5000)
        || pageCountProc.exitStatus() != QProcess::NormalExit || pageCountProc.exitCode() != 0) {
        setLastError("无法读取PDF总页数");
        return false;
    }
    bool okPages = false;
    const int totalPages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
    if (!okPages || totalPages <= 0) {
        setLastError("PDF总页数无效");
        return false;
    }

    if (pageAngles.size() != totalPages) {
        setLastError("页数与旋转设置不一致");
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QStringList arguments;
    for (int i = 0; i < pageAngles.size(); ++i) {
        const int angle = pageAngles[i].toInt();
        int norm = angle % 360;
        if (norm < 0) norm += 360;
        if (norm == 0) continue;

        QString rotateArg;
        if (norm == 90) rotateArg = "+90";
        else if (norm == 180) rotateArg = "180";
        else if (norm == 270) rotateArg = "-90";
        else {
            setLastError("存在非法旋转角度，仅支持90度步进");
            return false;
        }

        arguments << "--rotate=" + rotateArg + ":" + QString::number(i + 1);
    }

    arguments << inputPdf << outputPdf;
    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::reorderPdfPages(const QString &inputPdf,
                                      const QString &outputPdf,
                                      const QVariantList &newOrderPages)
{
    QString errorMessage;
    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        setLastError("输入或输出路径不能为空");
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        setLastError("输入PDF不存在");
        return false;
    }
    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    const QString qpdfProgram = resolveQpdfProgram();
    QProcess pageCountProc;
    pageCountProc.start(qpdfProgram, {"--show-npages", inputPdf});
    if (!pageCountProc.waitForStarted(3000) || !pageCountProc.waitForFinished(5000)
        || pageCountProc.exitStatus() != QProcess::NormalExit || pageCountProc.exitCode() != 0) {
        setLastError("无法读取PDF总页数");
        return false;
    }
    bool okPages = false;
    const int totalPages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
    if (!okPages || totalPages <= 0) {
        setLastError("PDF总页数无效");
        return false;
    }

    if (newOrderPages.size() != totalPages) {
        setLastError("排序页数与PDF页数不一致");
        return false;
    }

    QVector<bool> seen(totalPages + 1, false);
    QStringList ordered;
    ordered.reserve(totalPages);
    for (const QVariant &v : newOrderPages) {
        bool ok = false;
        const int p = v.toInt(&ok);
        if (!ok || p <= 0 || p > totalPages || seen[p]) {
            setLastError("排序数据无效（超范围或重复）");
            return false;
        }
        seen[p] = true;
        ordered << QString::number(p);
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());
    QStringList args;
    args << "--empty" << "--pages" << inputPdf << ordered.join(',') << "--" << outputPdf;

    const bool ok = runQpdfCommand(args, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::splitEveryNPages(const QString &inputPdf,
                                       const QString &outputDir,
                                       int pagesPerFile)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.isEmpty() || outputDir.isEmpty()) {
        errorMessage = "输入文件或输出目录不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (pagesPerFile <= 0) {
        errorMessage = "每个文件页数必须大于0";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir dir(outputDir);
    if (!dir.exists() && !QDir().mkpath(outputDir)) {
        errorMessage = "无法创建输出目录";
        setLastError(errorMessage);
        return false;
    }

    const QFileInfo inputInfo(inputPdf);
    const QString baseName = inputInfo.completeBaseName();
    const QString outputPattern = dir.filePath(baseName + "_%d.pdf");

    const QStringList arguments = {
        "--split-pages=" + QString::number(pagesPerFile),
        inputPdf,
        outputPattern
    };

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::mergePdfs(const QStringList &inputPdfs,
                                const QString &outputPdf)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdfs.isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入PDF列表或输出文件不能为空";
        setLastError(errorMessage);
        return false;
    }

    QStringList validFiles;
    validFiles.reserve(inputPdfs.size());
    for (const QString &file : inputPdfs) {
        const QString f = file.trimmed();
        if (f.isEmpty()) {
            continue;
        }
        if (!QFileInfo::exists(f)) {
            errorMessage = "输入PDF不存在：" + f;
            setLastError(errorMessage);
            return false;
        }
        validFiles << f;
    }

    if (validFiles.size() < 2) {
        errorMessage = "至少需要两个PDF文件进行合并";
        setLastError(errorMessage);
        return false;
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QStringList arguments;
    arguments << "--empty" << "--pages";
    for (const QString &file : validFiles) {
        arguments << file;
    }
    arguments << "--" << outputPdf;

    const bool ok = runQpdfCommand(arguments, errorMessage);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::startMergePdfs(const QStringList &inputPdfs,
                                     const QString &outputPdf)
{
    if (m_mergingPdf) {
        setLastError("已有合并任务正在执行");
        return false;
    }

    QString errorMessage;
    if (inputPdfs.isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入PDF列表或输出文件不能为空";
        setLastError(errorMessage);
        emit mergeCompleted(false, errorMessage, outputPdf);
        return false;
    }

    QStringList validFiles;
    validFiles.reserve(inputPdfs.size());
    m_mergeTotalInputBytes = 0;
    for (const QString &file : inputPdfs) {
        const QString f = file.trimmed();
        if (f.isEmpty()) continue;
        const QFileInfo fi(f);
        if (!fi.exists()) {
            errorMessage = "输入PDF不存在：" + f;
            setLastError(errorMessage);
            emit mergeCompleted(false, errorMessage, outputPdf);
            return false;
        }
        validFiles << f;
        m_mergeTotalInputBytes += fi.size();
    }

    if (validFiles.size() < 2) {
        errorMessage = "至少需要两个PDF文件进行合并";
        setLastError(errorMessage);
        emit mergeCompleted(false, errorMessage, outputPdf);
        return false;
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        emit mergeCompleted(false, errorMessage, outputPdf);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());
    if (QFileInfo::exists(outputPdf)) {
        QFile::remove(outputPdf);
    }

    QStringList args;
    args << "--empty" << "--pages";
    for (const QString &f : validFiles) args << f;
    args << "--" << outputPdf;

    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        setLastError(errorMessage);
        emit mergeCompleted(false, errorMessage, outputPdf);
        return false;
    }

    m_mergeOutputPdf = outputPdf;
    if (m_mergeProcess) {
        m_mergeProcess->deleteLater();
        m_mergeProcess = nullptr;
    }
    m_mergeProcess = new QProcess(this);

    if (!m_mergeProgressTimer) {
        m_mergeProgressTimer = new QTimer(this);
        m_mergeProgressTimer->setInterval(500);
        connect(m_mergeProgressTimer, &QTimer::timeout, this, [this]() {
            if (!m_mergingPdf) return;
            if (m_mergeTotalInputBytes <= 0) return;
            const QFileInfo outFi(m_mergeOutputPdf);
            const qint64 outSize = outFi.exists() ? outFi.size() : 0;
            int p = static_cast<int>((outSize * 100) / m_mergeTotalInputBytes);
            p = qBound(1, p, 99);
            if (p > m_mergeProgress) {
                setMergeProgress(p);
            }
        });
    }

    connect(m_mergeProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
                if (m_mergeProgressTimer) m_mergeProgressTimer->stop();

                QString msg;
                bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (ok) {
                    setMergeProgress(100);
                    msg = "合并完成";
                    setLastError(QString());
                } else {
                    const QString stderrText = QString::fromLocal8Bit(m_mergeProcess->readAllStandardError()).trimmed();
                    msg = stderrText.isEmpty() ? "合并失败" : stderrText;
                    setLastError(msg);
                }
                setMergingPdf(false);
                emit mergeCompleted(ok, msg, m_mergeOutputPdf);
            });

    setMergingPdf(true);
    setMergeProgress(1);
    m_mergeProcess->start(program, args);
    if (!m_mergeProcess->waitForStarted(5000)) {
        setMergingPdf(false);
        setMergeProgress(0);
        errorMessage = "无法启动 qpdf 进程：" + program;
        setLastError(errorMessage);
        emit mergeCompleted(false, errorMessage, outputPdf);
        return false;
    }

    m_mergeProgressTimer->start();
    return true;
}

bool PdfSplitService::compressPdf(const QString &inputPdf,
                                 const QString &outputPdf,
                                 const QString &quality)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入PDF或输出文件不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }

    QString gsQuality = quality.trimmed();
    if (gsQuality.isEmpty()) gsQuality = "/ebook";
    if (gsQuality != "/screen" && gsQuality != "/ebook" && gsQuality != "/printer" && gsQuality != "/prepress") {
        errorMessage = "压缩质量仅支持 /screen /ebook /printer /prepress";
        setLastError(errorMessage);
        return false;
    }

    if (!ensureGhostscriptExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    // 避免目标文件已存在时某些环境下进入覆盖等待，导致看起来“卡住”
    if (QFileInfo::exists(outputPdf) && !QFile::remove(outputPdf)) {
        errorMessage = "无法覆盖已有输出文件：" + outputPdf;
        setLastError(errorMessage);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    const QString program = resolveGhostscriptProgram();
    QStringList args;
    args << "-sDEVICE=pdfwrite"
         << "-dCompatibilityLevel=1.4"
         << "-dPDFSETTINGS=" + gsQuality
         << "-dNOPAUSE"
         << "-dBATCH"
         << "-sOutputFile=" + outputPdf
         << inputPdf;

    const bool ok = runProcessCommand(program, args, errorMessage, 1800000);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::startCompressPdf(const QString &inputPdf,
                                      const QString &outputPdf,
                                      const QString &quality)
{
    if (m_compressingPdf) {
        setLastError("已有压缩任务正在执行");
        return false;
    }

    QString errorMessage;
    if (inputPdf.trimmed().isEmpty() || outputPdf.trimmed().isEmpty()) {
        errorMessage = "输入PDF或输出文件不能为空";
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    QString gsQuality = quality.trimmed();
    if (gsQuality.isEmpty()) gsQuality = "/ebook";
    if (gsQuality != "/screen" && gsQuality != "/ebook" && gsQuality != "/printer" && gsQuality != "/prepress") {
        errorMessage = "压缩质量仅支持 /screen /ebook /printer /prepress";
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    if (!ensureGhostscriptExists(errorMessage)) {
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    // 避免目标文件已存在时某些环境下进入覆盖等待，导致进度卡在 90%+
    if (QFileInfo::exists(outputPdf) && !QFile::remove(outputPdf)) {
        errorMessage = "无法覆盖已有输出文件：" + outputPdf;
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    const QString program = resolveGhostscriptProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 Ghostscript。请先安装：brew install ghostscript";
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    QStringList args;
    args << "-sDEVICE=pdfwrite"
         << "-dCompatibilityLevel=1.4"
         << "-dPDFSETTINGS=" + gsQuality
         << "-dNOPAUSE"
         << "-dBATCH"
         << "-sOutputFile=" + outputPdf
         << inputPdf;

    // 真实进度基于“已处理页数/总页数”计算：先读取总页数
    m_compressTotalPages = 0;
    {
        const QString qpdfProgram = resolveQpdfProgram();
        if (!qpdfProgram.isEmpty()) {
            QProcess pageCountProc;
            pageCountProc.start(qpdfProgram, {"--show-npages", inputPdf});
            if (pageCountProc.waitForStarted(3000) && pageCountProc.waitForFinished(5000)
                && pageCountProc.exitStatus() == QProcess::NormalExit && pageCountProc.exitCode() == 0) {
                bool okPages = false;
                const int pages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
                if (okPages && pages > 0) {
                    m_compressTotalPages = pages;
                }
            }
        }
    }

    m_compressOutputPdf = outputPdf;
    if (m_compressProcess) {
        m_compressProcess->deleteLater();
        m_compressProcess = nullptr;
    }
    m_compressProcess = new QProcess(this);

    // 大文件压缩耗时长，设置保底超时，避免无限等待
    QTimer *compressTimeoutTimer = new QTimer(m_compressProcess);
    compressTimeoutTimer->setSingleShot(true);
    compressTimeoutTimer->setInterval(1800000); // 30 分钟
    connect(compressTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (m_compressProcess && m_compressProcess->state() != QProcess::NotRunning) {
            m_compressProcess->kill();
            setCompressingPdf(false);
            setLastError("压缩超时（30分钟），已终止进程");
            emit compressCompleted(false, m_lastError, m_compressOutputPdf);
        }
    });

    if (!m_compressProgressTimer) {
        m_compressProgressTimer = new QTimer(this);
        m_compressProgressTimer->setInterval(1000);
        // 仅保活 UI，不再进行伪进度推进
        connect(m_compressProgressTimer, &QTimer::timeout, this, [this]() {
            if (!m_compressingPdf) return;
            if (m_compressProgress <= 0) setCompressProgress(1);
        });
    }

    connect(m_compressProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
                if (m_compressProgressTimer) m_compressProgressTimer->stop();

                QString msg;
                bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (ok) {
                    setCompressProgress(100);
                    msg = "压缩完成";
                    setLastError(QString());
                } else {
                    const QString stderrText = QString::fromLocal8Bit(m_compressProcess->readAllStandardError()).trimmed();
                    msg = stderrText.isEmpty() ? "压缩失败" : stderrText;
                    setLastError(msg);
                }
                setCompressingPdf(false);
                emit compressCompleted(ok, msg, m_compressOutputPdf);
            });

    connect(m_compressProcess, &QProcess::readyReadStandardError, this, [this]() {
        if (!m_compressingPdf || m_compressTotalPages <= 0) {
            return;
        }
        // Ghostscript 常见输出包含："Page N"
        const QString stderrText = QString::fromLocal8Bit(m_compressProcess->readAllStandardError());
        static const QRegularExpression pageRe(R"(Page\s+(\d+))");
        QRegularExpressionMatchIterator it = pageRe.globalMatch(stderrText);
        int latestPage = -1;
        while (it.hasNext()) {
            const QRegularExpressionMatch m = it.next();
            latestPage = m.captured(1).toInt();
        }
        if (latestPage > 0) {
            const int p = qBound(1, (latestPage * 100) / m_compressTotalPages, 99);
            if (p > m_compressProgress) {
                setCompressProgress(p);
            }
        }
    });

    connect(m_compressProcess, &QProcess::readyReadStandardOutput, this, [this]() {
        if (!m_compressingPdf || m_compressTotalPages <= 0) {
            return;
        }
        const QString stdoutText = QString::fromLocal8Bit(m_compressProcess->readAllStandardOutput());
        static const QRegularExpression pageRe(R"(Page\s+(\d+))");
        QRegularExpressionMatchIterator it = pageRe.globalMatch(stdoutText);
        int latestPage = -1;
        while (it.hasNext()) {
            const QRegularExpressionMatch m = it.next();
            latestPage = m.captured(1).toInt();
        }
        if (latestPage > 0) {
            const int p = qBound(1, (latestPage * 100) / m_compressTotalPages, 99);
            if (p > m_compressProgress) {
                setCompressProgress(p);
            }
        }
    });

    setCompressingPdf(true);
    setCompressProgress(1);
    m_compressProcess->start(program, args);
    if (!m_compressProcess->waitForStarted(5000)) {
        compressTimeoutTimer->stop();
        setCompressingPdf(false);
        setCompressProgress(0);
        errorMessage = "无法启动 Ghostscript 进程：" + program;
        setLastError(errorMessage);
        emit compressCompleted(false, errorMessage, outputPdf);
        return false;
    }

    m_compressProgressTimer->start();
    compressTimeoutTimer->start();
    return true;
}

bool PdfSplitService::cancelCompressPdf()
{
    if (!m_compressingPdf) {
        setLastError("当前没有正在进行的压缩任务");
        return false;
    }

    if (m_compressProcess && m_compressProcess->state() != QProcess::NotRunning) {
        m_compressProcess->kill();
    }

    if (m_compressProgressTimer) {
        m_compressProgressTimer->stop();
    }

    setCompressingPdf(false);
    setLastError("压缩已手动中断");
    emit compressCompleted(false, m_lastError, m_compressOutputPdf);
    return true;
}

bool PdfSplitService::startSplitEveryNPages(const QString &inputPdf,
                                            const QString &outputDir,
                                            int pagesPerFile)
{
    if (m_splittingPdf) {
        setLastError("已有拆分任务正在执行");
        return false;
    }

    QString errorMessage;
    if (inputPdf.trimmed().isEmpty() || outputDir.trimmed().isEmpty()) {
        errorMessage = "输入文件或输出目录不能为空";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (pagesPerFile <= 0) {
        errorMessage = "每个文件页数必须大于0";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    QDir dir(outputDir);
    if (!dir.exists() && !QDir().mkpath(outputDir)) {
        errorMessage = "无法创建输出目录";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    const QFileInfo inputInfo(inputPdf);
    m_splitInputBytes = inputInfo.size();
    m_splitSingleOutputFile.clear();
    const QString baseName = inputInfo.completeBaseName();
    const QString outputPattern = dir.filePath(baseName + "_%d.pdf");
    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    int totalPages = 0;
    {
        QProcess pageCountProc;
        pageCountProc.start(program, {"--show-npages", inputPdf});
        if (pageCountProc.waitForStarted(3000) && pageCountProc.waitForFinished(5000)
            && pageCountProc.exitStatus() == QProcess::NormalExit && pageCountProc.exitCode() == 0) {
            bool okPages = false;
            totalPages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
            if (!okPages || totalPages < 0) totalPages = 0;
        }
    }
    m_splitExpectedFiles = (totalPages > 0) ? ((totalPages + pagesPerFile - 1) / pagesPerFile) : 0;
    m_splitOutputPatternPrefix = baseName + "_";

    QStringList args;
    args << "--split-pages=" + QString::number(pagesPerFile) << inputPdf << outputPattern;

    m_splitOutputPath = outputDir;
    if (m_splitProcess) {
        m_splitProcess->deleteLater();
        m_splitProcess = nullptr;
    }
    m_splitProcess = new QProcess(this);

    if (!m_splitProgressTimer) {
        m_splitProgressTimer = new QTimer(this);
        m_splitProgressTimer->setInterval(500);
        connect(m_splitProgressTimer, &QTimer::timeout, this, [this]() {
            if (!m_splittingPdf) return;
            if (m_splitExpectedFiles <= 0 || m_splitOutputPath.isEmpty() || m_splitOutputPatternPrefix.isEmpty()) {
                return;
            }
            QDir outDir(m_splitOutputPath);
            const QStringList files = outDir.entryList({m_splitOutputPatternPrefix + "*.pdf"}, QDir::Files);
            const int done = files.size();
            int p = (done * 100) / m_splitExpectedFiles;
            p = qBound(1, p, 99);
            if (p > m_splitProgress) {
                setSplitProgress(p);
            }
        });
    }

    connect(m_splitProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
                if (m_splitProgressTimer) m_splitProgressTimer->stop();

                QString msg;
                bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (ok) {
                    setSplitProgress(100);
                    msg = "拆分完成";
                    setLastError(QString());
                } else {
                    const QString stderrText = QString::fromLocal8Bit(m_splitProcess->readAllStandardError()).trimmed();
                    msg = stderrText.isEmpty() ? "拆分失败" : stderrText;
                    setLastError(msg);
                }
                setSplittingPdf(false);
                emit splitCompleted(ok, msg, m_splitOutputPath);
            });

    setSplittingPdf(true);
    setSplitProgress(1);
    m_splitProcess->start(program, args);
    if (!m_splitProcess->waitForStarted(5000)) {
        setSplittingPdf(false);
        setSplitProgress(0);
        errorMessage = "无法启动 qpdf 进程：" + program;
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    m_splitProgressTimer->start();
    return true;
}

bool PdfSplitService::startSplitByPageExpression(const QString &inputPdf,
                                                 const QString &outputDir,
                                                 const QString &pageExpression)
{
    if (m_splittingPdf) {
        setLastError("已有拆分任务正在执行");
        return false;
    }

    QString outputPdf = QDir(outputDir).filePath("selected_pages.pdf");
    m_splitInputBytes = QFileInfo(inputPdf).size();
    m_splitSingleOutputFile = outputPdf;
    QString errorMessage;

    if (inputPdf.trimmed().isEmpty() || outputDir.trimmed().isEmpty()) {
        errorMessage = "输入或输出路径不能为空";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    const QString expr = pageExpression.trimmed();
    static const QRegularExpression validExpr(R"(^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$)");
    if (expr.isEmpty() || !validExpr.match(expr).hasMatch()) {
        errorMessage = "页码格式无效，示例：1-3,5";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    if (!ensureQpdfExists(errorMessage)) {
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    QDir().mkpath(QFileInfo(outputPdf).absolutePath());

    QStringList args;
    args << "--empty" << "--pages" << inputPdf << expr << "--" << outputPdf;
    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    m_splitOutputPath = outputDir;
    if (m_splitProcess) {
        m_splitProcess->deleteLater();
        m_splitProcess = nullptr;
    }
    m_splitProcess = new QProcess(this);

    if (!m_splitProgressTimer) {
        m_splitProgressTimer = new QTimer(this);
        m_splitProgressTimer->setInterval(500);
        connect(m_splitProgressTimer, &QTimer::timeout, this, [this]() {
            if (!m_splittingPdf) return;
            if (m_splitSingleOutputFile.isEmpty() || m_splitInputBytes <= 0) return;
            const QString outFile = m_splitSingleOutputFile;
            const QFileInfo outFi(outFile);
            if (!outFi.exists()) return;
            const qint64 outSize = outFi.size();
            if (outSize <= 0) return;
            int p = static_cast<int>((outSize * 100) / m_splitInputBytes);
            p = qBound(1, p, 99);
            if (p > m_splitProgress) {
                setSplitProgress(p);
            }
        });
    }

    connect(m_splitProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
                if (m_splitProgressTimer) m_splitProgressTimer->stop();

                QString msg;
                bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (ok) {
                    setSplitProgress(100);
                    msg = "拆分完成";
                    setLastError(QString());
                } else {
                    const QString stderrText = QString::fromLocal8Bit(m_splitProcess->readAllStandardError()).trimmed();
                    msg = stderrText.isEmpty() ? "拆分失败" : stderrText;
                    setLastError(msg);
                }
                setSplittingPdf(false);
                emit splitCompleted(ok, msg, m_splitOutputPath);
            });

    setSplittingPdf(true);
    setSplitProgress(1);
    m_splitProcess->start(program, args);
    if (!m_splitProcess->waitForStarted(5000)) {
        setSplittingPdf(false);
        setSplitProgress(0);
        errorMessage = "无法启动 qpdf 进程：" + program;
        setLastError(errorMessage);
        emit splitCompleted(false, errorMessage, outputDir);
        return false;
    }

    m_splitProgressTimer->start();
    return true;
}

bool PdfSplitService::convertPdfToImages(const QString &inputPdf,
                                         const QString &outputDir,
                                         const QString &imageFormat,
                                         int dpi)
{
    QString errorMessage;
    errorMessage.clear();

    if (inputPdf.trimmed().isEmpty() || outputDir.trimmed().isEmpty()) {
        errorMessage = "输入PDF或输出目录不能为空";
        setLastError(errorMessage);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        return false;
    }
    if (dpi < 36 || dpi > 1200) {
        errorMessage = "DPI 范围应在 36 到 1200 之间";
        setLastError(errorMessage);
        return false;
    }

    QString format = imageFormat.trimmed().toLower();
    if (format.isEmpty()) {
        format = "png";
    }
    if (format != "png" && format != "jpg" && format != "jpeg" && format != "tiff" && format != "ppm") {
        errorMessage = "仅支持 png/jpg/tiff/ppm";
        setLastError(errorMessage);
        return false;
    }

    if (!ensurePdftoppmExists(errorMessage)) {
        setLastError(errorMessage);
        return false;
    }

    QDir outDir(outputDir);
    if (!outDir.exists() && !QDir().mkpath(outputDir)) {
        errorMessage = "无法创建输出目录";
        setLastError(errorMessage);
        return false;
    }

    const QFileInfo fi(inputPdf);
    const QString prefix = outDir.filePath(fi.completeBaseName() + "_page");
    QStringList arguments;
    arguments << "-r" << QString::number(dpi);
    if (format == "jpg" || format == "jpeg") {
        arguments << "-jpeg";
    } else if (format == "tiff") {
        arguments << "-tiff";
    } else if (format == "ppm") {
        // ppm 为 pdftoppm 默认输出格式，不加额外参数
    } else {
        arguments << "-png";
    }
    arguments << inputPdf << prefix;

    const QString program = resolvePdftoppmProgram();
    const bool ok = runProcessCommand(program, arguments, errorMessage, 300000);
    setLastError(ok ? QString() : errorMessage);
    return ok;
}

bool PdfSplitService::startConvertPdfToImages(const QString &inputPdf,
                                              const QString &outputDir,
                                              const QString &imageFormat,
                                              int dpi)
{
    if (m_convertingImages) {
        setLastError("已有转换任务正在执行");
        return false;
    }

    QString errorMessage;
    if (inputPdf.trimmed().isEmpty() || outputDir.trimmed().isEmpty()) {
        errorMessage = "输入PDF或输出目录不能为空";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (!QFileInfo::exists(inputPdf)) {
        errorMessage = "输入PDF不存在";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (dpi < 36 || dpi > 1200) {
        errorMessage = "DPI 范围应在 36 到 1200 之间";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }

    QString format = imageFormat.trimmed().toLower();
    if (format.isEmpty()) format = "png";
    if (format != "png" && format != "jpg" && format != "jpeg" && format != "tiff" && format != "ppm") {
        errorMessage = "仅支持 png/jpg/tiff/ppm";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }
    if (!ensurePdftoppmExists(errorMessage)) {
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }

    QDir outDir(outputDir);
    if (!outDir.exists() && !QDir().mkpath(outputDir)) {
        errorMessage = "无法创建输出目录";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }

    const QFileInfo fi(inputPdf);
    const QString prefix = outDir.filePath(fi.completeBaseName() + "_page");
    // 清理旧输出，确保“已生成文件数量”可用于真实进度
    {
        const QStringList oldFiles = outDir.entryList({fi.completeBaseName() + "_page-*"}, QDir::Files);
        for (const QString &f : oldFiles) {
            outDir.remove(f);
        }
    }
    m_convertOutputPrefix = fi.completeBaseName() + "_page-";
    m_convertTotalPages = 0;
    {
        const QString qpdfProgram = resolveQpdfProgram();
        if (!qpdfProgram.isEmpty()) {
            QProcess pageCountProc;
            pageCountProc.start(qpdfProgram, {"--show-npages", inputPdf});
            if (pageCountProc.waitForStarted(3000) && pageCountProc.waitForFinished(5000)
                && pageCountProc.exitStatus() == QProcess::NormalExit && pageCountProc.exitCode() == 0) {
                bool okPages = false;
                const int pages = QString::fromLocal8Bit(pageCountProc.readAllStandardOutput()).trimmed().toInt(&okPages);
                if (okPages && pages > 0) {
                    m_convertTotalPages = pages;
                }
            }
        }
    }
    QStringList arguments;
    arguments << "-r" << QString::number(dpi);
    if (format == "jpg" || format == "jpeg") {
        arguments << "-jpeg";
    } else if (format == "tiff") {
        arguments << "-tiff";
    } else if (format == "png") {
        arguments << "-png";
    }
    arguments << inputPdf << prefix;

    const QString program = resolvePdftoppmProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 pdftoppm。请先安装：brew install poppler";
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }

    m_convertOutputDir = outputDir;
    if (m_convertProcess) {
        m_convertProcess->deleteLater();
        m_convertProcess = nullptr;
    }
    m_convertProcess = new QProcess(this);

    if (!m_convertProgressTimer) {
        m_convertProgressTimer = new QTimer(this);
        m_convertProgressTimer->setInterval(500);
        connect(m_convertProgressTimer, &QTimer::timeout, this, [this]() {
            if (!m_convertingImages) return;
            if (m_convertTotalPages <= 0 || m_convertOutputDir.isEmpty() || m_convertOutputPrefix.isEmpty()) {
                return;
            }
            QDir outDir(m_convertOutputDir);
            const QStringList files = outDir.entryList({m_convertOutputPrefix + "*"}, QDir::Files);
            const int done = files.size();
            int p = (done * 100) / m_convertTotalPages;
            p = qBound(1, p, 99);
            if (p > m_convertProgress) {
                setConvertProgress(p);
            }
        });
    }

    connect(m_convertProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
                if (m_convertProgressTimer) m_convertProgressTimer->stop();

                QString msg;
                bool ok = (status == QProcess::NormalExit && exitCode == 0);
                if (ok) {
                    setConvertProgress(100);
                    msg = "转换完成";
                    setLastError(QString());
                } else {
                    const QString stderrText = QString::fromLocal8Bit(m_convertProcess->readAllStandardError()).trimmed();
                    msg = stderrText.isEmpty() ? "转换失败" : stderrText;
                    setLastError(msg);
                }
                setConvertingImages(false);
                emit convertCompleted(ok, msg, m_convertOutputDir);
            });

    setConvertingImages(true);
    setConvertProgress(1);
    m_convertProcess->start(program, arguments);
    if (!m_convertProcess->waitForStarted(5000)) {
        setConvertingImages(false);
        setConvertProgress(0);
        errorMessage = "无法启动 pdftoppm 进程：" + program;
        setLastError(errorMessage);
        emit convertCompleted(false, errorMessage, outputDir);
        return false;
    }
    m_convertProgressTimer->start();
    return true;
}

bool PdfSplitService::ensureQpdfExists(QString &errorMessage) const
{
    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        return false;
    }

    QProcess process;
    process.start(program, {"--version"});
    if (!process.waitForStarted(3000)) {
        errorMessage = "qpdf 可执行文件无法启动：" + program;
        return false;
    }
    if (!process.waitForFinished(5000)) {
        process.kill();
        errorMessage = "qpdf 版本检测超时：" + program;
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromLocal8Bit(process.readAllStandardError()).trimmed();
        errorMessage = stderrText.isEmpty() ? ("qpdf 不可用：" + program) : stderrText;
        return false;
    }
    return true;
}

bool PdfSplitService::ensurePdftoppmExists(QString &errorMessage) const
{
    const QString program = resolvePdftoppmProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 pdftoppm。请先安装：brew install poppler";
        return false;
    }
    return runProcessCommand(program, {"-v"}, errorMessage, 5000);
}

bool PdfSplitService::ensureGhostscriptExists(QString &errorMessage) const
{
    const QString program = resolveGhostscriptProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 Ghostscript。请先安装：brew install ghostscript";
        return false;
    }
    return runProcessCommand(program, {"-version"}, errorMessage, 5000);
}

bool PdfSplitService::runQpdfCommand(const QStringList &arguments, QString &errorMessage) const
{
    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        return false;
    }

    return runProcessCommand(program, arguments, errorMessage, 120000);
}

bool PdfSplitService::runProcessCommand(const QString &program,
                                        const QStringList &arguments,
                                        QString &errorMessage,
                                        int timeoutMs) const
{
    if (program.isEmpty()) {
        errorMessage = "可执行程序路径为空";
        return false;
    }

    QProcess process;
    process.start(program, arguments);

    if (!process.waitForStarted(5000)) {
        errorMessage = "无法启动进程：" + program;
        return false;
    }

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        errorMessage = "进程执行超时：" + program;
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromLocal8Bit(process.readAllStandardError()).trimmed();
        errorMessage = stderrText.isEmpty() ? ("进程执行失败：" + program) : stderrText;
        return false;
    }
    return true;
}
