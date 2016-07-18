getLinkReplace = (grunt, pkg, options) ->
  linkReplace = (features, symlink, tags) -> (match, path, app, major) ->
    env = if options['stable'] then 'stable' else 'beta'
    if symlink[app]
      console.log "link".blue, app, "->".blue, "local"
      return "/#{app}/#{path.replace('.min', '')}"
    else
      version = tags[app][env][major]
      console.log "link".blue, app, "->".blue, version
      return "//io.vtex.com.br/#{app}/#{version}/#{path}"


module.exports = getLinkReplace
