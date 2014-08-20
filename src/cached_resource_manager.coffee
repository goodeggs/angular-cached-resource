module.exports = (log) ->
  buildCachedResourceClass = require('./build_cached_resource_class')
  Cache = require('./cache')(log)

  class CachedResourceManager
    constructor: ($resource, $timeout, $q) ->
      @byKey = {}
      @build = angular.bind(@, buildCachedResourceClass, $resource, $timeout, $q, log)

    keys: ->
      Object.keys @byKey

    add: ->
      args = Array::slice.call arguments
      CachedResource = @build(args)

      @byKey[CachedResource.$key] = CachedResource
      CachedResource.$writes.flush()

      CachedResource

    flushQueues: ->
      CachedResource.$writes.flush() for key, CachedResource of @byKey

    clearAll: ({exceptFor, clearPendingWrites} = {}) ->
      exceptFor ?= []
      for key, CachedResource of @byKey when key not in exceptFor
        CachedResource.$clearAll({clearPendingWrites})

    clearUndefined: ->
      Cache.clear exceptFor: @keys()
