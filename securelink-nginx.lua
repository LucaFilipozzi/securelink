-- Copyright (C) 2013 Luca Filipozzi <luca.filipozzi@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

package.path = "/etc/nginx/?.lua;" .. package.path

local securelink = require("securelink-common")

local function get_uri()
  local _key = ngx.var.key  -- set in nginx configuration (eg: "secret")
  local _src = ngx.var.src  -- set in nginx configuration (eg: "/foo")
  local _tgt = ngx.var.tgt  -- set in nginx configuration (eg: "/bar")
  local _uri = ngx.var.uri  -- set by nginx automatically
  return _key, _src, _tgt, _uri
end

local function set_uri(_uri, _ext)
  ngx.req.set_uri(_uri)
  ngx.header["Content-Type"] = _ext
end

local function return_status(_status)
  ngx.exit(_status)
end

local function log_error(_error)
  ngx.log(ngx.ERR, _error)
end

securelink.return_status = return_status
securelink.log_error = log_error

-- get_uri() -> rewrite_uri() -> set_uri()
set_uri(securelink.rewrite_uri(get_uri()))

-- vim: set ts=2 sw=2 et ai si fdm=indent:
