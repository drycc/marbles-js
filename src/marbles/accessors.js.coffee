Marbles.Accessors = {
  set: (keypath, v, options={}) ->
    return unless keypath && keypath.length
    if !options.hasOwnProperty('keypath') || options.keypath
      keys = keypath.split('.')
    else
      keys = [keypath]
    last_key = keys.pop()

    obj = @
    for k in keys
      obj[k] ?= {}
      obj = obj[k]

    old_v = obj[last_key]
    obj[last_key] = v
    @trigger("change:#{keypath}", v, old_v, keypath) unless v == old_v
    v

  get: (keypath, options={}) ->
    return unless keypath && keypath.length
    if !options.hasOwnProperty('keypath') || options.keypath
      keys = keypath.split('.')
    else
      keys = [keypath]
    last_key = keys.pop()

    obj = @
    for k in keys
      obj = obj[k]
      return unless obj

    obj[last_key]
}
