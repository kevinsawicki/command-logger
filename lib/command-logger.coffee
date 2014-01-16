{$} = require 'atom'
CommandLoggerView = null

commandLoggerUri = 'atom://command-logger'

module.exports =
  activate: (state) ->
    @eventLog = state.eventLog ? {}
    atom.workspaceView.command 'command-logger:clear-data', => @eventLog = {}

    atom.project.registerOpener (filePath) =>
      if filePath is commandLoggerUri
        @createView({uri: commandLoggerUri, @eventLog})

    atom.workspaceView.command 'command-logger:show', ->
      atom.workspaceView.open(commandLoggerUri)

    registerTriggeredEvent = (eventName) =>
      eventNameLog = @eventLog[eventName]
      unless eventNameLog
        eventNameLog =
          count: 0
          name: eventName
        @eventLog[eventName] = eventNameLog
      eventNameLog.count++
      eventNameLog.lastRun = new Date().getTime()
    trigger = $.fn.trigger
    @originalTrigger = trigger
    $.fn.trigger = (event) ->
      eventName = event.type ? event
      registerTriggeredEvent(eventName) if $(this).events()[eventName]
      trigger.apply(this, arguments)

  deactivate: ->
    $.fn.trigger = @originalTrigger if @originalTrigger?
    @eventLog = {}

  serialize: ->
    {@eventLog}

  createView: (state) ->
    CommandLoggerView ?= require './command-logger-view'
    new CommandLoggerView(state)
