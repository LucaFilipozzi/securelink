#!/usr/bin/env lua
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

local common = require("common")

function do_extract(_str)
  -- pass in four parameters, delineated by '+' since RewriteMap
  -- provides no means to pass parameters via the environment
  local _key, _src, _tgt, _uri = string.match(_str, "^([^+]+)+([^+]+)+([^+]+)+(.+)$")
  return _key, _src, _tgt, _uri
end

function return_status(_status)
  error()
end

function log_error(_error)
  -- intentionally empty .. mechanism not available in apache via RewriteMap
end

function do_load(_uri, _ext)
  io.write(_uri .. "+" .. _ext)
end

-- extract -> transform -> load
while true do
  if not pcall(function () do_load(common.do_transform(do_extract(io.read()))) end) then
    io.write("NULL")
  end
  io.write("\n")
  io.flush()
end

-- vim: set ts=2 sw=2 et ai si fdm=indent:
