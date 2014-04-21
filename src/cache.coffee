LOCAL_STORAGE_PREFIX = 'cachedResource://'
{localStorage} = window

memoryCache = {}
buildKey = (key) ->
  "#{LOCAL_STORAGE_PREFIX}#{key}"

module.exports =
  getItem: (key, fallbackValue) ->
    key = buildKey key

    item = memoryCache[key]
    item ?= localStorage.getItem key

    if item? then angular.fromJson(item) else fallbackValue

  setItem: (key, value) ->
    key = buildKey key
    stringValue = angular.toJson value

    try
      localStorage.setItem(key, stringValue)
      delete memoryCache[key] if memoryCache[key]?
    catch
      memoryCache[key] = stringValue

    value

  clear: (key) ->
    key = buildKey(key)
    cacheKeys = [0...localStorage.length].map (i) -> localStorage.key(i)
    localStorage.removeItem cacheKey for cacheKey in cacheKeys when cacheKey.indexOf(key) is 0

  clearAll: ({exceptFor} = {}) ->
    exceptFor ?= []
    exceptFor = exceptFor.map buildKey

    keys = []
    for i in [0...localStorage.length]
      key = localStorage.key i
      continue unless key.indexOf(LOCAL_STORAGE_PREFIX) is 0

      skipKey = no
      for exception in exceptFor when key.indexOf(exception) is 0
        skipKey = yes
        break
      continue if skipKey

      keys.push key

    localStorage.removeItem(key) for key in keys
