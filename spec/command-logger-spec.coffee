{WorkspaceView} = require 'atom'

describe "CommandLogger", ->
  [commandLogger, editor] = []

  triggerKey = (key) ->
    editor.trigger(window.keydownEvent(key))

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    atom.workspaceView.attachToDom()
    editor = atom.workspaceView.getActiveView()
    editor.enableKeymap()

    waitsForPromise ->
      atom.packages.activatePackage('command-logger')

    runs ->
      commandLogger = atom.packages.getActivePackage('command-logger').mainModule
      commandLogger.eventLog = {}

  describe "when a command is triggered", ->
    it "records the number of times the command is triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerKey('backspace')
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      triggerKey('backspace')
      expect(commandLogger.eventLog['core:backspace'].count).toBe 2

    it "records the date the command was last triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerKey('backspace')
      lastRun = commandLogger.eventLog['core:backspace'].lastRun
      expect(lastRun).toBeGreaterThan 0
      start = Date.now()
      waitsFor ->
        Date.now() > start

      runs ->
        triggerKey('backspace')
        expect(commandLogger.eventLog['core:backspace'].lastRun).toBeGreaterThan lastRun

  describe "when the data is cleared", ->
    it "removes all triggered events from the log", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerKey('backspace')
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      atom.workspaceView.trigger 'command-logger:clear-data'
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()

  describe "when an event is ignored", ->
    it "does not create a node for that event", ->
      triggerKey('backspace')
      commandLoggerView = commandLogger.createView()
      commandLoggerView.ignoredEvents = ['core:backspace']
      commandLoggerView.eventLog = commandLogger.eventLog
      nodes = commandLoggerView.createNodes()

      for {name, children} in nodes
        for child in children
          expect(child.name.indexOf('Backspace')).toBe -1

  describe "command-logger:open", ->
    it "opens the command logger in a pane", ->
      atom.workspaceView.trigger 'command-logger:open'

      waitsFor ->
        atom.workspaceView.getActivePaneItem().treeMap?

      runs ->
        commandLoggerView = atom.workspaceView.getActivePaneItem()
        expect(commandLoggerView.categoryHeader.text()).toBe 'All Commands'
        expect(commandLoggerView.categorySummary.text()).toBe ' (1 command, 1 invocation)'
        expect(commandLoggerView.treeMap.find('svg').length).toBe 1
