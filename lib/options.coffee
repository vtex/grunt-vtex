require 'color'
log = -> console.log "grunt-vtex >>>".yellow, arguments...

module.exports = (grunt, pkg, options) ->
  # options.relativePath: where to put files under build folder
  options.relativePath or= pkg.name

  # options.replaceGlob: which files to replace on copy:deploy task
  options.replaceGlob or= "build/**/{index.html,app.js,app.min.js}"

  # options.replaceMap: which keys to replace with which values on copy:deploy task
  unless options.replaceMap
    options.replaceMap = {}
    options.replaceMap['/' + options.relativePath] = "//io.vtex.com.br/#{pkg.name}/#{pkg.version}"

  # options.devReplaceGlob: which files to replace on copy:dev task. Relative to build/relativePath.
  options.devReplaceGlob or= "index.html"

  # options.devReplaceMap: which keys to replace with which values on copy:dev task
  unless options.devReplaceMap
    options.devReplaceMap = {}

  # options.copyIgnore: array of globs to ignore on copy:main
  options.copyIgnore or= ['!views/**', '!partials/**', '!templates/**', '!**/*.coffee', '!**/*.less', '!**/*.pot', '!**/*.po']

  # options.dryrun: if true, nothing will actually be deployed
  options.dryrun or= if grunt.option('dry-run') then '--dryrun' else ''

  # options.open: whether to open automatically a page on running
  if options.open is undefined
    options.open =
      target: "http://basedevmkp.vtexlocal.com.br/#{options.relativePath}/"
      appName: "google-chrome --incognito"
  else if typeof options.open is "string"
    target = options.open
    options.open =
      target: target
      appName: "google-chrome --incognito"

  # options.verbose: whether to log all available information
  options.verbose or= grunt.option('verbose')

  # options.port: which port the connect proxy should listen to
  options.port or= 80

  # options.replaceHost: function to replace the host upon proxying
  options.replaceHost or= (h) -> h.replace("vtexlocal", "vtexcommercebeta")

  # options.proxyTarget: what target to proxy to
  options.proxyTarget or= "http://portal.vtexcommercebeta.com.br:80"

  # options.followHttps: whether to follow HTTPS redirects transparently and return HTTP
  options.followHttps or= false

  # options.livereload: whether to use livereload, or in which port to use it
  if options.livereload is undefined
    options.livereload = true

  # options.middlewares: array of middlewares to use in connect
  unless options.middlewares
    options.middlewares = [
      require('connect-tryfiles')('**', options.proxyTarget, {cwd: 'build/', verbose: options.verbose})
      require('connect').static('./build/')
      (err, req, res, next) ->
        errString = err.code?.red ? err.toString().red
        grunt.log.warn(errString, req.url.yellow)
    ]

    if options.livereload
      lrPort = if typeof options.livereload is 'number' then options.livereload else null
      options.middlewares.unshift(require('connect-livereload')({disableCompression: true, port: lrPort}))

    if options.followHttps
      options.middlewares.unshift(require('connect-http-please')(replaceHost: options.replaceHost, {verbose: options.verbose}))

    if grunt.option 'mock'
      options.middlewares.unshift(require('connect-mock')({verbose: options.verbose}))

  # grunt option `--stable`: proxies to stable API's instead of beta.
  if grunt.option 'stable'
    log "Pointing to stable APIs"
    addStableHeader = (req, res, next) -> req.headers['X-VTEX-Router-Backend-EnvironmentType'] = 'stable'; next()
    options.middlewares.unshift addStableHeader
