SRC_CC = vfs.cc

LIBS += spark cbe cbe_cxx sha256_4k external_crypto external_crypto_cxx
LIBS += external_trust_anchor external_trust_anchor_cxx

vpath % $(REP_DIR)/src/lib/vfs/cbe

SHARED_LIB = yes

CC_CXX_WARN_STRICT :=

include $(REP_DIR)/lib/mk/generate_ada_main_pkg.inc
