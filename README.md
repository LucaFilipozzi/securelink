# secure-link

a mechanism for front-end web applications to provide intuitive and safe links
into remote web-accessible back-end storage

- [Overview](#overview)
    - [Background](#background)
    - [Opportunity](#opportunity)
    - [Proposal](#proposal)
    - [Example](#example)
- [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Installation](#installation)

## Overview

### Background

Debian's [snapshot.debian.org][0] service provides a mechanism to access
point-in-time views of the Debian archive.

In order to avoid duplicating archive items (many versions of a package might
refer to the same upstream source tarball, say), the back-end storage stores
archive items with names based on the SHA1 checksum the contents of the archive
item in a hashed directory structure.

For example, instead of storing archive items by file name:

```
/path/to/blah-1.2.tar.gz
```

the back-end stores them by hash name:

```
/path/to/28/16/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a
```

The front-end provides the mapping between the archive item's front-end file
name and back-end hash name.

### Opportunity

Debian's [snapshot.debian.org][0] service currently provides access to 25 TB of
archive items.  The archive is growing at 5 TB/yr.

Debian is actively seeking partners to host the archive items since Debian's
current storage infrastructure is reaching capacity.

This necessitates an examination of the service from the perspective of
splitting the front-end from the back-end such that partners willing to provide
the back-end are not required to makesignificant changes to their web server
configuration.

That said, it is a requirement that the mapping between the front-end and the
back-end be both intuitive (users can access archive items by file name rather
than by hash name) and safe (users can trust the mapping between the file name
and the hash name).

### Proposal

Borrowing concepts from [nginx's][1] [secure_link][2] and [lighttpd's][3]
[mod_secdownload][4], the proposal is to configure the front-end to
generate a **secure link** that, when interpreted by the back-end, have three
features:

1. provide a mapping between the file name and the hash name for the archive
   item
2. provide a content type for the archive item
3. provide non-repudiation of the mapping and content-type

Specifically, the proposed mode of operation is:
 
- the user searches for a specific file (blah-1.2.tar.gz, say) via the
  front-end
- the front-end provides a link to the desired file
- the user requests to download the linked-to file
- the front-end responds with 302, redirecting the user to
  `http://[host][src]/[hmac]/[hash]/[type]/[file]` where
    - `[host]` is the hostname of the back-end
    - `[src]` is the source URI path
    - `[hmac]` is the MD5 HMAC where
	- `[key]` is the shared secret known to both the front-end and back-end
	- `[msg]` is the concatenation of `[hash]`, `[type]` and `[file]`
	  separated by forward slash
    - `[hash]` is the hash name of the archive item
    - `[type]` is the content type of the archive item (base16 encoded)
    - `[file]` is the file name of the archive item
- the back-end compares the computed HMAC with the received HMAC and, if equal,
    - sets the content type to `[type]` (decoded), and
    - rewrites the request URI to `/[tgt]/[dir1]/[dir2]/[hash]` where
        - `[tgt]` is the target URI path
        - `[dir1]` is first two hex digits of `[hash]`
        - `[dir2]` is next two hex digits of `[hash]`
- the user's browser will either display (inline) or offer to save (attachment)
  the file depending on the content type

The purpose of the `[src]` to `[tgt]` rewriting is to allow the back-end
operator to specify **secure link** rewriting for request URIs in the `[src]`
namespace while simultaneously serving the hash files from the `[tgt]`
namespace.

### Example

Suppose that the parameters are as follows:

```lua
host = "www.example.org"
src  = "/foo"
tgt  = "/bar"
hash = "2816d3b56ebeaabd4af3a31d9b1c17f545a8898a"
type = "6170706c69636174696f6e2f782d677a6970" -- "application/x-gzip" base16-encoded
file = "blah-1.2.tar.gz"
key  = "secret"
```

Then the `hmac` is computed as:

```lua
hmac = hmac_md5(key, hash .. "/" .. type .. "/" .. file)
```

yielding:

```lua
hmac = "e54b536a0d3f695112bb5790bd741206"
```

The redirection URL that the front-end generates is composed as:

```lua
uri = "https://" .. host .. src .. "/" .. hmac .. "/" .. hash .. "/" .. type .. "/" .. file
```

yielding:

```lua
uri = "https://www.example.org/foo/e54b536a0d3f695112bb5790bd741206/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a/6170706c69636174696f6e2f782d677a6970/blah-1.2.tar.gz"
```

After verifying the `hmac`, the back-end rewrites the request URI to:

```lua
uri = "https://" .. host .. tgt .. "/" .. dir1 .. "/" .. dir2 .. "/" .. hash
```

yielding:

```lua
uri = "https://www.example.org/bar/28/16/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a"
```

The client saves the content as:

`blah-1.2.tar.gz`

since the original request to the front-end ended in `blah-1.2.tar.gz` and
because the response header contains:

```html
Content-Type: application/x-gzip
```


## Getting Started

### Requirements

The back-end **secure link** capability is provided via a lua script.
Consequently, the web-server deployed on the back-end must support URI
rewriting via call-out to an external script.  This is true of nginx, lighttpd
and apache2 in Debian [wheezy][5].

#### nginx

```
apt-get install nginx-extras lua-md5
```

#### lighttpd

```
apt-get install lighttpd-mod-magnet lua-md5
```

#### apache2

```
apt-get install apache2 lua5.1 lua-md5
```

### Installation

Copy the web server-specific script and the shared script to the web server's
configuration directory.

#### nginx

```
wget -P /etc/nginx https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-common.lua
wget -P /etc/nginx https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-nginx.lua
```

#### lighttpd

```
wget -P /etc/lighttpd https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-common.lua
wget -P /etc/lighttpd https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-lighttpd.lua
```

#### apache2

```
wget -P /etc/apache2 https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-common.lua
wget -P /etc/apache2 https://raw.github.com/LucaFilipozzi/secure-link/master/secure-link-apache2.lua
```

### Configuration

#### nginx

The configuration for nginx on the back-end is trivial, primarily due to
nginx's excellent use of lua as an well-integrated mechanism for extending
functionality.

```
location /foo/ {
  set $key "secret";
  set $src "/foo";
  set $tgt "/bar";
  rewrite_by_lua_file secure-link-nginx.lua;
}
```

#### lighttpd

The configuration for lighttpd on the back-end is also trivial but leverages
[mod_magnet][6].  Thus, it is important that the lua script never blocks and
returns quickly.

```
server.modules = {
  ...
  "mod_magnet",
  "mod_setenv",
  ...}

$HTTP["url"] =~ "^/foo/" {
  setenv.add-environment = ("key" => "secret", "src" => "/foo", "tgt" => "/bar")
  magnet.attract-physical-path-to = ("/etc/lighttpd/secure-link-lighttpd.lua")
}
```

#### apache2

The configuration for apache2 is more complex as it leverages
[mod_rewrite][7]'s [RewriteMap][8] which passes context into scripts via STDIN
and expects responses via STDOUT.  Thus, the input parameters (`[key]`,
`[src]`, `[tgt]` and `[uri]`) are concatenated into a single input string and
the output string is parsed for two output parameters (`[uri]`, now rewritten,
and `[type]`).

```
RewriteLock /var/run/apache2/rewrite.lock

<VirtualHost ...>
  ...
  RewriteEngine On
  RewriteMap securelink prg:/etc/apache2/secure-link-apache2.lua
  RewriteRule ^(/foo/.+) ${securelink:secret+/foo+/bar+%{REQUEST_URI}} [C,DPI]
  RewriteRule ^(/bar/[^+]+)+(.+) $1 [L,T=$2]
  ...
</VirtualHost>
```


[0]: http://snapshot.debian.org
[1]: http://nginx.org
[2]: http://nginx.org/en/docs/http/ngx_http_secure_link_module.html
[3]: http://www.lighttpd.net
[4]: http://redmine.lighttpd.net/projects/1/wiki/Docs_ModSecDownload
[5]: http://www.debian.org/releases/wheezy
[6]: http://redmine.lighttpd.net/projects/1/wiki/Docs_ModMagnet
[7]: http://httpd.apache.org/docs/2.2/mod/mod_rewrite.html
[8]: http://httpd.apache.org/docs/2.2/mod/mod_rewrite.html#rewritemap
[9]: https://github.com/LucaFilipozzi/secure-link/issues
