exports.kit = {}

class exports.kit.view extends Backbone.View
  handleBindings: ->
    self = @
    if @contentBindings
      _.each @contentBindings, (selector, key) ->
        self.model.bind "change:" + key, ->
          el = (if (selector.length > 0) then self.$(selector) else $(self.el))
          el.html self.model.get(key)
    if @classBindings
      _.each @classBindings, (selector, key) ->
        self.model.bind "change:" + key, ->
          newValue = self.model.get(key)
          el = (if (selector.length > 0) then self.$(selector) else $(self.el))
          if _.isBoolean(newValue)
            if newValue
              el.addClass key
            else
              el.removeClass key
          else
            el.removeClass(self.model.previous(key)).addClass newValue
    @

  desist: (opts) ->
    opts or (opts = {})
    if @interval
      clearInterval @interval
      delete @interval
    if opts.quick
      $(@el).unbind().remove()
    else
      $(@el).animate
        height: 0
        opacity: 0
      , ->
        $(@).unbind().remove()

  addReferences: (hash) ->
    for item of hash
      @["$" + item] = $(hash[item], @el)

  autoSetInputs: ->
    @$(":input").bind "input", _(@genericKeyUp).bind(@)

  genericKeyUp: (e) ->
    res = {}
    target = $(e.target)
    target.blur()  if e.which == 13 and e.target.tagName.toLowerCase() == "input"
    res[type = target.data("type")] = target.val()
    @model.setServer res

  basicRender: (opts) ->
    #opts = {} unless opts
    #_.defaults(opts,
        #templateKey: @template
    #)
    #template = require('templates/' + opts.templateKey)
    #newEl = template(@model.toTemplate())
    #$(@el).replaceWith(newEl)
    #@el = newEl
    #@handleBindings()
    #@delegateEvents()

  subViewRender: (opts) ->
    #opts = {} unless opts
    #_.defaults(opts ,
        #placement: 'append',
        #templateKey: @template
    #)
    #template = require('templates/' + opts.templateKey)
    #newEl = template(@model.toTemplate())[0]
    #if (!@el.parentNode)
      #$(@containerEl)[opts.placement](newEl)
     #else
      #$(@el).replaceWith(newEl)

    #@el = newEl
    #@handleBindings()
    #@delegateEvents()

  bindomatic: (model, ev, handler, options) ->
    boundHandler = _(handler).bind(@)
    evs = (if (ev instanceof Array) then ev else [ ev ])
    _(evs).each (ev) ->
      model.bind ev, boundHandler

    boundHandler()  if options and options.trigger
    (@unbindomatic_list = @unbindomatic_list or []).push ->
      _(evs).each (ev) ->
        model.unbind ev, boundHandler

  unbindomatic: ->
    _(@unbindomatic_list or []).each (unbind) ->
      unbind()

  collectomatic: (collection, viewClass, options) ->
    views = {}
    self = @
    @bindomatic collection, "add", (model) ->
      views[model.cid] = new viewClass(_(model: model).extend(options))
      views[model.cid].parent = self

    @bindomatic collection, "remove", (model) ->
      views[model.cid].desist()
      delete views[model.cid]

    @bindomatic collection, "refresh", ->
      _(views).each (view) ->
        view.desist()

      views = {}
      collection.each (model) ->
        views[model.cid] = new viewClass(_(model: model).extend(options))
        views[model.cid].parent = self
    , trigger: true
    @bindomatic collection, "move", ->
      _(views).each (view) ->
        view.desist quick: true

      views = {}
      collection.each (model) ->
        views[model.cid] = new viewClass(_(model: model).extend(options))
        views[model.cid].parent = self

class exports.kit.router extends Backbone.Router
  constructor: ->
    super
    @_views = {}

