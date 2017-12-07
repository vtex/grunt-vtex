log = -> console.log "grunt-vtex >>>".yellow, arguments...

module.exports = (grunt, pkg, options) ->
  return {
    legacy_file_url: (s) ->
      return '/arquivos/' + s
    file_url: (s) ->
      return '/files/' + s
    vtex_io: (script, app, version) ->
      features = grunt.config.get("features")
      symlink = grunt.config.get("symlink")
      tags = grunt.config.get("tags")

      if symlink[app]
        log "Resolving ".green + "#{app}@#{version}".blue + " to ".green + "local".blue

        return "/#{app}/#{script.replace('.min', '')}"

      env = if grunt.option('stable') then 'stable' else 'beta'
      resolvedVersion = tags[app][env][version]

      log "Resolving ".green + "#{app}@#{version}".blue + " to #{env} ".green + resolvedVersion.blue
      return "//io.vtex.com.br/#{app}/#{resolvedVersion}/#{script}"

  }
