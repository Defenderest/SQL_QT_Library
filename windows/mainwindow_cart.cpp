#include "mainwindow.h"
#include "./ui_mainwindow.h"
#include <QFrame>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>
#include <QPixmap>
#include <QSpinBox>
#include <QPushButton>
#include <QDebug>
#include <QMessageBox>
#include <QMap>
#include <QSpacerItem>
#include <QStatusBar>
#include <QLineEdit>
#include <QPainter>
#include <QIcon>
#include "checkoutdialog.h"

// Реалізація допоміжної функції для стилізованих QMessageBox
QMessageBox::StandardButton MainWindow::showStyledMessageBox(QMessageBox::Icon icon, const QString &title, const QString &text, QMessageBox::StandardButtons buttons, QMessageBox::StandardButton defaultButton)
{
    QMessageBox msgBox(this); // Встановлюємо батьківський віджет
    msgBox.setIcon(icon);
    msgBox.setWindowTitle(title);
    msgBox.setText(text);
    msgBox.setStandardButtons(buttons);
    if (defaultButton != QMessageBox::NoButton) {
        msgBox.setDefaultButton(defaultButton);
    }
    msgBox.setStyleSheet("QMessageBox { background-color: white; color: black; }"
                         "QMessageBox QLabel { color: black; background-color: white; }" // Явно для QLabel всередині
                         "QMessageBox QPushButton { color: black; background-color: #E1E1E1; border: 1px solid #ADADAD; padding: 5px; min-width: 70px; }"
                         "QMessageBox QPushButton:hover { background-color: #D0D0D0; }"
                         "QMessageBox QPushButton:pressed { background-color: #C0C0C0; }");
    return static_cast<QMessageBox::StandardButton>(msgBox.exec());
}


