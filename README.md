# DAppNode Package Bind (Core)

[![Website dappnode.io](https://img.shields.io/badge/Website-dappnode.io-brightgreen.svg)](https://dappnode.io/)
[![Documentation Wiki](https://img.shields.io/badge/Documentation-Wiki-brightgreen.svg)](https://github.com/dappnode/DAppNode/wiki)
[![GIVETH Campaign](https://img.shields.io/badge/GIVETH-Campaign-1e083c.svg)](https://alpha.giveth.io/campaigns/OcKJryNwjeidMXi9)
[![RIOT DAppNode](https://img.shields.io/badge/RIOT-DAppNode-blue.svg)](https://riot.im/app/#/room/#DAppNode:matrix.org)
[![Twitter Follow](https://img.shields.io/twitter/follow/espadrine.svg?style=social&label=Follow)](https://twitter.com/DAppNODE?lang=es)

<p align="left">
  <img src="BIND-min.png" width="200"/>
</p>

Dappnode package responsible for providing DNS resolution

It is an AragonApp whose repo is deployed at this address: [0xb7e15019b306b9d76068742330e10cdc61bf5006](https://etherscan.io/address/0xb7e15019b306b9d76068742330e10cdc61bf5006) and whose ENS address is: [bind.dnp.dappnode.eth](https://etherscan.io/enslookup?q=bind.dnp.dappnode.eth])

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- git

  Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) commandline tool.

- docker

  Install [docker](https://docs.docker.com/engine/installation). The community edition (docker-ce) will work. In Linux make sure you grant permissions to the current user to use docker by adding current user to docker group, `sudo usermod -aG docker $USER`. Once you update the users group, exit from the current terminal and open a new one to make effect.

- docker-compose

  Install [docker-compose](https://docs.docker.com/compose/install)

**Note**: Make sure you can run `git`, `docker ps`, `docker-compose` without any issue and without sudo command.

### Building

```
$ git clone https://github.com/dappnode/DNP_BIND
```

```
$ docker-compose build
or
$ docker build --rm -f build/Dockerfile -t bind.dnp.dappnode.eth:dev build
```

## Running

### Start

```
$ docker-compose up -d
```

### Stop

```
$ docker-compose  down
```

### Status

```
$ docker-compose  ps
```

### Logs

```
$ docker-compose  logs -f
```

### Testing

The mission of this repo by itself is only to check the functionality provided by the bind service.

For this, once it has been started, you can run the below command to check that it resolves the expected address:

```
eduadiez~ $ dig @172.33.1.2 bind.dappnode.eth

; <<>> DiG 9.9.4-RedHat-9.9.4-61.el7_5.1 <<>> @172.33.1.2 bind.dappnode.eth
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8657
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;bind.dappnode.eth.		IN	A

;; ANSWER SECTION:
bind.dappnode.eth.	38400	IN	A	172.33.1.3

;; Query time: 2 msec
;; SERVER: 172.33.1.2#53(172.33.1.2)
;; WHEN: Sun Oct 07 11:39:18 CEST 2018
;; MSG SIZE  rcvd: 62

```

## Generating a tar.xz image

[xz](https://tukaani.org/xz/) is required

```
$ docker save bind.dnp.dappnode.eth:dev | xz -e9vT0 > bind.dnp.dappnode.eth_x.y.z.tar.xz
```

You can download the latest tar.xz version from here [releases](https://github.com/dappnode/DNP_BIND/releases).

### Loading a Docker image

```
$docker load -i bind.dnp.dappnode.eth_x.y.z.tar.xz
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/dappnode) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/dappnode/DNP_BIND/tags).

## Authors

- **Eduardo Antuña Díez** - _Initial work_ - [eduadiez](https://github.com/eduadiez)

See also the list of [contributors](https://github.com/dappnode/DNP_BIND/contributors) who participated in this project.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details

## References

[git](https://git-scm.com/)

[docker](https://www.docker.com/)

[docker-compose](https://docs.docker.com/compose/)

[BIND](https://www.isc.org/downloads/bind/)
