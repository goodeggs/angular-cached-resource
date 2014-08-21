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
      if @dirty and !dirty
        $log.error "unexpectedly setting a clean entry (load) over a dirty entry (pending write)"
      @dirty = dirty
      @_update()

    setClean: ->
      @dirty = false
      @_update()

    _update: ->
      Cache.setItem @fullCacheKey(), {@value, @dirty}
