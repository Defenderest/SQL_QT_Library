#include "logindialog.h"
#include <QCryptographicHash>
#include <QMessageBox>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFormLayout>
#include <QStyle>

LoginDialog::LoginDialog(DatabaseManager *dbManager, QWidget *parent)
    : QDialog(parent)
    , m_dbManager(dbManager)
{
    setupUI();
    setMode(Login);

    if (!m_dbManager) {
        qCritical() << "LoginDialog: DatabaseManager is null!";
        m_errorLabel->setText(tr("Помилка ініціалізації. Неможливо перевірити дані."));
        m_okButton->setEnabled(false);
    }
}

LoginDialog::~LoginDialog()
{
}

void LoginDialog::setupUI()
{
    setWindowTitle(tr("Вхід до Книгарні"));
    setMinimumWidth(400);

    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(16);
    mainLayout->setContentsMargins(32, 32, 32, 32);

    // Заголовок
    m_titleLabel = new QLabel(this);
    m_titleLabel->setStyleSheet("font-size: 24px; font-weight: bold; color: #ffffff;");
    mainLayout->addWidget(m_titleLabel, 0, Qt::AlignCenter);

    mainLayout->addSpacing(20);

    // Поля формы
    QFormLayout *formLayout = new QFormLayout();
    formLayout->setSpacing(12);

    m_firstNameLabel = new QLabel(tr("Ім'я:"), this);
    m_firstNameEdit = new QLineEdit(this);
    m_firstNameEdit->setStyleSheet("padding: 8px; border: 1px solid #333; border-radius: 4px; background: #1a1a1a; color: #fff;");
    formLayout->addRow(m_firstNameLabel, m_firstNameEdit);

    m_lastNameLabel = new QLabel(tr("Прізвище:"), this);
    m_lastNameEdit = new QLineEdit(this);
    m_lastNameEdit->setStyleSheet("padding: 8px; border: 1px solid #333; border-radius: 4px; background: #1a1a1a; color: #fff;");
    formLayout->addRow(m_lastNameLabel, m_lastNameEdit);

    m_emailLabel = new QLabel(tr("Email:"), this);
    m_emailEdit = new QLineEdit(this);
    m_emailEdit->setStyleSheet("padding: 8px; border: 1px solid #333; border-radius: 4px; background: #1a1a1a; color: #fff;");
    formLayout->addRow(m_emailLabel, m_emailEdit);

    m_passwordLabel = new QLabel(tr("Пароль:"), this);
    m_passwordEdit = new QLineEdit(this);
    m_passwordEdit->setEchoMode(QLineEdit::Password);
    m_passwordEdit->setStyleSheet("padding: 8px; border: 1px solid #333; border-radius: 4px; background: #1a1a1a; color: #fff;");
    formLayout->addRow(m_passwordLabel, m_passwordEdit);

    m_confirmPasswordLabel = new QLabel(tr("Підтвердження пароля:"), this);
    m_confirmPasswordEdit = new QLineEdit(this);
    m_confirmPasswordEdit->setEchoMode(QLineEdit::Password);
    m_confirmPasswordEdit->setStyleSheet("padding: 8px; border: 1px solid #333; border-radius: 4px; background: #1a1a1a; color: #fff;");
    formLayout->addRow(m_confirmPasswordLabel, m_confirmPasswordEdit);

    mainLayout->addLayout(formLayout);

    // Ошибка
    m_errorLabel = new QLabel(this);
    m_errorLabel->setStyleSheet("color: #ff4444; font-size: 12px;");
    m_errorLabel->setWordWrap(true);
    mainLayout->addWidget(m_errorLabel);

    mainLayout->addSpacing(10);

    // Кнопка OK
    m_okButton = new QPushButton(this);
    m_okButton->setStyleSheet(
        "QPushButton {"
        "  background-color: #ffffff;"
        "  color: #000000;"
        "  border: none;"
        "  padding: 12px 24px;"
        "  font-size: 14px;"
        "  font-weight: bold;"
        "}"
        "QPushButton:hover { background-color: #e0e0e0; }"
        "QPushButton:disabled { background-color: #555; color: #888; }"
    );
    m_okButton->setCursor(Qt::PointingHandCursor);
    connect(m_okButton, &QPushButton::clicked, this, &LoginDialog::onOkClicked);
    mainLayout->addWidget(m_okButton);

    // Кнопки переключения
    QHBoxLayout *switchLayout = new QHBoxLayout();

    m_switchToRegisterButton = new QPushButton(tr("Зареєструватися"), this);
    m_switchToRegisterButton->setStyleSheet("background: transparent; border: none; color: #888; text-decoration: underline;");
    m_switchToRegisterButton->setCursor(Qt::PointingHandCursor);
    connect(m_switchToRegisterButton, &QPushButton::clicked, this, &LoginDialog::onSwitchToRegister);
    switchLayout->addWidget(m_switchToRegisterButton);

    switchLayout->addStretch();

    m_switchToLoginButton = new QPushButton(tr("Вже є акаунт? Увійти"), this);
    m_switchToLoginButton->setStyleSheet("background: transparent; border: none; color: #888; text-decoration: underline;");
    m_switchToLoginButton->setCursor(Qt::PointingHandCursor);
    connect(m_switchToLoginButton, &QPushButton::clicked, this, &LoginDialog::onSwitchToLogin);
    switchLayout->addWidget(m_switchToLoginButton);

    mainLayout->addLayout(switchLayout);

    // Стили диалога
    setStyleSheet("QDialog { background-color: #0d0d0d; } QLabel { color: #ffffff; }");
}

int LoginDialog::getLoggedInCustomerId() const
{
    return m_loggedInCustomerId;
}

bool LoginDialog::getLoggedInIsAdmin() const
{
    return m_loggedInIsAdmin;
}

