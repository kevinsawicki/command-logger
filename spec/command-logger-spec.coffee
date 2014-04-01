{WorkspaceView} = require 'atom'

describe "CommandLogger", ->
  [commandLogger, editor] = []

  triggerBackspaceCommand = ->
    editor.trigger(window.keydownEvent('backspace'))

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
    it "records the number of times the commanxd is triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerBackspaceCommand()
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      triggerBackspaceCommand()
      expect(commandLogger.eventLog['core:backspace'].count).toBe 2

    it "records the date the command was last triggered", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerBackspaceCommand()
      lastRun = commandLogger.eventLog['core:backspace'].lastRun
      expect(lastRun).toBeGreaterThan 0
      start = Date.now()
      waitsFor ->
        Date.now() > start

      runs ->
        triggerBackspaceCommand()
        expect(commandLogger.eventLog['core:backspace'].lastRun).toBeGreaterThan lastRun

  describe "when the data is cleared", ->
    it "removes all triggered events from the log", ->
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()
      triggerBackspaceCommand()
      expect(commandLogger.eventLog['core:backspace'].count).toBe 1
      atom.workspaceView.trigger 'command-logger:clear-data'
      expect(commandLogger.eventLog['core:backspace']).toBeUndefined()

  describe "when an event is ignored", ->
    fit "does not create a node for that event", ->
      editor.trigger 'editor:delete-line'
      triggerBackspaceCommand()
      commandLoggerView = commandLogger.createView()
      # commandLoggerView.ignoredEvents.push 'editor:delete-line'
      commandLoggerView.eventLog = commandLogger.eventLog
      nodes = commandLoggerView.createNodes()

      console.log nodes
      for {name, children} in nodes# when name is 'Editor'
        for child in children
          expect(child.name.indexOf('Delete Line')).toBe -1

  describe "command-logger:open", ->
    it "opens the command logger in a pane", ->
      atom.workspaceView.attachToDom()
      atom.workspaceView.trigger 'command-logger:open'

      waitsFor ->
        atom.workspaceView.getActivePaneItem().treeMap?

      runs ->
        commandLoggerView = atom.workspaceView.getActivePaneItem()
        expect(commandLoggerView.categoryHeader.text()).toBe 'All Commands'
        expect(commandLoggerView.categorySummary.text()).toBe ' (1 command, 1 invocation)'
        expect(commandLoggerView.treeMap.find('svg').length).toBe 1
