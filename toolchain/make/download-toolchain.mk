include $(TOOLCHAIN_DIR)/make/kernel/ccache/ccache.mk
include $(TOOLCHAIN_DIR)/make/target/ccache/ccache.mk
include $(TOOLCHAIN_DIR)/make/target/libtool-host/libtool-host.mk
include $(TOOLCHAIN_DIR)/make/target/uclibc/uclibc.mk

ifeq ($(strip $(FREETZ_TOOLCHAIN_CCACHE)),y)
	CCACHE:=ccache-kernel ccache
endif

KERNEL_TOOLCHAIN_MD5_mipsel_3.4.6:=6b4bea759a111f39821310d82702099b
KERNEL_TOOLCHAIN_MD5_mips_4.4.6:=865b9bed7aa07565e1d229ec7c73b3f9
KERNEL_TOOLCHAIN_MD5_mipsel_4.4.6:=e3b0410b9e3f6517dac99dd175ed1a46
KERNEL_TOOLCHAIN_MD5:=$(KERNEL_TOOLCHAIN_MD5_$(TARGET_ARCH)_$(KERNEL_TOOLCHAIN_GCC_VERSION))

KERNEL_TOOLCHAIN_VERSION:=r8342
KERNEL_TOOLCHAIN_SOURCE:=$(TARGET_ARCH)_gcc-$(KERNEL_TOOLCHAIN_GCC_VERSION)-freetz-$(KERNEL_TOOLCHAIN_VERSION)-shared-glibc.tar.lzma

TARGET_TOOLCHAIN_ID:=$(TARGET_ARCH)_$(TARGET_TOOLCHAIN_GCC_VERSION)_$(TARGET_TOOLCHAIN_UCLIBC_VERSION)

# 4.5
TARGET_TOOLCHAIN_MD5_mipsel_4.5.3_0.9.28:=a7c5d1f9c30d14416564267c2572e054
TARGET_TOOLCHAIN_MD5_mipsel_4.5.3_0.9.29:=8be1a291865a549cca9c81522c9b44e8
TARGET_TOOLCHAIN_MD5_mips_4.5.3_0.9.30.3:=4a3ae57cb6e9c826d66e9d79b2a7fca8
TARGET_TOOLCHAIN_MD5_mips_4.5.3_0.9.31.1:=c68545d9ec6ee419720dacce4092ae20
TARGET_TOOLCHAIN_MD5_mipsel_4.5.3_0.9.31.1:=55124c826e2a187c886fdc3585711795
TARGET_TOOLCHAIN_MD5_mips_4.5.3_0.9.32.1:=e40834c638bea7b019251fd0b82f396a
TARGET_TOOLCHAIN_MD5_mipsel_4.5.3_0.9.32.1:=d2347262e4ee79ae09d7cc6f55e7cc6c
# 4.6
TARGET_TOOLCHAIN_MD5_mipsel_4.6.2_0.9.28:=d3f9035b88c521f3eb60ca9dc7c1c1ff
TARGET_TOOLCHAIN_MD5_mipsel_4.6.2_0.9.29:=9b7909664c7e3bb54526c725f075f4a1
TARGET_TOOLCHAIN_MD5_mips_4.6.2_0.9.30.3:=ab63c45a2c7d7a7020bf1c79a70f0612
TARGET_TOOLCHAIN_MD5_mips_4.6.2_0.9.31.1:=e60753d204e9ae73a44207440d0a0152
TARGET_TOOLCHAIN_MD5_mipsel_4.6.2_0.9.31.1:=6f4eef6892b8aee4c1082bd9a8f3816b
TARGET_TOOLCHAIN_MD5_mips_4.6.2_0.9.32.1:=a6ac7a57cc4e84e29207792aa26e0f8b
TARGET_TOOLCHAIN_MD5_mipsel_4.6.2_0.9.32.1:=447423ef9c529d602a874c0e197404a9
TARGET_TOOLCHAIN_MD5:=$(TARGET_TOOLCHAIN_MD5_$(TARGET_TOOLCHAIN_ID))