QWidget* MainWindow::createCartItemWidget(const CartItem &item, int bookId)
{
    QFrame *itemFrame = new QFrame();
    itemFrame->setObjectName("cartItemFrame");
    itemFrame->setFrameShape(QFrame::StyledPanel);
    itemFrame->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);

    QHBoxLayout *mainLayout = new QHBoxLayout(itemFrame);
    mainLayout->setSpacing(15);
    mainLayout->setContentsMargins(0, 0, 0, 0);

    QLabel *coverLabel = new QLabel();
    coverLabel->setObjectName("cartItemCoverLabel");
    coverLabel->setAlignment(Qt::AlignCenter);
    QPixmap coverPixmap(item.book.coverImagePath);
    if (coverPixmap.isNull() || item.book.coverImagePath.isEmpty()) {
        coverLabel->setText(tr("Фото"));
    } else {
        QSize labelSize = coverLabel->minimumSize();
        if (!labelSize.isValid() || labelSize.width() <= 0 || labelSize.height() <= 0) {
             labelSize = QSize(60, 85);
             qWarning() << "Cart item cover label size not set, using default:" << labelSize;
        }
        coverLabel->setPixmap(coverPixmap.scaled(labelSize, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        coverLabel->setText("");
    }
    mainLayout->addWidget(coverLabel);

    QVBoxLayout *infoLayout = new QVBoxLayout();
    infoLayout->setSpacing(2);
    QLabel *titleLabel = new QLabel(item.book.title);
    titleLabel->setObjectName("cartItemTitleLabel");
    titleLabel->setWordWrap(true);
    QLabel *authorLabel = new QLabel(item.book.authors);
    authorLabel->setObjectName("cartItemAuthorLabel");
    authorLabel->setWordWrap(true);
    infoLayout->addWidget(titleLabel);
    infoLayout->addWidget(authorLabel);
    infoLayout->addStretch(1);
    mainLayout->addLayout(infoLayout, 2);

    QLabel *priceLabel = new QLabel(QString::number(item.book.price, 'f', 2) + tr(" грн"));
    priceLabel->setObjectName("cartItemPriceLabel");
    priceLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
    mainLayout->addWidget(priceLabel, 1);

    QSpinBox *quantitySpinBox = new QSpinBox();
    quantitySpinBox->setObjectName("cartQuantitySpinBox");
    quantitySpinBox->setMinimum(1);
    // Максимум встановлюється на основі stockQuantity, яке має бути актуальним
    // на момент створення віджету (після завантаження корзини або оновлення)
    quantitySpinBox->setMaximum(item.book.stockQuantity > 0 ? item.book.stockQuantity : 1);
    quantitySpinBox->setValue(item.quantity);
    quantitySpinBox->setAlignment(Qt::AlignCenter);
    quantitySpinBox->setButtonSymbols(QAbstractSpinBox::UpDownArrows);
    quantitySpinBox->setProperty("bookId", bookId);
    // Використовуємо QOverload для явного вказання версії сигналу
    connect(quantitySpinBox, QOverload<int>::of(&QSpinBox::valueChanged), this, [this, bookId, quantitySpinBox](int newValue){
        updateCartItemQuantity(bookId, newValue, quantitySpinBox);
    });
    mainLayout->addWidget(quantitySpinBox);

    QLabel *subtotalLabel = new QLabel(QString::number(item.book.price * item.quantity, 'f', 2) + tr(" грн"));
    subtotalLabel->setObjectName("cartItemSubtotalLabel");
    subtotalLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
    subtotalLabel->setMinimumWidth(80);
    mainLayout->addWidget(subtotalLabel, 1);
    m_cartSubtotalLabels.insert(bookId, subtotalLabel);

    QPushButton *removeButton = new QPushButton();
    removeButton->setObjectName("cartRemoveButton");
    removeButton->setToolTip(tr("Видалити '%1' з кошика").arg(item.book.title));
    removeButton->setCursor(Qt::PointingHandCursor);
    removeButton->setProperty("bookId", bookId);
    connect(removeButton, &QPushButton::clicked, this, [this, bookId](){
        removeCartItem(bookId);
    });
    mainLayout->addWidget(removeButton);

    itemFrame->setLayout(mainLayout);
    return itemFrame;
}

void MainWindow::on_addToCartButtonClicked(int bookId)
{
    qInfo() << "Add to cart button clicked for book ID:" << bookId;
    if (!m_dbManager) {
        showStyledMessageBox(QMessageBox::Critical, tr("Помилка"), tr("Помилка доступу до бази даних."));
        return;
    }

    BookDisplayInfo currentBookInfo = m_dbManager->getBookDisplayInfoById(bookId);
    if (!currentBookInfo.found) {
         qWarning() << "Book with ID" << bookId << "not found for adding to cart.";
         showStyledMessageBox(QMessageBox::Warning, tr("Помилка"), tr("Не вдалося знайти інформацію про книгу (ID: %1).").arg(bookId));
         return;
    }

    int targetQuantity;
    bool isNewItemInCart = !m_cartItems.contains(bookId);

    if (isNewItemInCart) {
        if (currentBookInfo.stockQuantity <= 0) {
            showStyledMessageBox(QMessageBox::Information, tr("Немає в наявності"), tr("На жаль, книги '%1' зараз немає в наявності.").arg(currentBookInfo.title));
            return;
        }
        targetQuantity = 1;
    } else {
        targetQuantity = m_cartItems[bookId].quantity + 1;
    }

    bool dbSuccess = m_dbManager->addOrUpdateCartItem(m_currentCustomerId, bookId, targetQuantity);
    
    // Завжди отримуємо свіжу інформацію про книгу після спроби оновлення БД
    BookDisplayInfo freshBookInfo = m_dbManager->getBookDisplayInfoById(bookId);
    if (!freshBookInfo.found && dbSuccess) { // Якщо книга зникла після успішного додавання (дуже малоймовірно)
        qWarning() << "Book ID" << bookId << "was added to cart but now cannot be found.";
        // Можливо, варто відкотити операцію або видалити з корзини
    }


    if (dbSuccess) {
        if (isNewItemInCart) {
            CartItem newItem;
            newItem.book = freshBookInfo; // Використовуємо свіжу інформацію
            newItem.quantity = targetQuantity;
            m_cartItems.insert(bookId, newItem);
            qInfo() << "Added new book ID" << bookId << "to cart with quantity" << targetQuantity;
        } else {
            m_cartItems[bookId].quantity = targetQuantity;
            m_cartItems[bookId].book = freshBookInfo; // Оновлюємо інформацію про книгу (особливо stockQuantity)
            qInfo() << "Increased quantity for book ID" << bookId << "to" << targetQuantity;
        }
        ui->statusBar->showMessage(tr("Книгу '%1' додано/оновлено в кошику.").arg(freshBookInfo.title), 3000);
    } else {
        // Помилка додавання/оновлення в БД (ймовірно, через недостатню кількість)
        if (isNewItemInCart) {
            showStyledMessageBox(QMessageBox::Warning, tr("Не вдалося додати"), tr("Не вдалося додати книгу '%1' до кошика. Можливо, її немає в наявності або недостатньо на складі.").arg(currentBookInfo.title));
        } else {
            // Не вдалося збільшити кількість
             int quantityActuallyInCart = m_cartItems.value(bookId).quantity; // Поточна кількість в локальній корзині
             showStyledMessageBox(QMessageBox::Information, tr("Обмеження кількості"),
                                     tr("Не вдалося збільшити кількість книги '%1' до %2.\nНа складі доступно: %3 од.\nУ вашому кошику вже: %4 од.")
                                     .arg(freshBookInfo.title)
                                     .arg(targetQuantity)
                                     .arg(freshBookInfo.stockQuantity)
                                     .arg(quantityActuallyInCart));
        }
        // Оновлюємо локальний кеш stockQuantity, якщо товар є в корзині
        if (m_cartItems.contains(bookId)) {
            m_cartItems[bookId].book.stockQuantity = freshBookInfo.stockQuantity;
        }
    }

    updateCartIcon();

    if (ui->contentStackedWidget->currentWidget() == ui->cartPage) {
        populateCartPage(); // Перемальовує корзину, оновлюючи максимуми для QSpinBox
    }
}

void MainWindow::on_cartButton_clicked()
{
    qInfo() << "Cart button clicked. Navigating to cart page.";
    if (!ui->cartPage) {
        qWarning() << "Cart page widget not found in UI!";
        showStyledMessageBox(QMessageBox::Critical, tr("Помилка інтерфейсу"), tr("Сторінка кошика не знайдена."));
        return;
    }
    ui->contentStackedWidget->setCurrentWidget(ui->cartPage);
    populateCartPage();
}

void MainWindow::populateCartPage()
{
    qInfo() << "Populating cart page (new design)...";
    if (!ui->cartScrollArea || !ui->cartItemsContainerWidget || !ui->cartItemsLayout || !ui->cartTotalTextLabel || !ui->placeOrderButton || !ui->cartTotalsWidget) {
        qWarning() << "populateCartPage: One or more new cart page widgets are null!";
        if(ui->cartPage && ui->cartPage->layout()) {
             clearLayout(ui->cartPage->layout());
             QLabel *errorLabel = new QLabel(tr("Помилка інтерфейсу: Не вдалося відобразити кошик."), ui->cartPage);
             ui->cartPage->layout()->addWidget(errorLabel);
        }
        return;
    }

    clearLayout(ui->cartItemsLayout);
    m_cartSubtotalLabels.clear();

    QLabel* emptyCartLabel = ui->cartItemsContainerWidget->findChild<QLabel*>("emptyCartLabel");
    if(emptyCartLabel) {
        delete emptyCartLabel;
    }

    if (m_cartItems.isEmpty()) {
        qInfo() << "Cart is empty.";
        QLabel *noItemsLabel = new QLabel(tr("🛒\n\nВаш кошик порожній.\nЧас додати щось цікаве!"), ui->cartItemsContainerWidget);
        noItemsLabel->setObjectName("emptyCartLabel");
        noItemsLabel->setAlignment(Qt::AlignCenter);
        noItemsLabel->setWordWrap(true);
        ui->cartItemsLayout->addWidget(noItemsLabel);
        ui->cartItemsLayout->addSpacerItem(new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding));

        ui->placeOrderButton->setEnabled(false);
        ui->cartTotalTextLabel->setText(tr("Загальна сума: 0.00 грн"));
        ui->cartTotalsWidget->setVisible(false);
        return;
    }

    ui->cartTotalsWidget->setVisible(true);

    for (auto it = m_cartItems.constBegin(); it != m_cartItems.constEnd(); ++it) {
        // Перед створенням віджету, переконуємось, що stockQuantity актуальний
        // Це важливо, якщо populateCartPage викликається після невдалої спроби оновлення
        BookDisplayInfo freshBookInfo = m_dbManager->getBookDisplayInfoById(it.key());
        if (freshBookInfo.found) {
            m_cartItems[it.key()].book.stockQuantity = freshBookInfo.stockQuantity;
            // Якщо кількість в корзині перевищує новий залишок, коригуємо її
            if (m_cartItems[it.key()].quantity > freshBookInfo.stockQuantity) {
                 if (freshBookInfo.stockQuantity > 0) {
                    // Намагаємося оновити в БД до максимально доступної кількості
                    if(m_dbManager->addOrUpdateCartItem(m_currentCustomerId, it.key(), freshBookInfo.stockQuantity)) {
                        m_cartItems[it.key()].quantity = freshBookInfo.stockQuantity;
                    } else {
                        // Якщо навіть це не вдалося, можливо, книга зникла зовсім
                        // В такому випадку, її треба видалити з корзини (це зробить removeCartItem)
                        // Поки що просто логуємо
                        qWarning() << "Could not update cart item" << it.key() << "to stock quantity" << freshBookInfo.stockQuantity;
                    }
                 } else { // Товару зовсім немає
                    // Видаляємо з БД і локально
                    if(m_dbManager->removeCartItem(m_currentCustomerId, it.key())) {
                        // m_cartItems.remove(it.key()) // Буде видалено в наступній ітерації або при перезавантаженні
                        // Краще зробити це тут, але цикл for (auto it...) може стати невалідним
                        // Тому, краще перезавантажити populateCartPage() якщо таке сталося, або використовувати ітератори безпечно
                        qInfo() << "Item" << it.key() << "removed from cart as stock is 0.";
                        // Для простоти, поки що не видаляємо з m_cartItems прямо тут,
                        // покладаючись на те, що spinbox буде 0 або 1 і користувач видалить сам.
                        // Або, краще, після циклу перевірити і видалити такі елементи.
                    }
                 }
            }
        }

        QWidget *itemWidget = createCartItemWidget(it.value(), it.key());
        if (itemWidget) {
            ui->cartItemsLayout->addWidget(itemWidget);
        }
    }
    // Додатковий прохід для видалення товарів, яких немає в наявності, якщо їх кількість стала 0
    bool itemsRemoved = false;
    for (auto it = m_cartItems.begin(); it != m_cartItems.end(); ) {
        if (it.value().book.stockQuantity <= 0 && it.value().quantity > 0) {
            // Якщо товару немає на складі, але він ще в корзині з кількістю > 0
            // (це могло статися, якщо addOrUpdateCartItem не зміг оновити до 0)
            // Видаляємо його з БД і з локальної корзини
            qWarning() << "Item" << it.key() << "has 0 stock but quantity" << it.value().quantity << "in cart. Removing.";
            if (m_dbManager->removeCartItem(m_currentCustomerId, it.key())) {
                it = m_cartItems.erase(it);
                itemsRemoved = true;
            } else {
                ++it;
            }
        } else if (it.value().quantity > it.value().book.stockQuantity && it.value().book.stockQuantity > 0) {
            // Якщо кількість в корзині більша за наявну, але наявна > 0
            qWarning() << "Item" << it.key() << "quantity" << it.value().quantity << "exceeds stock" << it.value().book.stockQuantity << ". Adjusting.";
            if (m_dbManager->addOrUpdateCartItem(m_currentCustomerId, it.key(), it.value().book.stockQuantity)) {
                 it.value().quantity = it.value().book.stockQuantity;
                 itemsRemoved = true; // Технічно, це зміна, а не видалення, але може вимагати перемальовки
            }
            ++it;
        }
        else {
            ++it;
        }
    }
    if (itemsRemoved && m_cartItems.isEmpty()) { // Якщо після видалення корзина стала порожньою
        populateCartPage(); // Рекурсивний виклик для відображення порожньої корзини
        return;
    } else if (itemsRemoved) { // Якщо щось змінилося, але корзина не порожня
        // Потрібно перемалювати список товарів, оскільки віджети вже створені зі старими даними
        // Це найпростіший спосіб, хоча і не найефективніший
        clearLayout(ui->cartItemsLayout);
        m_cartSubtotalLabels.clear();
         for (auto it = m_cartItems.constBegin(); it != m_cartItems.constEnd(); ++it) {
            QWidget *itemWidget = createCartItemWidget(it.value(), it.key());
            if (itemWidget) ui->cartItemsLayout->addWidget(itemWidget);
        }
    }


    ui->cartItemsLayout->addSpacerItem(new QSpacerItem(20, 1, QSizePolicy::Minimum, QSizePolicy::Expanding));

    updateCartTotal();
    ui->placeOrderButton->setEnabled(!m_cartItems.isEmpty());
    qInfo() << "Cart page populated with" << m_cartItems.size() << "items.";

    ui->cartItemsContainerWidget->adjustSize();
}

