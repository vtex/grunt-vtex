const fetch = require('node-fetch')

module.exports = function (grunt, pkg, options) {
  grunt.registerTask('getTags', function () {
    if (grunt.config('tags') != null) {
      return true
    }

    const done = this.async()
    const registryURL =
      options.registryURL ??
      'http://vtex-versioned-us.s3.amazonaws.com/registry/1/tags.json'

    return fetch(registryURL)
      .then((res) => res.json())
      .then((tags) => {
        grunt.config('tags', tags)

        done()
      })
      .catch((err) => {
        done(err)
      })
  })

  return grunt.registerTask('nolr', function () {
    // Turn off LiveReload in development mode
    grunt.config('watch.options.livereload', false)

    return true
  })
}
