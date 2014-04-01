ResourceWriteQueue = require './resource_write_queue'

class CachedResourceManager
  constructor: (@$timeout) ->
    @queuesByKey = {}

  add: (CachedResource) ->
    @queuesByKey[CachedResource.$key] = new ResourceWriteQueue(CachedResource, @$timeout)

  getQueue: (CachedResource) ->
    @queuesByKey[CachedResource.$key]

  flushQueues: ->
    queue.flush() for key, queue of @queuesByKey

module.exports = CachedResourceManager