void MainWindow::updateCartTotal()
{
    if (!ui->cartTotalTextLabel) return;

    double total = 0.0;
    for (const auto &item : m_cartItems) {
        total += item.book.price * item.quantity;
    }

    ui->cartTotalTextLabel->setText(tr("Загальна сума: %1 грн").arg(QString::number(total, 'f', 2)));
    qInfo() << "Cart total updated:" << total;
}

void MainWindow::updateCartIcon()
{
    if (!ui->cartButton || !m_cartBadgeLabel) {
        qWarning() << "updateCartIcon: cartButton or m_cartBadgeLabel is null!";
        return;
    }

    int totalItems = 0;
    for (const auto &item : m_cartItems) {
        totalItems += item.quantity;
    }

    const QString baseIconPath = "D:/projects/DB_Kurs/QtAPP/untitled/icons/cart.png";
    QIcon baseIcon(baseIconPath);
    if (!baseIcon.isNull()) {
        ui->cartButton->setIcon(baseIcon);
        if (ui->cartButton->iconSize().isEmpty()) {
             ui->cartButton->setIconSize(QSize(24, 24));
        }
    } else {
        qWarning() << "Failed to load base cart icon:" << baseIconPath;
        ui->cartButton->setText("?");
    }
    ui->cartButton->setText("");

    if (totalItems > 0) {
        m_cartBadgeLabel->setText(QString::number(totalItems));
        m_cartBadgeLabel->show();
        ui->cartButton->setToolTip(tr("Кошик (%1 товар(ів))").arg(totalItems));
        qInfo() << "Cart badge updated. Total items:" << totalItems;
    } else {
        m_cartBadgeLabel->hide();
        ui->cartButton->setToolTip(tr("Кошик"));
        qInfo() << "Cart is empty, badge hidden.";
    }
}

