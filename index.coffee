glob = require 'glob'
exports.generateConfig = (grunt, pkg, options = {}) ->
  throw new Error("Grunt is required") unless grunt
  throw new Error("package.deploy and package.name are required") unless pkg and pkg.deploy and pkg.name

  # options.relativePath: where to put files under build folder
  options.relativePath or= pkg.paths[0].slice(1)
  
  # options.replaceGlob: which files to replace on copy:deploy task
  options.replaceGlob or= "build/**/{index.html,app.js,app.min.js}"
  
  # options.replaceMap: which keys to replace with which values on copy:deploy task
  unless options.replaceMap
    options.replaceMap = {}
    options.replaceMap[pkg.paths[0]] = "//io.vtex.com.br/#{pkg.name}/#{pkg.version}"

  # options.copyIgnore: array of globs to ignore on copy:main
  options.copyIgnore or= ['!views/**', '!partials/**', '!templates/**', '!**/*.coffee', '!**/*.less']
  
  # options.dryrun: if true, nothing will actually be deployed
  options.dryrun or= if grunt.option('dry-run') then '--dryrun' else ''

  # options.open: whether to open automatically a page on running
  if options.open is undefined 
    options.open = "http://basedevmkp.vtexlocal.com.br/#{options.relativePath}/"

  # options.verbose: whether to log all available information
  options.verbose or= grunt.option('verbose')
  
  # options.port: which port the connect proxy should listen to
  options.port or= 80

  # options.proxyTarget: what target to proxy to
  options.proxyTarget or= "http://portal.vtexcommercebeta.com.br:80"
  
  # options.middlewares: array of middlewares to use in connect
  unless options.middlewares
    options.middlewares = [
      require('connect-livereload')({disableCompression: true})
      require('connect-http-please')(replaceHost: ((h) -> h.replace("vtexlocal", environment)), {verbose: options.verbose})
      require('connect-tryfiles')('**', options.proxyTarget, {cwd: 'build/', verbose: options.verbose})
      require('connect').static('./build/')
      (err, req, res, next) ->
        errString = err.code?.red ? err.toString().red
        grunt.log.warn(errString, req.url.yellow)
    ]
    options.middlewares = middlewares.unshift(require('connect-mock')({verbose: options.verbose})) if grunt.option 'mock'

  relativePath: options.relativePath
    
  clean:
    main: ['build', 'deploy']

  copy:
    main:
      files: [
        expand: true
        cwd: 'src/'
        src: ['**'].concat(options.copyIgnore)
        dest: "build/#{options.relativePath}/"
      ]
    pkg:
      files: [
        src: ['package.json']
        dest: "build/#{options.relativePath}/package.json"
      ]
    janus_index:
      files: [
        # Serve index.html where janus expects it
        src: ['src/index.html']
        dest: "build/#{options.relativePath}/#{options.relativePath}/index.html"
      ]
    deploy:
      files: [
        expand: true
        cwd: "build/#{options.relativePath}/"
        src: ['**']
        dest: "#{pkg.deploy}/#{pkg.version}"
      ]
      options:
        processContentExclude: ['**/*.{png,gif,jpg,ico,psd}']
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
    deploy:
      command: "AWS_CONFIG_FILE=/.aws-config-front aws s3 sync --size-only #{options.dryrun} #{pkg.deploy} s3://vtex-io/#{pkg.name}/"

  concat:
    templates:
      options:
        process: (src, srcpath) ->
          fp = srcpath.split("/")
          fileName = fp[fp.length-1].replace(".html", "")
          body = src.replace(/(\r\n|\n|\r)/g, "").replace(/\"/g, "\\\"")
          return "document.write(\"<script type='text/html' id='#{fileName}'>#{body}</script>\");"
      src: 'src/templates/**/*.html'
      dest: "build/#{options.relativePath}/script/ko-templates.js"

  coffee:
    main:
      files: [
        expand: true
        cwd: 'src/script'
        src: ['**/*.coffee']
        dest: "build/#{options.relativePath}/script/"
        rename: (path, filename) ->
          path + filename.replace("coffee", "js")
      ]

  less:
    main:
      files: [
        expand: true
        cwd: 'src/style'
        src: ['style.less', 'print.less']
        dest: "build/#{options.relativePath}/style/"
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
      dest: "build/#{options.relativePath}/views/"

  ngtemplates:
    main:
      cwd: "build/#{options.relativePath}/"
      src: 'views/**/*.html',
      dest: "build/#{options.relativePath}/script/ng-templates.js"
      options:
        module: 'app'
        htmlmin:  collapseWhitespace: true, collapseBooleanAttributes: true

  useminPrepare:
    html: "build/#{options.relativePath}/index.html"
    options:
      dest: 'build/'
      root: 'build/'

  usemin:
    html: ["build/#{options.relativePath}/index.html", "build/#{options.relativePath}/#{options.relativePath}/index.html"]

  connect:
    http:
      options:
        hostname: "*"
        open: options.open
        port: process.env.PORT || options.port
        middleware: options.middlewares

  watch:
    options:
      livereload: true
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
      files: ['src/views/**/*.html', 'src/partials/**/*.html']
      tasks: ['nginclude', 'ngtemplates']
    kotemplates:
      files: ['src/templates/**/*.html']
      tasks: ['concat:templates']
    main:
      files: ['src/i18n/**/*.json', 'src/index.html', 'src/lib/**/*.*']
      tasks: ['copy']
