# syntax=docker/dockerfile:1.4

# Build arguments for base images
ARG BUILDER_BASE=ubuntu
ARG BUILDER_TAG=24.04
ARG RUNTIME_BASE=${BUILDER_BASE}
ARG RUNTIME_TAG=${BUILDER_TAG}

# Version arguments with sensible defaults
# Override these at build time: docker build --build-arg SNORT_VERSION=3.1.75.0
ARG SNORT_VERSION=latest
ARG LIBDAQ_VERSION=main
ARG LIBML_VERSION=main
ARG ODP_VERSION=33380

# ==============================================================================
# Builder Stage - Compile Snort3 and dependencies
# ==============================================================================
FROM ${BUILDER_BASE}:${BUILDER_TAG} AS builder

# OCI standard annotations
LABEL org.opencontainers.image.authors="datmanslo"
LABEL org.opencontainers.image.description="Snort3 IDS/IPS Builder Stage"
LABEL org.opencontainers.image.source="https://github.com/datmanslo/ubuntu-snort3"
LABEL stage="builder"

ENV DEBIAN_FRONTEND=noninteractive \
    PREFIX_DIR=/usr/local \
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
    CC=/usr/bin/gcc \
    CXX=/usr/bin/g++ \
    CFLAGS="-O3" \
    CXXFLAGS="-fno-rtti -O3" \
    CPPFLAGS="-O3"

# Install build dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        asciidoc \
        autoconf \
        automake \
        bison \
        build-essential \
        ca-certificates \
        checkinstall \
        cmake \
        curl \
        dblatex \
        flex \
        g++ \
        gawk \
        gdb \
        git \
        libcpputest-dev \
        libdumbnet-dev \
        libfl-dev \
        libflatbuffers-dev \
        libhwloc-dev \
        libhyperscan-dev \
        libjemalloc-dev \
        libluajit-5.1-dev \
        liblzma-dev \
        libmnl-dev \
        libnetfilter-queue-dev \
        libpcap-dev \
        libpcre2-dev \
        libsafec-dev \
        libssl-dev \
        libtirpc-dev \
        libtool \
        libunwind-dev \
        make \
        nano \
        pkg-config \
        uuid-dev \
        vim \
        w3m \
        wget \
        zlib1g-dev

# Build arguments passed to this stage
ARG SNORT_VERSION
ARG LIBDAQ_VERSION
ARG LIBML_VERSION
ARG ODP_VERSION
ARG PREFIX_DIR=/usr/local

# ==============================================================================
# Build libml (Machine Learning library for Snort3)
# ==============================================================================
WORKDIR /tmp/libml_src
RUN git clone https://github.com/snort3/libml.git && \
    cd libml && \
    if [ "${LIBML_VERSION}" != "main" ] && [ "${LIBML_VERSION}" != "latest" ]; then \
        git checkout "${LIBML_VERSION}"; \
    fi && \
    ./configure.sh --prefix="${PREFIX_DIR}" && \
    cd build && \
    make -j$(nproc --ignore=1) install && \
    ldconfig

# ==============================================================================
# Build libdaq (Data Acquisition library)
# ==============================================================================
WORKDIR /tmp/daq_src
RUN git clone https://github.com/snort3/libdaq.git && \
    cd libdaq && \
    if [ "${LIBDAQ_VERSION}" != "main" ] && [ "${LIBDAQ_VERSION}" != "latest" ]; then \
        git checkout "${LIBDAQ_VERSION}"; \
    fi && \
    ./bootstrap && \
    ./configure --prefix="${PREFIX_DIR}" && \
    make -j$(nproc --ignore=1) install && \
    ldconfig

# ==============================================================================
# Build Snort3
# ==============================================================================
WORKDIR /tmp/snort_src
RUN git clone https://github.com/snort3/snort3.git && \
    cd snort3 && \
    if [ "${SNORT_VERSION}" = "latest" ]; then \
        ACTUAL_VERSION=$(git describe --tags --abbrev=0) && \
        git checkout "${ACTUAL_VERSION}" && \
        echo "${ACTUAL_VERSION}" > /tmp/snort_version.txt; \
    elif [ "${SNORT_VERSION}" != "main" ]; then \
        git checkout "${SNORT_VERSION}" && \
        echo "${SNORT_VERSION}" > /tmp/snort_version.txt; \
    else \
        git describe --tags --always > /tmp/snort_version.txt; \
    fi && \
    ./configure_cmake.sh \
        --prefix="${PREFIX_DIR}" \
        --build-type=MinSizeRel \
        --enable-jemalloc-static \
        --enable-luajit-static \
        --disable-gdb \
        --enable-shell \
        --enable-tsc-clock \
        --disable-static-daq \
        --disable-docs \
        --enable-large-pcap && \
    cd build && \
    make -j$(nproc --ignore=1) install

# ==============================================================================
# Download and install OpenAppID
# ==============================================================================
WORKDIR /tmp
RUN wget "https://snort.org/downloads/openappid/${ODP_VERSION}" -O odp.tgz && \
    mkdir -p "${PREFIX_DIR}/etc/snort/" && \
    tar -xzvf odp.tgz -C "${PREFIX_DIR}/etc/snort/" && \
    rm -f odp.tgz

# ==============================================================================
# Runtime Stage - Minimal image with only runtime dependencies
# ==============================================================================
FROM ${RUNTIME_BASE}:${RUNTIME_TAG}

# OCI standard annotations
# Note: When SNORT_VERSION=latest, the actual version is resolved during build
# and stored in /usr/local/etc/snort/version.txt
LABEL org.opencontainers.image.authors="datmanslo"
LABEL org.opencontainers.image.title="Snort3"
LABEL org.opencontainers.image.description="Snort3 Network Intrusion Detection System"
LABEL org.opencontainers.image.version="${SNORT_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/datmanslo/ubuntu-snort3"
LABEL org.opencontainers.image.url="https://github.com/datmanslo/ubuntu-snort3"
LABEL org.opencontainers.image.vendor="datmanslo"

ENV DEBIAN_FRONTEND=noninteractive \
    LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\; \
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
    PREFIX_DIR=/usr/local

# Install runtime dependencies only
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libdumbnet1 \
        libflatbuffers2 \
        libhwloc15 \
        libhyperscan5 \
        libmnl0 \
        libnuma1 \
        libpcre3 \
        libpcap0.8 \
        libsafec3 \
        libssl3 \
        libunwind8

# Copy compiled binaries and libraries from builder
COPY --from=builder ${PREFIX_DIR}/etc ${PREFIX_DIR}/etc
COPY --from=builder ${PREFIX_DIR}/include ${PREFIX_DIR}/include
COPY --from=builder ${PREFIX_DIR}/lib ${PREFIX_DIR}/lib
COPY --from=builder ${PREFIX_DIR}/bin ${PREFIX_DIR}/bin

# Copy version information for reference
COPY --from=builder /tmp/snort_version.txt ${PREFIX_DIR}/etc/snort/version.txt

# Update dynamic linker cache
RUN ldconfig

# Snort runs as the entrypoint
ENTRYPOINT ["/usr/local/bin/snort"]

# Default to showing help/version (can be overridden)
CMD ["--version"]