void MainWindow::updateCartItemQuantity(int bookId, int newQuantity, QSpinBox* activeSpinBox)
{
    qInfo() << "Updating quantity for book ID" << bookId << "to" << newQuantity << "via spinbox.";
    if (!m_cartItems.contains(bookId) || !m_dbManager) {
        qWarning() << "Cannot update quantity: item not in cart or no DB manager.";
        if(activeSpinBox) { // Відновлюємо попереднє значення, якщо можливо
            activeSpinBox->blockSignals(true);
            activeSpinBox->setValue(m_cartItems.value(bookId).quantity); // Або 1, якщо немає
            activeSpinBox->blockSignals(false);
        }
        return;
    }

    int oldQuantityInCart = m_cartItems[bookId].quantity;
    bool dbSuccess = m_dbManager->addOrUpdateCartItem(m_currentCustomerId, bookId, newQuantity);
    BookDisplayInfo freshBookInfo = m_dbManager->getBookDisplayInfoById(bookId); // Завжди отримуємо свіжі дані

    if (freshBookInfo.found) {
         m_cartItems[bookId].book.stockQuantity = freshBookInfo.stockQuantity; // Оновлюємо кеш залишку
    } else {
        qWarning() << "Book ID" << bookId << "not found after attempting to update quantity.";
        // Можливо, книгу видалили, тоді її треба видалити з корзини
        removeCartItem(bookId); // Це викличе populateCartPage, якщо на сторінці корзини
        return;
    }


    if (dbSuccess) {
        m_cartItems[bookId].quantity = newQuantity;
        qInfo() << "Successfully updated quantity for book ID" << bookId << "to" << newQuantity << "in DB and memory.";
        if (activeSpinBox) { // Оновлюємо максимум для spinbox, якщо він переданий
            activeSpinBox->blockSignals(true);
            activeSpinBox->setMaximum(freshBookInfo.stockQuantity > 0 ? freshBookInfo.stockQuantity : 1);
            // Значення вже встановлено користувачем, якщо dbSuccess true
            activeSpinBox->blockSignals(false);
        }
    } else {
        // Не вдалося оновити в БД (ймовірно, newQuantity > freshBookInfo.stockQuantity)
        qWarning() << "Failed to update quantity for book ID" << bookId << "to" << newQuantity << "in DB.";
        showStyledMessageBox(QMessageBox::Warning, tr("Обмеження кількості"),
                             tr("Не вдалося встановити кількість %1 для книги '%2'.\nМаксимально доступно на складі: %3 од.\nПопереднє значення в кошику: %4 од.")
                             .arg(newQuantity)
                             .arg(freshBookInfo.title)
                             .arg(freshBookInfo.stockQuantity)
                             .arg(oldQuantityInCart));

        // Відновлюємо попереднє значення в локальній корзині
        m_cartItems[bookId].quantity = oldQuantityInCart;

        if (activeSpinBox) {
            activeSpinBox->blockSignals(true);
            activeSpinBox->setValue(oldQuantityInCart); // Відновлюємо значення spinbox
            activeSpinBox->setMaximum(freshBookInfo.stockQuantity > 0 ? freshBookInfo.stockQuantity : 1); // Оновлюємо максимум
            activeSpinBox->blockSignals(false);
        }
    }

    // Оновлюємо мітку підсумку для цього товару, якщо вона існує
    QLabel *subtotalLabel = m_cartSubtotalLabels.value(bookId, nullptr);
    if (subtotalLabel) {
        double newSubtotal = m_cartItems[bookId].book.price * m_cartItems[bookId].quantity;
        subtotalLabel->setText(QString::number(newSubtotal, 'f', 2) + tr(" грн"));
    } else if (ui->contentStackedWidget->currentWidget() == ui->cartPage) {
        // Якщо мітки немає, але ми на сторінці корзини, краще перемалювати всю корзину
        // Це може статися, якщо populateCartPage не був викликаний після зміни
        populateCartPage();
    }


    updateCartTotal();
    updateCartIcon();
}


