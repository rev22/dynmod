pkgInfo:
  version: "JsDigraph 0.1.4"
  description: "Operate Javascript objects as directed graphs"
  copyright: "Copyright (c) 2014 Michele Bini"
  license: "MIT"
  test:
    @>
      x = [
        do@>
          x =
            a: 1
            b:
              c: 2
        do@>
          x =
            a: 1
            b:
              c: 2
          x.x = x
          x
        do@>
          x =
            a: 1
            b:
              c:
                cc: 2
          x.d = e: f: x
          x.d = e: f: b: x.b
          x.x = x
          x.c = x.b.c
          x
      ]
      x = x[2]
      # throw @global.JSON.stringify
      @toTree(x)
      # throw @global.JSON.stringify
      @toArray(x)
global: global
count:
  (x)@>
    { global } = @
    isArray = [].constructor.isArray
    count = 0
    vid = "setouhosetnote"
    vis = [ ]
    descend = (x)->
      count++
      if typeof x is "object"
        if !x? or x is @global
          return
        if (xx = x[vid])?
          count--
          return
        vis.push x
        x[vid] = 1
        if isArray x
          descend(xx) for xx in x
        else
          for k,v of x
            if k isnt vid
              descend(v)
    descend x
    delete xxx[vid] for xxx in vis
    count
toArray:
  (x)@>
    { global } = @
    isArray = [].constructor.isArray
    vid = "setouhosetnote"
    vis = [ ]
    descend = (x)->
      if typeof x is "object"
        if !x? or x is @global
          return
        if (xx = x[vid])?
          return
        vis.push x
        x[vid] = 1
        if isArray x
          descend(xx) for xx in x
        else
          for k,v of x
            if k isnt vid
              descend(v)
    descend x
    delete xxx[vid] for xxx in vis
    vis
toTree:
  (x)@>
    # Retain only the shortest paths to objects, breaking all loops and removing duplicate objects
    { global } = @
    isArray = [].constructor.isArray
    vid = "setouhosetnote"
    vis = [ ]
    descend = (x, depth, parent, key)->
      if typeof x is "object"
        if !x?
          return
        if x is @global
          parent[key] = null
          return
        if (xx = x[vid])?
          if depth < xx[0]
            xx[1][xx[2]] = null
            xx[0] = depth
            xx[1] = parent
            xx[2] = key
          else
            parent[key] = null
          return
        vis.push x
        x[vid] = [ depth, parent, key ]
        depth++
        for k,v of x
          if k isnt vid
            descend v, depth, x, k
    descend x, 0, null
    delete xxx[vid] for xxx in vis
    x
checksumGeometry:
  (x)@>
    prime = [ 3, 5, 7, 13, 23, 43, 83, 163, 317, 631, 1279, 2557 ]
    { global } = @
    isArray = [].constructor.isArray
    hash = 2
    vid = "otesinonet"
    vis = [ ]
    xormix = (h,d)-> (h ^ 0x37EA9A24) + d
    out = (i)-> hash = xormix(hash, i)
    descend = (x)->
      if typeof x is "object"
        return out prime[10] if x is global
        if !x?
          out prime[1]
          return
        if (xx = x[vid])?
          out prime[2]
          return
        vis.push x
        x[vid] = 1
        if isArray x
          out prime[3]
          descend xx for xx in x
        else
          out prime[4]
          for k,v of x
            descend k
            if k isnt vid
              descend v
      else if typeof x is "string"
        out (x.length + 1) * prime[5]
      else if typeof x is "number"
        out ((x*10)|0)+1 * prime[6]
      else if typeof x is "function"
        if (coffee = x.coffee)?
          coffee = coffee.replace(/[ \t\n]+/g, "")
          out (coffee.length + 1) * prime[7]
        else
          out prime[8]
      else
        out prime[9]
    descend(x)
    delete xxx[vid] for xxx in vis
    hash
