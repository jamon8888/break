kit = SS.client.kit.kit
quotes = [
  "I could calculate your chance of survival, but you won't like it."
  "I'd give you advice, but you wouldn't listen. No one ever does."
  "On being left in a parking lot for 500 million years: The first ten million years were the worst. And the second ten million years, they were the worst too. The third ten million years I didn't enjoy at all. After that I went into sort of a decline"
  "I ache, therefore I am."
  "Pardon me for breathing, which I never do anyway so I don't know why I bother to say it, oh God, I'm so depressed. Here's another one of those self-satisfied doors. Life! Don't talk to me about life."
  "I have a million ideas, but, they all point to certain death."
]

class exports.main extends kit.router
  routes :
    "": "home"
    "admin": "admin"
    "window/google" : "windowGoogle"
    "window/google-images" : "windowGoogleImages"
    "list/venues": "tableVenues"
    "new/venue" : "newVenue"
    "edit/venue/:eid" : "editVenue"
    "delete/venue/:eid" : "deleteVenue"
    "list/events": "tableEvents"
    "new/event" : "newEvent"
    "edit/event/:eid" : "editEvent"
    "delete/event/:eid" : "deleteEvent"


  home: (application) ->
    console.log('tags.length',SS.app.tags.length)
    unless SS.app.tags.length > 0
      SS.server.app.export 'tags', (data) ->
        SS.app.mport(data)
        SS.app.tagTitles = SS.app.tags.pluck 'title'
    console.log('categories.length',SS.app.categories.length)
    unless SS.app.categories.length > 0
      SS.server.app.export 'categories', (data) ->
        SS.app.mport(data)
        SS.app.categoryTitles = SS.app.categories.pluck 'title'
    console.log('venues.length',SS.app.venues.length)
    unless SS.app.venues.length > 0
      SS.server.app.export 'venues', (data) ->
        SS.app.mport(data)
        SS.app.venueTitles = SS.app.venues.pluck 'title'
    console.log('events.length',SS.app.events.length)
    unless SS.app.events.length > 0
      SS.server.app.export 'events', (data) ->
        SS.app.mport(data)
        SS.app.eventTitles = SS.app.events.pluck 'title'
    #@_views['home'] ||= new exports.home({venues: SS.app.venues, artists: SS.app.artists, events: SS.app.events}).render()
    #@_views['home'] ||= new exports.home().render()

  admin: ->
    @_views['admin'] ||= new exports.admin {collection: SS.app.venues}

  listVenues: ->
    @_views['listVenues'] ||= new exports.listVenues({collection: SS.app.venues}).render()

  tableVenues: ->
    $('#left > .inner')
        .html('<div class="loading">' + quotes[Math.floor(Math.random() * quotes.length)] + '</div>')
        .fadeIn('slow')
    that = @
    console.log('venues.length',SS.app.venues.length)
    unless SS.app.venues.length > 0
      SS.server.app.export 'venues', (data) ->
        SS.app.mport(data)
        that._views['tableVenues'] ||= new exports.tableVenues({collection: SS.app.venues})
    else
      that._views['tableVenues'] ||= new exports.tableVenues({collection: SS.app.venues})

  tableEvents: ->
    $('#left > .inner')
        .html('<div class="loading">' + quotes[Math.floor(Math.random() * quotes.length)] + '</div>')
        .fadeIn('slow')
    that = @
    console.log('events.length',SS.app.events.length)
    unless SS.app.events.length > 0
      SS.server.app.export 'events', (data) ->
        SS.app.mport(data)
        that._views['tableEvents'] = new exports.tableEvents({collection: SS.app.events})
    else
      that._views['tableEvents'] ||= new exports.tableEvents({collection: SS.app.events})

  tableArtists: ->
    that = @
    unless SS.app.artists.length > 0
      SS.server.app.export 'artists', (data) ->
        SS.app.mport(data)
        that._views['tableArtists'] = new exports.tableArtists({collection: SS.app.artists}).render()
    else
      that._views['tableArtists'] ||= new exports.tableArtists({collection: SS.app.artists}).render()

  listEvents: ->
    @_views['listEvents'] ||= new exports.listEvents {collection: SS.app.events}

  listArtists: ->
    @_views['listArtists'] ||= new exports.listArtists {collection: SS.app.artists}

  newVenue: ->
    model = new SS.shared.models.venue
    @_views["venue-" + model.get('cid')] = new exports.editVenue { model : model, id: 'new-venue-'+model.get('cid')}

  newEvent: ->
    model = new SS.shared.models.event
    @_views["venue-" + model.get('cid')] = new exports.editEvent { model : model, id: 'new-event-'+model.get('cid')}

  viewVenue: (eid) ->
    @_views["view-venue-#{eid}"] ||= new exports.viewVenue {model: SS.app.venues.get(eid), id: 'view-venue-'+eid}

  previewVenue: (eid) ->
    @_views["preview-venue-#{eid}"] ||= new exports.previewVenue {model: SS.app.venues.get(eid), id: 'preview-venue-'+eid}

  editVenue: (eid) ->
    @_views["edit-venue-#{eid}"] = new exports.editVenue {model: SS.app.venues.get(eid), id: 'edit-venue-'+eid}

  deleteVenue: (eid) ->
    @_views["delete-venue--#{eid}"] ||= new exports.deleteVenue {model: SS.app.venues.get(eid), id: 'delete-venue-'+eid}

  editEvent: (eid) ->
    @_views["edit-event--#{eid}"] = new exports.editEvent {model: SS.app.events.get(eid), id: 'edit-event-'+eid}

  deleteEvent: (eid) ->
    @_views["delete-event--#{eid}"] ||= new exports.deleteEvent {model: SS.app.venues.get(eid), id: 'delete-event-'+eid}


  windowGoogle: ->
    @_views['windowGoogle'] = new exports.windowGoogle

  windowGoogleImages: ->
    @_views['windowGoogleImages'] = new exports.windowGoogleImages

