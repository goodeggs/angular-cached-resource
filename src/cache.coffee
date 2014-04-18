LOCAL_STORAGE_PREFIX = 'cachedResource://'

{localStorage} = window

module.exports = if localStorage?

  getItem: (key, fallback) ->
    item = localStorage.getItem("#{LOCAL_STORAGE_PREFIX}#{key}")
    if item? then angular.fromJson(item) else fallback

  setItem: (key, value) ->
    try
      localStorage.setItem("#{LOCAL_STORAGE_PREFIX}#{key}", angular.toJson value)
    catch
      # ignore failed write, for now
    value

else

  getItem: (key, fallback) ->
    fallback

  setItem: (key, value) ->
    value

