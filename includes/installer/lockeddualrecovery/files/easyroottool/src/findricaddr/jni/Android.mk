LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := findricaddr
LOCAL_SRC_FILES := findricaddr.c

include $(BUILD_EXECUTABLE)
