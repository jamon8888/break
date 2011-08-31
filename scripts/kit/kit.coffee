#if typeof exports != "undefined"
if typeof window is 'undefined'
  server = true
  _ = require("underscore")._
  uuid = require("node-uuid")
  now = require('now')
  Backbone = require("backbone")
  #Backbone.RelationalModel = require('Backbone-relational')
  exports.kit = {}
  #exports.couch = require('backbone-couch')({
    #host: '127.0.0.1'
    #port: '5984'
    #name: 'kit'
  #})
  exports.kit.couch = require('backbone-couch')({
    host: '127.0.0.1'
    port: '5984'
    name: 'data'
  })
  # Uncomment to clean db
  exports.kit.couch.install (err)->
    exports.kit.sync = exports.kit.couch.sync
else
  server = false
  #kit = exports
  _ = @_
  now = @now
  uuid = @uuid
  Backbone = @Backbone
  exports.kit = {}

exports.kit.stash = {}
exports.kit.stash.models = {}
class exports.kit.model extends Backbone.Model
  schema: {}

  initialize : ->
    base = {}
    for field, data of @values
      base[field] = data unless @get(field)
    for field, data of @data
      base[field] = data.default unless @get(field)
    @set(base)
    @register()

  url: ->
    @get('type') + 's/' + @get('id')

  isNew: ->
    @get('isNew')

  #fetch : (options) ->
    #options or (options = {})
    #model = @
    #success = (resp) ->
      #if (!model.set(model.parse(resp), options)) then return false
      #if (options.success) then options.success(model, resp)
    #error = wrapError(options.error, model, options)
    #kit.couch.sync('read', @, success, error)
    ##if server
      ##everyone.now.fetch(@)
    #return @

  save : (attrs, options) ->
    options or (options = {})
    if (attrs and not @set(attrs, options))
      return false
    model = @
    success = (resp) ->
      if (!model.set(model.parse(resp), options)) then return false
      if (options.success) then options.success(model, resp)
    error = wrapError(options.error, model, options)
    method = if @isNew() then 'create' else 'update'
    exports.kit.couch.sync(method, @, success, error)
    @set isNew: false
    return @

  destroy : (options) ->
    options or (options = {})
    model = @
    success = (resp) ->
      if (model.collection) then model.collection.remove(model)
      if (options.success) then options.success(model, resp)
    error = wrapError(options.error, model, options)
    exports.kit.couch.sync('delete', @, success, error)
    return @

  # ###register
  # Register ourselves. @ means generate a uuid if we're on the server
  # and listen for changes to ID (which you shouldn't really change) @ just handles the
  # case where our root model is initted on the client, before it has any data. Once it gets
  # its `id` you shouldn't ever change it.
  #
  # We also bind change so to our `publishChange` method.
  register: ->
    self = @
    if server and not @get("id")
      @set id: uuid()
      @set isNew: true
    exports.kit.stash.models[@id] = @  if @id and not exports.kit.stash.models[@id]
    #@bind "change:id", (model) ->
      #kit.stash.models[model.id] = self  unless kit.stash.models[@id]

    #@bind "change", _(@publishChange).bind(@)

  # ###addChildCollection
  # We use @ to build our nested model structure. @ will ensure
  # that `publish`, `add`, and `remove` events will bubble up to our root
  # model.
  addChildCollection: (label, constructor) ->
    @[label] = new constructor()
    #@[label].bind "publish", _(@publishProxy).bind(@)
    #@[label].bind "remove", _(@publishRemove).bind(@)
    #@[label].bind "add", _(@publishAdd).bind(@)
    #@[label].bind "move", _(@publishMove).bind(@)
    @[label].parent = @

  # ###addChildModel
  # Adds a child model and ensures that various publish events will be proxied up
  # and that we store a reference to the parent.
  addChildModel: (label, constructor) ->
    @[label] = new constructor()
    #@[label].bind "publish", _(@publishProxy).bind(@)
    @[label].parent = @

  # ###modelGetter
  # Convenience method for retrieving any model, no matter where, by id.
  modelGetter: (id) ->
    exports.kit.stash.models[id]

  safeSet: (attrs, user, errorCallback) ->
    self = @
    _.each attrs, (value, key) ->
      if key != "id" and _(self.clientEditable).contains(key) and self.canEdit(user)
        self.set attrs
      else
        errorCallback "set", user, attrs  if _.isFunction(errorCallback)

  safeDelete: (user, errorCallback) ->
    if @canEdit(user) and @collection
      @collection.remove @
    else
      errorCallback "delete", user, @  if _.isFunction(errorCallback)

  toggle: (attrName) ->
    change = {}
    change[attrName] = not (@get(attrName))
    @set change

  toggleServer: (attrName) ->
    change = {}
    change[attrName] = not (@get(attrName))
    @setServer change

  deleteServer: ->
    socket.send
      event: "delete"
      id: @id

  callServerMethod: (method) ->
    socket.send
      event: "method"
      id: @id
      method: method

  toTemplate: ->
    result = @toJSON()
    self = @
    result.htmlId = @cid
    if @templateHelpers
      _.each @templateHelpers, (val) ->
        #result[val] = _.bind(self[val], self)
    result

  xport: (opt) ->
    process = (targetObj, source) ->
      targetObj.attrs = source.toJSON()
      _.each source, (value, key) ->
        if settings.recurse
          if key != "collection" and source[key] instanceof Backbone.Collection
            targetObj.collections = targetObj.collections or {}
            targetObj.collections[key] = {}
            targetObj.collections[key].models = []
            targetObj.collections[key].id = source[key].id or null
            _.each source[key].models, (value, index) ->
              process targetObj.collections[key].models[index] = {}, value
          else if key != "parent" and source[key] instanceof Backbone.Model
            targetObj.models = targetObj.models or {}
            process targetObj.models[key] = {}, value
    result = {}
    settings = _(recurse: true).extend(opt or {})
    process result, @
    result

  mport: (data, silent) ->
    process = (targetObj, data) ->
      targetObj.set data.attrs, silent: silent
      if data.collections
        _.each data.collections, (collection, name) ->
          targetObj[name].id = collection.id
          exports.kit.stash.models[collection.id] = targetObj[name]
          _.each collection.models, (modelData, index) ->
            nextObject = targetObj[name].get(modelData.attrs.id) or targetObj[name]._add({}, silent: silent)
            process nextObject, modelData
      if data.models
        _.each data.models, (modelData, name) ->
          process targetObj[name], modelData
    process @, data
    @

  publishProxy: (data) ->
    @trigger "publish", data

  publishChange: (model) ->
    if model instanceof Backbone.Model
      @trigger "publish",
        event: "change"
        id: model.id
        data: model.attributes
    else
      console.error "event was not a model", e

  publishAdd: (model, collection) ->
    @trigger "publish",
      event: "add"
      data: model.xport()
      collection: collection.id

  publishRemove: (model, collection) ->
    @trigger "publish",
      event: "remove"
      id: model.id

  publishMove: (collection, id, newPosition) ->
    @trigger "publish",
      event: "move"
      collection: collection.id
      id: id
      newPosition: newPosition

  ensureRequired: ->
    self = @
    if @required
      _.each @required, (type, key) ->
        self.checkType type, self.get(key), key

  validate: (attr) ->
    self = @
    _.each attr, (value, key) ->
      if self.required and self.required.hasOwnProperty(key)
        type = self.required[key]
        self.checkType type, value, key

  checkType: (type, value, key) ->
    type = type.toLowerCase()
    switch type
      when "string"
        validator = _.isString
      when "boolean"
        validator = _.isBoolean
      when "date"
        validator = _.isDate
      when "array"
        validator = _.isArray
      when "number"
        validator = _.isNumber
    throw "The '" + key + "' property of a '" + @type + "' must be a '" + type + "'. You gave me '" + value + "'."  unless validator(value)

  setServer: (attrs) ->
    socket.send
      event: "set"
      id: @id
      change: attrs

  unsetServer: (property) ->
    socket.send
      event: "unset"
      id: @id
      property: property

  safeCall: (method, user, errorCallback) ->
    if @exposedServerMethods and @exposedServerMethods.indexOf(method) != -1 and @canEdit(user)
      @[method]()
    else
      errorCallback "call", user, method, @  if _.isFunction(errorCallback)

