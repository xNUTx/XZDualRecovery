LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_CFLAGS += -std=c99
LOCAL_MODULE    := writekmem
LOCAL_SRC_FILES := writekmem.c

include $(BUILD_EXECUTABLE)
