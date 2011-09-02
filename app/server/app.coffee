# Server-side Code
_ = require 'underscore'
fs = require 'fs'
async = require 'async'
child = require('child_process')
cradle = require('cradle')
db = new(cradle.Connection)().database('telerama_backup')

exports.actions =

  init: (cb) ->
      SS.app = new SS.shared.models.app
      #db.view 'events/countByVenue', {keys:false,group:'true'}, (err, res) ->
        #console.log(res)
      cb(SS.app.xport())

  export: (value, cb) ->
      SS.app[value].fetch
        success: (collection, response) ->
          cb(SS.app.xport())
        error: (collection, response) ->
          cb(SS.app.xport())

  reload: (id, cb) ->
    type = 'venues'
    model = SS.app[type].get(id)
    model.fetch
      success: (collection, response) ->
        cb(model.xport())
      error: (collection, response) ->
        cb(model.xport())

  #options: (obj)
  #  db: database (string)
  #  task: [links|images|both|translate|geo|readable] (string)
  #  items: (array)
  task: (options, cb) ->
    options.db = 'test'
    args = []
    args.push 'task'
    args.push options.task
    args.push options.db
    for i in options.items
      args.push i
    cmd = 'node.io'
    cwd = process.cwd() + '/scripts'
    called = false
    proc = child.spawn(cmd, args, {cwd: cwd})
    stdout = ''
    stderr = ''

    proc.stdout.on 'data', (data) ->
      stdout += data

    proc.stderr.on 'data', (data) ->
      if (/^execvp\(\)/.test(data.asciiSlice(0, data.length)))
        cb('Failed to start child process.')
        called = true
      else
        stderr += data

    proc.on 'exit', ->
      if not called
        #cb(null, stdout, stderr)
        cb('???')

  dbView: (settings, cb) ->
    #settings.options ?= {}
    db.view settings.name, settings.options, (err, res) ->
      if not err then cb(res)
      else cb(err)

  dbQuery: (settings, cb) ->
      settings.options ?= {}
      console.log('options',settings.options)
      db.query 'GET', settings.path, settings.options, (err, res) ->
          if not err then cb(res)
          else cb(err)
  change: (cb) ->
      #cb('done')
      async.parallel([
          (callback) -> SS.app.venues.fetch(
                success: (collection, response) ->
                  #console.log(collection)
                  callback()
                error: (collection, response) ->
                  #console.log(collection)
                  callback()
              )
          (callback) -> SS.app.artists.fetch(
                success: (collection, response) ->
                  #console.log(collection)
                  callback()
                error: (collection, response) ->
                  #console.log(collection)
                  callback()
              )
          (callback) -> SS.app.events.fetch(
                success: (collection, response) ->
                  callback()
                error: (collection, response) ->
                  callback()
              )
      ], (err, results) ->
          _.each(SS.app.events.models, (a) ->
            artists = a.get('artists')
            venues = a.get('venue')
            artistArray = []
            venueArray = []
            for id in artists
              model = _.find SS.app.artists.models, (b) ->
                return id is b.attributes.sid
              if model
                artistArray.push model.get('id')
              #else console.log(id)
            for id in venues
              model = _.find SS.app.venues, (b) ->
                return id is b.attributes.sid
              if model
                venueArray.push model.get('id')
              #else console.log(id)
            #console.log(venueArray)
            #console.log(artistArray)
          )
          cb('done')
      )

  exportAll: (cb) ->
      async.parallel([
          (callback) -> SS.app.venues.fetch(
                success: (collection, response) ->
                  console.log(collection)
                  callback()
                error: (collection, response) ->
                  console.log(collection)
                  callback()
              )
          (callback) -> SS.app.artists.fetch(
                success: (collection, response) ->
                  console.log(collection)
                  callback()
                error: (collection, response) ->
                  console.log(collection)
                  callback()
              )
          (callback) -> SS.app.events.fetch(
                success: (collection, response) ->
                  callback()
                error: (collection, response) ->
                  callback()
              )
      ], (err, results) ->
          cb(SS.app.xport())
      )

  readGeo: (cb) ->
      fields = []
      file = fs.readFileSync('/var/www/scrappy/metro.csv', 'utf8')
      data = file.split('\n')
      _.each data, (d)->
        fields.push _.compact(d.split('\t'))
      cb(fields)

  modelSave: (model, cb) ->
      console.log(SS.app)
      console.log(model.attrs.type)
      console.log(SS.app[model.attrs.type + 's'])
      if model.attrs.id
        m = SS.app[model.attrs.type + 's'].get(model.attrs.id).mport(model).save()
        cb(m.xport())
      else
        m = SS.app[model.attrs.modelType + 's'].create(model.attrs)
        cb(m)
      #cb(application.xport())

  sync: (cb) ->
      cb(application.xport())

