{localStorage} = window

class Cache
  memoryCache: {}

  constructor: ({@$log, @localStoragePrefix}) ->

  getItem: (key, fallbackValue) ->
    key = @_buildKey key

    item = @memoryCache[key]
    item ?= localStorage.getItem key

    out = if item? then angular.fromJson(item) else fallbackValue
    @$log.debug "CACHE GET: #{key}", out

    out

  setItem: (key, value) ->
    key = @_buildKey key
    stringValue = angular.toJson value

    try
      localStorage.setItem(key, stringValue)
      delete @memoryCache[key] if @memoryCache[key]?
    catch e
      @$log.error "Failed to write to localStorage.", {error: e, key, value: stringValue}
      @memoryCache[key] = stringValue

    @$log.debug "CACHE PUT: #{key}", angular.fromJson angular.toJson value

    value

  clear: ({key, exceptFor, where} = {}) ->
    return @$log.error "Using where and exceptFor arguments at once in clear() method is forbidden!" if where && exceptFor

    if exceptFor
      exceptFor ?= []

      cacheKeys = []
      for i in [0...localStorage.length]
        cacheKey = localStorage.key i
        continue unless @_cacheKeyHasPrefix(cacheKey, key)

        skipKey = no
        for exception in exceptFor when @_cacheKeyHasPrefix(cacheKey, exception)
          skipKey = yes
          break

        continue if skipKey
        cacheKeys.push cacheKey

      localStorage.removeItem(cacheKey) for cacheKey in cacheKeys
    else
      for cacheKey in where
        localStorage.removeItem @_buildKey cacheKey

  _buildKey: (key) ->
    "#{@localStoragePrefix}#{key}"

  _cacheKeyHasPrefix: (cacheKey, prefix) ->
    return cacheKey.indexOf(@localStoragePrefix) is 0 unless prefix?
    prefix = @_buildKey prefix
    index = cacheKey.indexOf prefix
    nextChar = cacheKey[prefix.length]
    index is 0 and (not nextChar? or nextChar in ['?', '/'])


module.exports = (providerParams) ->
  new Cache(providerParams)
