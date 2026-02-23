#ifndef THEME_H
#define THEME_H

#include <QObject>
#include <QColor>
#include <QFont>
#include <QFontDatabase>
#include <QDebug>

class Theme : public QObject
{
    Q_OBJECT

    // Colors - Obsidian Luxe Palette
    Q_PROPERTY(QColor bgBody READ bgBody CONSTANT)
    Q_PROPERTY(QColor bgCard READ bgCard CONSTANT)
    Q_PROPERTY(QColor glassPanel READ glassPanel CONSTANT)
    Q_PROPERTY(QColor borderLight READ borderLight CONSTANT)
    Q_PROPERTY(QColor borderHover READ borderHover CONSTANT)
    Q_PROPERTY(QColor textPrimary READ textPrimary CONSTANT)
    Q_PROPERTY(QColor textSecondary READ textSecondary CONSTANT)
    Q_PROPERTY(QColor textMuted READ textMuted CONSTANT)
    Q_PROPERTY(QColor spotlightColor READ spotlightColor CONSTANT)
    Q_PROPERTY(QColor accentWhite READ accentWhite CONSTANT)
    Q_PROPERTY(QColor cardHover READ cardHover CONSTANT)
    Q_PROPERTY(QColor success READ success CONSTANT)
    Q_PROPERTY(QColor info READ info CONSTANT)
    Q_PROPERTY(QColor warning READ warning CONSTANT)
    Q_PROPERTY(QColor error READ error CONSTANT)

    // Fonts
    Q_PROPERTY(QFont fontDisplay READ fontDisplay CONSTANT)      // Playfair Display - заголовки
    Q_PROPERTY(QFont fontDisplayItalic READ fontDisplayItalic CONSTANT)
    Q_PROPERTY(QFont fontBody READ fontBody CONSTANT)            // Inter - обычный текст
    Q_PROPERTY(QFont fontBodyLight READ fontBodyLight CONSTANT)
    Q_PROPERTY(QFont fontCaption READ fontCaption CONSTANT)      // Мелкий текст
    Q_PROPERTY(QFont fontButton READ fontButton CONSTANT)        // Кнопки

    // Sizes
    Q_PROPERTY(int dockWidth READ dockWidth CONSTANT)
    Q_PROPERTY(int headerHeight READ headerHeight CONSTANT)
    Q_PROPERTY(int cardWidth READ cardWidth CONSTANT)
    Q_PROPERTY(int cardHeight READ cardHeight CONSTANT)
    Q_PROPERTY(int filterPanelWidth READ filterPanelWidth CONSTANT)
    Q_PROPERTY(int bookCoverWidth READ bookCoverWidth CONSTANT)
    Q_PROPERTY(int bookCoverHeight READ bookCoverHeight CONSTANT)
    Q_PROPERTY(int bookCoverAspectW READ bookCoverAspectW CONSTANT)
    Q_PROPERTY(int bookCoverAspectH READ bookCoverAspectH CONSTANT)
    Q_PROPERTY(int authorPhotoSize READ authorPhotoSize CONSTANT)
    Q_PROPERTY(int avatarSize READ avatarSize CONSTANT)

    // Spacing
    Q_PROPERTY(int spacingXS READ spacingXS CONSTANT)
    Q_PROPERTY(int spacingS READ spacingS CONSTANT)
    Q_PROPERTY(int spacingM READ spacingM CONSTANT)
    Q_PROPERTY(int spacingL READ spacingL CONSTANT)
    Q_PROPERTY(int spacingXL READ spacingXL CONSTANT)
    Q_PROPERTY(int spacingXXL READ spacingXXL CONSTANT)

    // Radius
    Q_PROPERTY(int radiusSharp READ radiusSharp CONSTANT)
    Q_PROPERTY(int radiusSoft READ radiusSoft CONSTANT)
    Q_PROPERTY(int radiusRound READ radiusRound CONSTANT)
    Q_PROPERTY(int radiusPill READ radiusPill CONSTANT)

    // Animation durations
    Q_PROPERTY(int animationFast READ animationFast CONSTANT)
    Q_PROPERTY(int animationNormal READ animationNormal CONSTANT)
    Q_PROPERTY(int animationSmooth READ animationSmooth CONSTANT)
    Q_PROPERTY(int animationSlow READ animationSlow CONSTANT)

public:
    explicit Theme(QObject *parent = nullptr);

    // Colors
    QColor bgBody() const { return QColor("#030303"); }
    QColor bgCard() const { return QColor(255, 255, 255, 3); }  // rgba(255,255,255,0.01)
    QColor glassPanel() const { return QColor(20, 20, 20, 150); }  // 60% opacity
    QColor borderLight() const { return QColor(255, 255, 255, 20); } // 8% opacity
    QColor borderHover() const { return QColor(255, 255, 255, 51); } // 20% opacity
    QColor textPrimary() const { return QColor("#ffffff"); }
    QColor textSecondary() const { return QColor("#888888"); }
    QColor textMuted() const { return QColor("#666666"); }
    QColor spotlightColor() const { return QColor(255, 255, 255, 30); } // 12% opacity
    QColor accentWhite() const { return QColor("#ffffff"); }
    QColor cardHover() const { return QColor(255, 255, 255, 13); } // 5% opacity
    QColor success() const { return QColor("#4CAF50"); }
    QColor info() const { return QColor("#2196F3"); }
    QColor warning() const { return QColor("#FF9800"); }
    QColor error() const { return QColor("#ff4444"); }

    // Fonts
    QFont fontDisplay() const;
    QFont fontDisplayItalic() const;
    QFont fontBody() const;
    QFont fontBodyLight() const;
    QFont fontCaption() const;
    QFont fontButton() const;

    // Sizes
    int dockWidth() const { return 100; }
    int headerHeight() const { return 100; }
    int cardWidth() const { return 280; }
    int cardHeight() const { return 460; }  // Увеличили чтобы влезла обложка 2:3 + текст
    int filterPanelWidth() const { return 400; }
    int bookCoverWidth() const { return 180; }
    int bookCoverHeight() const { return 240; }
    int bookCoverAspectW() const { return 2; }
    int bookCoverAspectH() const { return 3; }
    int authorPhotoSize() const { return 120; }
    int avatarSize() const { return 120; }

    // Spacing
    int spacingXS() const { return 4; }
    int spacingS() const { return 8; }
    int spacingM() const { return 16; }
    int spacingL() const { return 24; }
    int spacingXL() const { return 40; }
    int spacingXXL() const { return 60; }

    // Radius
    int radiusSharp() const { return 4; }
    int radiusSoft() const { return 8; }
    int radiusRound() const { return 50; } // percentage for circle
    int radiusPill() const { return 30; }  // pill shape

    // Animation
    int animationFast() const { return 200; }
    int animationNormal() const { return 300; }
    int animationSmooth() const { return 400; }
    int animationSlow() const { return 600; }
};

#endif // THEME_H
