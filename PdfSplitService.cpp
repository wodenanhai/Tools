#include "PdfSplitService.h"

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QDesktopServices>
#include <QUrl>

PdfSplitService::PdfSplitService(QObject *parent)
    : QObject(parent)
{
}

QString PdfSplitService::lastError() const
{
    return m_lastError;
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

bool PdfSplitService::runQpdfCommand(const QStringList &arguments, QString &errorMessage) const
{
    const QString program = resolveQpdfProgram();
    if (program.isEmpty()) {
        errorMessage = "未检测到 qpdf。请先安装：brew install qpdf";
        return false;
    }

    QProcess process;
    process.start(program, arguments);

    if (!process.waitForStarted(5000)) {
        errorMessage = "无法启动 qpdf 进程：" + program;
        return false;
    }

    if (!process.waitForFinished(120000)) {
        process.kill();
        errorMessage = "qpdf 执行超时";
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromLocal8Bit(process.readAllStandardError()).trimmed();
        errorMessage = stderrText.isEmpty() ? "qpdf 执行失败" : stderrText;
        return false;
    }

    return true;
}