#_.extend(kit.model, Backbone.Events, Backbone.RelationalModel)
_.extend(exports.kit.model, Backbone.Events)

class exports.kit.collection extends Backbone.Collection
  register: ->
    @id = uuid()  if server
    exports.kit.stash.models[@id] = @ if @id and not exports.kit.stash.models[@id]

  #fetch : (options) ->
    #options || (options = {})
    #collection = @
    #success = (resp) ->
      #collection[if options.add then 'add' else 'refresh'](collection.parse(resp), options)
      #if (success) then options.success(collection, resp)
    #error = wrapError(options.error, collection, options)
    #kit.couch.sync.call('read', @, success, error)

  safeAdd: (attrs, user, errorCallback) ->
    newObj = new @model()
    if @canAdd(user)
      newObj.safeSet attrs, user, errorCallback
      @add newObj
    else
      errorCallback "add", user, objectProperties, @  if _.isFunction(errorCallback)

  addServer: (data) ->
    socket.send
      event: "add"
      id: @id
      data: data

  moveServer: (id, newPosition) ->
    socket.send
      event: "move"
      collection: @id
      id: id
      newPosition: newPosition

  #registerRadioProperties: ->
    #collection = @
    #if @radioProperties
      #_.each @radioProperties, (property) ->
        #collection.bind "change:" + property, (changedModel) ->
          #if changedModel.get(property)
            #collection.each (model) ->
              #tempObj = {}
              #if model.get(property) and model.cid != changedModel.cid
                #tempObj[property] = false
                #model.set tempObj

        #collection.bind "add", (addedModel) ->
          #tempObj = {}
          #if collection.select((model) ->
            #model.get property
          #).length > 1
            #tempObj[property] = false
            #addedModel.set tempObj

  filterByProperty: (prop, value) ->
    @filter (model) ->
      model.get(prop) == value

  findByProperty: (prop, value) ->
    @find (model) ->
      model.get(prop) == value

  setAll: (obj) ->
    @each (model) ->
      model.set obj
    @

  safeMove: (id, newPosition, user, errorCallback) ->
    if @canMove(user)
      @moveItem id, newPosition
    else
      errorCallback "move", user, id, newPosition  if _.isFunction(errorCallback)

  moveItem: (id, newPosition) ->
    model = @get(id)
    currPosition = _(@models).indexOf(model)
    if currPosition != newPosition
      @models.splice currPosition, 1
      @models.splice newPosition, 0, model
      model.trigger "move", @, id, newPosition

  value: ->
      @map((a) ->
          a.serialize()
      ).join(" ")

  find: (a) ->
      b = this.detect (b) ->
          b.get("category") is a
      b and b.get("value")

  count: (a) ->
      @select((b) ->
          b.get("category") is a
      ).length

  #values: (a) ->
      #b = this.select((b) ->
          #b.get("category") is a
      #_.map(b, (a) ->
          #a.get("value")

  #has: (a, b) ->
      #@any((c) ->
          #d = c.get("category") is a
          #if (!b) then return d
          #else return d and c.get("value") is b

  #withoutCategory: (a) ->
      #@map((b) ->
          #if (b.get("category") isnt a) then return b.serialize()
      #).join(" ")


_.extend(exports.kit.collection, Backbone.Events)

# Wrap an optional error callback with a fallback error event.
wrapError = (onError, model, options) ->
  return (resp) ->
    if (onError)
      onError(model, resp)
    else
      model.trigger('error', model, resp, options)

#exports.kit = kit
#if client
if server
  Backbone.sync = exports.kit.couch.sync
  Backbone.Model.sync = exports.kit.couch.sync
  Backbone.Collection.sync = exports.kit.couch.sync
  exports.sync = exports.kit.couch.sync
  #exports.kit.sync = exports.kit.couch.sync
  #exports.kit.model.sync = exports.kit.couch.sync
  #exports.kit.collection.sync = exports.kit.couch.sync
  #kit.collections = require('./kollections')
  #kit.models = require('./models')
