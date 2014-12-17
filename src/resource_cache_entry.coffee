module.exports = (providerParams) ->
  {$log} = providerParams
  Cache = require('./cache')(providerParams)

  class ResourceCacheEntry
    defaultValue: {}
    cacheKeyPrefix: -> @key

    fullCacheKey: ->
      @cacheKeyPrefix() + @cacheKeyParams

    constructor: (@key, params) ->
      paramKeys = if angular.isObject(params) then Object.keys(params).sort() else []
      if paramKeys.length
        @cacheKeyParams = '?' + ("#{param}=#{params[param]}" for param in paramKeys).join('&')
      else
        @cacheKeyParams = ''

    load: ->
      {@value, @dirty} = Cache.getItem(@fullCacheKey(), @defaultValue)
      @

    set: (@value, dirty) ->
      @dirty = dirty
      @_update()

    _update: ->
      Cache.setItem @fullCacheKey(), {@value, @dirty}
