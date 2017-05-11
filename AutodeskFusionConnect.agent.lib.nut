// MIT License
//
// Copyright 2016-7 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

class AutodeskFusionConnect {

    static VERSION = "2.0.0";

    _base_url = null;

    // @params : string - hostname for your account provided by autodesk,
    //           string or integer - port for your account provided by autodesk,
    //           optional - boolean - if https protocol should be used in base url
    // @return : null
    constructor(hostname, tcp_port, https = false) {
        local protocol = https ? "https" : "http";
        if (typeof tcp_port == "integer") tcp_port = tcp_port.tostring();
        _base_url = format("%s://%s:%s", protocol, hostname, tcp_port);
    }

    // @params : string - unique id for device,
    //           string - unique message code set in "connect/device_profiles/message",
    //           optional - table or array of tables - data to be sent,
    //           optional - function - callback executed with response from autodesk
    // @return : null if callback provided
    function sendMessage(id, message_code, values=null, cb=null) {
        local body = {};
        local headers = { "Content-Type":"application/json" };
        local url = format("%s/json", _base_url);

        body.target <- id;
        body.code <- message_code;
        if(values) body.values <- values;
        //add timestamp
        body.time <- formatTimestamp();

        local request = http.post(url, headers, http.jsonencode(body));
        request.sendasync(function(res) {
            local response = _processResponse(res);
            if(cb != null) {
                cb(response.err, response.data);
            }
        }.bindenv(this));
    }

    // @params : string - unique id for device,
    //           integer - time in seconds between checks for new messages
    //           function - callback function to run when have new message(s)
    //           optional - function - callback called if error encountered during request
    // @return : null
    function openDirectiveListener(id, timer, onMsg, onErr=null) {
        local body = {};
        local headers = { "Content-Type":"application/json" };
        local url = format("%s/json/directive", _base_url);
        body.target <- id;

        local request = http.post(url, headers, http.jsonencode(body));

        request.sendasync(function(res) {

            local loop = true;
            local response = _processResponse(res);
            if (response.err) {
                if(onErr) { onErr(response.err, response.data); }
            } else {
                if (response.data.count > 0) {
                    onMsg(response.data);
                    // get all messages
                    if(response.data.count > 1) {
                        openDirectiveListener(id, timer, onMsg, onErr);
                        loop = false;
                    }
                }
            }

            if(loop) {
                imp.wakeup(timer, function() {
                    openDirectiveListener(id, timer, onMsg, onErr);
                }.bindenv(this))
            }

        }.bindenv(this));
    }

    // @params : optional - integer - epoch timestamp
    // @return : string - time formatted as 2015-12-03T00:54:51Z
    function formatTimestamp(ts = null) {
        local d = ts ? date(ts) : date();
        return format("%04d-%02d-%02dT%02d:%02d:%02dZ", d.year, d.month+1, d.day, d.hour, d.min, d.sec)
    }

    // Private Functions
    // --------------------------------------------------

    // @params : string - raw response from autodesk cloud
    // @return : table - parsed response table with err and data slots
    function _processResponse(res) {
        local err = null;
        local data = null;

        if(res.statuscode != 200) {
            err = format("Error: HTTP request unsuccessful status code - %i", res.statuscode);
            data = res;
        } else {
            try {
                data = http.jsondecode(res.body);
                if(!data.success) {
                    err = format("Error: %s", data.message);
                }
            } catch(ex) {
                err = format("Error: %s", ex);
                data = res;
            }
        }

        return {"err": err, "data": data};
    }
}
