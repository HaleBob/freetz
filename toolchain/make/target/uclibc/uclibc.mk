UCLIBC_VERSION:=$(TARGET_TOOLCHAIN_UCLIBC_VERSION)
UCLIBC_DIR:=$(TARGET_TOOLCHAIN_DIR)/uClibc-$(UCLIBC_VERSION)
UCLIBC_MAKE_DIR:=$(TOOLCHAIN_DIR)/make/target/uclibc
UCLIBC_SOURCE:=uClibc-$(UCLIBC_VERSION).tar.bz2
UCLIBC_SOURCE_SITE:=http://www.uclibc.org/downloads$(if $(or $(FREETZ_TARGET_UCLIBC_VERSION_0_9_28),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_29)),/old-releases)

UCLIBC_MD5_0.9.28   = 1ada58d919a82561061e4741fb6abd29
UCLIBC_MD5_0.9.29   = 61dc55f43b17a38a074f347e74095b20
UCLIBC_MD5_0.9.30.3 = 73a4bf4a0fa508b01a7a3143574e3d21
UCLIBC_MD5_0.9.31.1 = c86d7665ce9653e5335d76871f46747d
UCLIBC_MD5_0.9.32.1 = ade6e441242be5cdd735fec97954a54a
UCLIBC_MD5_0.9.33   = cf9d25e4b3c87af1a99d33a6b959fbf1
UCLIBC_MD5=$(UCLIBC_MD5_$(UCLIBC_VERSION))

UCLIBC_KERNEL_HEADERS_DIR:=$(KERNEL_HEADERS_DEVEL_DIR)

UCLIBC_DEVEL_SUBDIR:=uClibc_dev

# uClibc >= 0.9.31 supports parallel building
UCLIBC_MAKE:=$(if $(or $(FREETZ_TARGET_UCLIBC_VERSION_0_9_31),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_32),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_33)),$(MAKE),$(MAKE1))

# uClibc pregenerated locale data
UCLIBC_LOCALE_DATA_SITE:=http://www.uclibc.org/downloads
# TODO: FREETZ_TARGET_UCLIBC_REDUCED_LOCALE_SET is a REBUILD_SUBOPT
ifeq ($(strip $(FREETZ_TARGET_UCLIBC_REDUCED_LOCALE_SET)),y)
UCLIBC_LOCALE_DATA_FILENAME:=uClibc-locale-$(if $(FREETZ_TARGET_ARCH_BE),be,le)-32-de_DE-en_US.tar.gz
else
UCLIBC_LOCALE_DATA_FILENAME:=uClibc-locale-030818.tgz
endif
UCLIBC_COMMON_BUILD_FLAGS := LOCALE_DATA_FILENAME=$(UCLIBC_LOCALE_DATA_FILENAME)

ifeq ($(strip $(FREETZ_VERBOSITY_LEVEL)),2)
ifeq ($(or $(FREETZ_TARGET_UCLIBC_VERSION_0_9_32),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_33)),y)
# Changed with uClibc-0.9.32-rc3: "V=1 is quiet plus defines. V=2 are verbatim commands."
# For more details see <http://lists.uclibc.org/pipermail/uclibc/2011-March/045005.html>
UCLIBC_COMMON_BUILD_FLAGS += V=2
else
UCLIBC_COMMON_BUILD_FLAGS += V=1
endif
endif

UCLIBC_HOST_CFLAGS:=$(TOOLCHAIN_HOST_CFLAGS) -U_GNU_SOURCE -fno-strict-aliasing

$(DL_DIR)/$(UCLIBC_LOCALE_DATA_FILENAME): | $(DL_DIR)
	$(DL_TOOL) $(DL_DIR) $(UCLIBC_LOCALE_DATA_FILENAME) $(UCLIBC_LOCALE_DATA_SITE)

uclibc-source: $(DL_DIR)/$(UCLIBC_SOURCE)
$(DL_DIR)/$(UCLIBC_SOURCE): | $(DL_DIR)
	$(DL_TOOL) $(DL_DIR) $(UCLIBC_SOURCE) $(UCLIBC_SOURCE_SITE) $(UCLIBC_MD5)

