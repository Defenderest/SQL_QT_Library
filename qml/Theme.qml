pragma Singleton
import QtQuick 2.15

QtObject {
    // === ЦВЕТА OBSIDIAN.LUXE ===
    readonly property color bgBody: "#030303"
    readonly property color bgCard: "rgba(255,255,255,0.01)"
    readonly property color glassPanel: "rgba(10, 10, 10, 0.85)"

    // Границы
    readonly property color borderLight: "rgba(255, 255, 255, 0.08)"
    readonly property color borderHover: "rgba(255, 255, 255, 0.2)"
    readonly property color borderDefault: "#333333"

    // Текст
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#888888"
    readonly property color textMuted: "#666666"
    readonly property color textDisabled: "#555555"

    // Акцент
    readonly property color accentWhite: "#ffffff"

    // Spotlight
    readonly property color spotlightColor: "rgba(255,255,255,0.06)"

    // === ШРИФТЫ ===
    // Display - Playfair Display для заголовков
    readonly property font fontDisplay: ({
        family: "Playfair Display",
        pixelSize: 20,
        weight: Font.Normal
    })

    readonly property font fontDisplayItalic: ({
        family: "Playfair Display",
        pixelSize: 28,
        weight: Font.Normal,
        italic: true
    })

    // Body - Inter для основного текста
    readonly property font fontBody: ({
        family: "Inter",
        pixelSize: 14,
        weight: Font.Light
    })

    // Body Light - Inter Light для описаний
    readonly property font fontBodyLight: ({
        family: "Inter",
        pixelSize: 14,
        weight: Font.ExtraLight
    })

    // Caption - для меток
    readonly property font fontCaption: ({
        family: "Inter",
        pixelSize: 10,
        weight: Font.Normal
    })

    // === РАЗМЕРЫ ===
    readonly property int sidebarWidth: 100
    readonly property int dockWidth: 80  // Ширина боковой панели
    readonly property int topBarHeight: 100
    readonly property int headerHeight: 80  // Высота верхней панели
    readonly property int filterPanelWidth: 400

    // Карточки книг
    readonly property int cardWidth: 200
    readonly property int cardHeight: 400
    readonly property int coverWidth: 180
    readonly property int coverHeight: 270  // 2:3 ratio

    // Размеры для страниц
    readonly property int authorPhotoSize: 200
    readonly property int bookCoverWidth: 280
    readonly property int bookCoverHeight: 420
    readonly property color cardHover: "rgba(255,255,255,0.05)"

    // Цвета статусов
    readonly property color success: "#4CAF50"
    readonly property color info: "#2196F3"
    readonly property color error: "#F44336"
    readonly property color warning: "#FF9800"

    // === ОТСТУПЫ ===
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 20
    readonly property int spacingXL: 30
    readonly property int spacingXXL: 60

    // === СКРУГЛЕНИЯ ===
    readonly property int radiusSharp: 4
    readonly property int radiusSoft: 8
    readonly property int radiusRound: 20
    readonly property int radiusPill: 30

    // === АНИМАЦИИ ===
    readonly property int animationFast: 150
    readonly property int animationNormal: 300
    readonly property int animationSmooth: 400
    readonly property int animationSlow: 600
}
