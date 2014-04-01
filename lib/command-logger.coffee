{$} = require 'atom'
CommandLoggerView = null

commandLoggerUri = 'atom://command-logger'

module.exports =
  activate: ({@eventLog}={}) ->
    @eventLog ?= {}
    atom.workspaceView.command 'command-logger:clear-data', => @eventLog = {}

    atom.project.registerOpener (filePath) =>
      @createView() if filePath is commandLoggerUri

    atom.workspaceView.command 'command-logger:open', ->
      atom.workspaceView.open(commandLoggerUri)

    registerTriggeredEvent = (eventName) =>
      eventNameLog = @eventLog[eventName]
      unless eventNameLog
        eventNameLog =
          count: 0
          name: eventName
        @eventLog[eventName] = eventNameLog
      eventNameLog.count++
      eventNameLog.lastRun = Date.now()

    atom.keymap.on 'matched.command-logger', ({binding}) ->
      registerTriggeredEvent(binding.command)

  deactivate: ->
    atom.keymap.off('.command-logger')
    @eventLog = {}

  serialize: ->
    {@eventLog}

  createView: ->
    CommandLoggerView ?= require './command-logger-view'
    new CommandLoggerView({uri: commandLoggerUri, @eventLog})
