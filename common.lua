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

local snapshot = {}

local md5 = require("md5")

function hmac_md5(_key, _msg)
  if type(_key) ~= "string" or type(_msg) ~= "string" then
    return nil
  end

  local _blocksize = 64 -- 512 bits for md5

  -- keys longer than blocksize are shortened
  if string.len(_key) > _blocksize then
    _key = md5.sum(_key)
  end

  -- keys shorter than blocksize are zero-padded
  if string.len(_key) < _blocksize then
    _key = _key .. string.rep(string.char(0x00), _blocksize - string.len(_key))
  end

  local _opad = md5.exor(string.rep(string.char(0x5c), _blocksize), _key)
  local _ipad = md5.exor(string.rep(string.char(0x36), _blocksize), _key)

  return md5.sumhexa(_opad .. md5.sum(_ipad .. _msg))
end

function base16_decode(_str)
  return (_str:gsub('..', function(_cc)
    return string.char(tonumber(_cc, 16))
  end))
end

function snapshot.do_transform(_key, _src, _tgt, _uri)
  if not _key or not _src or not _tgt then
    log_error("web server incorrectly configured")
    return_status(500) -- internal server error
  end

  local _hmac, _msg = string.match(_uri, "^" .. _src .. "/(%x+)/(.*)$")
  if not _hmac or not _msg then
    log_error("hmac and message not found in uri")
    return_status(400) -- bad request
  end

  if hmac_md5(_key, _msg) ~= string.lower(_hmac) then
    log_error("computed hmac does not match the received hmac")
    return_status(401) -- unauthorized
  end

  local _hash, _type, _file = string.match(_msg, "^(%x+)/(%x+)/([^/]+)$")
  if not _hash or not _type or not _file then
    log_error("message does contain necessary components")
    return_status(403) -- forbidden
  end

  local _dir1, _dir2 = string.match(_hash, "^(%x%x)(%x%x)%x+$")

  -- update URI
  local _uri = _tgt .. "/" .. _dir1 .. "/" .. _dir2 .. "/" .. _hash

  -- update content-type (EXTension)
  local _ext = base16_decode(_type)

  return _uri, _ext
end

return snapshot

-- vim: set ts=2 sw=2 et ai si fdm=indent:
