dns = require('dns')
express = require('express')
app = express()
app.set 'view engine', 'hjs'
app.get /([a-z])(\d+)(\..+)?/, (req, res) ->
  domain = req.params[0] + '.lv5.ac'
  port = parseInt(req.params[1])
  dns.resolve req.params[0] + '.lv5.ac', (err, address, family) ->
    if err
      return res.status(500).send(err)
    switch req.params[2]
      when '.smartproxy'
        res.render 'smartproxy', proxy: address + ':' + req.params[1]
      else
        res.type 'application/x-ns-proxy-autoconfig'
        res.render 'proxy', https_proxy: "#{domain}:#{port+1}", http_proxy: "#{address}:#{port}"
    return
  return
app.listen 3000
