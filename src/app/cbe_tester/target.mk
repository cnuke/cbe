REQUIRES := x86_64

TARGET  := cbe_tester
SRC_CC  := main.cc

# force binder for adainit
SRC_ADS := dummy.ads
LIBS    += spark

INC_DIR := $(PRG_DIR)
LIBS    += base cbe cbe_cxx sha256_4k external_crypto external_crypto_cxx
LIBS    += cbe_init cbe_init_cxx cbe_check cbe_check_cxx cbe_dump cbe_dump_cxx
