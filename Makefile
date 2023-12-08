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

CFLAGS ?= -march=native -mtune=native -O2 -fomit-frame-pointer -pipe
LDFLAGS ?= -Wl,-O2 -Wl,--as-needed -Wl,--sort-common -Wl,--hash-style=gnu

CFLAGS += -Wall -Werror -std=gnu11 -fcommon

CFLAGS += $(shell pkg-config --cflags libmnl)
LDFLAGS += $(shell pkg-config --libs-only-other --libs-only-L libmnl)
LIBS += $(shell pkg-config --libs-only-l libmnl) -lpthread

CODE_DIRECTORY = code
BUILD_DIRECTORY = build
CODE = $(wildcard $(CODE_DIRECTORY)/*.c)
HEADER = $(wildcard $(CODE_DIRECTORY)/*.h)
OBJECT = $(patsubst $(CODE_DIRECTORY)/%.c,$(BUILD_DIRECTORY)/%.o,$(CODE))
EXECUTABLE = $(BUILD_DIRECTORY)/openhybrid

.PHONY: clean build

build: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECT)
	@mkdir -p $(BUILD_DIRECTORY)
	$(CC) $(LDFLAGS) $(OBJECT) -o $(EXECUTABLE) $(LIBS)

$(BUILD_DIRECTORY)/%.o: $(CODE_DIRECTORY)/%.c $(HEADER)
	@mkdir -p $(BUILD_DIRECTORY)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJECT) $(EXECUTABLE)
