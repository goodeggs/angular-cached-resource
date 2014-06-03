module.exports = (debug) ->
  ResourceCacheEntry = require('./resource_cache_entry')(debug)

  class ResourceCacheArrayEntry extends ResourceCacheEntry
    defaultValue: []

    setKey: (key) -> @key = "#{key}/array"
