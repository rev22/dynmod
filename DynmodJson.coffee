pkgInfo:
  version: "DynmodJson 0.3.5"
  description: "Compress code and data into a JSON-compatible object"
  copyright: "Copyright (c) 2014 Michele Bini"
  license: "MIT"
Array: Array
CoffeeScript: CoffeeScript
console: console
fromJson:
  (x, options)@>
    customImport = null
    if options?
      { customImport } = options
    handleType = null
    objs = [ ]
    addObj = (x)-> objs.push x; x
    fromJson = (x, par = null)->
      rec = (xx, x)-> fromJson xx, { x, par }
      return addObj(imp) if (imp = customImport?(x))?
      handleType[x.t](x.d, rec, par)
    handleType =
      c: addObj
      f: (x)=> addObj(@CoffeeScript.eval x)
      a: (x, rec)=>
        addObj(l = [])
        l.push rec(xx, l) for xx in x
        l
      g: (x)=> addObj(if x? then @global[x] else @global)
      h: (x, rec)=>
        addObj(r = {})
        for kk, vv of x
          r[kk] = rec vv, r
        r
      H: (x, rec)=>
        keyOrder = []
        addObj(r = { })
        ii = 0
        len = x.length
        while ii < len
          kk = x[ii]
          keyOrder.push kk
          vv = x[ii + 1]
          r[kk] = rec vv, r
          ii = ii + 2
        # r.keyOrder = keyOrder if len > 2
        r
      r: (x)=> addObj(objs[objs.length - 1 - x])
      y: (x, rec, par)=>
        b = x[0] - 1
        while b-- > 0
          par = par.par
        y = par.x
        i = x[1]
        len = i.length
        ii = 0
        while ii < len
          y = y[i[ii]]
          ii++
        addObj(y)
    fromJson x
fromJsonNoCopies:
  (x)@>
    # @update()
    handleType = null
    fromJson = (x)-> handleType[x.t](x.d)
    handleType =
      c: (x)=> x
      f: (x)=> @CoffeeScript.eval x
      a: (x)=> (fromJson(xx) for xx in x)
      g: (x)=> if x? then @getGlobal x else @global
      h: (x)=>
        r = {}
        for kk, vv of x
          r[kk] = fromJson vv
        r
    fromJson x
getGlobal:
  (k)@>
    return r if (r = @global[k])?
    # return r if (r = @nodejsModules[k])?
    # return @require(r) if r = @coreNodejsModules[k])
    throw "Global object or nodejs module #{k} was not found"
global: global
handlePair:
  (k, v, o, r, rec, addObj)@>
    # By default, global imports are skipped
    return if v is undefined
    if v is @global
      r.push k
      r.push addObj(@wrapGlobal null)
      return
    if @isGlobal k, v
      r.push k
      r.push addObj(@wrapGlobal k)
      return
    r.push k
    r.push(rec v, k)
isGlobal:
  (k, v)@>
    v is @global[k] # or v is @nodejsModules[k] or (@coreNodejsModules[k] and v is @require(k))
toJsonUnstable:
  (x, options)@>
    normalizeRefcoffee = (s)@>
      ind = ""
      ni = ind + "  "
      if /\n/.test s
            lines = s.split "\n"
            if lines.length > 1
              if (mn = lines[1].match(/^[ \t]+/))?
                mn = mn[0].length
                id = mn - ni.length
                if id > 0
                  x = new @RegExp("[ \\t]{#{id}}")
                  lines = (line.replace x, "" for line in lines)
                else if id < 0
                  ni = @Array(-id + 1).join(" ")
                  lines = (ni + line for line in lines)                
            lines.join "\n"
      else
            s
    customExport = null
    if options?
      { customExport } = options
    wrapCopyOld = (copy, orig)@>
      getPath = (par)@>
        l = []
        while par?
          l.push par.idx
          par = par.par
        return l.reverse()
      orig = getPath orig
      copy = getPath copy
      while orig.length and copy.length and orig[0] is copy[0]
        orig.shift()
        copy.shift()
      { t: "y", d: [ copy.length, orig ] }
    objs = [ ]
    wrapCopy = (orig)->
      d = objs.length - 1 - orig.pos
      # if d < 0
      #  throw "something is wrong here"
      { t: "r", d: d }
    handleType = null
    toJson = (x, par = null)->
      rec = (xx, idx)-> toJson xx, { x, idx, par }
      objs.push x
      t = typeof x
      return h x, rec, par if (h = handleType[t])?
      @wrapUnknown x, t, rec, par
    vis = [ ]
    vid = 'dynmodJsonId' # visit token for detecting copies of objects
    detectDup = (x, par)->
      if (orig = x[vid])?
        wr = wrapCopy orig
        orig.pos = objs.length
        return wr
        # return wrapCopy par, orig.par
      else
        vis.push(x[vid] = { par, x, pos: objs.length })
        return
    strings = { }
    detectStringDup = (x, par)->
      if (orig = strings[x])?
        wr = wrapCopy orig
        orig.pos = objs.length
        return wr
        # return wrapCopy par, orig.par
      else
        strings[x] = { par, x, pos: objs.length }
        return
    coffees = { }
    detectCoffeeDup = (x, par)->
      coffee = x.coffee
      if (orig = coffees[coffee])?
        wr = wrapCopy orig
        orig.pos = objs.length
        return wr
        # return wrapCopy par, orig.par
      else
        coffees[coffee] = { par, x, pos: objs.length }
        return
    handleType =
        "undefined": => @wrapUndef()
        "boolean":   (x)=> @wrapBoolean x
        "string":    (x, rec, par)=>
          return dup if (dup = detectStringDup x, par)?
          @wrapString x
        "number":    (x)=> @wrapNumber x
        "function":  (x, rec, par)=>
          if (x.coffee)?
            x.coffee = normalizeRefcoffee x.coffee
            return dup if (dup = detectCoffeeDup x, par)?            
            @wrapFunction x
          else
            return dup if (dup = detectDup x, par)?
            @wrapNativeFunction x
        "object":    (x, rec, par)=>
          if x is null
            return @wrapNull()
          return dup if (dup = detectDup x, par)?
          return exp if (exp = customExport?(x, rec, par))?
          if @Array.isArray x
            i = 0
            @wrapArray (rec xx, i++ for xx in x)
          else
            r = [ ]
            addObj = (x)-> objs.push x; x
            if (keyOrder = x.keyOrder)?
              for kk in keyOrder
                vv = x[kk]
                try
                  @handlePair kk, vv, x, r, rec, addObj
                catch error
                  error = "While processing value of key #{kk}: #{error}"
                  throw error.replace(/: While processing value of key /g, ".")
            else
              for kk, vv of x
                continue if kk is vid
                try
                  @handlePair kk, vv, x, r, rec, addObj
                catch error
                  error = "While processing value of key #{kk}: #{error}"
                  throw error.replace(/: While processing value of key /g, ".")
            @wrapHash r
    r = toJson x
    delete xx.x[vid] for xx in vis # Remove visit tokens
    r
