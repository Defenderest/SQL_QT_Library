#ifndef LOGINDIALOG_H
#define LOGINDIALOG_H

#include <QDialog>
#include <QMap>
#include <QLineEdit>
#include <QLabel>
#include <QPushButton>
#include "database.h"

class LoginDialog : public QDialog
{
    Q_OBJECT

public:
    explicit LoginDialog(DatabaseManager *dbManager, QWidget *parent = nullptr);
    ~LoginDialog();

    int getLoggedInCustomerId() const;
    bool getLoggedInIsAdmin() const;

private slots:
    void onSwitchToRegister();
    void onSwitchToLogin();
    void onOkClicked();

private:
    enum Mode { Login, Register };

    void setupUI();
    void setMode(Mode mode);
    bool checkCredentials(const QString &email, const QString &password);
    bool performRegistration();

    DatabaseManager *m_dbManager;
    int m_loggedInCustomerId = -1;
    bool m_loggedInIsAdmin = false;
    Mode m_currentMode = Login;
    QMap<QString, int> m_loginAttempts;
    static const int MAX_LOGIN_ATTEMPTS = 5;

    // UI Elements
    QLabel *m_titleLabel;
    QLabel *m_errorLabel;
    QLabel *m_firstNameLabel;
    QLineEdit *m_firstNameEdit;
    QLabel *m_lastNameLabel;
    QLineEdit *m_lastNameEdit;
    QLabel *m_emailLabel;
    QLineEdit *m_emailEdit;
    QLabel *m_passwordLabel;
    QLineEdit *m_passwordEdit;
    QLabel *m_confirmPasswordLabel;
    QLineEdit *m_confirmPasswordEdit;
    QPushButton *m_okButton;
    QPushButton *m_switchToRegisterButton;
    QPushButton *m_switchToLoginButton;
};

#endif // LOGINDIALOG_H
