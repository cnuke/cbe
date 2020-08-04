ifeq ($(called_from_lib_mk),yes)

CUSTOM_BINDER_FLAGS ?= -n -we -D768k

SRC_ADB := b~$(LIB).adb
SRC_ADS := dummy.ads

ALIS := $(addsuffix .ali, $(basename $(SRC_ADS) $(SRC_ADB)))
ALI_DIRS := $(foreach LIB,$(LIBS),$(call select_from_repositories,lib/ali/$(LIB)))
BINDER_SEARCH_DIRS = $(addprefix -I$(BUILD_BASE_DIR)/var/libcache/, $(LIBS)) $(addprefix -aO, $(ALI_DIRS))

BINDER_SRC := b~$(LIB).adb

$(BINDER_SRC): dummy.ali
	$(VERBOSE)$(GNATBIND) $(CUSTOM_BINDER_FLAGS) $(BINDER_SEARCH_DIRS) $(INCLUDES) --RTS=$(ADA_RTS) -o $@ $^

all: $(BINDER_SRC)

endif
