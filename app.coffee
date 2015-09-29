dns = require 'dns'
child_process = require 'child_process'
express = require 'express'

app = express()
app.set 'view engine', 'hjs'
app.get /([a-z])(\d+)(-[-\w]*)?(\..+)?/, (req, res) ->
  console.log req.params
  domain = req.params[0] + '.lv5.ac'
  port = parseInt req.params[1]
  dns.resolve req.params[0] + '.lv5.ac', (err, address, family) ->
    if err
      return res.status(500).send(err)
    if req.params[2]
      params = req.params[2].split('-')
    console.log req.params[3]
    switch req.params[3]
      when '.smartproxy'
        res.render 'smartproxy', proxy: address + ':' + req.params[1]
      when '.mobileconfig'
        if params[params.length - 1] == 'legacy'
          template = 'ios-legacy'
        else
          template = 'ios'
        app.render template, (err, mobileconfig)->
          child_process.execFile 'openssl', ['smime', '-sign', '-signer', '/etc/nginx/railgun.ac.crt', '-inkey', '/etc/nginx/railgun.ac.key', '-certfile', '/etc/nginx/intermediate_domain_ca.crt', '-nodetach', '-outform', 'der'], (error, stdout, stderr)->
            if err
              return res.status(500).send(err)
            if stderr.length > 0
              return res.status(500).send(stderr)
            res.type 'application/x-apple-aspen-config'
            res.send stdout
      else
        res.type 'application/x-ns-proxy-autoconfig'
        res.render 'proxy', https_proxy: "#{domain}:#{port+1}", http_proxy: "#{address}:#{port}"

app.listen 3000
