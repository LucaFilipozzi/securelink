#!/usr/bin/env lua
-- Copyright (C) 2013 Luca Filipozzi <luca.filipozzi@gmail.com>
--
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

local md5 = require("md5")

function hmac_md5(_key, _msg)
  if type(_key) ~= "string" or type(_msg) ~= "string" then
    return nil
  end

  local _blocksize = 64 -- 512 bits for md5

  -- keys longer than blocksize are shortened
  if string.len(_key) > _blocksize then -- truncate
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

function base16_encode(_str)
  return (_str:gsub('.', function(_c)
    return string.format('%02x', string.byte(_c))
  end))
end

local _host = "www.example.org"
local _src  = "/foo"
local _hash = "2816d3b56ebeaabd4af3a31d9b1c17f545a8898a"
local _type = "application/x-gzip"
local _file = "blah-1.2.tar.gz"

local _key = "secret"
local _msg = _hash .. "/" .. base16_encode(_type) .. "/" .. _file

local _hmac = hmac_md5(_key, _msg)

local _rest = _src .. "/" .. _hmac .. "/" .. _msg
print("https://" .. _host .. _rest)
