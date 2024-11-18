<!-- markdownlint-disable MD013 -->
# D0me Grafana dashboard

## Installation

### Requirements

#### Docker Desktop

Follow the instructions provided at [Docker Desktop](https://docs.docker.com/desktop/) according to your O.S.

#### luarocks

Follow the [Download](https://github.com/luarocks/luarocks/wiki/Download) instructions from the official luarocks repository.

> [!IMPORTANT]
> Make sure to install Lua 5.4 or higher, which is the version required by the metric generation script.

Once luarocks is setup, proceed with the installation of libraries `luasocket` and `luafilesystem` as follows:

```bash
sudo luarocks install luasocket
sudo luarocks install luafilesystem
```

### Install the dashboard

> [!TIP]
> The dashboard comes into two different versions, Portuguese (`dashboard.json`), the default, and English (`dashboard_en.json`)
> Make sure to replace `dashboard.json` with `dashboard_en.json` before installing it if you need to use the English version.

From the current directory, execute:

```bash
./install
```

This will pull the necessary Grafana/InfluxDB docker images and configure the dashboard.

### Start/stop the dashboard

To start the dashboard and the necessary docker containers, simply execute:

```bash
./start
```

Similarly, to stop the dashboard, run:

```bash
./stop
```

### Generate random InfluxDB metrics

The dashboard comes with a script for random metric generation, which may be executed as follows, to feed the backing InfluxDB bucket:

```bash
cd influx-data-gen
./influx-data-gen
```

> [!TIP]
> You may override the target InfluxDB IP address by setting `$INFLUX_HOSTNAME` before executing the script.

In order to interrupt metric generation, simply type:

```bash
Control + c
```

### Navigate the dashboard

The Grafana dashboard is available at <http://localhost:3000/d/edr5k61vs5hj4d/ring-0-d0me?orgId=1>.

- user: `admin`
- pass: `admin123`

### Managing InfluxDB data

The InfluxDB instance is accessible at <http://localhost:8086>.

To login, use the following credentials:

- user: admin
- pass: admin123
