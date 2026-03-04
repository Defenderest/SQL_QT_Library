#include "password_utils.h"

#include <QCryptographicHash>
#include <QPasswordDigestor>
#include <QRandomGenerator>
#include <QRegularExpression>

namespace {
constexpr int kPasswordIterations = 120000;
constexpr int kSaltLengthBytes = 16;
constexpr int kHashLengthBytes = 32;

QByteArray generateRandomSalt(int length)
{
    QByteArray salt;
    salt.resize(length);
    for (int i = 0; i < length; ++i) {
        salt[i] = static_cast<char>(QRandomGenerator::global()->bounded(0, 256));
    }
    return salt;
}

QByteArray derivePbkdf2Sha256(const QString& password, const QByteArray& salt, int iterations, int keyLength)
{
    return QPasswordDigestor::deriveKeyPbkdf2(QCryptographicHash::Sha256,
                                              password.toUtf8(),
                                              salt,
                                              iterations,
                                              keyLength);
}

bool constantTimeEquals(const QByteArray& left, const QByteArray& right)
{
    if (left.size() != right.size()) {
        return false;
    }

    quint8 diff = 0;
    for (int i = 0; i < left.size(); ++i) {
        diff |= static_cast<quint8>(left.at(i) ^ right.at(i));
    }
    return diff == 0;
}

bool isLegacySha256Hex(const QString& hash)
{
    static const QRegularExpression legacyPattern(QStringLiteral("^[0-9a-fA-F]{64}$"));
    return legacyPattern.match(hash.trimmed()).hasMatch();
}
}

QString createPasswordHash(const QString& password)
{
    if (password.isEmpty()) {
        return QString();
    }

    const QByteArray salt = generateRandomSalt(kSaltLengthBytes);
    const QByteArray derived = derivePbkdf2Sha256(password, salt, kPasswordIterations, kHashLengthBytes);

    if (derived.isEmpty()) {
        return QString();
    }

    const QString saltBase64 = QString::fromUtf8(salt.toBase64());
    const QString hashBase64 = QString::fromUtf8(derived.toBase64());
    return QStringLiteral("pbkdf2_sha256$%1$%2$%3")
        .arg(kPasswordIterations)
        .arg(saltBase64)
        .arg(hashBase64);
}

bool verifyPasswordHash(const QString& password, const QString& storedHash)
{
    const QString trimmedHash = storedHash.trimmed();
    if (password.isEmpty() || trimmedHash.isEmpty()) {
        return false;
    }

    if (trimmedHash.startsWith(QStringLiteral("pbkdf2_sha256$"))) {
        const QStringList parts = trimmedHash.split('$');
        if (parts.size() != 4) {
            return false;
        }

        bool iterationsOk = false;
        const int iterations = parts.at(1).toInt(&iterationsOk);
        if (!iterationsOk || iterations <= 0) {
            return false;
        }

        const QByteArray salt = QByteArray::fromBase64(parts.at(2).toUtf8());
        const QByteArray expectedHash = QByteArray::fromBase64(parts.at(3).toUtf8());
        if (salt.isEmpty() || expectedHash.isEmpty()) {
            return false;
        }

        const QByteArray actualHash = derivePbkdf2Sha256(password, salt, iterations, expectedHash.size());
        return constantTimeEquals(actualHash, expectedHash);
    }

    if (isLegacySha256Hex(trimmedHash)) {
        const QString candidate = QString::fromUtf8(
            QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
        return constantTimeEquals(candidate.toUtf8().toLower(), trimmedHash.toUtf8().toLower());
    }

    return false;
}

bool passwordHashNeedsUpgrade(const QString& storedHash)
{
    return isLegacySha256Hex(storedHash);
}
