require('nko')('WP4Tfg3Wdz0fNnzA')

isProduction = process.env.NODE_ENV == 'production'
http = require('http')
port = if isProduction then 80 else 8000

server = http.createServer (req, res) ->
  # http://blog.nodeknockout.com/post/35364532732/protip-add-the-vote-ko-badge-to-your-app
  voteko = '<iframe src="http://nodeknockout.com/iframe/pastel-734m" frameborder=0 scrolling=no allowtransparency=true width=115 height=25></iframe>'

  res.writeHead 200, 'Content-Type': 'text/html'
  res.end '<html><body>' + voteko + '</body></html>\n'

server.listen port, (err) ->
  if err
    console.error(err)
    process.exit(-1)

  # if run as root, downgrade to the owner of this file
  if process.getuid() == 0
    require('fs').stat __filename, (err, stats) ->
      return console.error(err) if err
      process.setuid stats.uid

  console.log "Server running at http://0.0.0.0:#{port}/"
