# ubuntu-snort3
Docker based build of Snort 3 from [source](https://github.com/snort3)  
Creates two Docker images:

- Larger buildtime image with source code (/tmp) and dev tools: `datmanslo/ubuntu-snort3-build:<snort-version>`
- Smaller runtime image: `datmanslo/ubuntu-snort3:latest<snort-version>`

## Usage

### Build
Requirements: Docker, curl  
Run the [build.sh](build.sh) script to create the images. `./build.sh`

### Check Snort Version

Command: `docker run --rm docker.io/datmanslo/ubuntu-snort3:3.1.39.0 -V`  
Example output:

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

### Check Available Daq Modules

Command: `docker run --rm docker.io/datmanslo/ubuntu-snort3:3.1.39.0 --daq-dir /usr/local/lib/daq --daq-list`  

Example Output:

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

## Snort3 Usage and Documentation

For information/documentation regarding Snort3 see the [official Snort Website](https://snort.org/snort3)
