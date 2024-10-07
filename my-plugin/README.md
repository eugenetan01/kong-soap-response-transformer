# Custom Auth Plugin

- Handler.lua - this is the file to write your code
  - the bulk of execution logic sits in access phase

- schema.lua - this is the file to define the schema for your plugin, so that you can configure fields in the UI (Kong Manager) to feed as values / parameters to the plugin code in handler.lua
