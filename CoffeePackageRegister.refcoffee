module.exports =
  pkgInfo:
    version: "CoffeePackageRegister 0.4.9"
    description: "Package handling loading and saving of dynmod modules"
    copyright: "Copyright (c) 2014 Michele Bini"
  modCompile:
    (options)@>
      { dir, @coffeeOnly } = options if options?
      @dir = dir ?= "dynmod"
      @modExtend(@methods).modMixin fs: @require 'fs'
  pkgIncluded:
    DynmodPackage:
      dynmodPackageRegister.load 'DynmodPackage'
  JSON: global.JSON
  global: global.global
  require: global.require
  CoffeeScript: global.CoffeeScript
  loadWithNodejs:
    false
  saveForNodejs:
    true
  NodejsLoader:
    dynmodPackageRegister.load 'NodejsLoader'
  Buffer: global.Buffer
  loadFile:
    (filename, options)@>
      fs = @fs ?= @require 'fs'
      getFileHeader = (filename, size)->
        buffer = new @Buffer(size)
        fd = fs.openSync filename, "r"
        r = fs.readSync fd, buffer, 0, size
        fs.closeSync fd
        d = buffer.slice(0, r)
        { StringDecoder } = @string_decoder ?= @require "string_decoder"
        decoder = new StringDecoder
        decoder.write d
      if @NodejsLoader? and /^module.exports/.test(getFileHeader(filename, 40)) or @loadWithNodejs
        # Loader compatible with NodeJs only.
        # It is the only one supporting the coffeescript source map, though.
        @NodejsLoader.load filename
        # if options.?cleanEnv
        #   cache = require.cache
        #   try
        #     require.cache { }
        #     @require filename
        #   finally
        #     require.cache = cache
        # else
        #   delete require.cache[filename] if options.?mustReload
        #   @require filename
      else if true
        # Loader compatible with NodeJs
        x = fs.readFileSync(filename).toString()
        module = @global.module
        try
          @global.module = { }
          @CoffeeScript.eval x
        finally
          @global.module = module
      else
        # Incompatible loader
        x = fs.readFileSync(filename).toString()
        @CoffeeScript.eval x, { filename }
  bootstrap:
    (options)@>
      # Boostrap loading of package register for dynmod modules
      # options.coffeeOnly results in loading only js files and is 
      # ~40% faster
      dir = options?.dir ? "."
      cDir = options?.cDir ? dir
      jDir = options?.jDir ? dir
    
      CoffeeScript = @CoffeeScript
      dynmodJson = @dynmodJson
      JSON = @JSON
      @global.fs = fs = @fs
      # fs buffer child_process cluster crypto dgram dns events fs http https net os path punycode querystring readline repl string_decoder tls tty url util vm zlib
      nodejs_builtin_modules = "net,child_process,crypto,cluster,dgram,dns,events,fs,http,https,os,path,punycode,querystring,readline,repl,string_decoder,tls,tty,url,util,vm,zlib"
      for x in nodejs_builtin_modules.split ","
        @global[x] ?= @require x
    
      loadRefcoffeePkg = (pkgName)=>
        @loadFile "#{cDir}/#{pkgName}.refcoffee"
    
      pkg = loadRefcoffeePkg "DynmodPackage"
    
      pkgs = { }
    
      customImport = null
    
      loadJsonPkg = (pkgName)=>
        return x if (x = pkgs[pkgName])?
        pkgs[pkgName] = r = { }
        m = dynmodJson.fromJson(JSON.parse(fs.readFileSync("#{pkgName}.json").toString()), { customImport })
        r[k] = v for k,v of m
        r
    
      customImport = ({ t, d })->
        return null unless t is "P"
        d = d.replace(/\ .*/, "")
        loadJsonPkg d
    
      # now we are able to load dynmod json module files
    
      @global.dynmodPackageRegister =
        load: loadRefcoffeePkg

      unless options?.coffeOnly
        # { dynmodJson }  = require './dynmodJson'
        dynmodJson = loadRefcoffeePkg "DynmodJson"
        dynmodJson = pkg.pkgInclude pkg, target: dynmodJson
    
      global.dynmodPackageRegister =
        load: loadRefcoffeePkg
    
      # packageRegister = loadJsonPkg "SimpleDirectoryPackageRegister"
      # packageRegister = loadRefcoffeePkg "SimpleDirectoryPackageRegister"
      if options.coffeeOnly
        packageRegister = @
      else
        packageRegister = loadRefcoffeePkg "CoffeeJsonPackageRegister"
      # packageRegister.dynmodJson = dynmodJson
      packageRegister = pkg.pkgInclude pkg, target: packageRegister
      options.dir = jDir
      packageRegister = packageRegister.modCreate options
    
      @global.dynmodPackageRegister = packageRegister
    
      # { dynmod }  = require './dynmod'
      { dynmod } = packageRegister.load "DynmodCore"
    
      { pkg, dynmod, dynmodJson, loadJsonPkg, loadRefcoffeePkg, packageRegister }
  dynmodJson:
    dynmodPackageRegister.load 'DynmodJson'
  dynmodPrinter:
    dynmodPackageRegister.load 'DynmodPrinter'
  methods:
    has:
      (name)@> @fs.existsSync("#{@dir}/#{name}.json")
    load:
      (name, options)@>
        throw "No package name to load!" unless name?
        name = name.replace(/\ .*/, "")
        if options?.shallow
          customImport = ( ({ t, d })=> return null if t isnt "P"; pkgInfo: version: d )
          return @dynmodJson.fromJson @JSON.parse( @fs.readFileSync("#{@dir}/#{name}.json").toString() ), { customImport }
        pkgs = null
        noInclusions = false
        fromJson = false
        coffeeOnly = @coffeeOnly
        { pkgs, noInclusions, jsonOnly, coffeeOnly } = options if options?
        pkgs = @pkgs ?= { } unless pkgs?
        customImport = ({ t, d })=>
          return null unless t is "P"
          throw "No package name or version to load!" unless d?
          d = d.replace(/\ .*/, "")
          try
            @load d, { pkgs } # FIXME: the pkgs[d] = could be a mistake here
          catch error
            throw "While loading #{d}: #{error}"
        return cached if (cached = pkgs[name])?
        pkgs[name] = r = { }
        if jsonOnly
          j = @JSON.parse( @fs.readFileSync("#{@dir}/#{name}.json").toString() )
          m = @dynmodJson.fromJson j, { customImport }
        else if coffeeOnly
          filename = "#{@dir}/#{name}.refcoffee"
          m = @loadFile filename
        else
          # Load both
          filename = "#{@dir}/#{name}.refcoffee"
          mc = @loadFile filename
          filename = "#{@dir}/#{name}.json"
          if @fs.existsSync(filename)
            j = @JSON.parse( @fs.readFileSync(filename).toString() )
            mj = @dynmodJson.fromJson j, { customImport }
            m = @graft mj, mc
          else
            m = mc
        r[k] = v for k,v of m
        return r if noInclusions
        @pkgRedoInclusions target: r
    shouldReallySave:
      (pkg, pkgName)@>
        # return true
        if !(nameVersion = pkg?.pkgInfo?.version)?
          throw "Package has no name or version"
        return true unless @has pkgName
        m = @load pkgName, noInclusions:1, shallow:1
        if !(oldNameVersion = m?.pkgInfo?.version)?
          throw "Package on disk has no name or version"
        return nameVersion isnt oldNameVersion
    graft:
      (loaded, pkg)@>
        loaded = @pkgAmend target: loaded
        pkgInfo = @modMixin.call @modStrip.call(pkg.pkgInfo, lineage:1, dist:1), loaded.pkgInfo
        @modMixin.call { pkgInfo }, pkg
    loadAndGraft:
      (pkgName, pkg)@>
        try
          loaded = @load pkgName, noInclusions: 1, pkgs: { }, jsonOnly: 1
        catch error
          throw "While loading #{pkgName}: #{error}"
        @graft loaded, pkg
    save:
      (pkg, options)@>
        # @console.log "saving #{pkg.pkgInfo.version}"
        pkgName = @pkgGetName target: pkg
        toSave = { }
        pkgs = null
        depth = 1
        { pkgs, depth, noGraftError } = options if options?
        if (graft = options?.graft)?
          if @has graft
            pkg = @loadAndGraft graft, pkg
          else
            if noGraftError
              pkg = @pkgRecompile target: pkg
            else
              throw "Package #{graft} to graft doesn't exist"
        if (message = options?.commit)?
          pkg = @pkgCommit message, target: pkg
        pkgs ?= { }
        customExport = (obj, rec, par)=>
          return null unless par?
          if typeof obj is "object"
            if obj.pkgInfo?
              try
                d = @pkgGetName target: obj
              catch error
                return null
              return null if d is pkgName
              nameVersion = obj.pkgInfo.version
              unless nameVersion?
                throw "Can not persist a package without name or version"
              # @save obj, { pkgs } # This would work if @save was reentrant (it isn't because of visit tokens added to visited structures)
              if obj?.pkgInfo?.dist 
                toSave[d] ?= obj
              return { t: "P", d: nameVersion }
          return null
        return cached if (cached = pkgs[pkgName])?
        pkgs[pkgName] = r = { }
        if @shouldReallySave pkg, pkgName
          pkg = @pkgRevert target: pkg, noInclusions: 1
          try
            customImport = ( ({ t, d })=> return null if t isnt "P"; pkgInfo: version: d )
            j = @dynmodJson.toJson pkg, { customExport, customImport }
          catch error
            throw "While saving #{pkgName}: #{error}"
          r[k] = v for k,v of j
          @fs.writeFileSync "#{@dir}/#{pkgName}.json", @JSON.stringify(j)
          @updateRefcoffeeSource pkgName unless options.noUpdateRefcoffee
        else
          if depth <= 1
            throw "Could not save #{pkgName} (version and name are unchanged)"
        depth++
        @save v, { pkgs, depth } for k,v of toSave
        r
    getRefcoffeeSource:
      (name)@>
        p = @load name, shallow: 1, noInclusions: 1, jsonOnly: 1
        { pkgInfo } = p
        if pkgInfo?
          p = @modStrip.call p, pkgInfo: 1
          pkgInfo = @modStrip.call pkgInfo, lineage: 1, dist: 1
          { version } = pkgInfo
          { description } = pkgInfo
          pkgInfo = @modStrip.call pkgInfo, version: 1, description: 1
          pkgInfo = @modMixin.call pkgInfo, { description } if description?
          pkgInfo = @modMixin.call pkgInfo, { version } if version?
          p = @modMixin.call p, { pkgInfo } if pkgInfo?
        if @saveForNodejs
          return "module.exports =\n  " + @dynmodPrinter.print(p).replace(/\n/g, "\n  ") + "\n"
        else
          return @dynmodPrinter.print(p) + "\n"
        # s2 = s2.replace(/\n[\ \t]+\n/g, "\n\n")
        # @fs.writeFileSync "#{@dir}/#{name}.refcoffee"
        # "#{s1}\n#{s2}\n"
    updateRefcoffeeSource:
      (name)@>
        filename = "#{@dir}/#{name}.refcoffee"
        source = @getRefcoffeeSource name
        if @fs.existsSync(filename)
          existingSourceCode = @fs.readFileSync(filename).toString()
          a = source
          b = existingSourceCode
          if @normalizeSource(a) is @normalizeSource(b)
            unless a is b
              @fs.writeFileSync(filename, source)
          else
            @fs.writeFileSync(filename + ".new", source)
        else
          @fs.writeFileSync(filename, source)
    normalizeSource:
      (x)@>
        x.replace(/^module[.](exports)\ =\n/, "").replace(/[\ \n]+/g, " ").replace(/^[\ \t\n]+/, "").replace(/[\ \t\n]+$/, "").replace(/global[.]/g, "")
    testRefcoffeeSource:
      (name)@>
        filename = "#{@dir}/#{name}.refcoffee"
        source = @getRefcoffeeSource name
        if @fs.existsSync(filename)
          existingSourceCode = @fs.readFileSync(filename).toString()
          if source is existingSourceCode
            return "unchanged"
          a = @normalizeSource source
          b = @normalizeSource existingSourceCode
          if a is b
            return "whitespace change"
          else
            return "changed"
        else
          return "missing"
