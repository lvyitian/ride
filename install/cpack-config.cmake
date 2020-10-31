INCLUDE(InstallRequiredSystemLibraries)
# INSTALL(FILES ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} DESTINATION bin COMPONENT Libraries)

SET(CPACK_PACKAGE_VERSION_MAJOR "${RIDE_VERSION_MAJOR}")
SET(CPACK_PACKAGE_VERSION_MINOR "${RIDE_VERSION_MINOR}")
SET(CPACK_PACKAGE_VERSION_PATCH "${RIDE_VERSION_REVISION}")


SET(CPACK_PACKAGE_NAME "Ride")
SET(CPACK_PACKAGE_DESCRIPTION "Ride")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Ride is good program")
SET(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
SET(CPACK_PACKAGE_FILE_NAME "ride-${CPACK_PACKAGE_VERSION}")
SET(CPACK_RESOURCE_FILE_LICENSE  "${PROJECT_SOURCE_DIR}/install/LICENSE.txt")
SET(CPACK_PACKAGE_EXECUTABLES  "ride;Ride ${CPACK_PACKAGE_VERSION}")

SET(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_INSTALL_PREFIX}")


MESSAGE(STATUS "Setting cpack paths to ${PROJECT_SOURCE_DIR}/install/gfx/")
SET(CPACK_DMG_BACKGROUND_IMAGE "${PROJECT_SOURCE_DIR}/install/gfx/dmg-install.png")
SET(CPACK_DMG_DS_STORE "${PROJECT_SOURCE_DIR}/install/gfx/ds_store")

IF(${APPLE})
  SET(CPACK_GENERATOR DragNDrop)
ENDIF()

# nsis setup
SET(NSIS_WIZARD_BMP "${PROJECT_SOURCE_DIR}/install/gfx/nsis-wizard.bmp")
SET(NSIS_HEADER_BMP "${PROJECT_SOURCE_DIR}/install/gfx/nsis-header.bmp")
SET(NSIS_INSTALLER_ICON "${PROJECT_SOURCE_DIR}/ride/resources/application.ico")
string(REGEX REPLACE "/" "\\\\\\\\" NSIS_WIZARD_BMP "${NSIS_WIZARD_BMP}")
string(REGEX REPLACE "/" "\\\\\\\\" NSIS_HEADER_BMP "${NSIS_HEADER_BMP}")
string(REGEX REPLACE "/" "\\\\\\\\" NSIS_INSTALLER_ICON "${NSIS_INSTALLER_ICON}")
SET(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
SET(CPACK_NSIS_MUI_ICON "${PROJECT_SOURCE_DIR}/runner/resources/application.ico")
SET(CPACK_NSIS_MUI_UNIICON "${PROJECT_SOURCE_DIR}/runner/resources/application.ico")
SET(CPACK_NSIS_INSTALLED_ICON_NAME "ride.exe")
SET(CPACK_NSIS_HELP_LINK "http://madeso.github.io/ride")
SET(CPACK_NSIS_URL_INFO_ABOUT "http://madeso.github.io/ride")
SET(CPACK_NSIS_MUI_FINISHPAGE_RUN "ride.exe")
SET(CPACK_NSIS_EXECUTABLES_DIRECTORY ".") # https://cmake.org/Bug/view.php?id=7829
SET(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "
!define MUI_HEADERIMAGE_BITMAP \\\"${NSIS_HEADER_BMP}\\\"
!define MUI_HEADERIMAGE_UNBITMAP \\\"${NSIS_HEADER_BMP}\\\"
!define MUI_WELCOMEFINISHPAGE_BITMAP \\\"${NSIS_WIZARD_BMP}\\\"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP \\\"${NSIS_WIZARD_BMP}\\\"
Icon \\\"${NSIS_INSTALLER_ICON}\\\"
BrandingText \\\" \\\"
") 
#old thread, is this still needed?
if(X64)
    # http://public.kitware.com/Bug/view.php?id=9094
    set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
endif()

# wix setup
SET(CPACK_WIX_UPGRADE_GUID "AF8E1C30-9FE1-4AF0-A9B8-DCC9ECD57CF6")
SET(CPACK_WIX_LICENSE_RTF "${PROJECT_SOURCE_DIR}/install/LICENSE.rtf")
SET(CPACK_WIX_PRODUCT_ICON "${PROJECT_SOURCE_DIR}/runner/resources/application.ico")
SET(CPACK_WIX_UI_BANNER "${PROJECT_SOURCE_DIR}/install/gfx/wix-banner.bmp")
SET(CPACK_WIX_UI_DIALOG "${PROJECT_SOURCE_DIR}/install/gfx/wix-dialog.bmp")

IF(${WIN32})
  SET(CPACK_GENERATOR NSIS;WIX)
ENDIF()

MESSAGE(STATUS "Install generators are ${CPACK_GENERATOR}")

# this must always be last
INCLUDE(CPack)
