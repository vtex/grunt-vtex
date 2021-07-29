const chalk = require('chalk')

const getLinkReplace = function (grunt, pkg, options) {
  return function linkReplace(features, symlink, tags) {
    return function (match, path, app, major) {
      const env = options.stable ? 'stable' : 'beta'

      if (symlink[app]) {
        console.log(chalk.blue('link'), app, chalk.blue('->'), 'local')

        return `/${app}/${path.replace('.min', '')}`
      }

      const version = tags[app][env][major]

      console.log(chalk.blue('link'), app, chalk.blue('->'), version)

      return `//io.vtex.com.br/${app}/${version}/${path}`
    }
  }
}

module.exports = getLinkReplace
