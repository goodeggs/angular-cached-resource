Cache = require './cache'

class ResourceCacheEntry
  defaultValue: {}

  constructor: (resourceKey, params) ->
    @setKey(resourceKey)
    
    paramKeys = if angular.isObject(params) then Object.keys(params).sort() else []
    if paramKeys.length
      @key += '?' + ("#{param}=#{params[param]}" for param in paramKeys).join('&')

    {@value, @dirty} = Cache.getItem(@key, @defaultValue)

  setKey: (@key) ->

  set: (@value, @dirty) ->
    @_update()

  setClean: ->
    @dirty = false
    @_update()

  _update: ->
    Cache.setItem @key, {@value, @dirty}

module.exports = ResourceCacheEntry
