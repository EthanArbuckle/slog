TARGET := iphone:clang:latest:7.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = slog

slog_FILES = main.m
slog_CFLAGS = -fobjc-arc -lObjc
slog_FRAMEWORKS = Foundation
slog_CODESIGN_FLAGS = -Sentitlements.plist
slog_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
