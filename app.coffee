fs = require 'fs'
dns = require 'dns'
child_process = require 'child_process'
express = require 'express'

app = express()
app.set 'view engine', 'hjs'
app.get /([a-z])(\d+)(-[-\w]*)?(\..+)?/, (req, res) ->
  console.log req.params
  domain = req.params[0] + '.lv5.ac'
  port = parseInt req.params[1]
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
      app.render template, username: params[1], password: req.params[1], host: domain, (err, mobileconfig)->
        console.log mobileconfig
        openssl = child_process.execFile 'openssl', ['smime', '-sign', '-signer', 'railgun.ac.crt', '-inkey', 'railgun.ac.key', '-certfile', 'intermediate_domain_ca.crt', '-nodetach', '-outform', 'der'], encoding: 'buffer', (error, stdout, stderr)->
          if err
            return res.status(500).send(err)
          if stderr.length > 0
            return res.status(500).send(stderr)
          res.type 'application/x-apple-aspen-config'
          res.end stdout
        openssl.stdin.end mobileconfig
    else
      dns.resolve req.params[0] + '.lv5.ac', (err, address, family) ->
        if err
          return res.status(500).send(err)
        res.type 'application/x-ns-proxy-autoconfig'
        res.render 'proxy', https_proxy: "#{domain}:#{port+1}", http_proxy: "#{address}:#{port}", http_proxy: "#{domain}:#{port}"

if fs.existsSync '/var/run/railgun-profiles.sock'
  fs.unlinkSync '/var/run/railgun-profiles.sock'
app.listen '/var/run/railgun-profiles.sock'
