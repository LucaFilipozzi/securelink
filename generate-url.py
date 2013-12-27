#!/usr/bin/env python
# Copyright (C) 2013 Luca Filipozzi <luca.filipozzi@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import hmac
import base64

_host = "www.example.org"
_src  = "/foo"
_hash = "2816d3b56ebeaabd4af3a31d9b1c17f545a8898a"
_type = "application/x-gzip"
_file = "blah-1.2.tar.gz"

_key = "secret"
_msg = "/".join([_hash, base64.b16encode(_type).lower(), _file])

_hmac = hmac.new(_key, _msg).hexdigest()

_rest = "/".join([_src, _hmac, _msg])
print "https://" + _host + _rest
