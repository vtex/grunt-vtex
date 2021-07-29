const glob = require('glob')
const chalk = require('chalk')

const log = (...args) => {
  return console.log(chalk.yellow('grunt-vtex >>>'), ...args)
}

module.exports = function (grunt, pkg, options) {
  const config = {
    relativePath: options.relativePath,
    clean: {
      main: ['build', 'deploy'],
    },
    copy: {
      main: {
        files: [
          {
            expand: true,
            cwd: 'src/',
            src: ['**'].concat(options.copyIgnore),
            dest: 'build/<%= relativePath %>/',
          },
        ],
      },
      pkg: {
        files: [
          {
            src: ['package.json'],
            dest: 'build/<%= relativePath %>/package.json',
          },
        ],
      },
      janus_index: {
        files: [
          {
            // Serve index.html where janus expects it
            src: ['src/index.html'],
            dest: 'build/<%= relativePath %>/<%= relativePath %>/index.html',
          },
        ],
      },
      deploy: {
        files: [
          {
            expand: true,
            cwd: 'build/<%= relativePath %>/',
            src: ['**'],
            dest: `${pkg.deploy}/${pkg.version}`,
          },
        ],
        options: {
          processContentExclude: [
            '**/*.{png,gif,jpg,ico,psd,ttf,otf,woff,svg}',
          ],
          process(src, srcpath) {
            const replaceFiles =
              grunt.config('deployReplaceFiles') ??
              grunt.config('deployReplaceFiles', glob.sync(options.replaceGlob))

            for (const file of replaceFiles) {
              if (!(file.indexOf(srcpath) >= 0)) {
                continue
              }

              log('Replacing file...', file)

              for (const k in options.replaceMap) {
                const v = options.replaceMap[k]

                log('Replacing key', k, 'with value', v)
                src = src.replace(new RegExp(k, 'g'), v)
              }
            }

            return src
          },
        },
      },
      dev: {
        files: [
          {
            expand: true,
            cwd: 'build/<%= relativePath %>/',
            src: options.devReplaceGlob,
            dest: 'build/<%= relativePath %>/',
          },
        ],
        options: {
          processContentExclude: [
            '**/*.{png,gif,jpg,ico,psd,ttf,otf,woff,svg}',
          ],
          process(src, srcpath) {
            log('Replacing file...', srcpath)

            const features = grunt.config.get('features')
            const symlink = grunt.config.get('symlink')
            const tags = grunt.config.get('tags')

            for (const key in options.devReplaceMap) {
              const value = options.devReplaceMap[key]
              const replaceValue =
                typeof value === 'function'
                  ? value(features, symlink, tags)
                  : value

              log(
                chalk.green('replace'),
                key.replace(/\n/g, '\\n').replace(/\rn/g, '\\rn'),
                typeof replaceValue === 'string'
                  ? chalk.green('-> ') + replaceValue
                  : `${chalk.green('-> ')}function return`
              )
              src = src.replace(new RegExp(key, 'g'), replaceValue)
            }

            return src
          },
        },
      },
    },
    shell: {
      sync: {
        command: `aws s3 sync --size-only ${options.dryrun} ${pkg.deploy} s3://vtex-io-us/${pkg.name}/`,
      },
      cp: {
        command: `aws s3 cp --recursive ${options.dryrun} ${pkg.deploy} s3://vtex-io-us/${pkg.name}/`,
      },
    },
    concat: {
      templates: {
        options: {
          process(src, srcpath) {
            const fp = srcpath.split('/')
            const fileName = fp[fp.length - 1].replace('.html', '')
            const body = src.replace(/(\r\n|\n|\r)/g, '').replace(/"/g, '\\"')

            return `document.write("<script type='text/html' id='${fileName}'>${body}</script>");`
          },
        },
        src: 'src/templates/**/*.html',
        dest: 'build/<%= relativePath %>/script/ko-templates.js',
      },
    },
    jshint: {
      options: {
        node: true,
        esnext: true,
        bitwise: true,
        camelcase: true,
        curly: true,
        eqeqeq: true,
        immed: true,
        indent: 2,
        latedef: true,
        newcap: true,
        noarg: true,
        quotmark: 'single',
        regexp: true,
        undef: true,
        unused: true,
        strict: true,
        trailing: true,
        smarttabs: true,
        white: true,
      },
      main: {
        src: ['src/script/**/*.js'],
      },
    },
    coffee: {
      main: {
        files: [
          {
            expand: true,
            cwd: 'src/script',
            src: ['**/*.coffee'],
            dest: 'build/<%= relativePath %>/script/',
            rename(path, filename) {
              return path + filename.replace('coffee', 'js')
            },
          },
        ],
      },
    },
    less: {
      main: {
        files: [
          {
            expand: true,
            cwd: 'src/style',
            src: ['style.less', 'print.less'],
            dest: 'build/<%= relativePath %>/style/',
            ext: '.css',
          },
        ],
      },
    },
    uglify: {
      options: {
        banner: `/* ${pkg.name} - v${pkg.version} */`,
        mangle: false,
      },
    },
    nginclude: {
      options: {
        assertDirs: ['src/'],
      },
      src: {
        expand: true,
        cwd: 'src/views/',
        src: ['**/*.html'],
        dest: 'build/<%= relativePath %>/views/',
      },
    },
    ngtemplates: {
      main: {
        cwd: 'build/<%= relativePath %>/',
        src: 'views/**/*.html',
        dest: 'build/<%= relativePath %>/script/ng-templates.js',
        options: {
          module: 'app',
          htmlmin: {
            collapseWhitespace: true,
            collapseBooleanAttributes: true,
          },
        },
      },
    },
    nggettext_extract: {
      pot: {
        files: {
          'src/i18n/template.pot': ['src/**/*.html'],
        },
      },
    },
    nggettext_compile: {
      all: {
        options: {
          module: 'app',
        },
        files: {
          'build/<%= relativePath %>/script/ng-translations.js': [
            'src/i18n/*.po',
          ],
        },
      },
    },
    useminPrepare: {
      html: 'build/<%= relativePath %>/index.html',
      options: {
        dest: 'build/',
        root: 'build/',
      },
    },
    usemin: {
      html: [
        'build/<%= relativePath %>/index.html',
        'build/<%= relativePath %>/<%= relativePath %>/index.html',
      ],
    },
    connect: {
      http: {
        options: {
          hostname: '*',
          open: options.open,
          port: process.env.PORT || options.port,
          middleware: options.middlewares,
        },
      },
      https: {
        options: {
          hostname: '*',
          port: 443,
          protocol: 'https',
          key: grunt.file
            .read('node_modules/grunt-vtex/assets/server.key')
            .toString(),
          cert: grunt.file
            .read('node_modules/grunt-vtex/assets/server.crt')
            .toString(),
          middleware: options.middlewares,
        },
      },
    },
    symlink: {
      main: {},
    },
    watch: {
      options: {
        livereload: options.livereload,
      },
      link: {
        files: ['!build/<%= relativePath %>/*', 'build/**/*'],
      },
      coffee: {
        files: ['src/script/**/*.coffee'],
        tasks: ['coffee'],
      },
      less: {
        options: {
          livereload: false,
        },
        files: ['src/style/**/*.less'],
        tasks: ['less'],
      },
      css: {
        files: ['build/**/*.css'],
      },
      ngtemplates: {
        files: ['src/views/**/*.html', 'src/partials/**/*.html'],
        tasks: ['nginclude', 'ngtemplates'],
      },
      kotemplates: {
        files: ['src/templates/**/*.html'],
        tasks: ['concat:templates'],
      },
      ngtranslations: {
        files: ['src/i18n/**/*.po'],
        tasks: ['nggettext_compile'],
      },
      gruntfile: {
        files: ['Gruntfile.coffee'],
      },
      main: {
        files: [
          'src/i18n/**/*.json',
          'src/script/**/*.js',
          'src/img/**/*',
          'src/lib/**/*',
          'src/index.html',
          'src/index.dust',
        ],
        tasks: ['copy:main', 'getTags', 'copy:dev'],
      },
    },
  }

  const linkedProjectsOption = grunt.option('link')

  // grunt option `--link`: sibling project directories to link in order to develop locally.
  if ((linkedProjectsOption?.length ?? 0) > 0) {
    const symlink = {}

    for (const project of linkedProjectsOption.split(',')) {
      log('Linking', project, `to build/${project}`)
      symlink[project] = {
        src: `../${project}/build/${project}`,
        dest: `build/${project}`,
      }
    }

    config.symlink = symlink
  }

  const featuresOption = grunt.option('ft')

  // grunt option `--ft`: features that should be toggled.
  if ((featuresOption?.length ?? 0) > 0) {
    const features = {}
    const featuresArray = featuresOption.split(',')

    for (const feature of featuresArray) {
      features[feature] = {
        toggle: true,
      }
      log('Feature toggle:', feature)
    }

    config.features = features
  }

  return config
}
