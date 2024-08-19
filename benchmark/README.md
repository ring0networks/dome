# Benchmarks

This directory contains a script (`run`) for executing HTTP and HTTPS benchmarks using [Siege](https://github.com/JoeDog/siege), [wrk](https://github.com/wg/wrk) and [ApacheBench (ab)](https://httpd.apache.org/docs/current/programs/ab.html).

## Dependencies

Before running the script, ensure the following dependencies are installed:

```sh
sudo apt install -y apache2-utils wrk siege
```

## Usage

```sh
./run <ipddr> [http/https]
```

- Replace `<ipaddr>` with the IP address of the HTTP server.
- The optional `[http/https]` argument specifies the protocol to be used in the benchmarks. If omitted, the script will run benchmarks for both HTTP and HTTPS.

Upon completion, the log directory will hold the results of the most recent benchmarks.

