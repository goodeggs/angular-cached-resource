LOCAL_STORAGE_PREFIX = 'cachedResource://'
{localStorage} = window

memoryCache = {}

buildKey = (key) ->
  "#{LOCAL_STORAGE_PREFIX}#{key}"

cacheKeyHasPrefix = (cacheKey, prefix) ->
  return cacheKey.indexOf(LOCAL_STORAGE_PREFIX) is 0 unless prefix?
  prefix = buildKey prefix
  index = cacheKey.indexOf prefix
  nextChar = cacheKey[prefix.length]
  index is 0 and (not nextChar? or nextChar in ['?', '/'])

module.exports = (log) ->
  getItem: (key, fallbackValue) ->
    key = buildKey key

    item = memoryCache[key]
    item ?= localStorage.getItem key

    out = if item? then angular.fromJson(item) else fallbackValue
    log.debug "CACHE GET: #{key}", out

    out

  setItem: (key, value) ->
    key = buildKey key
    stringValue = angular.toJson value

    try
      localStorage.setItem(key, stringValue)
      delete memoryCache[key] if memoryCache[key]?
    catch
      memoryCache[key] = stringValue

    log.debug "CACHE PUT: #{key}", angular.fromJson angular.toJson value

    value

  clear: ({key, exceptFor, where} = {}) ->
    return log.error "Using where and exceptFor arguments at once in clear() method is forbidden!" if where && exceptFor

    if exceptFor
      exceptFor ?= []

      cacheKeys = []
      for i in [0...localStorage.length]
        cacheKey = localStorage.key i
        continue unless cacheKeyHasPrefix(cacheKey, key)

        skipKey = no
        for exception in exceptFor when cacheKeyHasPrefix(cacheKey, exception)
          skipKey = yes
          break

        continue if skipKey

        cacheKeys.push cacheKey

      localStorage.removeItem(cacheKey) for cacheKey in cacheKeys
    else
      for cacheKey in where
        localStorage.removeItem(LOCAL_STORAGE_PREFIX + cacheKey)
