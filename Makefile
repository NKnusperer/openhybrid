# OpenHybrid - an open GRE tunnel bonding implementation
# Copyright (C) 2019  Friedrich Oslage <friedrich@oslage.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

CFLAGS ?= -Wall -Werror -Wextra -Wpedantic -std=gnu11 -fcommon -Os -fomit-frame-pointer
LDFLAGS ?= -Wl,-Os -Wl,--as-needed -Wl,--sort-common -Wl,--hash-style=gnu

CODE_DIRECTORY = code
BUILD_DIRECTORY = build
OPENWRT_BUILD_DIRECTORY = build-openwrt

CODE = $(wildcard $(CODE_DIRECTORY)/*.c)
HEADER = $(wildcard $(CODE_DIRECTORY)/*.h)

OBJECT = $(patsubst $(CODE_DIRECTORY)/%.c,$(BUILD_DIRECTORY)/%.o,$(CODE))
OPENWRT_OBJECT = $(patsubst $(CODE_DIRECTORY)/%.c,$(OPENWRT_BUILD_DIRECTORY)/%.o,$(CODE))

EXECUTABLE = $(BUILD_DIRECTORY)/openhybrid
OPENWRT_EXECUTABLE = $(OPENWRT_BUILD_DIRECTORY)/openhybrid

# STAGING_DIR environment variable is expected to be provided by the OpenWrt toolchain
export STAGING_DIR := /builder/staging_dir

.PHONY: build build-openwrt build-openwrt-libmnl clean clean-openwrt

build: $(EXECUTABLE)
HOST_CFLAGS = $(CFLAGS) $(shell pkg-config --cflags libmnl)
HOST_LDFLAGS = $(LDFLAGS) $(shell pkg-config --libs-only-other --libs-only-L libmnl)
HOST_LIBS = $(shell pkg-config --libs-only-l libmnl) -lpthread
$(EXECUTABLE): $(OBJECT)
	@mkdir -p $(BUILD_DIRECTORY)
	$(CC) $(HOST_LDFLAGS) $(OBJECT) -o $(EXECUTABLE) $(HOST_LIBS)

$(BUILD_DIRECTORY)/%.o: $(CODE_DIRECTORY)/%.c $(HEADER)
	@mkdir -p $(BUILD_DIRECTORY)
	$(CC) $(HOST_CFLAGS) -c $< -o $@

build-openwrt: $(OPENWRT_EXECUTABLE)
OPENWRT_DIR=$(STAGING_DIR)/toolchain-*
OPENWRT_CC=$(OPENWRT_DIR)/bin/*-openwrt-linux-gcc
OPENWRT_INCLUDE_DIR=$(OPENWRT_DIR)/usr/include
OPENWRT_LIBS = -lpthread -lmnl
$(OPENWRT_EXECUTABLE): $(OPENWRT_OBJECT)
	@mkdir -p $(OPENWRT_BUILD_DIRECTORY)
	$(wildcard $(OPENWRT_CC)) $(LDFLAGS) $(OPENWRT_OBJECT) -o $(OPENWRT_EXECUTABLE) $(OPENWRT_LIBS)

$(OPENWRT_BUILD_DIRECTORY)/%.o: $(CODE_DIRECTORY)/%.c $(HEADER)
	@mkdir -p $(OPENWRT_BUILD_DIRECTORY)
	$(wildcard $(OPENWRT_CC)) -I $(wildcard $(OPENWRT_INCLUDE_DIR)) $(CFLAGS) -c $< -o $@

build-openwrt-libmnl:
	@unset STAGING_DIR && \
	cd /builder && \
	./scripts/feeds update base && \
	make defconfig && \
	./scripts/feeds install libmnl && \
	make package/libmnl/compile && \
	cp -R $(STAGING_DIR)/target-*/usr/lib/libmnl.* $(STAGING_DIR)/toolchain-*/usr/lib/ && \
	cp -R $(STAGING_DIR)/target-*/usr/include/libmnl $(STAGING_DIR)/toolchain-*/usr/include/

clean:
	rm -rf $(OBJECT) $(EXECUTABLE)

clean-openwrt:
	rm -rf $(OPENWRT_OBJECT) $(OPENWRT_EXECUTABLE)
