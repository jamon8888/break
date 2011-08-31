# Server Config + Routes
# ----------------------

exports.init = (middleware) ->
  express = require('express')
  app = express.createServer(middleware)
  app.register('.html', require('eco'))

  app.configure ->
    app.set 'views', SS.root
    app.use express.static(SS.root)

  app.get '/', (req, res) ->
    res.render('index')

  app
