# InfluxDB request data generator

This tool generates random data about https pass/warn/block requests and sends to InfluxDB HTTP API

Sample formats:

```bash
https,host=ring-0.io,location=rj reason="scam",domain="crestoption.com",action="block" 1720040940922001109
https,host=ring-0.io,location=rj reason="ransomware",domain="hjhqmbxyinislkkt.1cnkik.top",action="block" 1720040940922001166
https,host=ring-0.io,location=rj reason="porn",domain="macbeef.tumblr.com",action="block" 1720040940929001366
https,host=ring-0.io,location=rj reason="phishing",domain="eletricista24horas.com.br",action="block" 1720040940921001058
https,host=ring-0.io,location=rj reason="malware",domain="bzvrokupjb.neliver.com",action="block" 1720040940920001041
https,host=ring-0.io,location=rj reason="drugs",domain="bagesti.net",action="block" 1720040940920001022
https,host=ring-0.io,location=rj reason="gambling",domain="promo.casinoroom.com",action="warn" 1720040940920009951
https,host=ring-0.io,location=rj reason="piracy",domain="iddl.org",action="warn" 1720040940919009789
https,host=ring-0.io,location=rj reason="crypto",domain="adinfo.ra1.xlmc.sec.miui.com",action="warn" 1720040940917007957
https,host=ring-0.io,location=rj reason="fraud",domain="cgireview-issues.com",action="warn" 1720040940917007842
https,host=ring-0.io,location=rj reason="not-work",domain="baidu.com",action="pass" 1720040940916007593
https,host=ring-0.io,location=rj reason="work",domain="openai.com",action="pass" 1720040940916007529
```

## Setup

### Install luarocks

<https://github.com/luarocks/luarocks/wiki/Download>

### Install luasocket and luafilesystem

```bash
sudo luarocks install luasocket
sudo luarocks install luafilesystem
```

## Sending data to InfluxDB HTTP API

### Start sending

```bash
./influx-data-gen
```

### Stop sending

```bash
Control + c
```
