ARG BUILDER_BASE=ubuntu
ARG BUILDER_TAG=22.04
ARG RUNTIME_BASE=${BUILDER_BASE}
ARG RUNTIME_TAG=${BUILDER_TAG}

# Compilation stage
FROM ${BUILDER_BASE}:${BUILDER_TAG} as builder
ENV DEBIAN_FRONTEND=noninteractive

# Install Snort 3 and libDAQ build dependencies
RUN \
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
        libpcre3-dev \
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
        zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

   # Existing Dockerfile content...

# Add the new RUN command
RUN apt-get update && apt-get install -y libnuma1 && \
    ln -s /usr/lib/x86_64-linux-gnu/libnuma.so.1 /usr/lib/libnuma.so.1

# Continue with the rest of the Dockerfile...

# OpenAppID version can change in the future (26425)
ARG ODP_URL=https://snort.org/downloads/openappid/26425

# Set installation location
ENV PREFIX_DIR=/usr/local
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/lib64

# Build libdaq
WORKDIR /tmp/daq_src
RUN git clone https://github.com/snort3/libdaq.git \
&& cd libdaq \
&& ./bootstrap \
&& CXX_FLAGS="-fno-rtti O3" CPFLAGS="-O3" CFLAGS="-O3" ./configure --prefix=${PREFIX_DIR} \
&& make -j$(nproc --ignore=1) install \
&& ldconfig

# Build Snort
WORKDIR /tmp/snort_src
RUN git clone https://github.com/snort3/snort3.git \
&& cd snort3 \
&& CXX_FLAGS="-fno-rtti O3" CPFLAGS="-O3" CFLAGS="-O3" ./configure_cmake.sh \
   --prefix=${PREFIX_DIR} \
   --build-type=MinSizeRel \
   --enable-jemalloc-static \
   --enable-luajit-static \
   --disable-gdb \
   --enable-shell \
   --enable-tsc-clock \
   --enable-tsc-clock \
   --disable-static-daq \
   --disable-docs \
   --enable-large-pcap \
&& cd build \
&& make -j$(nproc --ignore=1) install

WORKDIR /tmp
RUN wget ${ODP_URL} -O odp.tgz \
&& tar -xzvf odp.tgz -C ${PREFIX_DIR}/etc/snort/ \
&& rm -f odp.tgz

# Create a "portable" tarball of the installation: /tmp/snort3.tar.gz
WORKDIR /tmp
RUN tar -czvf snort3.tar.gz \
  ${PREFIX_DIR}/etc \
  ${PREFIX_DIR}/include  \
  ${PREFIX_DIR}/lib  \
  ${PREFIX_DIR}/bin

# Final image
FROM ${RUNTIME_BASE}:${RUNTIME_TAG}
ENV DEBIAN_FRONTEND="noninteractive"
ENV LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\;
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/lib64
ENV PREFIX_DIR=/usr/local
RUN apt-get update \
  && apt-get install -y \
     libdumbnet1 \
     libflatbuffers1 \
     libhwloc15 \
     libhyperscan5 \
     libmnl0 \
     libpcap0.8 \
     libsafec3 \
     libssl3 \
     libunwind8 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --from=builder ${PREFIX_DIR}/etc ${PREFIX_DIR}/etc
COPY --from=builder ${PREFIX_DIR}/include ${PREFIX_DIR}/include
COPY --from=builder ${PREFIX_DIR}/lib ${PREFIX_DIR}/lib
COPY --from=builder ${PREFIX_DIR}/bin ${PREFIX_DIR}/bin
RUN ldconfig
ENTRYPOINT ["/usr/local/bin/snort"]
