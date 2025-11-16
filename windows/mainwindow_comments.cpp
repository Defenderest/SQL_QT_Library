#include "mainwindow.h"
#include "./ui_mainwindow.h"
#include <QLabel>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFrame>
#include <QLocale>
#include <QDateTime>
#include <QDebug>
#include <QMessageBox>
#include <QLineEdit>
#include <QPushButton>
#include "starratingwidget.h"
#include <QSpacerItem>

void MainWindow::displayComments(const QList<CommentDisplayInfo> &comments)
{
    clearLayout(ui->commentsListLayout);

    if (comments.isEmpty()) {
        QLabel *noCommentsLabel = new QLabel(tr("Відгуків ще немає. Будьте першим!"));
        noCommentsLabel->setAlignment(Qt::AlignCenter);
        noCommentsLabel->setStyleSheet("color: #6c757d; font-style: italic; padding: 20px;");
        ui->commentsListLayout->addWidget(noCommentsLabel);
        ui->commentsListLayout->addSpacerItem(new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding));
    } else {
        for (const CommentDisplayInfo &commentInfo : comments) {
            QWidget *commentWidget = createCommentWidget(commentInfo);
            if (commentWidget) {
                ui->commentsListLayout->addWidget(commentWidget);
            }
        }
        ui->commentsListLayout->addSpacerItem(new QSpacerItem(20, 1, QSizePolicy::Minimum, QSizePolicy::Expanding));
    }
}

void MainWindow::refreshBookComments()
{
    if (m_currentBookDetailsId <= 0 || !m_dbManager) {
        qWarning() << "Cannot refresh comments: invalid book ID or DB manager.";
        displayComments({});
        return;
    }
    qInfo() << "Refreshing comments for book ID:" << m_currentBookDetailsId;
    QList<CommentDisplayInfo> comments = m_dbManager->getBookComments(m_currentBookDetailsId);
    displayComments(comments);
}


QWidget* MainWindow::createCommentWidget(const CommentDisplayInfo &commentInfo)
{
    QFrame *commentFrame = new QFrame();
    commentFrame->setObjectName("commentFrame");
    commentFrame->setFrameShape(QFrame::StyledPanel);
    commentFrame->setFrameShadow(QFrame::Plain);
    commentFrame->setLineWidth(0);
    commentFrame->setStyleSheet(R"(
        QFrame#commentFrame {
            background-color: #ffffff;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 10px;
        }
    )");

    QVBoxLayout *mainLayout = new QVBoxLayout(commentFrame);
    mainLayout->setSpacing(8);
    mainLayout->setContentsMargins(0, 0, 0, 0);

    QHBoxLayout *headerLayout = new QHBoxLayout();
    headerLayout->setSpacing(10);

    QLabel *authorLabel = new QLabel(commentInfo.authorName);
    authorLabel->setStyleSheet("font-weight: 600; font-size: 11pt; color: #343a40;");

    QLabel *dateLabel = new QLabel(QLocale::system().toString(commentInfo.commentDate, QLocale::ShortFormat));
    dateLabel->setStyleSheet("color: #868e96; font-size: 9pt;");
    dateLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);

    headerLayout->addWidget(authorLabel);
    headerLayout->addStretch(1);
    headerLayout->addWidget(dateLabel);
    mainLayout->addLayout(headerLayout);

    mainLayout->addLayout(headerLayout);

    StarRatingWidget *ratingWidget = new StarRatingWidget();
    ratingWidget->setMaxRating(5);
    ratingWidget->setRating(commentInfo.rating > 0 ? commentInfo.rating : 0);
    ratingWidget->setReadOnly(true);
    ratingWidget->setMinimumHeight(20);
    ratingWidget->setMaximumHeight(20);
    mainLayout->addWidget(ratingWidget);

    QLabel *commentTextLabel = new QLabel(commentInfo.commentText);
    commentTextLabel->setWordWrap(true);
    commentTextLabel->setStyleSheet("color: #495057; font-size: 10pt; line-height: 1.5;");
    mainLayout->addWidget(commentTextLabel);

    commentFrame->setLayout(mainLayout);
    return commentFrame;
}

void MainWindow::on_sendCommentButton_clicked()
{
    qInfo() << "Send comment button clicked.";

    if (m_currentBookDetailsId <= 0) {
        QMessageBox::warning(this, tr("Помилка"), tr("Неможливо відправити відгук, не визначено книгу."));
        qWarning() << "Cannot send comment: m_currentBookDetailsId is invalid:" << m_currentBookDetailsId;
        return;
    }
    if (m_currentCustomerId <= 0) {
        QMessageBox::warning(this, tr("Помилка"), tr("Неможливо відправити відгук, користувач не авторизований."));
        qWarning() << "Cannot send comment: m_currentCustomerId is invalid:" << m_currentCustomerId;
        return;
    }
    if (!m_dbManager) {
        QMessageBox::critical(this, tr("Помилка"), tr("Помилка доступу до бази даних. Неможливо відправити відгук."));
        qWarning() << "Cannot send comment: m_dbManager is null.";
        return;
    }
    if (!ui->newCommentTextEdit || !ui->newCommentStarRatingWidget) {
         QMessageBox::critical(this, tr("Помилка інтерфейсу"), tr("Не знайдено поля для введення відгуку або рейтингу."));
         qWarning() << "Cannot send comment: UI elements missing.";
         return;
    }

    if (m_dbManager->hasUserCommentedOnBook(m_currentBookDetailsId, m_currentCustomerId)) {
        qWarning() << "Attempted to add a second comment for book ID:" << m_currentBookDetailsId << "by customer ID:" << m_currentCustomerId;
        refreshBookComments();
        populateBookDetailsPage(m_dbManager->getBookDetails(m_currentBookDetailsId));
        return;
    }

    QString commentText = ui->newCommentTextEdit->text().trimmed();
    int rating = ui->newCommentStarRatingWidget->rating();

    if (commentText.isEmpty()) {
        QMessageBox::warning(this, tr("Відправка відгуку"), tr("Будь ласка, введіть текст вашого відгуку."));
        ui->newCommentTextEdit->setFocus();
        return;
    }

    qInfo() << "Attempting to add comment for book ID:" << m_currentBookDetailsId << "by customer ID:" << m_currentCustomerId << "Rating:" << rating;
    bool success = m_dbManager->addComment(m_currentBookDetailsId, m_currentCustomerId, commentText, rating);

    if (success) {
        qInfo() << "Comment added successfully.";
        ui->newCommentStarRatingWidget->setRating(0);
        BookDetailsInfo updatedDetails = m_dbManager->getBookDetails(m_currentBookDetailsId);
        if (updatedDetails.found) {
            populateBookDetailsPage(updatedDetails);
        } else {
            qWarning() << "Book details not found after adding comment for ID:" << m_currentBookDetailsId;
            ui->contentStackedWidget->setCurrentWidget(ui->booksPage);
        }

    } else {
        QMessageBox::critical(this, tr("Помилка відправки"), tr("Не вдалося додати ваш відгук. Перевірте журнал помилок або спробуйте пізніше."));
        qWarning() << "Failed to add comment. DB Error:" << m_dbManager->lastError().text();
    }
}