void LoginDialog::onSwitchToRegister()
{
    setMode(Register);
}

void LoginDialog::onSwitchToLogin()
{
    setMode(Login);
}

void LoginDialog::setMode(Mode mode)
{
    m_currentMode = mode;
    m_errorLabel->clear();
    m_loginAttempts.clear();
    m_okButton->setEnabled(true);
    m_emailEdit->setEnabled(true);
    m_passwordEdit->setEnabled(true);

    if (mode == Login) {
        m_titleLabel->setText(tr("Вхід до Книгарні"));
        m_okButton->setText(tr("Увійти"));
        m_switchToRegisterButton->setVisible(true);
        m_switchToLoginButton->setVisible(false);
        m_firstNameLabel->setVisible(false);
        m_firstNameEdit->setVisible(false);
        m_lastNameLabel->setVisible(false);
        m_lastNameEdit->setVisible(false);
        m_confirmPasswordLabel->setVisible(false);
        m_confirmPasswordEdit->setVisible(false);
        m_firstNameEdit->clear();
        m_lastNameEdit->clear();
        m_confirmPasswordEdit->clear();
        m_emailEdit->setFocus();
    } else {
        m_titleLabel->setText(tr("Реєстрація нового користувача"));
        m_okButton->setText(tr("Зареєструватися"));
        m_switchToRegisterButton->setVisible(false);
        m_switchToLoginButton->setVisible(true);
        m_firstNameLabel->setVisible(true);
        m_firstNameEdit->setVisible(true);
        m_lastNameLabel->setVisible(true);
        m_lastNameEdit->setVisible(true);
        m_confirmPasswordLabel->setVisible(true);
        m_confirmPasswordEdit->setVisible(true);
        m_passwordEdit->clear();
        m_firstNameEdit->setFocus();
    }
}

void LoginDialog::onOkClicked()
{
    m_errorLabel->clear();

    if (m_currentMode == Login) {
        const QString email = m_emailEdit->text().trimmed();
        const QString password = m_passwordEdit->text();

        if (email.isEmpty() || password.isEmpty()) {
            m_errorLabel->setText(tr("Будь ласка, введіть email та пароль."));
            return;
        }

        if (checkCredentials(email, password)) {
            qInfo() << "Login successful for user ID:" << m_loggedInCustomerId;
            m_loginAttempts.remove(email);
            accept();
        } else {
            int attempts = m_loginAttempts.value(email, 0) + 1;
            m_loginAttempts[email] = attempts;

            if (attempts >= MAX_LOGIN_ATTEMPTS) {
                m_errorLabel->setText(tr("Забагато невдалих спроб. Спробуйте пізніше."));
                m_okButton->setEnabled(false);
                m_emailEdit->setEnabled(false);
                m_passwordEdit->setEnabled(false);
            } else {
                int remaining = MAX_LOGIN_ATTEMPTS - attempts;
                m_errorLabel->setText(tr("Невірний email або пароль. Залишилось спроб: %1").arg(remaining));
                m_passwordEdit->clear();
                m_passwordEdit->setFocus();
            }
        }
    } else {
        if (performRegistration()) {
            qInfo() << "Registration successful for user ID:" << m_loggedInCustomerId;
            accept();
        }
    }
}

bool LoginDialog::performRegistration()
{
    if (!m_dbManager) {
        m_errorLabel->setText(tr("Помилка бази даних. Реєстрація неможлива."));
        return false;
    }

    CustomerRegistrationInfo regInfo;
    regInfo.firstName = m_firstNameEdit->text().trimmed();
    regInfo.lastName = m_lastNameEdit->text().trimmed();
    regInfo.email = m_emailEdit->text().trimmed();
    regInfo.password = m_passwordEdit->text();
    const QString confirmPassword = m_confirmPasswordEdit->text();

    if (regInfo.firstName.isEmpty() || regInfo.lastName.isEmpty() ||
        regInfo.email.isEmpty() || regInfo.password.isEmpty()) {
        m_errorLabel->setText(tr("Будь ласка, заповніть всі поля."));
        return false;
    }
    if (regInfo.password != confirmPassword) {
        m_errorLabel->setText(tr("Паролі не співпадають."));
        m_confirmPasswordEdit->clear();
        m_passwordEdit->setFocus();
        m_passwordEdit->selectAll();
        return false;
    }

    int newId = -1;
    if (m_dbManager->registerCustomer(regInfo, newId)) {
        m_loggedInCustomerId = newId;
        m_loggedInIsAdmin = false;
        return true;
    } else {
        if (m_dbManager->lastError().text().contains("duplicate")) {
            m_errorLabel->setText(tr("Користувач з таким email вже існує."));
            m_emailEdit->setFocus();
            m_emailEdit->selectAll();
        } else {
            m_errorLabel->setText(tr("Помилка реєстрації. Спробуйте пізніше."));
        }
        return false;
    }
}

bool LoginDialog::checkCredentials(const QString &email, const QString &password)
{
    m_loggedInIsAdmin = false;
    if (!m_dbManager) return false;

    CustomerLoginInfo loginInfo = m_dbManager->getCustomerLoginInfo(email);

    if (!loginInfo.found) {
        qWarning() << "Login attempt failed: Email not found -" << email;
        return false;
    }

    QByteArray enteredPasswordHash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    QString enteredPasswordHashHex = QString::fromUtf8(enteredPasswordHash.toHex());

    if (enteredPasswordHashHex == loginInfo.passwordHash) {
        m_loggedInCustomerId = loginInfo.customerId;
        m_loggedInIsAdmin = loginInfo.isAdmin;
        return true;
    } else {
        qWarning() << "Login attempt failed: Incorrect password for email -" << email;
        return false;
    }
}
