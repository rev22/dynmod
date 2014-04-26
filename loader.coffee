# Copyright (c) 2014 Michele Bini
# License: MIT

# This how you can bootstrap the package archive and load other Dynmod modules

dir = './'

global.require = require
global[x] = require x for x in 'fs path'.split ' '
  
global.dynmodArchive = archive =
  dir: dir
  require: require
  load: (n)@>
    @require "#{@dir}#{n}.coffee"

archive = archive.load "CoffeePackageRegister"

return module.exports = { pkg, dynmod, dynmodJson, loadJsonPkg, loadRefcoffeePkg, dynmodArchive } = archive.bootstrap { dir }
