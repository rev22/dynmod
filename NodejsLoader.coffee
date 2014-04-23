module.exports =
  pkgInfo:
    version: "NodejsLoader 0.0.0"
    description: "Module loader compatible with Node and Coffeescript's source map"
    copyright: "Copyright (c) 2014 Michele Bini"
    license: "MIT"  
  fs: global.fs
  require: global.require
  path: global.path
  JSON: global.JSON
  CoffeeScript: global.CoffeeScript
  load:
    (filename, options = {}) @>
      { require } = @
      main = require.main
      options.sourceMap = 1
      options.filename = filename
      main.filename = @fs.realpathSync filename
      main.moduleCache and= {}
      dir = @path.dirname @fs.realpathSync main.filename
      main.paths = require('module')._nodeModulePaths dir
      code = @fs.readFileSync filename, "utf-8"
      code = @CoffeeScript.compile code, options
      code = code.js ? code
      main._compile code, main.filename
      main.exports
