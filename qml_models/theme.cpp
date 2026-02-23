#include "theme.h"

Theme::Theme(QObject *parent)
    : QObject(parent)
{
    // Загружаем шрифты из системы
    // Playfair Display и Inter обычно доступны на большинстве систем
    // Если нет - используем fallback
}

QFont Theme::fontDisplay() const
{
    QFont font("Playfair Display");
    if (!QFontDatabase::hasFamily("Playfair Display")) {
        font.setFamily("Georgia"); // fallback
    }
    font.setPointSize(20);
    font.setWeight(QFont::Normal);
    return font;
}

QFont Theme::fontDisplayItalic() const
{
    QFont font = fontDisplay();
    font.setItalic(true);
    font.setPointSize(24);
    return font;
}

QFont Theme::fontBody() const
{
    QFont font("Inter");
    if (!QFontDatabase::hasFamily("Inter")) {
        font.setFamily("Segoe UI"); // fallback для Windows
    }
    font.setPointSize(12);
    font.setWeight(QFont::Normal);
    return font;
}

QFont Theme::fontBodyLight() const
{
    QFont font = fontBody();
    font.setWeight(QFont::Light);
    return font;
}

QFont Theme::fontCaption() const
{
    QFont font = fontBody();
    font.setPointSize(10);
    font.setWeight(QFont::Medium);
    return font;
}

QFont Theme::fontButton() const
{
    QFont font = fontBody();
    font.setPointSize(11);
    font.setWeight(QFont::Medium);
    font.setLetterSpacing(QFont::AbsoluteSpacing, 2);
    return font;
}
