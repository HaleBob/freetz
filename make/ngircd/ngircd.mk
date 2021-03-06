$(call PKG_INIT_BIN,18)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.gz
$(PKG)_SOURCE_MD5:=4958c8b2d128cf3e9888af3f782892a1
$(PKG)_SITE:=ftp://ftp.berlios.de/pub/$(pkg)

$(PKG)_BINARY:=$($(PKG)_DIR)/src/$(pkg)/$(pkg)
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/$(pkg)

$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_NGIRCD_WITH_TCP_WRAPPERS
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_NGIRCD_WITH_ZLIB
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_NGIRCD_WITH_SSL
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_NGIRCD_STATIC
$(PKG)_REBUILD_SUBOPTS += FREETZ_TARGET_IPV6_SUPPORT

ifeq ($(strip $(FREETZ_PACKAGE_NGIRCD_WITH_TCP_WRAPPERS)),y)
$(PKG)_DEPENDS_ON += tcp_wrappers
endif

ifeq ($(strip $(FREETZ_PACKAGE_NGIRCD_WITH_ZLIB)),y)
$(PKG)_DEPENDS_ON += zlib
endif

ifeq ($(strip $(FREETZ_PACKAGE_NGIRCD_WITH_SSL)),y)
$(PKG)_DEPENDS_ON += openssl
endif

ifeq ($(strip $(FREETZ_PACKAGE_NGIRCD_STATIC)),y)
$(PKG)_LDFLAGS += -static
endif

$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_NGIRCD_WITH_TCP_WRAPPERS),--with-tcp-wrappers,--without-tcp-wrappers)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_NGIRCD_WITH_ZLIB),--with-zlib,--without-zlib)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_NGIRCD_WITH_SSL),--with-openssl,--without-openssl)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_TARGET_IPV6_SUPPORT),--enable-ipv6,--disable-ipv6)
$(PKG)_CONFIGURE_OPTIONS += --with-syslog
$(PKG)_CONFIGURE_OPTIONS += --without-ident
$(PKG)_CONFIGURE_OPTIONS += --without-kqueue
$(PKG)_CONFIGURE_OPTIONS += --with-pam=no
$(PKG)_CONFIGURE_OPTIONS += --with-gnutls=no

#$(PKG)_CONFIGURE_OPTIONS += --enable-sniffer
#$(PKG)_CONFIGURE_OPTIONS += --enable-debug

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(NGIRCD_DIR) \
		LDFLAGS="$(TARGET_LDFLAGS) $(NGIRCD_LDFLAGS)"

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	-$(SUBMAKE) -C $(NGIRCD_DIR) clean
	$(RM) $(NGIRCD_FREETZ_CONFIG_FILE)

$(pkg)-uninstall:
	$(RM) $(NGIRCD_TARGET_BINARY)

$(PKG_FINISH)