class exports.home extends kit.view
  id: 'home'

  constructor: ->
    super
    @render()

  render: ->
    $('#page').html($(@el).html($('#templates-home').tmpl()))

class exports.admin extends kit.view
  id: 'admin'

  constructor: ->
    super
    @render()

  render: ->
    $('#page').html($(@el).html($('#templates-admin').tmpl({venues: @collection.models})))

class exports.windowGoogle extends kit.view
  id: 'google'
  className: 'window'

  initialize: ->
    @render()

  render: ->
    iframe = '<div class="button close">X</div><iframe src="http://www.google.com/" width="100%" height="100%" z-index="1000"></iframe>'
    $('#page #left > .inner').append($(@el).html(iframe))

  events:
    'click .button.close' : 'clickClose'

  clickClose: ->
    $(@el).remove()


class exports.windowGoogleImages extends kit.view
  id: 'googleImages'
  className: 'window'

  constructor: ->
    super
    @render()

  render: ->
    iframe = '<div class="button close">X</div><iframe src="http://images.google.com/" width="100%" height="100%" z-index="1000"></iframe>'
    $('#page #left > .inner').append($(@el).html(iframe))

  events:
    'click .button.close' : 'clickClose'

  clickClose: ->
    $(@el).remove()

class exports.tableVenues extends kit.view
#class exports.home extends kit.view
  templateId: 'tableVenues'
  tagName: 'div',
  id: 'panel'

  initialize: ->
    db = {}
    async.auto(
      getEventCount: (a) =>
        settings =
          path: '/_design/events/_view/countByVenue'
          options: {group: true}
        SS.server.app.dbQuery settings, (results) ->
          db.eventCount = {}
          _.each results, (b) ->
            if b.key then db.eventCount[b.key] = b.value
          a()
      process: ['getEventCount', (a) =>
        @data = []
        @results = []
        @cols = [
          'id'
          'title'
          'website'
          'category'
          'score'
          'events'
          'isNew'
          'status'
        ]
        @collection.each((b) =>
          @data.push {value: b.get('id'), label: b.get('title')}
          eventCount = db.eventCount[b.get('_id')] or 0
          #category = _.detect SS.app.categories.models, (category) -> b.get('category') is category.attributes['_id']
          category = SS.app.categories.detect (category) -> b.get('category') is category.get('_id')
          #SS.app.categories.each (category) -> console.log(b.get('category') + ' ---- ' + category.get('_id')) if b.get('category')  is category.get('_id')

          @results.push [
            b.get('id')
            '<div class="icon icon-open"><a href="#edit/venue/' + b.get('id') + '">&#x271A;</a></div>'
            b.get('title')
            b.get('website')
            #b.get('category')
            category.get('original')
            b.get('score')
            eventCount
            b.get('isNew')
            '<div class="icon icon-status status-' + b.get('status') + '"><a href="#publish/venue/' + b.get('id') + '">&#x2731;</a></div>'
            #'<div class="icon icon-delete"><a href="#delete/venue/' + b.get('id') + '">&#x2716;</a></div>'
          ]
        )
        a()
      ]
      render: ['process', (a) =>
        @render()
        a()
      ]
    )


  render: ->
    $el = $(@el)
    $el.empty()
    that = @

    $('#left > .inner').html($(@el).html('<table id="tableVenues"></table'))

    table = $('#tableVenues').dataTable(
        bScrollInfinite: true
        #bScrollCollapse: true
        iDisplayLength: 60
        bJQueryUI: true
        oLanguage:
          sSearch: "Search all columns:"
        #aaSorting: [[1,'asc'], [2,'asc'], [3,'asc'], [4,'asc'], [5,'asc']]
        aaSorting: [[2,'asc'], [3,'asc'], [4,'asc'], [5,'asc']]
        sScrollY: "700px"
        aaData: @results
        aoColumnDefs: [
          {bVisible: false, aTargets: [0]}
          {bSortable: false, aTargets: [1]}
        ]
        aoColumns: [
            sTitle: 'ID'
            sClass: 'id'
        ,
            sTitle: '+'
            sClass: 'open gs-1'
        ,
            sTitle: 'Title'
            sClass: 'title gs-5'
        ,
            sTitle: 'Website'
            sClass: 'website gs-4'
        ,
            sTitle: 'Category'
            sClass: 'category gs-3'
        ,
            sTitle: 'Score'
            sClass: 'score gs-2'
        ,
            sTitle: 'Events'
            sClass: 'events gs-2'
        ,
            sTitle: 'isNew'
            sClass: 'isNew gs-2'
        ,
            sTitle: 'Status'
            sClass: 'status gs-2'
        ,
            #sTitle: 'Delete'
            #sClass: 'delete gs-1'
        #,
            #sTitle: 'Address'
            #sClass: 'address editable'
        #,
            #sTitle: 'Telephone'
            #sClass: 'telephone editable gs-5'
        #,
            #sTitle: 'Fax'
            #sClass: 'fax editable'
        #,
        ]
    )


    $('#tableVenues tr').live 'click', ->
        if ( $(@).hasClass('row_selected') )
            $(@).removeClass('row_selected')
        else
            $(@).addClass('row_selected')

    $('#delete').live 'click', ->
        selected = getSelected(table)
        for i in [0..selected.length]
          pos = table.fnGetPosition(selected[i])
          data = table.fnGetData(pos)
          id = data[0]
          table.fnDeleteRow(pos)

    $('#publish').live 'click', ->
        selected = getSelected(table)
        for i in [0..selected.length]
          pos = table.fnGetPosition(selected[i])
          data = table.fnGetData(pos)
          id = data[0]

    getSelected = (table) ->
        value = []
        rows = table.fnGetNodes()
        for i in [0..rows.length]
            if $(rows[i]).hasClass 'row_selected'
                value.push rows[i]
        value


    fields = new Array()
    $('.dataTables_wrapper').after('
    <div class="tableFooter">
        <span class="filter venue title"></span>
        <span class="filter venue website"></span>
        <span class="filter venue category"></span>
        <span class="filter venue score"></span>
        <span class="filter venue count"></span>
        <span class="filter venue isNew"></span>
    </div>')
        #<span class="filter events"></span>

    $(".tableFooter .filter").each (i) ->
      @innerHTML = "<input type='textfield'></input>" #fnCreateSelect(table.fnGetColumnData(i))
      $("input", @).change ->
          table.fnFilter $(@).val(), i+2

    $(".tableFooter input").keyup ->
      table.fnFilter @value, $(".tableFooter input").index(@) + 2

    $(".tableFooter input").each (i) ->
      fields[i] = @value

    $(".tableFooter input").focus ->
      if @className == "search_init"
        @className = ""
        @value = ""

    $(".tableFooter input").blur (i) ->
      if @value == ""
        @className = "search_init"
        @value = fields[$(".tableFooter input").index(this) + 2]

    #$.editable.addInputType "autocomplete",
      #element: $.editable.types.text.element
      #plugin: (settings, original) ->
        #$("input", this).autocomplete(
            #source: settings.autocomplete.data
            #select: (event, ui) ->
              ##change input text to label
              ##change input data-value to value
              ##when saving, if data-value, save that
              ##else save value

              #console.log($(@).parents(td))
              ##aPos = table.fnGetPosition(@)
              ##nodes = table.fnGetNodes(aPos[0])
              ##console.log(nodes)
              ##console.log($(nodes))
              ##id = table.fnGetData aPos[0], 0
              ##table.fnUpdate value, aPos[0], aPos[1] + 1
              ##$(@).val(ui.item.label)
              ##$(@).attr('data-selected', ui.item.value)
              #console.log($(@))
              #console.log(ui)
              #console.log(event)
              #console.log(@)
        #)

    #$('td', table.fnGetNodes()).filter('td.editable').editable(
      #(value, settings)=>
          #return value
      #callback: (value, settings) ->
        ##get position array (row, col)
        #aPos = table.fnGetPosition(this)
        ##get model id from row, col 0 (value)
        #id = table.fnGetData aPos[0], 0
        #model = that.options.venues.get(id)
        #changes = {}
        #changes[that.cols[aPos[1]]] = value
        #model.set(changes)
        #SS.server.app.modelSave model.xport(), (msg) ->
            #console.log(msg)
        #table.fnUpdate value, aPos[0], aPos[1] + 1
      ##type: 'autocomplete'
      #placeholder: '------------------'
      ##autocomplete:
          ##data: that.data
    #)

    #$('#tabs-table').tabs(
        #show: (event, ui) ->
          ##tableVenues = $("div.dataTables_scrollBody>table.display", ui.panel).dataTable()
          #tableVenues.fnAdjustColumnSizing() if tableVenues.length > 0
          ##console.log(tableVenues.fnGetNodes())
          #$('td', tableVenues.fnGetNodes()).filter('td.editable').editable(
            #(value, settings)=>
                #return value
            #callback: (value, settings) ->
              #aPos = tableVenues.fnGetPosition(this)
              #id = tableVenues.fnGetData aPos[0], 0
              #model = that.options.venues.get(id)
              #changes = {}
              #changes[that.cols[aPos[1]]] = value
              #model.set(changes)
              #SS.server.app.modelSave model.xport(), (msg) ->
                  #console.log(msg)
              #tableVenues.fnUpdate value, aPos[0], aPos[1] + 1
            #type: 'autocomplete'
            #placeholder: '------------------'
            #autocomplete:
                #data: that.data
          #)
    #)
    #$("#tabs").tabs
      #oTable = $("div.dataTables_scrollBody>table.display", ui.panel).dataTable()
      #oTable.fnAdjustColumnSizing()  if oTable.length > 0

    #$("table.display").dataTable
      #sScrollY: "200px"
      #bScrollCollapse: true
      #bPaginate: false
      #bJQueryUI: true
      #aoColumnDefs: [
        #sWidth: "10%"
        #aTargets: [ -1 ]
       #]
    #accentMap =
      #"À" : "A"
      #"Á" : "A"
      #"Â" : "A"
      #"Ã" : "A"
      #"Ä" : "A"
      #"Å" : "A"
      #"Æ" : "A"
      #"Ç" : "C"
      #"È" : "E"
      #"É" : "E"
      #"Ê" : "E"
      #"Ë" : "E"
      #"Ì" : "I"
      #"Í" : "I"
      #"Î" : "I"
      #"Ï" : "I"
      #"Ð" : "D"
      #"Ñ" : "N"
      #"Ò" : "O"
      #"Ó" : "O"
      #"Ô" : "O"
      #"Õ" : "O"
      #"Ö" : "O"
      #"Ø" : "O"
      #"Ù" : "U"
      #"Ú" : "U"
      #"Û" : "U"
      #"Ü" : "U"
      #"Ý" : "Y"
      #"à" : "a"
      #"á" : "a"
      #"â" : "a"
      #"ã" : "a"
      #"ä" : "a"
      #"å" : "a"
      #"æ" : "a"
      #"ç" : "c"
      #"è" : "e"
      #"é" : "e"
      #"ê" : "e"
      #"ë" : "e"
      #"ì" : "i"
      #"í" : "i"
      #"î" : "i"
      #"ï" : "i"
      #"ñ" : "n"
      #"ò" : "o"
      #"ó" : "o"
      #"ô" : "o"
      #"õ" : "o"
      #"ö" : "o"
      #"ø" : "o"
      #"ù" : "u"
      #"ú" : "u"
      #"û" : "u"
      #"ü" : "u"
      #"ý" : "y"
      #"ÿ" : "y"

    #normalize = (term) ->
      #ret = ""
      #i = 0

      #while i < term.length
        #ret += accentMap[term.charAt(i)] or term.charAt(i)
        #i++
      #ret

    #$("#developer").autocomplete source: (request, response) ->
      #matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i")
      #response $.grep(names, (value) ->
        #value = value.label or value.value or value
        #matcher.test(value) or matcher.test(normalize(value))
      #)

class exports.tableEvents extends kit.view
  templateId: 'tableEvents'
  tagName: 'div',
  id: 'panel'

  initialize: ->
    async.auto(
      #getEventCount: (a) =>
        #eventCount = {name:'events/countByVenue',options:{keys:false,group:true}}
        #SS.server.app.dbView options, (res) ->
          #a()
      process: (a) =>
        @data = []
        @results = []
        @cols = [
          'id'
          'title'
          'opening'
          #'venue'
          #'artists'
          'isNew'
          'status'
        ]
        @collection.each((b) =>
          @data.push {value: b.get('id'), label: b.get('title')}
          category = SS.app.categories.detect (category) -> b.get('category') is category.get('_id')
          if b.get('dates')? and b.get('dates')[0]?.length > 0 and b.get('dates')[0][0].days.from
            date = b.get('dates')[0][0].days.from
          else date = ''

          @results.push [
            b.get('id')
            '<div class="icon icon-open"><a href="#edit/event/' + b.get('id') + '">&#x271A;</a></div>'
            b.get('title')
            category.get('original')
            date
            b.get('score')
            b.get('isNew')
            '<div class="icon icon-status status-' + b.get('status') + '"><a href="#publish/venue/' + b.get('id') + '">&#x2731;</a></div>'
          ]
        )
        a()
      render: ['process', (a) =>
        @render()
        a()
      ]
    )

  render: ->
    $el = $(@el)
    $el.empty()
    that = @

    $('#left > .inner').html($(@el).html('<table id="tableEvents"></table'))
    table = $('#tableEvents').dataTable(
        bScrollInfinite: true
        #bScrollCollapse: true
        iDisplayLength: 60
        bJQueryUI: true
        oLanguage:
          sSearch: "Search all columns:"
        aaSorting: [[2,'asc'], [3,'asc'], [4,'asc']]
        sScrollY: "700px"
        aaData: @results
        aoColumnDefs: [
          {bVisible: false, aTargets: [0]}
          {bSortable: false, aTargets: [1]}
        ]
        aoColumns: [
            sTitle: 'ID'
            sClass: 'id'
        ,
            sTitle: '+'
            sClass: 'open gs-1'
        ,
            sTitle: 'Title'
            sClass: 'title gs-8'
        ,
            sTitle: 'Category'
            sClass: 'category gs-3'
        ,
            sTitle: 'Opening'
            sClass: 'opening gs-3'
        ,
            sTitle: 'Score'
            sClass: 'score gs-2'
        ,
            sTitle: 'isNew'
            sClass: 'isNew gs-2'
        ,
            sTitle: 'Status'
            sClass: 'status gs-2'
        ,
        ]
    )

    asInitVals = new Array()
    $('.dataTables_wrapper').after('
    <div class="tableFooter">
        <span class="filter event title"></span>
        <span class="filter event category"></span>
        <span class="filter event opening"></span>
        <span class="filter event score"></span>
        <span class="filter event isNew"></span>
    </div>')

    $(".tableFooter span").each (i) ->
      @innerHTML = "<input type='textfield'></input>" #fnCreateSelect(table.fnGetColumnData(i))
      $("input", this).change ->
          table.fnFilter $(this).val(), i+2

    $(".tableFooter input").keyup ->
      table.fnFilter @value, $(".tableFooter input").index(this) + 2

    $(".tableFooter input").each (i) ->
      asInitVals[i] = @value

    $(".tableFooter input").focus ->
      if @className == "search_init"
        @className = ""
        @value = ""

    $(".tableFooter input").blur (i) ->
      if @value == ""
        @className = "search_init"
        @value = asInitVals[$(".tableFooter input").index(this) + 2]

    #$.editable.addInputType "autocomplete",
      #element: $.editable.types.text.element
      #plugin: (settings, original) ->
        #$("input", this).autocomplete(
            #source: settings.autocomplete.data
        #)
    $('td', table.fnGetNodes()).filter('td.editable').editable(
      (value, settings)=>
          return value
      callback: (value, settings) ->
        aPos = table.fnGetPosition(this)
        id = table.fnGetData aPos[0], 0
        model = that.options.venues.get(id)
        changes = {}
        changes[that.cols[aPos[1]]] = value
        model.set(changes)
        SS.server.app.modelSave model.xport(), (msg) ->
            console.log(msg)
        table.fnUpdate value, aPos[0], aPos[1] + 1
      #type: 'autocomplete'
      placeholder: '------------------'
      #autocomplete:
          #data: that.data
    )


#class exports.listVenues extends kit.view
  #templateId: 'listVenues'
  #tagName: "div",
  #id: 'listVenues'
  #all = @collection

  #events:
    #'click .button.filter' : 'onFilter'

  #initialize: ->
    #@template = $('#templates-' + @templateId)
    #@_mainView = new updatingList
      #collection : @collection
      #childViewConstructor : exports.listVenue
      #childViewTagName : 'div'
    #@results = []
    #@collection.each((a) =>
      #@results.push [
        #a.get('title')
        #a.get('address')
        #a.get('website')
        #a.get('email')
        #a.get('telephone')
        #a.get('fax')
        ##a.get('status')
      #]
    #)
    ##console.log(results)

  #render: ->
    #$el = $(@el)
    #$el.empty()
    ##$(@el).empty()
    ##@template.tmpl().appendTo(@el)
    ##$('#left').html(@_mainView.render().el)
    #$('#left').html($el.html(@template.tmpl()))
    #@_mainView.el = @$('.listVenues')
    #@_mainView.render()

  #onFilter: ->
     #@filteredCollection = @collection.filter (a)->
       #a.get('telephone') isnt null
     ##console.log(@collection)
     #@collection.reset(@filteredCollection)
     ##console.log(@collection)

class updatingList extends kit.view
  initialize: (options) ->
    _(this).bindAll "add", "remove"
    throw "no child view constructor provided" unless options.childViewConstructor
    throw "no child view tag name provided" unless options.childViewTagName
    @_childViewConstructor = options.childViewConstructor
    @_childViewTagName = options.childViewTagName
    @_childViews = []
    @collection.each @add
    @collection.bind "add", @add
    @collection.bind "remove", @remove

  add: (model) ->
    childView = new @_childViewConstructor
      tagName: @_childViewTagName
      model: model
    @_childViews.push childView
    $(@el).append childView.render().el if @_rendered
    #console.log(@)

  remove: (model) ->
    viewToRemove = _(@_childViews).select((cv) ->
      cv.model == model
    )[0]
    @_childViews = _(@_childViews).without(viewToRemove)
    $(viewToRemove.el).remove()  if @_rendered

  render: ->
    that = @
    @_rendered = true
    $(@el).empty()
    _(@_childViews).each (childView) ->
      $(that.el).append childView.render().el
    #console.log(@)
    @

class exports.listVenue extends kit.view
  tagName : "div"
  className : "venue"
  initialize: ->
    @render = _.bind(this.render, this)
    @model.bind('change:title', this.render)

  render: ->
    $el = $(@el)
    @el.innerHTML = '<a href="#edit/venue/' + @model.get('id') + '">' + @model.get('title') + '</a>'
    #console.log(@)
    @
    #$('#left').html($(@el).html($('#templates-listVenue').tmpl({venue: @model})))

class exports.editEvent extends kit.form
  className : "edit-event"
  #id : "edit-event-" + @model.get('id')
  initialize: ->
    self = @
    current = unless _.isArray(@model.get('category')) then [@model.get('category')] else @model.get('category')
    @model.categories = SS.app.categories.map (category) -> {id: category.get('_id'), label: category.get('label'), selected: _.contains(current, category.get('_id') ) }
    super
    @render()

  render: ->
    $(@el).html($('#templates-editEvent').tmpl({event: @model})).appendTo('#content > .inner')
    console.log(@model)
    #$('.field-venue input', @el).autocomplete(
      #source: SS.app.venueTitles
    #).result( (event, data, formatted) ->
      #$('.field-venue .value').val( data[1] )
    #)

    super

  save: (cb, silent = false) ->
    super
    SS.server.app.modelSave @model.xport(), (data) =>
      if not @model.attributes.id or @model.id
        @model.mport(data)
        @model.id = @model.attributes.id = data.id
      if cb then cb(@model)


class exports.editVenue extends kit.form
  className : "edit-venue"
  #id : "edit-venue-" + @model.get('id')
  initialize: ->
    super
    self = @
    async.auto(
      getEvents: (a) =>
        settings =
          path: '/_design/events/_view/byVenue'
          options:
            key: JSON.stringify(self.model.get('_id'))
        SS.server.app.dbQuery settings, (results) ->
          console.log('results-events',results)
          self.model.events = []
          _.each results, (b) ->
            if b.key then self.model.events.push b.value
          a()
      process: ['getEvents', (a) =>
        current = unless _.isArray(@model.get('category')) then [@model.get('category')] else @model.get('category')
        @model.categories = SS.app.categories.map (category) -> {id: category.get('_id'), label: category.get('label'), selected: _.contains(current, category.get('_id') ) }
        @render()
        a()
      ]
    )

  render: ->
    $(@el).html($('#templates-editVenue').tmpl({venue: @model})).appendTo('#content > .inner')
    console.log(@model)
    super

  save: (cb, silent = false) ->
    super
    SS.server.app.modelSave @model.xport(), (data) =>
      if not @model.attributes.id or @model.id
        @model.mport(data)
        @model.id = @model.attributes.id = data.id
      if cb then cb(@model)

  refresh: ->
    id = @model.id
    type = 'venues'
    that = @
    console.log(@model.id)
    SS.server.app.reload id, (model) =>
      console.log(@model.id)
      that.model.mport(model)
      $(that.el).html($('#templates-editVenue').tmpl({venue: that.model}))
      $('.accordion').accordion
        collapsible: true
        autoHeight: false
      $('.datepicker').datepicker
        numberOfMonths: 3
        formatDate: 'yy/mm/dd'

#class exports.autocomplete extends kit.view
  #initialize: (options) ->
    #options = _.extend({}, options)
    #_.bindAll this, "refresh"
    #@input = options.input
    #@choices = options.choices
    #@selected = options.selected
    #@iterator = options.iterator
    #@label = options.label
    #@allowDupes = options.allowDupes
    #@choices.bind "refresh", @refresh

  #refresh: (models) ->
    #choices = @choices
    #selected = @selected
    #iterator = @iterator
    #label = @label
    #allowDupes = @allowDupes
    #$el = $(@el)
    #$el.autocomplete(
      #source: (request, response) ->
        #matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i")
        #response choices.filter((model) ->
          #iterator model, matcher
        #)
      #focus: (event, ui) ->
        #$el.val label(ui.item)
        #false
      #select: (event, ui) ->
        #selected.add ui.item
        #choices.remove ui.item  unless allowDupes
        #$el.val ""
        #false
    #).data("autocomplete")._renderItem = (ul, item) ->
      #$("<li/>").data("item.autocomplete", item).append($("<a/>").text(label(item))).appendTo ul
