# Grunt VTEX

A Grunt convention-over-configuration parasite.

## Usage

In your Gruntfile:

    GruntVTEX = require 'grunt-vtex'

    module.exports = (grunt) ->
      pkg = grunt.file.readJSON 'package.json'
  
      options = {...}
      config = GruntVTEX.generateConfig grunt, pkg, options

      tasks = {...}
    
      grunt.initConfig config
      grunt.loadNpmTasks name for name of pkg.devDependencies when name[0..5] is 'grunt-'
      grunt.registerTask taskName, taskArray for taskName, taskArray of tasks

## Options

**options.relativePath** where to put files under build folder  
**options.replaceGlob** which files to replace on copy:deploy task  
**options.replaceMap** which keys to replace with which values on copy:deploy task  
**options.copyIgnore** array of globs to ignore on copy:main  
**options.dryrun** if true, nothing will actually be deployed  
**options.open** whether to open automatically a page on running  
**options.verbose** whether to log all available information  
**options.port** which port the connect proxy should listen to  
**options.replaceHost** function to replace the host upon proxying  
**options.proxyTarget** what target to proxy to  
**options.middlewares** array of middlewares to use in connect  
  
------

VTEX - 2014
