/* eslint-disable node/global-require */

const chalk = require('chalk')

const getLinkReplace = require('./linkReplace')

const log = (...args) => {
  console.log(chalk.yellow('grunt-vtex >>>'), ...args)
}

module.exports = function (grunt, pkg, options) {
  // options.relativePath: where to put files under build folder
  options.relativePath || (options.relativePath = pkg.name)
  // options.replaceGlob: which files to replace on copy:deploy task
  options.replaceGlob ||
    (options.replaceGlob = 'build/**/{index.html,app.js,app.min.js}')

  // options.replaceMap: which keys to replace with which values on copy:deploy task
  if (!options.replaceMap) {
    options.replaceMap = {}
    options.replaceMap[
      `/${options.relativePath}`
    ] = `//io.vtex.com.br/${pkg.name}/${pkg.version}`
  }

  // options.devReplaceGlob: which files to replace on copy:dev task. Relative to build/relativePath.
  options.devReplaceGlob || (options.devReplaceGlob = 'index.html')
  // options.devReplaceMap: which keys to replace with which values on copy:dev task
  options.devReplaceMap || (options.devReplaceMap = {})
  options.devReplaceMap[
    "\\{\\{ \\'(.*)\\' \\| vtex_io: \\'(.*)\\', (\\d) \\}\\}"
  ] = getLinkReplace(grunt, pkg, options)
  // options.copyIgnore: array of globs to ignore on copy:main
  options.copyIgnore ||
    (options.copyIgnore = [
      '!views/**',
      '!partials/**',
      '!templates/**',
      '!**/*.coffee',
      '!**/*.less',
      '!**/*.pot',
      '!**/*.po',
    ])
  // options.dryrun: if true, nothing will actually be deployed
  options.dryrun || (options.dryrun = grunt.option('dry-run') ? '--dryrun' : '')
  // options.open: whether to open automatically a page on running
  if (options.open === undefined) {
    options.open = {
      target: `http://basedevmkp.vtexlocal.com.br/${options.relativePath}/`,
    }
  } else if (typeof options.open === 'string') {
    const target = options.open

    options.open = {
      target,
    }
  }

  // options.verbose: whether to log all available information
  options.verbose || (options.verbose = grunt.option('verbose'))
  // options.port: which port the connect proxy should listen to
  options.port || (options.port = 80)
  // options.replaceHost: function to replace the host upon proxying
  options.replaceHost ||
    (options.replaceHost = function (h) {
      return h.replace('vtexlocal', 'vtexcommercebeta')
    })
  // options.proxyTarget: what target to proxy to
  options.proxyTarget ||
    (options.proxyTarget = 'http://portal.vtexcommercebeta.com.br:80')
  // options.followHttps: whether to follow HTTPS redirects transparently and return HTTP
  options.followHttps || (options.followHttps = false)
  // options.janusEnvHeader: Janus header to set environment
  options.janusEnvHeader ||
    (options.janusEnvHeader = 'X-VTEX-Janus-Router-CurrentApp-EnvironmentType')
  // options.livereload: whether to use livereload, or in which port to use it
  if (options.livereload === undefined) {
    options.livereload = true
  }

  if (options.headers === undefined) {
    options.headers = {}
    options.headers[options.janusEnvHeader] = 'beta'
  }

  // grunt option `--stable`: proxies to stable API's instead of beta.
  if (grunt.option('stable')) {
    log('Pointing to stable APIs')
    options.headers || (options.headers = {})
    options.headers[options.janusEnvHeader] = 'stable'
  }

  // if options.middleware is defined, nothing else to do
  if (!options.middlewares) {
    // options.middlewares: array of middlewares to use in connect
    options.middlewares = []
    // Header middlewares - always go first
    if (grunt.option('mock')) {
      options.middlewares.push(
        require('connect-mock')({
          verbose: options.verbose,
        })
      )
    }

    if (options.headers) {
      const addHeaders = function (req, res, next) {
        for (const h in options.headers) {
          const v = options.headers[h]

          req.headers[h] = v
        }

        req.env = req.headers[options.janusEnvHeader]

        return next()
      }

      options.middlewares.push(addHeaders)
    }

    if (options.livereload) {
      const lrPort =
        typeof options.livereload === 'number' ? options.livereload : null

      options.middlewares.push(
        require('connect-livereload')({
          disableCompression: true,
          port: lrPort,
        })
      )
    }

    if (options.followHttps) {
      options.middlewares.push(
        require('connect-http-please')(
          {
            replaceHost: options.replaceHost,
          },
          {
            verbose: options.verbose,
          }
        )
      )
    }

    // Use additional user defined middlewares
    if (options.additionalMiddlewares) {
      options.middlewares = options.middlewares.concat(
        options.additionalMiddlewares
      )
    }

    // Tail middlewares - always go last
    return (options.middlewares = options.middlewares.concat([
      require('connect-tryfiles')('**', options.proxyTarget, {
        cwd: 'build/',
        verbose: options.verbose,
      }),
      require('connect').static('./build/'),
      function (err, req) {
        const errString = chalk.red(err.code ?? err.toString())

        return grunt.log.warn(errString, chalk.yellow(req.url))
      },
    ]))
  }
}
