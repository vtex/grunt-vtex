registerTasks = require './lib/tasks.coffee'
parseOptions = require './lib/options.coffee'
configTemplate = require './lib/config.coffee'

exports.generateConfig = (grunt, pkg, options = {}) ->
  throw new Error("Grunt is required") unless grunt
  throw new Error("package.deploy and package.name are required") unless pkg and pkg.deploy and pkg.name

  registerTasks(grunt, pkg, options)
  parseOptions(grunt, pkg, options)
  return configTemplate(grunt, pkg, options)