uclibc-unpacked: $(UCLIBC_DIR)/.unpacked
$(UCLIBC_DIR)/.unpacked: $(DL_DIR)/$(UCLIBC_SOURCE) $(DL_DIR)/$(UCLIBC_LOCALE_DATA_FILENAME) | $(TARGET_TOOLCHAIN_DIR)
	$(RM) -r $(UCLIBC_DIR)
	tar -C $(TARGET_TOOLCHAIN_DIR) $(VERBOSE) -xf $(DL_DIR)/$(UCLIBC_SOURCE)
	set -e; \
	for i in $(UCLIBC_MAKE_DIR)/$(UCLIBC_VERSION)/*.patch; do \
		$(PATCH_TOOL) $(UCLIBC_DIR) $$i; \
	done
	cp -dpf $(DL_DIR)/$(UCLIBC_LOCALE_DATA_FILENAME) $(UCLIBC_DIR)/extra/locale/
	touch $@

$(UCLIBC_DIR)/.config: $(UCLIBC_DIR)/.unpacked
	cp $(TOOLCHAIN_DIR)/make/target/uclibc/Config.$(TARGET_TOOLCHAIN_UCLIBC_REF).$(UCLIBC_VERSION) $(UCLIBC_DIR)/.config
	$(call PKG_EDIT_CONFIG,CROSS=$(TARGET_MAKE_PATH)/$(TARGET_CROSS)) $(UCLIBC_DIR)/Rules.mak
	$(call PKG_EDIT_CONFIG, \
		$(if $(FREETZ_TARGET_UCLIBC_VERSION_0_9_28), \
			KERNEL_SOURCE=\"$(UCLIBC_KERNEL_HEADERS_DIR)\" \
		, \
			KERNEL_HEADERS=\"$(UCLIBC_KERNEL_HEADERS_DIR)/include\" \
			ARCH_WANTS_LITTLE_ENDIAN=$(if $(FREETZ_TARGET_ARCH_BE),n,y) \
			ARCH_WANTS_BIG_ENDIAN=$(if $(FREETZ_TARGET_ARCH_BE),y,n) \
		) \
		CONFIG_MIPS_ISA_MIPS32_4KC=$(if $(FREETZ_TARGET_ARCH_LE),y,n) \
		CONFIG_MIPS_ISA_MIPS32_24KC=$(if $(FREETZ_TARGET_ARCH_BE),y,n) \
		UCLIBC_HAS_IPV6=$(FREETZ_TARGET_IPV6_SUPPORT) \
		UCLIBC_HAS_LFS=$(FREETZ_TARGET_LFS) \
		UCLIBC_HAS_FOPEN_LARGEFILE_MODE=n \
		UCLIBC_HAS_WCHAR=y \
	) $(UCLIBC_DIR)/.config

	mkdir -p $(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/usr/include
	mkdir -p $(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/usr/lib
	mkdir -p $(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/lib
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		HOSTCC="$(TOOLCHAIN_HOSTCC) $(UCLIBC_HOST_CFLAGS)" \
		oldconfig < /dev/null > /dev/null
	touch $@

$(UCLIBC_DIR)/.configured: $(UCLIBC_DIR)/.config | $(UCLIBC_KERNEL_HEADERS_DIR)/include/linux/version.h
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		HOSTCC="$(TOOLCHAIN_HOSTCC) $(UCLIBC_HOST_CFLAGS)" headers \
		$(if $(FREETZ_TARGET_UCLIBC_VERSION_0_9_28),install_dev,install_headers)
	touch $@

uclibc-menuconfig: $(UCLIBC_DIR)/.config
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TARGET_TOOLCHAIN_DIR)/$(UCLIBC_DEVEL_SUBDIR)/ \
		HOSTCC="$(TOOLCHAIN_HOSTCC) $(UCLIBC_HOST_CFLAGS)" \
		menuconfig && \
	cp -f $^ $(TOOLCHAIN_DIR)/make/target/uclibc/Config.$(TARGET_TOOLCHAIN_UCLIBC_REF).$(UCLIBC_VERSION) && \
	touch $^

$(UCLIBC_DIR)/lib/libc.a: $(UCLIBC_DIR)/.configured $(GCC_BUILD_DIR1)/.installed
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX= \
		DEVEL_PREFIX=/ \
		RUNTIME_PREFIX=/ \
		HOSTCC="$(TOOLCHAIN_HOSTCC) $(UCLIBC_HOST_CFLAGS)" \
		all
ifeq ($(or $(FREETZ_TARGET_UCLIBC_VERSION_0_9_30),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_31),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_32),$(FREETZ_TARGET_UCLIBC_VERSION_0_9_33)),y)
	# At this point uClibc is compiled and there is no reason for us to recompile it.
	# Remove some FORCE rule dependencies causing parts of uClibc to be recompiled (without a need)
	# over and over again each time make is invoked within uClibc dir (the actual target doesn't matter).
	# This is a bit dirty workaround we actually should get rid of as soon as we find a better solution.
	for i in $(UCLIBC_DIR)/Makerules $(UCLIBC_DIR)/extra/locale/Makefile.in; do \
		cp -a "$$i" "$$i-with-FORCE"; \
		sed -i -r -e '/.*%[.]o[sS]:.*FORCE.*/s, FORCE , ,g' $$i; \
	done;
endif
	touch -c $@

