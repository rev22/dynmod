pkgInfo:
  version: "DynmodPrinter 0.2.6"
  description: "Generic printer, for data and reflective code"
  copyright: "Copyright (c) 2014 Michele Bini"
  license: "MIT"
pkgIncluded:
  DynmodPackage:
    dynmodArchive.load 'DynmodPackage'
Array: Array
RegExp: RegExp
columns:
  74
console: console
global: global
symbolicPackages: true
print:
  (x, prev, depth = 0, ind = "")@>
    p = arguments.callee
    depth = depth + 1
    print = (y)=> p.call @, y, { prev, x }, depth
    clean = (x)->
      if /^[(]([(@][^\n]*)[)]$/.test x
        x.substring(1, x.length - 1)
      else
        x
    if x == null
      ind + "null"
    else if x == @global
      ind + "global"
    else if x == undefined
      ind + "undefined"
    else
      t = typeof x
      if t is "boolean"
        ind + if x then "true" else "false"
      else if t is "number"
        ind + @printNumber x
      else if t is "string"
        if x.length > 8 and /\n/.test x
          l = x.split("\n")
          l = (x.replace /\"\"\"/g, '\"\"\"' for x in l)
          l.unshift ind + '"""'
          l.push     ind + '"""'
          l.join(ind + "\n")
        else
          ind + '"' + x.replace(/\"/g, "\\\"") + '"'
      else if t is "function"
        ni = ind + "  "
        if x.coffee?
          # YAY a reflective function!!!
          s = x.coffee
          if depth is 1 or /\n/.test s
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
            ind + "(" + s + ")"
        else
          ind + x.toString().replace(/\n/g, '\n' + ni)
      else if (c = (do (p = prev, c = 1)-> (return c if p.x == x; p = p.prev; c++) while p?; 0))
        # Report cyclic structures
        "<cycle-#{c}+#{depth - c - 1}>"
      else if t isnt "object"
        # print object of odd type
        "<#{t}>"
      else if @Array.isArray x
        if x.length is 0
          "[ ]"
        else
          cl = 2
          hasLines = false
          xxxx = for xx in x
            xx = print xx
            hasLines = true if /\n/.test xx
            cl += 2 + xx.length
            xx
          if not hasLines and depth * 2 + cl + 1 < @columns
            "[ " + xxxx.join(", ") + " ]"
          else
            ni = ind + "  "
            l = [ ind + "[" ]
            for xx in xxxx
              l.push ni + clean(xx).replace(/\n/g, '\n' + ni)
            l.push ind + "]"
            l.join "\n"
      else
        l = [ ]
        if @symbolicPackages and depth > 1 and (packageVersion = x.pkgInfo?.version)?
          return ind + "dynmodArchive.load '" + packageVersion.replace(/\ .*/, "") + "'"
        ind = ""
        unless (!prev? or typeof prev.x is "object" and !@Array.isArray prev.x)
          l = [ "do->" ]
          ind = "  "
        ni = ind + "  "
        # keys = (h)@> (x for x of h).sort()
        for k,v of x
          # v = x[k]
          if @global[k] is v
            # l.push ind + k + ": eval " + "'" + k + "'"
            l.push ind + k + ": global." + k
          else
            v = clean(print v).replace(/\n/g, '\n' + ni)
            if !/\n/.test(v) and  ind.length + k.toString().length + 2 + v.length < @columns
              l.push ind + k + ": " + v
            else
              l.push ind + k + ":"
              l.push ni + v
        if l.length
          l.join "\n"
        else
          "{ }"
printNumber:
  (x)@> "#{x}"
