# ubuntu-snort3
Docker-based build of Snort 3 from [source](https://github.com/snort3)

Modern, self-contained Dockerfile using multi-stage build to create:
- Intermediate builder stage with compilation tools and dependencies
- Minimal runtime image with only Snort 3 and necessary runtime libraries

## Usage

### Build

**Requirements:** Docker with BuildKit support (Docker 18.09+)

**Basic build (latest versions):**
```bash
docker build -t ubuntu-snort3:latest .
```

**Build with specific versions:**
```bash
docker build \
  --build-arg SNORT_VERSION=3.1.75.0 \
  --build-arg ODP_VERSION=33380 \
  -t ubuntu-snort3:3.1.75.0 .
```

**Build arguments:**
- `SNORT_VERSION` - Snort3 version/tag (default: `latest`)
  - When set to `latest`, the build automatically resolves to the most recent release tag
  - The actual version is stored in `/usr/local/etc/snort/version.txt`
- `LIBDAQ_VERSION` - libdaq version/tag (default: `main`)
- `LIBML_VERSION` - libml version/tag (default: `main`)
- `ODP_VERSION` - OpenAppID version number (default: `33380`)
- `BUILDER_BASE` / `BUILDER_TAG` - Builder base image (default: `ubuntu:24.04`)
- `RUNTIME_BASE` / `RUNTIME_TAG` - Runtime base image (default: `ubuntu:24.04`)

**Access the builder stage (for debugging):**
```bash
docker build --target builder -t ubuntu-snort3-build:latest .
```

### Run Snort

**Check version:**
```bash
docker run --rm ubuntu-snort3:latest --version
```

**Check build version (when using SNORT_VERSION=latest):**
```bash
docker run --rm ubuntu-snort3:latest cat /usr/local/etc/snort/version.txt
```

**Example output:**

```bash
   ,,_     -*> Snort++ <*-
  o"  )~   Version 3.1.39.0
   ''''    By Martin Roesch & The Snort Team
           http://snort.org/contact#team
           Copyright (C) 2014-2022 Cisco and/or its affiliates. All rights reserved.
           Copyright (C) 1998-2013 Sourcefire, Inc., et al.
           Using DAQ version 3.0.9
           Using LuaJIT version 2.1.0-beta3
           Using OpenSSL 3.0.2 15 Mar 2022
           Using libpcap version 1.10.1 (with TPACKET_V3)
           Using PCRE version 8.39 2016-06-14
           Using ZLIB version 1.2.11
           Using Hyperscan version 5.4.0 2021-01-26
           Using LZMA version 5.2.5
```

**Check available DAQ modules:**
```bash
docker run --rm ubuntu-snort3:latest --daq-dir /usr/local/lib/daq --daq-list
```

**Example output:**

```bash
Available DAQ modules:
afpacket(v7): live inline multi unpriv
 Variables:
  buffer_size_mb <arg> - Packet buffer space to allocate in megabytes
  debug - Enable debugging output to stdout
  fanout_type <arg> - Fanout loadbalancing method
  fanout_flag <arg> - Fanout loadbalancing option
  use_tx_ring - Use memory-mapped TX ring
bpf(v1): inline unpriv wrapper
dump(v5): inline unpriv wrapper
 Variables:
  file <arg> - PCAP filename to output transmitted packets to (default: inline-out.pcap)
  output <arg> - Set to none to prevent output from being written to file (deprecated)
  dump-rx [arg] - Also dump received packets to their own PCAP file (default: inline-in.pcap)
fst(v1): unpriv wrapper
 Variables:
  no_binding_verdicts - Disables enforcement of binding verdicts
  enable_meta_ack - Enables support for filtering bare TCP acks
  ignore_checksums - Ignore bad checksums while decoding
gwlb(v1): inline unpriv wrapper
nfq(v8): live inline multi
 Variables:
  debug - Enable debugging output to stdout
  fail_open - Allow the kernel to bypass the netfilter queue when it is full
  queue_maxlen <arg> - Maximum queue length (default: 1024)
pcap(v4): readback live multi unpriv
 Variables:
  buffer_size <arg> - Packet buffer space to allocate in bytes
  no_promiscuous - Disables opening the interface in promiscuous mode
  no_immediate - Disables immediate mode for traffic capture (may cause unbounded blocking)
  readback_timeout - Return timeout receive status in file readback mode
savefile(v1): readback multi unpriv
trace(v1): inline unpriv wrapper
 Variables:
  file <arg> - Filename to write text traces to (default: inline-out.txt)
```

## CI/CD

This repository includes a GitHub Actions workflow that automatically builds and publishes Docker images to Docker Hub.

### Automatic Builds

The workflow triggers on:
- **Push to `main` branch** - Automatically builds and publishes when Dockerfile changes
- **Manual dispatch** - Allows building specific versions on-demand

### Published Images

Images are published to: **`datmanslo/ubuntu-snort3`**

Tags:
- `datmanslo/ubuntu-snort3:latest` - Latest Snort3 release
- `datmanslo/ubuntu-snort3:<version>` - Specific Snort version (e.g., `3.9.6.0`)

### Setup Requirements

To enable automated publishing, configure these GitHub repository secrets:
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token ([create one here](https://hub.docker.com/settings/security))

### Manual Workflow Dispatch

You can manually trigger a build with custom parameters:

1. Go to **Actions** tab in GitHub
2. Select **Build and Publish Docker Image** workflow
3. Click **Run workflow**
4. Optionally specify:
   - `snort_version` - Snort version to build (default: `latest`)
   - `odp_version` - OpenAppID version (default: `33380`)

## Snort3 Usage and Documentation

For information/documentation regarding Snort3 see the [official Snort Website](https://snort.org/snort3)
