require('coffee-script')
sys = require('sys')
nodeio = require 'node.io'
async = require 'async'
Base = require('./base.coffee').class
cradle = require('cradle')
_ = require("underscore")._

class Task extends Base
  input: false
  run: ->
    if @options.args.length < 3 then @exit
    @task = @options.args[0]
    @database = @options.args[1]
    @keys = @options.args.slice(2)
    @db = new(cradle.Connection)().database(@database)
    @data = []
    @lang = 'fr'
    async.auto(
      data: (a) =>
        #fetch ids from database
        @db.get @keys, (err, docs) =>
          for doc in docs
            @data.push doc.doc
          a()
      process: ['data', (b) =>
        switch @task
          when 'links'
            Base::links @, @data, '10', (links) =>
              _.each @data, (i, index) ->
                i.links = links[index]
              #@links = links
              b()
          when 'images'
            Base::images @, @data, '10', (images) =>
              _.each @data, (i, index) ->
                i.images = images[index]
              #@images = images
              b()
          when 'both'
            async.parallel [
              (c) =>
                Base::links @, @data, '10', (links) =>
                  _.each @data, (i, index) ->
                    i.links = links[index]
                  #@links = links
                  c()
              (c) =>
                Base::images @, @data, '10', (images) =>
                  _.each @data, (i, index) ->
                    i.images = images[index]
                  #@images = images
                  c()
            ], =>
              b()
          when 'tags'
            async.series [
              (c) =>
                #Use english text for tagging, more results...
                if @lang is 'en' then input = @text else input = @translations['en']
                Base::tags @, input, (tags) =>
                  _.each @data, (i, index) ->
                    i.tags['en'] = tags[index]
                    @tags = tags
                  c()
              ,(c) =>
                #Translate them
                Base::translate @, @tags, 'en', true, (translations) =>
                  for lang in translations
                    _.each @data, (i, index) ->
                      i.tags[lang] = translations[lang][index]
                  #_.extend(@tags, translations)
                  c()
            ], (err) =>
              b()
          when 'translate'
            Base::translate @, @text, @lang, false, (translations) =>
              for lang in translations
                _.each @data, (i, index) ->
                  i.text[lang] = translations[lang][index]
              #@translations = translations
              b()
          when 'geo'
            Base::geo @, @data, 'France', (addresses, locations) =>
              _.each @data, (i, index) ->
                i.address = addresses[index]
                i.location = locations[index]
              #@addresses = addresses
              #@locations = locations
              b()
          #when 'process'
          else
            @exit()
      ]
      #presave: ['process', ->
      #]
      save: ['process', =>
        #console.log(@data)
        #@emit(@data)
        @db.save @data, (err, res) =>
          if err then console.log(err)
          @emit()
      ]
    )

#nodeio.start(Task, (err, output) ->
  ##console.log(output); //[4,5,6]
#}, true)
@class = Task
@job = new Task({timeout:30, proxy: 'http://121.101.214.221:80'})
