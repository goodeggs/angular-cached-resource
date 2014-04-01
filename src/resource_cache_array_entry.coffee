ResourceCacheEntry = require './resource_cache_entry'

class ResourceCacheArrayEntry extends ResourceCacheEntry
  defaultValue: []
  
  setKey: (key) -> @key = "#{key}/array"

module.exports = ResourceCacheArrayEntry