TARGET_TOOLCHAIN_VERSION_mips_4.5.3_0.9.32.1:=r8424
TARGET_TOOLCHAIN_VERSION_mipsel_4.5.3_0.9.32.1:=r8424
TARGET_TOOLCHAIN_VERSION_mips_4.6.2_0.9.32.1:=r8424
TARGET_TOOLCHAIN_VERSION_mipsel_4.6.2_0.9.32.1:=r8424
TARGET_TOOLCHAIN_VERSION:=$(or $(TARGET_TOOLCHAIN_VERSION_$(TARGET_TOOLCHAIN_ID)),r8367)
TARGET_TOOLCHAIN_SOURCE:=$(TARGET_ARCH)_gcc-$(TARGET_TOOLCHAIN_GCC_VERSION)_uClibc-$(TARGET_TOOLCHAIN_UCLIBC_VERSION)-freetz-$(TARGET_TOOLCHAIN_VERSION)-shared-glibc.tar.lzma

$(KERNEL_TOOLCHAIN_DIR):
	@mkdir -p $@

$(TARGET_TOOLCHAIN_DIR):
	@mkdir -p $@

$(DL_DIR)/$(KERNEL_TOOLCHAIN_SOURCE): | $(DL_DIR)
	@$(DL_TOOL) $(DL_DIR) $(KERNEL_TOOLCHAIN_SOURCE) "" $(KERNEL_TOOLCHAIN_MD5)

$(DL_DIR)/$(TARGET_TOOLCHAIN_SOURCE): | $(DL_DIR)
	@$(DL_TOOL) $(DL_DIR) $(TARGET_TOOLCHAIN_SOURCE) "" $(TARGET_TOOLCHAIN_MD5)

download-toolchain: $(KERNEL_CROSS_COMPILER) kernel-configured \
			$(TARGET_CROSS_COMPILER) target-toolchain-kernel-headers \
			$(TARGET_SPECIFIC_ROOT_DIR)/lib/libc.so.0 \
			$(CCACHE) $(STDCXXLIB) $(TARGET_CXX_CROSS_COMPILER_SYMLINK_TIMESTAMP) libtool-host $(if $(FREETZ_PACKAGE_GDB_HOST),gdbhost)

gcc-kernel: $(KERNEL_CROSS_COMPILER)
$(KERNEL_CROSS_COMPILER): $(DL_DIR)/$(KERNEL_TOOLCHAIN_SOURCE) | \
		$(KERNEL_TOOLCHAIN_SYMLINK_DOT_FILE) $(TOOLS_DIR)/busybox
	mkdir -p $(TOOLCHAIN_DIR)/build
	$(RM) -r $(TOOLCHAIN_BUILD_DIR)/$(KERNEL_TOOLCHAIN_COMPILER)
	$(TOOLS_DIR)/busybox tar $(VERBOSE) -xf $(DL_DIR)/$(KERNEL_TOOLCHAIN_SOURCE) -C $(TOOLCHAIN_DIR)/build
	@touch $@

gcc: $(TARGET_CROSS_COMPILER)
$(TARGET_CROSS_COMPILER): $(DL_DIR)/$(TARGET_TOOLCHAIN_SOURCE) | \
		$(TARGET_TOOLCHAIN_SYMLINK_DOT_FILE) $(TOOLS_DIR)/busybox
	mkdir -p $(TOOLCHAIN_DIR)/build
	$(RM) -r $(TOOLCHAIN_BUILD_DIR)/$(TARGET_TOOLCHAIN_COMPILER)
	$(TOOLS_DIR)/busybox tar $(VERBOSE) -xf $(DL_DIR)/$(TARGET_TOOLCHAIN_SOURCE) -C $(TOOLCHAIN_DIR)/build
	@touch $@

download-toolchain-clean:

download-toolchain-dirclean: kernel-toolchain-dirclean target-toolchain-dirclean

download-toolchain-distclean: kernel-toolchain-distclean target-toolchain-distclean

kernel-toolchain-dirclean:

target-toolchain-dirclean:

.PHONY: gcc-kernel gcc
