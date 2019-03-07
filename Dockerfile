FROM sdthirlwall/raspberry-pi-cross-compiler
# Install wget, openssl, libssl-dev, pkg-config
RUN apt-get update && \
    apt-get install -y wget openssl libssl-dev pkg-config
# Set env variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.26.0 \
    ARMV7_UNKNOWN_LINUX_GNUEABIHF_OPENSSL_LIB_DIR=/tmp/openssl-1.1.0h \
    ARMV7_UNKNOWN_LINUX_GNUEABIHF_OPENSSL_INCLUDE_DIR=/tmp/openssl-1.1.0h/include
# Install rustc, rustup and cargo
RUN set -eux; \
    \
# this "case" statement is generated via "update.sh"
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='c9837990bce0faab4f6f52604311a19bb8d2cde989bea6a7b605c8e526db6f02' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='297661e121048db3906f8c964999f765b4f6848632c0c2cfb6a1e93d99440732' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='a68ac2d400409f485cb22756f0b3217b95449884e1ea6fd9b70522b3c0a929b2' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='27e6109c7b537b92a6c2d45ac941d959606ca26ec501d86085d651892a55d849' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    \
    url="https://static.rust-lang.org/rustup/archive/1.11.0/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup target add armv7-unknown-linux-gnueabihf; \
    rustup --version; \
    cargo --version; \
    rustc --version;
# Download open-ssl from source and cross compiles it for arm7
RUN cd /tmp && \
    wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz && \
    tar xzf openssl-1.1.0h.tar.gz && \
    export MACHINE=armv7 && \
    export ARCH=arm && \
    export CC=gcc && \
cd openssl-1.1.0h && ./config shared && make