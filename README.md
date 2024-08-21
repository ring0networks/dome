# Ring-0 D0me

## Compilation

There are two ways to compile Ring-0 D0me:
- **Bridge Mode**: Simply invoke `make`. This will set the filter to run in “bridge mode”, where the module will swap the Ethernet source and destination and then return `TX`. This is the default. 
- **Router Mode**: Use `make CFLAGS=-DDOME_CONFIG_ROUTER` to compile it in “router mode”. In this mode, the XDP will return `PASS`, allowing the packet to fall through the entire TCP stack.


## Configuration

### Bridge Mode 

When running in “bridge mode”, it is common to use the `filter` in conjunction with the BPF module located in the `redirect` directory. For detailed instructions, please refer to the `redirect/README.md`.


### Telegraf

```
[agent]
  interval = "1s"
  flush_interval = "1s"
  omit_hostname = true

[[inputs.socket_listener]]
  service_address = "udp://localhost:8094"
  data_format = "influx"

[[outputs.influxdb_v2]]
  urls = ["http://<influx_host>:8086"]
  content_encoding = "identity"
  organization = "<influx_org>"
  token = "<influx_token>"
  bucket = "ring0dome"
```

