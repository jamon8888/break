# Bind to events
SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'connect', ->     $('#message').text('SocketStream server is up :-)')

# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->

  SS.server.app.init (data) ->
    SS.app = new SS.shared.models.app
    SS.app.homeController = new SS.client.views.main()
    Backbone.history.start()
    SS.app.homeController.home()

#TODO - Easy
#show event names instead of id's
##add price field
##isNew should change on save
#one-click-publish

#TODO - Hard
#quand on cree un nouveau evennement, choisir la venue
#add multifield groups (metro/dates)
#add tag field, comma separated = array
#tag names vs tag id

#TODO - Later
#check why tasks dont work
#mass actions (delete/publish)


# SCRAPPER
#make scrapper search venue if it doesn't exist
#cron (1 week, every morning) + stats

