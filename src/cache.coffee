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

  clear: ({key, exceptFor} = {}) ->
    key ?= ''
    key = buildKey key

    exceptFor ?= []
    exceptFor = exceptFor.map buildKey

    cacheKeys = []
    for i in [0...localStorage.length]
      cacheKey = localStorage.key i
      continue unless cacheKey.indexOf(key) is 0

      skipKey = no
      for exception in exceptFor when cacheKey.indexOf(exception) is 0
        skipKey = yes
        break

      continue if skipKey

      cacheKeys.push cacheKey

    localStorage.removeItem(cacheKey) for cacheKey in cacheKeys
