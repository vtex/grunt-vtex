# Grunt VTEX

A Grunt convention-over-configuration meta-project.

The file `index.coffee` exposes only one function: `generateConfig`.  
It receives your `grunt`, `pkg` (your package.json parsed object) and `options`.  
It returns an object with configurations for all tasks used across projects in VTEX.  

Your project should only define very specific customizations outside of this config.  
This enforces uniformity and eases advancing configurations across every project simultaneously.

## Important - contributors

If you are heavily altering a defined task or adding a new one, please **bump the minor version**.

## Usage

In your Gruntfile:

    GruntVTEX = require 'grunt-vtex'

    module.exports = (grunt) ->
      pkg = grunt.file.readJSON 'package.json'
  
      options = {...}
      config = GruntVTEX.generateConfig grunt, pkg, options

      ## customize by altering config
      config.copy.main = {...}
      
      tasks = {...}
    
      grunt.initConfig config
      grunt.loadNpmTasks name for name of pkg.devDependencies when name[0..5] is 'grunt-'
      grunt.registerTask taskName, taskArray for taskName, taskArray of tasks

## Options

**options.relativePath** where to put files under build folder  
**options.replaceGlob** which files to replace on copy:deploy task  
**options.replaceMap** which keys to replace with which values on copy:deploy task  
**options.devReplaceGlob** which files to replace on copy:dev task  
**options.devReplaceMap** which keys to replace with which values on copy:dev task  
**options.copyIgnore** array of globs to ignore on copy:main  
**options.dryrun** if true, nothing will actually be deployed  
**options.open** whether to open automatically a page on running  
**options.verbose** whether to log all available information  
**options.port** which port the connect proxy should listen to  
**options.replaceHost** function to replace the host upon proxying  
**options.proxyTarget** what target to proxy to  
**options.followHttps** whether to follow HTTPS redirects transparently and return HTTP  
**options.livereload** whether to use livereload, or in which port to use it 
**options.middlewares** array of middlewares to use in connect  

## Grunt command line options

- `--stable`: proxies to stable API's instead of beta.
- `--link`: sibling project directories to link in order to develop locally.
- `--ft`: features that should be toggled.

## Registered tasks

- **getTags**: this task fetches the current `tags.json` file, which tells us which apps are currently published with which versions. 

Example excerpt of a `tags.json` file:

    {
        oms-ui: {
            stable: {
                2: "2.9.76"
            },
            beta: {
                2: "2.9.99-beta"
            }
        },
        license-manager-ui: {
            stable: {
                2: "2.1.23"
            },
            beta: {
                2: "2.1.23"
            }
        },
        vtex-id-ui: {
            stable: {
                2: "2.2.6",
                3: "3.2.29"
            },
            next: { },
            beta: {
                2: "2.2.6",
                3: "3.2.29-beta"
            },
            alpha: { }
        }
    }

## Using link

To develop two projects simultaneously, follow these steps:

- Clone the other project into a sibling directory, install and start with the "dev" task.

        $ cd Projects/
        $ git clone git@github.com:vtex/front.shipping-data.git
        $ cd front.shipping-data
        $ npm i
        $ grunt dev // some target which doesn't run a server and livereload

- In another terminal tab, start grunt with the `link` option, passing the name of the component:

        $ cd Projects/vcs.checkout-ui
        $ grunt --link front.shipping-data
    
This will symlink the `build` folder from the sibling into the `build` folder in this project.

You can also separate multiple projects with a comma, e.g.

        $ grunt --link front.shipping-data,front.cart

## Using feature toggles

You may turn a feature on using the `ft` option:

        $ grunt --ft totem
  
## Advanced `devReplaceMap` usage

`devReplaceMap` accepts a string or a function as a value for a key. In case of a function, it will receive three parameters:

- features, the map of toggled features (using `--ft`)
- symlink, the `symlink` task config, which is created according to the `--link` option
- tags, the `tags.json` map of published projects.

The result of this function is passed on to the `replace` function. Therefore, you can return a `function` that handles the pattern matching!

e.g.:

    featureToggleReplace = (features, symlink, tags) ->	(match) ->
		if features?['totem'] then match else ''

	linkReplace = (features, symlink, tags) -> (match, path, app, major) ->
		env = if grunt.option('stable') then 'stable' else 'beta'
		if symlink[app]
			console.log "link".blue, app, "->".blue, "local"
			return "/#{app}/#{path}"
		else
			version = tags[app][env][major]
			console.log "link".blue, app, "->".blue, version
			return "//io.vtex.com.br/#{app}/#{version}/#{path}"

	devReplaceMap = {}
	devReplaceMap["{{ 'checkout-custom.css' | legacy_file_url }}"] = '/arquivos/checkout-custom.css'
	devReplaceMap["{{ 'checkout-custom.css' | file_url }}"] = '/files/checkout-custom.css'
	devReplaceMap["{% if config.kiosk %}(\n|\rn|.)*\{% endif %}"] = featureToggleReplace
	devReplaceMap["\\{\\{ \\'(.*)\\' \\| vtex_io: \\'(.*)\\', (\\d) \\}\\}"] = linkReplace
  
------

VTEX - 2014
