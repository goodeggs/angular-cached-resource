CACHE_RETRY_TIMEOUT = 60000 # one minute

ResourceCacheEntry = require './resource_cache_entry'
Cache = require './cache'

class ResourceWriteQueue
  constructor: (@CachedResource, @$timeout) ->
    @key = "#{@CachedResource.$key}/write"
    @queue = Cache.getItem(@key, [])

  enqueue: (params, action, deferred) ->
    entry = @findEntry {params, action}
    if not entry?
      @queue.push {params, action, deferred}
      @_update()
    else
      entry.deferred?.promise.then (response) ->
        deferred.resolve response
      entry.deferred?.promise.catch (error) ->
        deferred.reject error

  findEntry: ({action, params}) ->
    for entry in @queue
      return entry if action is entry.action and angular.equals(params, entry.params)

  removeEntry: ({action, params}) ->
    newQueue = []
    for entry in @queue
      newQueue.push entry unless action is entry.action and angular.equals(params, entry.params)
    @queue = newQueue

    if @queue.length is 0 and @timeoutPromise
      @$timeout.cancel @timeoutPromise
      delete @timeoutPromise

    @_update()

  flush: ->
    @_setFlushTimeout()
    @_processEntry(entry) for entry in @queue

  processResource: (params, done) ->
    notDone = true
    for entry in @_entriesForResource(params)
      @_processEntry entry, =>
        if notDone and @_entriesForResource(params).length is 0
          notDone = false
          done()

  _entriesForResource: (params) ->
    entry for entry in @queue when angular.equals(params, entry.params)

  _processEntry: (entry, done) ->
    cacheEntry = new ResourceCacheEntry(@CachedResource.$key, entry.params)
    onSuccess = (value) =>
      @removeEntry entry
      cacheEntry.setClean()
      entry.deferred?.resolve value
      done() if angular.isFunction(done)
    onFailure = (error) =>
      entry.deferred?.reject error
    @CachedResource.$resource[entry.action](entry.params, cacheEntry.value, onSuccess, onFailure)

  _setFlushTimeout: ->
    if @queue.length > 0 and not @timeoutPromise
      @timeoutPromise = @$timeout angular.bind(@, @flush), CACHE_RETRY_TIMEOUT
      @timeoutPromise.then =>
        delete @timeoutPromise
        @_setFlushTimeout()

  _update: ->
    savableQueue = @queue.map (entry) ->
      params: entry.params
      action: entry.action
    Cache.setItem @key, savableQueue

module.exports = ResourceWriteQueue