JsDigraph:
  dynmodPackageRegister.load 'JsDigraph'
DynmodPrinter:
  dynmodPackageRegister.load 'DynmodPrinter'
DynmodCore:
  dynmodPackageRegister.load 'DynmodCore'
toJson:
  (x, options)@>
    dx = (a, rx)->
      for k of a
        delete a[k] if rx.test k
      a
  
    dnx = (a, rx)->
      for k of a
        delete a[k] unless rx.test k
      a
    checksum = (x)=>
      custom = (x, depth)@>
        if x? and (depth > 0) and (typeof x is "object") and x.pkgInfo?.version?
          return 0x39053
        return null
      @JsDigraph.checksumGeometry(x, { custom })
    DebugPrinter = @DynmodCore.dynmod.modMixin.call { symbolicPackages: false }, @DynmodPrinter
    print = (x)=> DebugPrinter.print(x) + "\n"
    h1 = checksum x
    r = @toJsonUnstable x, options
    unless h1 is checksum(@fromJson(r, options))
      throw "Conversion to JSON introduced a data geometry error"
    r
toJsonNoCopies:
  (x)@>
    handleType = null
    toJson = (x)->
      t = typeof x
      return h x if (h = handleType[t])?
      @wrapUnknown x, t
    handleType =
        "undefined": => @wrapUndef()
        "boolean":   (x)=> @wrapBoolean x
        "string":    (x)=> @wrapString x
        "number":    (x)=> @wrapNumber x
        "function":  (x)=>
          if x.coffee?
            @wrapFunction x
          else
            @wrapNativeFunction x
        "object":    (x)=>
          if x is null
            return @wrapNull()
          if @Array.isArray x
            i = 0
            @wrapArray (toJson xx, i++ for xx in x)
          else
            r = { }
            for kk, vv of x
              @handlePair kk, vv, x, r, toJson, ((x)->x)
            @wrapHash r
    toJson x
wrapArray:
  (d)@> { t: "a", d }
wrapBoolean:
  (x)@> @wrapConstant x
wrapConstant:
  (d)@> { t: "c", d }
wrapFunction:
  (x)@> { t: "f", d: x.coffee }
wrapGlobal:
  (d)@> { t: "g", d }
wrapHash:
  (d)@> { t: "H", d }
wrapNativeFunction:
  (x)@>
    throw "Native function can not be exported!"
wrapNull:
  @> @wrapConstant null
wrapNumber:
  (x)@> @wrapConstant x
wrapString:
  (x)@> @wrapConstant x
wrapUndef:
  @> @wrapConstant undefined
wrapUnknown:
  (x, t)@>
    throw "Unsupported object of type #{t}"
  # coreNodejsModules: do@>
  #   l = "fs buffer child_process cluster crypto dgram dns events fs http https net os path punycode querystring readline repl string_decoder tls tty url util vm zlib"
  #   r = { }
  #   r[l] = 1 for x in l
  #   r
  # nodejsModules: { }
  # console: console
  # update: (x)@>
  #   r = { }
  #   for k,v of @require.cache
  #     n = k.replace(/.*\//, "").replace(/\..*/, "")
  #     @console.log "Adding module #{n}"
  #     r[n] = v
  #   @nodejsModules = r
pkgIncluded:
  DynmodPackage:
    dynmodPackageRegister.load 'DynmodPackage'
