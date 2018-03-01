# DNP_BIND

Dappnode package responsible for providing DNS resolution

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
$ docker build --rm -f build/Dockerfile -t dnp_bind:dev build 
```

## Running

### Start
```
$ docker-compose up -d
```
### Stop
```
$ docker-compose down
```
### Status
```
$ docker-compose ps
```
### Logs
```
$ docker-compose logs -f
```

### Testing

The mission of this repo by itself is only to check the functionality provided by the bind service.

For this, once it has been started, yo cand run the above command to check that it resolves the expected address:

```
eduadiez~ $ dig @localhost bind.dappnode.eth

; <<>> DiG 9.9.7-P3 <<>> @localhost bind.dappnode.eth
; (2 servers found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27001
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;bind.dappnode.eth.		IN	A

;; ANSWER SECTION:
bind.dappnode.eth.	38400	IN	A	10.17.0.2

;; AUTHORITY SECTION:
eth.			38400	IN	NS	10.17.0.2.eth.

;; ADDITIONAL SECTION:
10.17.0.2.eth.		38400	IN	A	10.17.0.3

;; Query time: 1 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Thu Mar 01 17:22:32 CET 2018
;; MSG SIZE  rcvd: 102
```

**Note**: In case of having the port 53 occupied, you should change them in the file docker-compose.yml by other.

## Generating a tar.xz image

[xz](https://tukaani.org/xz/) is required 

```
$ docker save dnp_bind:dev | xz -9 > dnp_bind.tar.xz
```

You can download the latest tar.xz version from here [releases](https://github.com/dappnode/DNP_BIND/releases).

### Loading a Docker image

```
$docker load -i dnp_bind.tar.xz
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/dappnode) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/dappnode/DNP_BIND/tags). 

## Authors

* **Eduardo Antuña Díez** - *Initial work* - [eduadiez](https://github.com/eduadiez)

See also the list of [contributors](https://github.com/dappnode/DNP_BIND/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## References

[git](https://git-scm.com/)

[docker](https://www.docker.com/)

[docker-compose](https://docs.docker.com/compose/)

[BIND](https://www.isc.org/downloads/bind/)