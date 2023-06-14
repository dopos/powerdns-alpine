# PowerDNS Docker Container

* Small Alpine based Image
* MySQL (default), Postgres, SQLite and Bind backend included
* DNSSEC support optional
* Automatic MySQL database initialization
* Latest PowerDNS version (if not pls file an issue)
* Guardian process enabled
* Graceful shutdown using pdns_control

## Supported tags

* PowerDNS Version 4.8.0

## Usage

```shell
# Start a MySQL Container
$ docker run -d \
  --name pdns-mysql \
  -e MYSQL_ROOT_PASSWORD=supersecret \
  -v $PWD/mysql-data:/var/lib/mysql \
  mariadb:10.1

$ docker run --name pdns \
  --link pdns-mysql:mysql \
  -p 53:53 \
  -p 53:53/udp \
  -e PDNS_GMYSQL_USER=root \
  -e PDNS_GMYSQL_PASS=supersecret \
  -e PDNS_GMYSQL_PORT=3306 \
  -e PDNS_LAUNCH=gpgsql,bind \
  -e PDNS_API=yes \
  ghcr.io/dopos/powerdns-alpine \
    --cache-ttl=120 \
    --allow-axfr-ips=127.0.0.1,123.1.2.3
```

## Configuration

**Environment Configuration:**

All of environment variables with `PDNS_` prefix are saved to `/etc/pdns/pdns.conf` according to following rules:

* do nothing if `/etc/pdns/pdns.conf` exists already
* if name has `_FILE` suffix - read value from file and rename suffix
* remove `PDNS_` prefix
* replace `_` with `-`
* lowercase variable name
* write resulting name and value fo file

* To support docker secrets, use same variables as above with suffix `_FILE`.
* Want to disable mysql initialization? Use `MYSQL_AUTOCONF=false`
* DNSSEC is disabled by default, to enable use `MYSQL_DNSSEC=yes`
* Want to use own config files? Mount a Volume to `/etc/pdns/conf.d` or simply overwrite `/etc/pdns/pdns.conf`

**PowerDNS Configuration:**

Append the PowerDNS setting to the command as shown in the example above.
See `docker run --rm ghcr.io/dopos/powerdns-alpine --help`

## License

[GNU General Public License v2.0](https://github.com/PowerDNS/pdns/blob/master/COPYING) applyies to PowerDNS and all files in this repository.


## Maintainer

* Aleksei Kovrizhkin <lekovr+dopos@gmail.com>

### Credits

* Christoph Wiechert <wio@psitrax.de>: Original project's author
* Mathias Kaufmann <me@stei.gr>: Reduced image size

