LOCAL_STORAGE_PREFIX = 'cachedResource://'

module.exports = if window.localStorage?

  getItem: (key, fallback) ->
    item = localStorage.getItem("#{LOCAL_STORAGE_PREFIX}#{key}")
    if item? then angular.fromJson(item) else fallback

  setItem: (key, value) ->
    localStorage.setItem("#{LOCAL_STORAGE_PREFIX}#{key}", angular.toJson value)
    value

else

  getItem: (key, fallback) -> 
    fallback
    
  setItem: (key, value) -> 
    value

