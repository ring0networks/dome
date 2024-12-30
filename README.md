<!-- markdownlint-disable MD013 -->
# ring-0 d0me

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)](https://github.com/ring0networks/dome)

ring-0 d0me is a secure web gateway designed to enhance network security and filtering capabilities.
With its extensibility powered by Lua scripting, it allows tailored configurations to meet diverse requirements.
It offers flexible deployment options, operating either through XDP or Netfilter, depending on your configuration.

## Features

- **Custom Block Responses**: Blocked HTTP requests are redirected to a user-defined URL, while blocked HTTPS requests are replied with a TCP RST.
- **Event Reporting**: Sends event messages to a local Telegraf agent for logging and monitoring.
- **XDP (eXpress Data Path)**: Provides high-performance packet processing at the kernel level.
- **Netfilter**: Leverages standard Linux packet filtering for ease of integration.
- **Configurable Modes**: Operate in either Bridge Mode or Router Mode for XDP filters (see below).

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/ring0networks/dome.git
cd dome
```

### Compilation Options for XDP Filter

#### **Router Mode** (Default)

  ```bash
  make
  ```

>[!NOTE]
>This mode uses `XDP_PASS` to let the packet continue moving through the TCP stack, enabling deeper packet processing.

## Basic Usage

1. **Install:**

   ```bash
   make install
   ```

2. *(optional)* **Set up a network namespace:**

   To run the `dome` *Router Mode* using a *virtual interface*, follow these steps:

   ```bash
   make namespace
   ```

   This step executes the `namespace.sh` script to create the necessary network namespace and virtual interface.

3. **Run the project:**

   ```bash
   ./dome.sh start
   ```

   This starts the `dome` project in Router Mode, utilizing the virtual interface created in the previous step.

4. **Stop the project:**

   ```bash
   ./dome.sh stop
   ```

   This stops the running instance of `dome` and cleans up resources.

>[!IMPORTANT]
>Ensure that all prerequisites for the project are met and that you have sufficient permissions to run these commands on your system.

## Configuration

ring-0 d0me utilizes a Lua configuration file.
Here is an example:

```lua
return {
  filter = 'xdp', -- xdp/netfilter
  policy = 'allow', -- allow/block
  iface = 'eth1', -- used with xdp only
  mailbox_max = 100 * 1024,
  notify_header = 'http,host=ring-0.io,location=rj ',
  redirect_url = 'https://www.ring0networks.com.br/br/block?',
  allowlists = {},
  blocklists = {'example'}
}
```

- **Bridge Mode**:

  ```bash
  make bridge
  ```

  - This mode is intended to immediately return the packet using `XDP_TX`, swapping the Ethernet source and destination addresses before re-transmitting it.
  - When running in bridge mode, it is common to use the BPF module located in the `redirect` directory, in conjuntion with the usual `filter` module. For detailed instructions, please refer to the [`redirect/README.md`](https://github.com/ring0networks/dome/blob/master/redirect/README.md).

### Field Descriptions

- **`filter`**: Determines the packet filtering mechanism. Possible values:
  - `xdp`: Use XDP for packet filtering.
  - `netfilter`: Use Netfilter for packet filtering.

- **`policy`**: Defines the default behavior of the gateway.
  - `allow`: Permit traffic by default.
  - `block`: Deny traffic by default.

- **`iface`**: Specifies the interface to be used when operating with XDP (e.g., `eth1`).

- **`mailbox_max`**: Sets the maximum mailbox size for notifications in bytes.

- **`notify_header`**: Telegraf message header format.

- **`redirect_url`**: URL to redirect blocked HTTP traffic (e.g., a custom block page). Notice that blocked HTTPS requests, however, will be replied with a TCP RST instead.

- **`allowlists`**: Contains the names of Lua modules specifying the list of domains to allow.

- **`blocklists`**: Contains the names of Lua modules specifying the list of domains to block.

### Blocklists

Blocklists are stored in the `blocklist` directory of the repository. Update or manage these files to customize blocking rules.

### Telegraf

ring-0 d0me sends event messages to a local [Telegraf](https://github.com/influxdata/telegraf) for further processing and monitoring. Below is an example configuration file:

```toml
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

## Contributing

Contributions are welcome!
Please submit issues or pull requests via [GitHub](https://github.com/ring0networks/dome).

## License

ring-0 d0me is licensed under the GPL-2.0. See the `LICENSE` file for more details.

---

For more information, visit the [project repository](https://github.com/ring0networks/dome).
