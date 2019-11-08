#!/bin/bash

KERNEL=linux BOARD=linux make run/cbe_clean || exit 1
CBE_IMAGE_SIZE=34 KERNEL=linux BOARD=linux make run/cbe_init | tee cbe_init.log || exit 1
KERNEL=linux BOARD=linux make run/cbe_test_write_full | tee cbe_test_write.log || exit 1

#make -C build/x86_64-cbe KERNEL=linux run/cbe_test_write1 || exit 1
#make -C build/x86_64-cbe KERNEL=linux run/cbe_test_read1 || exit 1

#make -C build/x86_64-cbe KERNEL=linux run/cbe_test_compare || exit 1
#make -C build/x86_64-cbe KERNEL=linux run/cbe_test_compare || exit 1
