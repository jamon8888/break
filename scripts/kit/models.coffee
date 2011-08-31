if typeof window is 'undefined'
  server = true
  uuid = require("node-uuid")
  #kit = exports
  kit = require('./kit.coffee').kit
  #kit = SS.shared.kit.kit
  #collections = SS.shared.collections
  #exports.models = {}
  #exports.collections = {}
  Backbone = require("backbone")
  #Backbone.RelationalModel = require('Backbone-relational')
else
  server = false
  kit = SS.shared.kit.kit
  collections = SS.shared.collections
  #exports.kit = @kit or (@kit = {})
  #exports.models = {}
  #exports.collections = {}
  Backbone = @Backbone
  #uuid = @uuid

class exports.app extends kit.model
  type: 'app'
  initialize: ->
    super
    @set type: 'app'
    @addChildCollection('artists', exports.artists)
    @addChildCollection('venues', exports.venues)
    @addChildCollection('events', exports.events)

class exports.artist extends kit.model
  type: 'artist',
  url: => '/artists/' + @get('id')
  values:
    modelType: 'artist'
    created: Date.now
    updated: Date.now
  data:
    name: {type: 'string', default: null}
    email: {type: 'string', default: null}
    address: {type: 'string', default: null}
    images: {type: 'media', default: null}
    website: {type: 'string', default: null}
    #tags: {type: 'string', default: null}
  #relations: [
    #type: Backbone.HasMany
    #key: 'venues'
    #relatedModel: 'kit.models.event'
    #reverseRelation: key: 'artist'
  #]
  venues: []

class exports.event extends kit.model
  type: 'event',
  url: => '/events/' + @get('id')
  values:
    modelType: 'event'
    created: Date.now
    updated: Date.now
  data:
    title: {type: 'string', default: null}
    date: {type: 'string', default: null}
    images: {type: 'media', default: null}
    #tags: {type: 'string', default: null}
  artist: []
  venue: []

class exports.venue extends kit.model
  type: 'venue',
  url: => '/venues/' + @get('id')
  values:
    modelType: 'venue'
    created: Date.now
    updated: Date.now
    uuid: null
  data:
    title: {type: 'string', default: null}
    location: {type: 'location', default: null}
    email: {type: 'string', default: null}
    address: {type: 'string', default: null}
    images: {type: 'media', default: null}
    website: {type: 'string', default: null}
    #tags: {type: 'string', required: false, default: null}
  #relations: [
    #type: Backbone.HasMany
    #key: 'artists'
    #relatedModel: 'event'
    #reverseRelation: key: 'venue'
  #]
  artists: []


class exports.artists extends kit.collection
  model: exports.artist
  url: '/artists'
class exports.venues extends kit.collection
  model: exports.venue
  url: '/venues'
class exports.events extends kit.collection
  model: exports.event
  url: '/events'

###
#sort events by
#  date
#  proximity
#  featured
#
#sort artists by
#  name
#  recent events
#
#sort galleries by
#  name
#  recent events
#

#filter events by
#  date (mon/tue/...)
#  category (art types)
#  tags
#  region
  #orangerie = new exports.models.gallery(name: "Orangerie")
  #orangerie.bind "add:employees", (model, coll) ->
  #dali.get("galleries").add company: niceCompany

  #initialize: ->
    #super
    #@register()
    #@set({url: '/' + @type + '/' + @title + '/' })
  #@set({url: '/' + @type + '/' + @title + '/' })
    #if @isNew() then return '/elements/new/'
  #url: ->
    #return 'elements/' + @attributes.title
    #@weight = 1000

    #relations: [
      #{
        #type: Backbone.HasMany #// Use the type, or the string 'HasOne' or 'HasMany'.
        #key: 'occupants'
        #relatedModel: 'Person'
        #includeInJSON: false
        #reverseRelation: {
          #key: 'livesIn'
        #}
      #},
      #{ #// Create a (recursive) one-to-one relationship
        #type: Backbone.HasOne,
        #key: 'user',
        #relatedModel: 'User',
        #reverseRelation: {
          #type: Backbone.HasOne,
          #key: 'person'
        #}
      #}
    #]
  #initialize: ->
    #@elements: new exports.collections.Element
##
class CommentList extends Backbone.Collection
  url : "/comments",
  model : CommentModel,
  comparator : (comment) ->
    return comment.get("date")

Comments = new CommentList()

class EditView extends Backbone.View
  el : $("#edit"),

  events :
    "click #send" : "onSubmit"

  initialize : ->
    _.bindAll(@, "onSubmit")

  onSubmit : ->
     name = $("#name").val()
     text = $("#text").val()
    name = name.replace(/&/g, '&amp').replace(/</g, '&lt').replace(/"/g, '&quot')
    text = text.replace(/&/g, '&amp').replace(/</g, '&lt').replace(/"/g, '&quot')
    Comments.create(
      "name" : name,
      "text" : text,
      "date" : new Date().getTime()
    )

class EntryView extends Backbone.View
  tagName : "tr",

  template : _.template($("#entry-template").html()),
  events :
    "click .delete" : "deleteMe",
    "dblclick td" : "dummyFetch"

  initialize : ->
    _.bindAll(@, 'render', 'deleteMe', 'dummyFetch')
    @model.bind('change', @render)


  dummyFetch : ->
    @model.fetch()

  render : ->
     content = @model.toJSON()
    $(@el).html(@template(content))
    return @

  deleteMe : ->
    if(@model)
      @model.destroy()
    $(@el).fadeOut("fast",->
      $(@).remove()
    )

class CommentsTable extend Backbone.View
  el: $("#comments"),

  initialize : ->
    _.bindAll(@, 'refreshed', 'addRow', 'deleted')

    Comments.bind("refresh", @refreshed)
    Comments.bind("add", @addRow)
    Comments.bind("remove", @deleted)

  addRow : (comment) ->
     view = new EntryView(model: comment)
     rendered = view.render().el
    @el.prepend(rendered)

  refreshed : ->
    $("#comments").html("")
    if(Comments.length > 0)
      Comments.each(@addRow)

  deleted : ->
    @refreshed()

class App extends Backbone.Controller
  initialize : ->
    Comments.fetch()

new EditView()
new CommentsTable()
new App()
