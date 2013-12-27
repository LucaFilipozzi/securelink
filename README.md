### The Background

Debian's snapshot service (snapshot.debian.org) provides a mechanism to access
point-in-time views of the Debian archive.

In order to avoid duplicating archive items (many versions of a package might
refer to the upstream source, say), the back-end storage stores archive items
with names based on the SHA1 checksum the contents of the archive item in a
hashed directory structure.

For example, instead of storing /path/to/blah-1.2.tar.gz (by file name), the
back-end stores /path/to/28/16/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a (by
hash name)

The front-end provides the mapping between the archive item's front-end file
name and the back-end hash name.

### The Opportunity

Debian's snapshot service currently provides access to 25TB of archive items,
growing at 5TB/yr.

Debian is actively seeking partners to host the archive items since Debian's
current storage environments reaching capacity.

This necessitates an examination of the service from the perspective of
splitting the front-end from the back-end such that partners willing to provide
the back-end would not be required to provide a dedicated host or to make
significant changes to their web server configuration.

That said, it is a requirement that the mapping between the front-end and the
back-end be both user-friendly (users access archive items by file name rather
than hash name) and secure (users can trust the mapping between the file name
and the hash name).

### The Proposal

Borrowing concepts from [nginx's][1] [secure_link][2] and [lighttpd's][3]
[mod_secdownload][4], the proposal is to configure the front-end to
generate *secure links* that, when interpreted by the back-end, have three
features:

1. provide a mapping between the file name and the hash name for the archive item
2. provide a content type for the archive item
3. provide non-repudiation via hashed message authentication code

Specifically, the mode of operation is:
 
- the user searches for a specific file (blah-1.2.tar.gz, say) via the front-end
- the front-end provides a link to the desired file
- the user requests to download the linked-to file from the front-end
- the front-end responds with 302, redirecting the user to `http://[host][src]/[hmac]/[hash]/[type]/[file]` where
    - `[host]` = the hostname of the back-end
    - `[src]` = the source uri path
    - `[hmac]` = an md5 hmac where
        - `[key]` = a shared secret known to both the front-end and back-end
        - `[msg]` = the concatenation of `[hash]`, `[type]` and `[file]` separated by forward slash
    - `[hash]` = the hash name of the archive item
    - `[type]` = the content type of the archive item (base16 encoded)
    - `[file]` = the file name of the archive item
- the back-end compares the computed hmac with the received hmac and, if equal,
    - sets the content type to `[type]` (decoded), and
    - rewrites the request uri to `/[tgt]/[dir1]/[dir2]/[hash]` where
        - `[tgt]` = the target uri path
        - `[dir1]` = first two hex digits of `[hash]`
    - `[dir2]` = next two hex digits of `[hash]`
- the user's browser will either display (inline) or offer to save (attachment) the file depending on the content type

### An Example

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

Then the `[hmac]` is computed as:

```lua
hmac = hmac_md5(key, [hash] .. "/" .. type .. "/" .. file)
```

yielding:

```lua
hmac = "e54b536a0d3f695112bb5790bd741206"
```

The redirection URL is composed as:

```lua
uri = "https://" .. host .. src .. "/" .. hmac .. "/" .. hash .. "/" .. type .. "/" .. file
```

yielding:

```lua
uri = "https://www.example.org/foo/e54b536a0d3f695112bb5790bd741206/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a/6170706c69636174696f6e2f782d677a6970/blah-1.2.tar.gz"
```

After verifying the `[hmac]`, the web server rewrites the URL to:

```lua
uri = "https://" .. host .. tgt .. "/" .. dir1 .. "/" .. dir2 .. "/" .. hash
```

yielding:

```lua
uri = "https://www.example.org/bar/28/16/2816d3b56ebeaabd4af3a31d9b1c17f545a8898a"
```

The client saves the content as:

`blah-1.2.tar.gz`

since the response header contains:

```html
Content-Type: application/x-gzip
```


[1]: http://nginx.org/
[2]: http://nginx.org/en/docs/http/ngx_http_secure_link_module.html
[3]: http://www.lighttpd.net/
[4]: http://redmine.lighttpd.net/projects/1/wiki/Docs_ModSecDownload

