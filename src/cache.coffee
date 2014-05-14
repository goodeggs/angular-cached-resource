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

module.exports =
  getItem: (key, fallbackValue) ->
    key = buildKey key

    item = memoryCache[key]
    item ?= localStorage.getItem key

    out = if item? then angular.fromJson(item) else fallbackValue
    # console.log 'get', key, out
    out

  setItem: (key, value) ->
    # console.log 'set', key, angular.toJson(value)
    key = buildKey key
    stringValue = angular.toJson value

    try
      localStorage.setItem(key, stringValue)
      delete memoryCache[key] if memoryCache[key]?
    catch
      memoryCache[key] = stringValue

    value

  clear: ({key, exceptFor} = {}) ->
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