ifeq ($(strip $(FREETZ_BUILD_TOOLCHAIN)),y)
UCLIBC_PREREQ=$(GCC_BUILD_DIR1)/.installed
$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a: $(UCLIBC_DIR)/lib/libc.a
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=/ \
		DEVEL_PREFIX=$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/ \
		RUNTIME_PREFIX=$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/ \
		install_runtime install_dev
	# Copy some files to make mklibs happy
ifneq ($(strip $(UCLIBC_VERSION)),0.9.28)
	for f in libc_pic.a libdl_pic.a libpthread_pic.a; do \
		$(RM) $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/$$f; \
	done; \
	cp $(UCLIBC_DIR)/libc/libc_so.a $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/libc_pic.a; \
	cp $(UCLIBC_DIR)/libpthread/*/libpthread_so.a $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/libpthread_pic.a ; \
	cp $(UCLIBC_DIR)/ldso/libdl/libdl_so.a $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/libdl_pic.a
endif
	# Build the host utils.
	# Note: in order the host utils to work the __ELF_NATIVE_CLASS (= __WORDSIZE) of the host
	# must match that of the target. That's the reason we hardcode the "-m32" option here.
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR)/utils \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=$(TARGET_TOOLCHAIN_STAGING_DIR) \
		HOSTCC="$(TOOLCHAIN_HOSTCC) $(UCLIBC_HOST_CFLAGS) -m32" \
		BUILD_LDFLAGS="$(if $(FREETZ_TOOLCHAIN_STATIC),-static)" \
		hostutils
	for i in ldd ldconfig; do \
		install -c $(UCLIBC_DIR)/utils/$$i.host $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)/bin/$$i; \
		$(HOST_STRIP) $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)/bin/$$i; \
		ln -sf ../$(REAL_GNU_TARGET_NAME)/bin/$$i $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-$$i; \
		ln -sf $(REAL_GNU_TARGET_NAME)-$$i $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-$$i; \
	done
	touch -c $@

$(TARGET_SPECIFIC_ROOT_DIR)/lib/libc.so.0: $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX="$(FREETZ_BASE_DIR)/$(TARGET_SPECIFIC_ROOT_DIR)" \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		install_runtime
	touch -c $@
else
UCLIBC_PREREQ=$(TARGET_CROSS_COMPILER)
$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a: $(TARGET_CROSS_COMPILER)
	touch -c $@

$(TARGET_SPECIFIC_ROOT_DIR)/lib/libc.so.0: $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a
	@$(RM) -r $(TARGET_SPECIFIC_ROOT_DIR)/lib
	@mkdir -p $(TARGET_SPECIFIC_ROOT_DIR)/lib
	for i in $(UCLIBC_FILES); do \
		cp -a $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/$$i $(TARGET_SPECIFIC_ROOT_DIR)/lib/$$i; \
	done
	ln -sf libuClibc-$(UCLIBC_VERSION).so $(TARGET_SPECIFIC_ROOT_DIR)/lib/libc.so
	touch -c $@
endif

uclibc-configured: kernel-configured $(UCLIBC_DIR)/.configured

uclibc: $(UCLIBC_PREREQ) $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a $(TARGET_SPECIFIC_ROOT_DIR)/lib/libc.so.0

uclibc-configured-source: uclibc-source

uclibc-clean:
	-$(MAKE1) -C $(UCLIBC_DIR) clean
	$(RM) $(UCLIBC_DIR)/.config

uclibc-dirclean:
	$(RM) -r $(UCLIBC_DIR)

.PHONY: uclibc-configured uclibc

#############################################################
#
# uClibc for the target
#
#############################################################

$(TARGET_UTILS_DIR)/usr/lib/libc.a: $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/libc.a
	$(UCLIBC_MAKE) -C $(UCLIBC_DIR) \
		$(UCLIBC_COMMON_BUILD_FLAGS) \
		PREFIX=$(TARGET_UTILS_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		RUNTIME_PREFIX_LIB_FROM_DEVEL_PREFIX_LIB=/lib/ \
		install_dev
	# create two additional symlinks, required because libc.so is not really
	# a shared lib, but a GNU ld script referencing the libs below
	for f in libc.so.0 ld-uClibc.so.0; do \
		ln -fs /lib/$$f $(TARGET_UTILS_DIR)/usr/lib/; \
	done
	$(call COPY_KERNEL_HEADERS,$(UCLIBC_KERNEL_HEADERS_DIR),$(TARGET_UTILS_DIR)/usr)
	$(call REMOVE_DOC_NLS_DIRS,$(TARGET_UTILS_DIR))
	touch -c $@

uclibc_target: gcc uclibc $(TARGET_UTILS_DIR)/usr/lib/libc.a

uclibc_target-clean: uclibc_target-dirclean
	$(RM) $(TARGET_UTILS_DIR)/lib/libc.a

uclibc_target-dirclean:
	$(RM) -r $(TARGET_UTILS_DIR)/usr/include
