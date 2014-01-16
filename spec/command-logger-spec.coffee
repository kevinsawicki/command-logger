{WorkspaceView} = require 'atom'

describe "CommandLogger", ->
  [commandLogger, editor] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    commandLogger = atom.packages.activatePackage('command-logger').mainModule
    commandLogger.eventLog = {}
    editor = atom.workspaceView.getActiveView()

  describe "when a command is triggered", ->
    it "records the number of times the command is triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      editor.trigger 'core:backspace'
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      editor.trigger 'core:backspace'
      expect(commandLogger.eventLog['core:backspace'].count).toBe 2

    it "records the date the command was last triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      editor.trigger 'core:backspace'
      lastRun = commandLogger.eventLog['core:backspace'].lastRun
      expect(lastRun).toBeGreaterThan 0
      start = Date.now()
      waitsFor ->
        Date.now() > start

      runs ->
        editor.trigger 'core:backspace'
        expect(commandLogger.eventLog['core:backspace'].lastRun).toBeGreaterThan lastRun

  describe "when the data is cleared", ->
    it "removes all triggered events from the log", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      editor.trigger 'core:backspace'
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      atom.workspaceView.trigger 'command-logger:clear-data'
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()

  describe "when an event is ignored", ->
    it "does not create a node for that event", ->
      commandLoggerView = commandLogger.createView()
      commandLoggerView.ignoredEvents.push 'editor:delete-line'
      editor.trigger 'editor:delete-line'
      commandLoggerView.eventLog = commandLogger.eventLog
      nodes = commandLoggerView.createNodes()
      for node in nodes
        continue unless node.name is 'Editor'
        for child in node.children
          expect(child.name.indexOf('Delete Line')).toBe -1
