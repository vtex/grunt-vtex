const registerTasks = require('./tasks')
const parseOptions = require('./options')
const configTemplate = require('./defaultConfig')

exports.generateConfig = function (grunt, pkg, options = {}) {
  if (!grunt) {
    throw new Error('Grunt is required')
  }

  if (!(pkg && pkg.deploy && pkg.name)) {
    throw new Error('package.deploy and package.name are required')
  }

  registerTasks(grunt, pkg, options)
  parseOptions(grunt, pkg, options)

  return configTemplate(grunt, pkg, options)
}
