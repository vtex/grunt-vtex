request = require 'request'
path = require 'path'
liquidFilters = require './liquid-filters'

module.exports = (grunt, pkg, options) ->
  grunt.registerTask 'getTags', ->
    return true if grunt.config('tags')?
    done = @async()
    registryURL = options.registryURL ? 'http://vtex-versioned-us.s3.amazonaws.com/registry/1/tags.json'
    request registryURL, (err, res, body) ->
      return done(err) if err
      grunt.config('tags', JSON.parse(body))
      done()

  grunt.registerTask 'nolr', ->
    # Turn off LiveReload in development mode
    grunt.config 'watch.options.livereload', false
    return true

  grunt.registerMultiTask 'liquid', 'Compile liquid templates', () ->
    done = @async()
    engine = require("./liquid-extensions")()
    taskOptions = this.options({
      includes: ""
    })

    grunt.verbose.writeflags(taskOptions, "Options")

    defaultFilters = liquidFilters(grunt, pkg, options)
    engine.registerFilters(defaultFilters)

    if taskOptions.filters
      engine.registerFilters(taskOptions.filters)

    templates = @files.map((fp) ->
      srcFiles = fp.src
      content = grunt.file.read(srcFiles)
      newpath = if Array.isArray(fp.src) then fp.src[0] else fp.src
      ext = path.extname(newpath)
      dir = path.dirname(newpath)

      parsePromise = engine.extParse(content, (subFilepath, cb) ->
        found = false
        includes = taskOptions.includes

        if !Array.isArray(includes)
          includes = [includes]

        includes.some((include) ->
          includePath = path.join(include, subFilepath + ext)
          partialIncludePath = path.join(include, "_" + subFilepath + ext)

          if grunt.file.exists(includePath)
            found = true
            cb(null, grunt.file.read(includePath))
          else if (grunt.file.exists(partialIncludePath))
            found = true
            cb(null, grunt.file.read(partialIncludePath))

          return found
        )

        if !found
          return cb("Not found.")
      )

      return parsePromise.then((template) ->
        return template.render(taskOptions).then((output) ->
          grunt.file.write(fp.dest, output)
          return grunt.log.writeln("File \"" + fp.dest + "\" created.")
        )
        .catch((e) ->
          return grunt.fail.warn(e)
        )
      )
      .catch((e) ->
        grunt.log.error(e)
        return grunt.fail.warn("Liquid failed to compile " + srcFiles + ".")
      )
    )

    return Promise.all(templates).then((logs) ->
      return Promise.all(logs)
    )
    .then(() ->
      return done()
    )
    .catch((e) ->
      grunt.log.error(e)
      return done()
    )
