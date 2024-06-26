# Ring-0 D0me

## Configuration

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

