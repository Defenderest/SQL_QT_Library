#ifndef PASSWORD_UTILS_H
#define PASSWORD_UTILS_H

#include <QString>

QString createPasswordHash(const QString& password);
bool verifyPasswordHash(const QString& password, const QString& storedHash);
bool passwordHashNeedsUpgrade(const QString& storedHash);

#endif // PASSWORD_UTILS_H
