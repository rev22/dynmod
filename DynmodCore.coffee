pkgInfo:
  version: "DynmodCore 0.2.2"
  description: "Basic operations for Dynmod modules"
  copyright: "Copyright (c) 2014 Michele Bini"
  license: "MIT"
pkgIncluded:
  DynmodPackage:
    dynmodPackageRegister.load 'DynmodPackage'
dynmod:
  modClone:
    @> @modExtend()
  modCompile:
    @> @
  modCreate:
    @> @modCompile.apply @modClone(), arguments
  modExtend:
    @>
      o = { }
      o[n] = v for n,v of @
      (o[n] = v for n,v of fields) for fields in arguments
      o.modRecompile()
  modMixin:
    @>
      o = { }
      (o[n] = v for n,v of fields) for fields in arguments
      o[n] = v for n,v of @
      o
  modRecompile:
    @> @
  modRegress:
    @>
      # this can be thought of as reversing modExtend:
      #   b.modExtend(b.modExtend(a).modStrip b) is b.modExtend(a)
      # also can be useful for converting modules into traits
      o = { }
      o[n] = v for n,v of @
      ((delete o[k] if o[k] == x) for k,x of fields) for fields in arguments
      o
  modStrip:
    @>
      # this is useful for coverting modules into mixins
      o = { }
      o[n] = v for n,v of @
      (delete o[k] for k,x of fields) for fields in arguments
      o
