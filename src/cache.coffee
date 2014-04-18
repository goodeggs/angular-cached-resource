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
