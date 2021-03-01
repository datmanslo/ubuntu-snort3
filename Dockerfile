ARG BUILDER_BASE=datmanslo/ubuntu-snort3-dev
ARG BUILDER_TAG=20.04
ARG RUNTIME_BASE=ubuntu
ARG RUNTIME_TAG=20.04

# Compilation stage
FROM ${BUILDER_BASE}:${BUILDER_TAG} as builder

# OpenAppID version can change in the future (17843)
ARG ODP_URL=https://snort.org/downloads/openappid/17843

# Set installation location
ENV PREFIX_DIR=/usr/local
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# Build libdaq
WORKDIR /tmp/daq_src
RUN git clone https://github.com/snort3/libdaq.git \
&& cd libdaq \
&& ./bootstrap \
&& ./configure --prefix=${PREFIX_DIR} \
&& make -j$(nproc --ignore=1) install \
&& ldconfig

# Build Snort
WORKDIR /tmp/snort_src
RUN git clone https://github.com/snort3/snort3.git \
&& cd snort3 \
&& CXX_FLAGS="-fno-rtti O3" ./configure_cmake.sh \
   --prefix=${PREFIX_DIR} \
   --build-type=MinSizeRel \
   --disable-gdb \
   --enable-tsc-clock \
   --disable-static-daq \
   --enable-tcmalloc \
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
ENV PREFIX_DIR=/usr/local
RUN apt-get update \
  && apt-get install -y \
     libgoogle-perftools4 \
     libdumbnet1 \
     libflatbuffers1 \
     libhwloc15 \
     libluajit-5.1-2 \
     libssl1.1 \
     libpcap0.8 \
     libhyperscan5 \
     libmnl0 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --from=builder ${PREFIX_DIR}/etc ${PREFIX_DIR}/etc
COPY --from=builder ${PREFIX_DIR}/include ${PREFIX_DIR}/include
COPY --from=builder ${PREFIX_DIR}/lib ${PREFIX_DIR}/lib
COPY --from=builder ${PREFIX_DIR}/bin ${PREFIX_DIR}/bin
RUN ldconfig
CMD ["/usr/local/bin/snort", "-V"]
