pkgInfo:
  description: "Basic methods for packages"
  version: "DynmodPackage 0.4.2"
  copyright: "Copyright (c) 2014, Michele Bini"
  license: "MIT"
Date: Date
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
  # this is useful for coverting modules into mixins
modRecompile:
  @>
    return @ unless @pkgInfo?
    return @ if @pkgInfo.dist?
    return @pkgAmend() if @pkgAmend?
    @
pkgRecompile:
  (options)@>
    target = options?.target ? @
    return target unless target.pkgInfo?
    return target if target.pkgInfo.dist?
    target = @pkgAmend { target }
    target
modRegress:
  @>
    o = { }
    o[n] = v for n,v of @
    ((delete o[k] if o[k] == x) for k,x of fields) for fields in arguments
    o
modStrip:
  @>
    o = { }
    o[n] = v for n,v of @
    (delete o[k] for k,x of fields) for fields in arguments
    o
  # this can be thought of as reversing modExtend:
  #   b.modExtend(b.modExtend(a).modStrip(b)) is b.modExtend(a)
  # also can be useful for converting modules into traits
pkgAmend:
  (options)@>
    target = options?.target ? @
    { pkgInfo } = target
    pkgInfo  = @modStrip.call pkgInfo, dist: 1, lineage: 1
    dist     = @modMixin.call { pkgInfo }, (@pkgUndoInclusions { target })
    pkgInfo  = @modMixin.call { dist }, target.pkgInfo
    @modMixin.call { pkgInfo }, target
pkgRevert:
  (options)@>
    target = options?.target ? @
    noInclusions = options?.noInclusions
    { pkgInfo } = target
    { dist } = pkgInfo
    unless dist?
      throw "Package has no pristine state recorded"
    pkgInfo = @modMixin.call (dist.pkgInfo ? { }), pkgInfo
    target = @modMixin.call { pkgInfo }, dist
    unless noInclusions
      target = @pkgRedoInclusions { target }
    target
pkgArchive:
  (options)@>
    # Convert package into the form found in pkgInfo.lineage.parents
    # 
    # pkgInfo:
    #   version: *
    #   dist:
    #     pkgInfo:
    #       version: OV
    #       OI
    #     OD
    #   lineage:
    #     message: OM
    #     *
    #   *
    # *
    # 
    # into:
    # 
    #  pkgInfo:
    #    version: OV
    #    lineage:
    #      message: OM
    #      OL
    #    OI
    #  OD
    #
    target = options?.target ? @
    pristine = @pkgGetPristine { target }
    # undo-inclusions here may be redundant as we already do that when creating pkgInfo.dist
    @pkgUndoInclusions
      target:
        if (lineage = target.pkgInfo?.lineage)?
          { pkgInfo } = pristine
          pkgInfo = @modMixin.call { lineage }, pkgInfo
          @modMixin.call { pkgInfo }, pristine
        else
          pristine
pkgCommit:
  (message, options)@>
    #
    # Rougly, convert:
    # 
    # pkgInfo:
    #   version: NV
    #   dist:
    #     pkgInfo:
    #       version: OV
    #       OI
    #     OD
    #   lineage:
    #     message: OM
    #     OL
    #   NI
    # ND
    # 
    # into:
    # 
    # pkgInfo:
    #   version: NV
    #   dist:
    #     pkgInfo:
    #       version: NV
    #       NI
    #     ND
    #   lineage:
    #     message: message
    #     parent:
    #       pkgInfo:
    #         version: OV
    #         lineage:
    #           message: OM
    #           OL
    #         OI
    #       OD
    #     OL
    #   NI
    # ND
    #
    target = @
    target = t if (t = options?.target)?
    throw "package to commit has no pkgInfo meta data" unless target.pkgInfo?
    pkgName = @pkgGetName { target }
    try
      @pkgTest { target } or throw "'test' method returned false"
    catch error
      throw "Test for #{pkgName} failed: #{error}"
    if !target.pkgInfo.lineage?
      # First commit!
      parents = [ ]
    else
      parent = @pkgArchive { target }
      newVersion = target?.pkgInfo?.version
      oldVersion = parent?.pkgInfo?.version
      if oldVersion is newVersion
        throw "Please set a new version before committing.  Current: #{newVersion}"
      parents = [ parent ]
    lineage = { message, parents, date: (new @Date).toISOString() }
    { pkgInfo } = target
    pkgInfo = @modStrip.call pkgInfo, dist: 1
    pkgInfo = @modMixin.call { lineage }, pkgInfo
    @pkgAmend target: (@modMixin.call { pkgInfo }, target)
pkgFork:
  (name, options)@>
    target = options?.target ? @
    x = @modExtend.call target
      pkgInfo:
        version: do->
          if /\ /.test(name)
            name
          else
            "#{name} 0.0.0"
        lineage:
          message: "#forked"
          parents: [ @ ]
    x.pkgAmend()
pkgGetName:
  (options)@>
    target = options?.target ? @
    target.pkgInfo.version.replace(/\ .*/, "")
pkgGetPristine:
  (options)@>
    target = options?.target ? @
    return target unless target.pkgInfo.dist?
    target.pkgInfo.dist
pkgGetMembers:
  (options)@>
    target = options?.target ? @
    @modStrip.call target, pkgInfo: 1, pkgDefinitions: 1, pkgInclusions: 1, pkgIncluded: 1
pkgSave:
  (register, options)@>
    target = options?.target ? @
    register.save target
pkgInclude:
  (pkg, options)@>
    target = options?.target ? @
    members = @pkgGetMembers { target: pkg }
    name = @pkgGetName { target: pkg } # Get name; FIXME: should include major version here
    @modMixin.call target, members,
      pkgDefinitions: do=>
        definitions = target.pkgDefinitions ? @pkgGetMembers { target }
        definitions
      pkgInclusions: do=>
        inclusions = target.pkgInclusions ? { }
        @modMixin.call inclusions, members
      pkgIncluded: do=>
        included = target.pkgIncluded ? { }
        included[name] = pkg
        included
pkgExclude:
  (pkg, options)@>
    target = options?.target ? @
    throw "unimplemented"
    members = @pkgGetMembers { target: pkg }
    name = @pkgGetName { target } # Get name; FIXME: should include major version here
    target = @modStrip.call target, members
    x =
      pkgIncluded: do->
        # included
    @modMixin.call(x, target)
pkgUndoInclusions:
  (options)@>
    target = options?.target ? @
    if (inclusions = target.pkgInclusions)?
      target = @modRegress.call target, inclusions
      @modStrip.call target, pkgInclusions: 1, pkgDefinitions: 1
    else
      target
pkgRedoInclusions:
  (options)@>
    target = options?.target ? @
    if (included = target.pkgIncluded)?
      for k,v of included
        target = @pkgInclude v, { target }
    target
pkgTest:
  (options)@>
    # Perform package self-checks
    target = options?.target ? @
    if (test = target.pkgInfo.test)?
      test.call target
