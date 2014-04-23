# Copyright (c) 2014 Michele Bini
# License: MIT

# This how you can bootstrap the package register and load other Dynmod modules

dir = './'

global.require = require
global[x] = require x for x in 'fs path'.split ' '
  
reg = global.dynmodPackageRegister =
  dir: dir
  require: require
  load: (n)@>
    @require "#{@dir}#{n}.coffee"

packageRegister = reg.load "CoffeePackageRegister"

return module.exports = { pkg, dynmod, dynmodJson, loadJsonPkg, loadRefcoffeePkg, packageRegister } = packageRegister.bootstrap { dir }
