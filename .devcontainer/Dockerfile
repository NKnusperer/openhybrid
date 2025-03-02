ARG ARCH=x86-64
ARG VERSION=24.10.0

FROM docker.io/openwrt/sdk:$ARCH-$VERSION AS build
WORKDIR /source
ADD Makefile .
RUN make build-openwrt-libmnl

FROM docker.io/openwrt/sdk:$ARCH-$VERSION
# Copy libmnl from build stage to temporary directories
COPY --from=build --chown=buildbot:buildbot /builder/staging_dir/target-*/usr/lib/libmnl.* /tmp/libmnl_lib/
COPY --from=build --chown=buildbot:buildbot /builder/staging_dir/target-*/usr/include/libmnl /tmp/libmnl_include/

USER buildbot

# Find the actual toolchain directory and move files to correct location.
# We can not use COPY because wildcards only get expanded in source paths but are treated literally in destination paths.
RUN TOOLCHAIN_DIR=$(find /builder/staging_dir -name "toolchain-*" -type d | head -1) && \
    mkdir -p "$TOOLCHAIN_DIR/usr/include/libmnl" && \
    cp /tmp/libmnl_lib/* "$TOOLCHAIN_DIR/usr/lib/" && \
    cp /tmp/libmnl_include/* "$TOOLCHAIN_DIR/usr/include/libmnl/" && \
    rm -rf /tmp/libmnl_lib /tmp/libmnl_include && \
    # Create a symlink to the toolchain for use in .vscode/c_cpp_properties.json
    mkdir -p toolchain/bin && \
    ln -s "$TOOLCHAIN_DIR"/bin/*-openwrt-linux-gcc toolchain/bin/gcc && \
    ln -s "$TOOLCHAIN_DIR/include/" toolchain/ && \
    mkdir -p toolchain/usr && \
    ln -s "$TOOLCHAIN_DIR/usr/include/" toolchain/usr
