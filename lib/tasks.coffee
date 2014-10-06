request = require 'request'

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
