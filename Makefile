TARGET := iphone:clang:latest:15.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := roothide
INSTALL_TARGET_PROCESSES := SpringBoard Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := NativeDepthUnlock
NativeDepthUnlock_FILES := Tweak.xm
NativeDepthUnlock_CFLAGS := -fobjc-arc
NativeDepthUnlock_FRAMEWORKS := Foundation CoreFoundation
NativeDepthUnlock_LIBRARIES := substrate

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME := NativeDepthUnlockPrefs
NativeDepthUnlockPrefs_FILES := NDRootListController.m
NativeDepthUnlockPrefs_FRAMEWORKS := UIKit
NativeDepthUnlockPrefs_PRIVATE_FRAMEWORKS := Preferences
NativeDepthUnlockPrefs_INSTALL_PATH := /Library/PreferenceBundles
NativeDepthUnlockPrefs_BUNDLE_RESOURCE_DIRS := Resources
NativeDepthUnlockPrefs_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp PreferenceEntry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NativeDepthUnlockPrefs.plist$(ECHO_END)