void MainWindow::removeCartItem(int bookId)
{
     bool removedFromDb = false;
     if (m_dbManager) {
         removedFromDb = m_dbManager->removeCartItem(m_currentCustomerId, bookId);
         if (!removedFromDb) {
              qWarning() << "Failed to remove item (bookId:" << bookId << ") from DB cart for customerId:" << m_currentCustomerId;
              // Незважаючи на помилку в БД, продовжуємо видалення з локальної корзини,
              // щоб інтерфейс відповідав очікуванням користувача.
              // При наступному завантаженні корзини з БД, стан може синхронізуватися.
         }
     } else {
         qWarning() << "removeCartItem: DatabaseManager is null, cannot remove item from DB cart.";
     }

     if (m_cartItems.contains(bookId)) {
         QString bookTitle = m_cartItems[bookId].book.title;
         m_cartItems.remove(bookId);
         qInfo() << "Removed book ID" << bookId << "from memory cart.";
         ui->statusBar->showMessage(tr("Книгу '%1' видалено з кошика.").arg(bookTitle), 3000);

         if (ui->contentStackedWidget->currentWidget() == ui->cartPage) {
            populateCartPage(); // Перемальовуємо корзину
         }
         updateCartIcon(); // Оновлюємо іконку корзини
         updateCartTotal(); // Оновлюємо загальну суму
     } else {
         qWarning() << "Attempted to remove non-existent book ID from cart:" << bookId;
     }
}

