#ifndef PROFILEMODEL_H
#define PROFILEMODEL_H

#include <QObject>
#include "../models/datatypes.h"

class DatabaseManager;

class ProfileModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int customerId READ customerId WRITE setCustomerId NOTIFY customerIdChanged)
    Q_PROPERTY(QString firstName READ firstName NOTIFY profileChanged)
    Q_PROPERTY(QString lastName READ lastName NOTIFY profileChanged)
    Q_PROPERTY(QString email READ email NOTIFY profileChanged)
    Q_PROPERTY(QString phone READ phone NOTIFY profileChanged)
    Q_PROPERTY(QString address READ address NOTIFY profileChanged)
    Q_PROPERTY(QDate joinDate READ joinDate NOTIFY profileChanged)
    Q_PROPERTY(bool loyaltyProgram READ loyaltyProgram NOTIFY profileChanged)
    Q_PROPERTY(int loyaltyPoints READ loyaltyPoints NOTIFY profileChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY profileChanged)

public:
    explicit ProfileModel(QObject *parent = nullptr);

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int customerId() const;
    void setCustomerId(int customerId);

    QString firstName() const;
    QString lastName() const;
    QString email() const;
    QString phone() const;
    QString address() const;
    QDate joinDate() const;
    bool loyaltyProgram() const;
    int loyaltyPoints() const;
    bool loaded() const;

    Q_INVOKABLE void loadProfile();
    Q_INVOKABLE bool updateProfile(const QString& firstName, const QString& lastName,
                                   const QString& phone, const QString& address);

signals:
    void dbManagerChanged();
    void customerIdChanged();
    void profileChanged();
    void errorOccurred(const QString& message);
    void profileUpdated();

private:
    DatabaseManager* m_dbManager = nullptr;
    int m_customerId = -1;
    CustomerProfileInfo m_profile;
};

#endif // PROFILEMODEL_H
