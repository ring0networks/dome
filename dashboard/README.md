# Grafana dashboard playground

## Install Docker Desktop

<https://docs.docker.com/desktop/>

## Install Grafana/InfluxDB docker images

```bash
./install
```

## Start docker conteiners

```bash
./start
```

## Generate InfluxDB random traffic data

### Install luarocks

Follow the [Download](https://github.com/luarocks/luarocks/wiki/Download) 
instructions from the official luarocks repository.

### Install luasocket and luafilesystem

```bash
sudo luarocks install luasocket
sudo luarocks install luafilesystem
```

### Start InfluxDB random traffic generation

 ```bash
cd influx-data-gen
./influx-data-gen
```

### Stop InfluxDB random traffic generation

 ```bash
Control + c
```

## Watch grafana dashboard

<http://localhost:3000/d/edr5k61vs5hj4d/ring-0-d0me?orgId=1>

- user: admin
- pass: admin123

## Managing InfluxDB

<http://localhost:8086>

- user: admin
- pass: admin123

## Stop docker conteiners

```bash
./stop
```