void MainWindow::on_placeOrderButton_clicked()
{
    qInfo() << "Place order button clicked. Opening checkout dialog...";
    if (m_cartItems.isEmpty()) {
        showStyledMessageBox(QMessageBox::Information, tr("Кошик порожній"), tr("Ваш кошик порожній. Будь ласка, додайте товари перед оформленням замовлення."));
        return;
    }
    if (!m_dbManager) {
        showStyledMessageBox(QMessageBox::Critical, tr("Помилка"), tr("Помилка доступу до бази даних. Неможливо оформити замовлення."));
        return;
    }
     if (m_currentCustomerId <= 0) {
        showStyledMessageBox(QMessageBox::Critical, tr("Помилка"), tr("Неможливо оформити замовлення, користувач не визначений."));
        return;
    }

    // Перевірка актуальності залишків перед оформленням
    bool allItemsAvailable = true;
    QString unavailableItemsMessage = tr("Деякі товари у вашому кошику більше не доступні в замовленій кількості або відсутні на складі:\n");
    for (auto it = m_cartItems.begin(); it != m_cartItems.end(); ++it) {
        BookDisplayInfo freshInfo = m_dbManager->getBookDisplayInfoById(it.key());
        if (!freshInfo.found || freshInfo.stockQuantity < it.value().quantity) {
            allItemsAvailable = false;
            unavailableItemsMessage += tr("\n- %1 (замовлено: %2, доступно: %3)")
                                       .arg(it.value().book.title)
                                       .arg(it.value().quantity)
                                       .arg(freshInfo.found ? freshInfo.stockQuantity : 0);
            // Оновлюємо локальний кеш, якщо потрібно
            it.value().book.stockQuantity = freshInfo.found ? freshInfo.stockQuantity : 0;
            if (it.value().quantity > it.value().book.stockQuantity) {
                // Можна запропонувати користувачу оновити корзину або автоматично зменшити кількість
                // Поки що просто інформуємо
            }
        }
    }

    if (!allItemsAvailable) {
        unavailableItemsMessage += tr("\n\nБудь ласка, оновіть ваш кошик.");
        showStyledMessageBox(QMessageBox::Warning, tr("Товари недоступні"), unavailableItemsMessage);
        populateCartPage(); // Оновлюємо відображення корзини
        return;
    }


    CustomerProfileInfo profile = m_dbManager->getCustomerProfileInfo(m_currentCustomerId);
    if (!profile.found) {
        showStyledMessageBox(QMessageBox::Critical, tr("Помилка профілю"), tr("Не вдалося завантажити дані профілю користувача."));
        return;
    }

    double currentTotal = 0.0;
    for (const auto &item : m_cartItems) {
        currentTotal += item.book.price * item.quantity;
    }

    CheckoutDialog dialog(profile, currentTotal, this);
    if (dialog.exec() == QDialog::Accepted) {
        QString finalAddress = dialog.getShippingAddress();
        QString finalPaymentMethod = dialog.getPaymentMethod();
        qInfo() << "Checkout confirmed. Address:" << finalAddress << "Payment:" << finalPaymentMethod;

        finalizeOrder(finalAddress, finalPaymentMethod);

    } else {
        qInfo() << "Checkout cancelled by user.";
    }
}