class exports.kit.form extends exports.kit.view
  tagName : "div"
  initialize: ->
    #_(this).bindAll "add", "remove"
    #@bind 'refresh', @render
    _(this).bindAll "refresh"
    @model.bind 'change', @refresh
    #@render()

  render: ->
    @rendered = true
    $('.accordion').accordion
      collapsible: true
      autoHeight: false
    $('.datepicker').datepicker
      numberOfMonths: 3
      formatDate: 'yy/mm/dd'

  events:
    'click .button.save' : 'clickSave'
    'click .button.delete' : 'clickDelete'
    'click .button.cancel' : 'clickCancel'
    'click .button.publish' : 'clickPublish'
    'click .image .button.select' : 'clickSelectImage'
    'click .link .button.select' : 'clickSelectLink'
    'click .image .button.erase' : 'clickEraseImage'
    'click .link .button.erase' : 'clickEraseLink'
    'click .button.links' : 'clickLinks'
    'click .button.images' : 'clickImages'
    'click .button.add-link' : 'clickAddLink'
    'click .button.add-link-select' : 'clickAddLinkSelect'
    'click .button.add-tag' : 'clickAddTag'

  save: (cb, silent = false) ->
    fields = {}
    fields.isNew = false
    #console.log('fields', @$('.field input, .field textarea'))
    for field in @$('.field input, .field textarea')
      name = $(field).attr('name').split('_')
      console.log(field)
      console.log(name)
      if name.length is 1
        fields[name[0]] = $(field).val()
      else if name.length is 2
        fields[name[0]] ?= {}
        fields[name[0]][name[1]] = $(field).val()
      else if name.length is 3
        fields[name[0]] ?= {}
        fields[name[0]][name[1]] ?= {}
        fields[name[0]][name[1]][name[2]] = $(field).val()
    fields.links = []
    for link in @$('.fieldgroup .link')
      fields.links.push $(link).attr('name')
    fields.tags = []
    for tag in @$('.fieldgroup .tag')
      fields.tags.push $(tag).attr('name')
    fields.categories = []
    for option in @$('.field-category select option:selected')
      fields.categories.push $(option).val()
    fields.categories = []
    for option in @$('.field-category select option:selected')
      fields.categories.push $(option).val()
    console.log(@model)
    @model.set(fields)



      #if subfields = $(field).find('.subfield')
        #for subfield in subfields
          #fields[field.attr('name')][subfield.attr('name')] = subfieldfield.find('input, textarea').val()
      #else
        ##field = field.find('input')
        #fields[field.attr('name')] = $(field).find('input, textarea').val()
    #for fieldgroup in @$('.fieldgroup')
      #fields[fieldgroup.attr('name')]

    #if silent
      #@model.set fields, {silent: true}
    #else @model.set fields

  refresh: ->
    id = @model.id
    type = 'events'
    that = @
    console.log(@model.id)
    SS.server.app.reload id, (model) =>
      console.log('asdf')
      console.log(@model.id)
      that.model.mport(model)
      $(that.el).html($('#templates-editevent').tmpl({event: that.model}))
      $('.accordion').accordion
        collapsible: true
        autoHeight: false
      $('.datepicker').datepicker
        numberOfMonths: 3
        formatDate: 'yy/mm/dd'

  reset: ->
    if @model.hasChanged() then @model.previousAttributes()
    #@model.reset()

  task: (name) ->
    id = @model.id
    that = @
    @save (model) ->
      i = id or that.model.id
      item = '/events/' + i
      SS.server.app.task {task: name, items: [item]}, (a) ->
        that.model.trigger('change')
    , true

  clickSave: (e) ->
    @save (model) =>
      $(@el).remove()

  clickDelete: (e) ->
    $(@el).remove()

  clickCancel: (e) ->
    @reset()
    $(@el).remove()

  clickPublish: (e) ->
    @model.set(published: true)
    @save (model) ->
      $(@el).remove()

  clickSelectImage: (e) ->
    image = $(e.currentTarget).parent('.image')
    images = $(@el).find('.image').not(image)
    for i in images
      @removeImages.push $(i).attr('name')
      $(i).hide()

  clickSelectLink: (e) ->
    link = $(e.currentTarget).parent('.link')
    links = $(@el).find('.link').not(link)
    for i in links
      @removeLinks.push $(i).attr('name')
      $(i).hide()

  clickEraseImage: (e) ->
    image = $(e.currentTarget).parent('.image')
    @removeImages.push image.attr('name')
    image.hide()

  clickEraseLink: (e) ->
    link = $(e.currentTarget).parent('.link')
    #@removeLinks.push link.attr('name')
    link.hide()

  clickAddLink: (e) ->
    element = $(@el).find('input[name="link"]')
    link = element.val()
    element.val('')
    @$('.field-links').append('<div class="link" name="' + link + '"><span><a href="' + link + '">' + link + '</a></span><button class="button btn erase" type="button">✖</button></div>')

  clickAddTag: (e) ->
    element = $(@el).find('input[name="tag"]')
    tag = element.val()
    element.val('')
    @$('.field-tags').append('<div class="tag" name="' + tag + '"><span><a href="#">' + tag + '</a></span><button class="button btn erase" type="button">✖</button></div>')

  clickAddLinkSelect: (e) ->
    element = $(@el).find('input[name="link"]')
    link = element.val()
    element.val('')
    links = $(@el).find('.link').not(link)
    @addLinks.push link
    #@model.set {links: link}
    @$('.field-links').append('<div class="link" name="' + link + '"><button class="button select" type="button">✔</button><button class="button erase" type="button">✖</button><a href="' + link + '">' + link + '</a></div>')
    for i in links
      @removeLinks.push $(i).attr('name')
      $(i).hide()

  clickLinks: (e) ->
    @task('links')

  clickImages: (e) ->
    @task('images')
