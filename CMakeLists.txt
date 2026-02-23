# Минимальная версия CMake
cmake_minimum_required(VERSION 3.16)

# Название проекта, версия и язык
project(Library VERSION 0.1 LANGUAGES CXX)

# Включаем автоматическую обработку MOC и RCC (UIC больше не нужен)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC OFF)
set(CMAKE_AUTORCC ON)

# Устанавливаем стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# --- Поиск Qt ---
# Ищем Qt6 или Qt5 и запрашиваем ВСЕ необходимые компоненты СРАЗУ.
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Sql Widgets Quick QuickControls2 Network WebEngineQuick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Sql Widgets Quick QuickControls2 Network WebEngineQuick)

# Добавляем текущую директорию в пути поиска заголовочных файлов
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/dialogs
    ${CMAKE_CURRENT_SOURCE_DIR}/models
    ${CMAKE_CURRENT_SOURCE_DIR}/utils
    ${CMAKE_CURRENT_SOURCE_DIR}/widgets
    ${CMAKE_CURRENT_SOURCE_DIR}/qml_models
)

# --- Список исходных файлов ---
set(PROJECT_SOURCES
    main.cpp
    core/database.h
    core/bookfiltermanager.h
    models/database_connection.cpp
    models/database_customer.cpp
    models/database_book.cpp
    models/database_author.cpp
    models/database_order.cpp
    models/database_comment.cpp
    models/database_cart.cpp
    models/database_admin.cpp
    models/datatypes.h
    # QML Models
    qml_models/appcontext.cpp
    qml_models/booklistmodel.cpp
    qml_models/bookdetailsmodel.cpp
    qml_models/authorlistmodel.cpp
    qml_models/authordetailsmodel.cpp
    qml_models/cartmodel.cpp
    qml_models/ordersmodel.cpp
    qml_models/profilemodel.cpp
    qml_models/adminmodel.h
    qml_models/adminmodel.cpp
    qml_models/theme.cpp
    # Dialogs
    dialogs/logindialog.cpp
    dialogs/logindialog.h
    utils/testdata.cpp
    utils/testdata.h
    utils/searchsuggestiondelegate.cpp
    utils/searchsuggestiondelegate.h
    widgets/starratingwidget.cpp
    widgets/starratingwidget.h
    widgets/RangeSlider.cpp
    widgets/RangeSlider.h
)

# --- Создание исполняемого файла ---
if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(untitled
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
        resourses.qrc
        qml/qml.qrc
    )
else()
    if(ANDROID)
        add_library(untitled SHARED
            ${PROJECT_SOURCES}
            resourses.qrc
            qml/qml.qrc
        )
    else()
        add_executable(untitled
            ${PROJECT_SOURCES}
            resourses.qrc
            qml/qml.qrc
        )
    endif()
endif()

# --- Линковка с библиотеками Qt ---
target_link_libraries(untitled PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Sql
    Qt${QT_VERSION_MAJOR}::Widgets
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::QuickControls2
    Qt${QT_VERSION_MAJOR}::Network
    Qt${QT_VERSION_MAJOR}::WebEngineQuick
)

# --- Копирование SQL файлов в директорию сборки ---
add_custom_command(TARGET untitled POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/sql
    ${CMAKE_CURRENT_BINARY_DIR}/sql
    COMMENT "Copying SQL files to build directory..."
)

# --- Настройки для платформ ---
if(${QT_VERSION} VERSION_LESS 6.1.0 AND (APPLE OR CMAKE_SYSTEM_NAME STREQUAL "iOS"))
    set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.untitled)
endif()
set_target_properties(untitled PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    WIN32_EXECUTABLE TRUE
)

# --- Установка ---
include(GNUInstallDirs)
install(TARGETS untitled
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# --- Встановлення SQL файлів ---
install(FILES
    sql/schema.sql
    sql/author_queries.sql
    sql/book_queries.sql
    sql/cart_queries.sql
    sql/comment_queries.sql
    sql/customer_queries.sql
    sql/order_queries.sql
    sql/functions/calculate_average_rating.sql
    sql/award_loyalty_trigger.sql
    DESTINATION ${CMAKE_INSTALL_BINDIR}/sql
)

# --- Финализация для Qt 6 ---
if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(untitled)
endif()
