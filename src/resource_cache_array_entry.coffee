module.exports = (log) ->
  ResourceCacheEntry = require('./resource_cache_entry')(log)

  class ResourceCacheArrayEntry extends ResourceCacheEntry
    defaultValue: []

    setKey: (key) -> @key = "#{key}/array"