void MainWindow::finalizeOrder(const QString &shippingAddress, const QString &paymentMethod)
{
     qInfo() << "Finalizing order. Address:" << shippingAddress << "Payment:" << paymentMethod;

     if (m_cartItems.isEmpty() || !m_dbManager || m_currentCustomerId <= 0) {
         qWarning() << "Finalize order called with empty cart, no DB manager, or invalid customer ID.";
         showStyledMessageBox(QMessageBox::Critical, tr("Помилка"), tr("Не вдалося завершити оформлення замовлення через внутрішню помилку."));
         return;
     }

     QMap<int, int> itemsMap;
     for (auto it = m_cartItems.constBegin(); it != m_cartItems.constEnd(); ++it) {
         itemsMap.insert(it.key(), it.value().quantity);
     }

     int newOrderId = -1;
     double orderTotal = m_dbManager->createOrder(m_currentCustomerId, itemsMap, shippingAddress, paymentMethod, newOrderId);

     if (orderTotal >= 0 && newOrderId > 0) {
         qInfo() << "Order" << newOrderId << "placed successfully for total" << orderTotal;
         showStyledMessageBox(QMessageBox::Information, tr("Замовлення оформлено"), tr("Ваше замовлення #%1 на суму %2 грн успішно оформлено!").arg(newOrderId).arg(QString::number(orderTotal, 'f', 2)));


         int pointsToAdd = static_cast<int>(orderTotal / 10.0);
         if (pointsToAdd > 0) {
             qInfo() << "Adding" << pointsToAdd << "loyalty points for order total" << orderTotal;
             if (m_dbManager->addLoyaltyPoints(m_currentCustomerId, pointsToAdd)) {
                 qInfo() << "Loyalty points added successfully.";
                 ui->statusBar->showMessage(tr("Вам нараховано %1 бонусних балів!").arg(pointsToAdd), 4000);
             } else {
                 qWarning() << "Failed to add loyalty points for customer ID:" << m_currentCustomerId;
             }
         } else {
              qInfo() << "No loyalty points to add for order total" << orderTotal;
         }

         if (!m_dbManager->clearCart(m_currentCustomerId)) {
             qWarning() << "Failed to clear DB cart for customerId:" << m_currentCustomerId << "after placing order.";
         } else {
             qInfo() << "DB cart cleared successfully for customerId:" << m_currentCustomerId;
         }

         m_cartItems.clear();
         updateCartIcon();
         // populateCartPage(); // Корзина порожня, populateCartPage відобразить це
         on_navOrdersButton_clicked(); // Переходимо на сторінку замовлень
         ui->contentStackedWidget->setCurrentWidget(ui->ordersPage); // Явно переключаємо сторінку

     } else {
         showStyledMessageBox(QMessageBox::Critical, tr("Помилка оформлення"), tr("Не вдалося оформити замовлення. Можливо, деяких товарів вже немає в наявності або їх кількість змінилася. Будь ласка, перевірте ваш кошик та спробуйте знову."));
         qWarning() << "Failed to create order. DB Error:" << m_dbManager->lastError().text() << "Returned total:" << orderTotal;
         // Завантажуємо актуальний стан корзини з БД, оскільки замовлення не вдалося
         loadCartFromDatabase(); // Це оновить m_cartItems
         populateCartPage(); // Це оновить UI корзини
     }
}
