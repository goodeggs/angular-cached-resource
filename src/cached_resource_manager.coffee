module.exports = (debug) ->
  ResourceWriteQueue = require('./resource_write_queue')(debug)
  cache = require('./cache')(debug)

  class CachedResourceManager
    constructor: (@$timeout) ->
      @byKey = {}

    keys: ->
      Object.keys @byKey

    add: (CachedResource) ->
      queue = new ResourceWriteQueue(CachedResource, @$timeout)
      @byKey[CachedResource.$key] = {resource: CachedResource, queue}

    getQueue: (CachedResource) ->
      @byKey[CachedResource.$key].queue

    flushQueues: ->
      queue.flush() for key, {queue} of @byKey

    clearAll: ({exceptFor, clearPendingWrites} = {}) ->
      exceptFor ?= []
      resource.$clearAll({clearPendingWrites}) for key, {resource} of @byKey when key not in exceptFor

    clearUndefined: ->
      cache.clear exceptFor: @keys()
