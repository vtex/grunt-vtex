glob = require 'glob'
exports.generateConfig = (grunt, pkg, options = {}) ->
  throw new Error("Grunt is required") unless grunt
  throw new Error("package.deploy and package.name are required") unless pkg and pkg.deploy and pkg.name

  # options.relativePath: where to put files under build folder
  options.relativePath or= pkg.name

  # options.replaceGlob: which files to replace on copy:deploy task
  options.replaceGlob or= "build/**/{index.html,app.js,app.min.js}"

  # options.replaceMap: which keys to replace with which values on copy:deploy task
  unless options.replaceMap
    options.replaceMap = {}
    options.replaceMap['/' + options.relativePath] = "//io.vtex.com.br/#{pkg.name}/#{pkg.version}"

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

  if grunt.option 'stable'
    console.log "grunt-vtex >>> Pointing to stable APIs"
    addStableHeader = (req, res, next) -> req.headers['X-VTEX-Router-Backend-EnvironmentType'] = 'stable'; next()
    options.middlewares.unshift addStableHeader

  relativePath: options.relativePath

  clean:
    main: ['build', 'deploy']

  copy:
    main:
      files: [
        expand: true
        cwd: 'src/'
        src: ['**'].concat(options.copyIgnore)
        dest: "build/<%= relativePath %>/"
      ]
    pkg:
      files: [
        src: ['package.json']
        dest: "build/<%= relativePath %>/package.json"
      ]
    janus_index:
      files: [
        # Serve index.html where janus expects it
        src: ['src/index.html']
        dest: "build/<%= relativePath %>/<%= relativePath %>/index.html"
      ]
    deploy:
      files: [
        expand: true
        cwd: "build/<%= relativePath %>/"
        src: ['**']
        dest: "#{pkg.deploy}/#{pkg.version}"
      ]
      options:
        processContentExclude: ['**/*.{png,gif,jpg,ico,psd,ttf,otf,woff,svg}']
        # Replace contents on files before deploy following rules in options.replace.map.
        process: (src, srcpath) ->
          replaceFiles = glob.sync options.replaceGlob
          for file in replaceFiles when file.indexOf(srcpath) >= 0
            console.log "Replacing file...", file
            for k, v of options.replaceMap
              console.log "Replacing key", k, "with value", v
              src = src.replace(new RegExp(k, 'g'), v)
          return src

  shell:
    sync:
      command: "AWS_CONFIG_FILE=/.aws-config-front aws s3 sync --size-only #{options.dryrun} #{pkg.deploy} s3://vtex-io-us/#{pkg.name}/"
    cp:
      command: "AWS_CONFIG_FILE=/.aws-config-front aws s3 cp --recursive #{options.dryrun} #{pkg.deploy} s3://vtex-io-us/#{pkg.name}/"
    # O Bucket vtex-io usa a região São Paulo, para fallback em caso de problemas com vtex-io-us
    sync_br:
      command: "AWS_CONFIG_FILE=/.aws-config-front aws s3 sync --size-only #{options.dryrun} #{pkg.deploy} s3://vtex-io/#{pkg.name}/"
    cp_br:
      command: "AWS_CONFIG_FILE=/.aws-config-front aws s3 cp --recursive #{options.dryrun} #{pkg.deploy} s3://vtex-io/#{pkg.name}/"

  concat:
    templates:
      options:
        process: (src, srcpath) ->
          fp = srcpath.split("/")
          fileName = fp[fp.length-1].replace(".html", "")
          body = src.replace(/(\r\n|\n|\r)/g, "").replace(/\"/g, "\\\"")
          return "document.write(\"<script type='text/html' id='#{fileName}'>#{body}</script>\");"
      src: 'src/templates/**/*.html'
      dest: "build/<%= relativePath %>/script/ko-templates.js"

  coffee:
    main:
      files: [
        expand: true
        cwd: 'src/script'
        src: ['**/*.coffee']
        dest: "build/<%= relativePath %>/script/"
        rename: (path, filename) ->
          path + filename.replace("coffee", "js")
      ]

  less:
    main:
      files: [
        expand: true
        cwd: 'src/style'
        src: ['style.less', 'print.less']
        dest: "build/<%= relativePath %>/style/"
        ext: '.css'
      ]

  uglify:
    options:
      mangle: false

  nginclude:
    options:
      assertDirs: ['src/']
    src:
      expand: true
      cwd: 'src/views/'
      src: ['**/*.html']
      dest: "build/<%= relativePath %>/views/"

  ngtemplates:
    main:
      cwd: "build/<%= relativePath %>/"
      src: 'views/**/*.html',
      dest: "build/<%= relativePath %>/script/ng-templates.js"
      options:
        module: 'app'
        htmlmin:  collapseWhitespace: true, collapseBooleanAttributes: true

  nggettext_extract:
    pot:
      files: 'src/i18n/template.pot': ['src/**/*.html']

  nggettext_compile:
    all:
      options:
        module: 'app'
      files:
        'build/<%= relativePath %>/script/ng-translations.js': ['src/i18n/*.po']

  useminPrepare:
    html: "build/<%= relativePath %>/index.html"
    options:
      dest: 'build/'
      root: 'build/'

  usemin:
    html: ["build/<%= relativePath %>/index.html", "build/<%= relativePath %>/<%= relativePath %>/index.html"]

  connect:
    http:
      options:
        hostname: "*"
        open: options.open
        port: process.env.PORT || options.port
        middleware: options.middlewares
    https:
      options:
        hostname: "*"
        port: 443
        protocol: 'https'
        middleware: options.middlewares

  watch:
    options:
      livereload: options.livereload
    coffee:
      files: ['src/script/**/*.coffee']
      tasks: ['coffee']
    less:
      options:
        livereload: false
      files: ['src/style/**/*.less']
      tasks: ['less']
    css:
      files: ['build/**/*.css']
    ngtemplates:
      files: ['src/views/**/*.html',
              'src/partials/**/*.html']
      tasks: ['nginclude', 'ngtemplates']
    kotemplates:
      files: ['src/templates/**/*.html']
      tasks: ['concat:templates']
    ngtranslations:
      files: ['src/i18n/**/*.po']
      tasks: ['nggettext_compile']
    main:
      files: ['src/i18n/**/*.json',
              'src/script/**/*.js',
              'src/img/**/*',
              'src/lib/**/*',
              'src/index.html']
      tasks: ['copy:main']
