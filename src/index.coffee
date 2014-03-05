app = angular.module 'cached-resource', []

app.service 'cachedResource', ($q) ->

  (resource) ->
    cachedResource = {}
    if resource.get?
      cachedResource.get = (parameters, success, error) ->
        deferred = $q.deffered()
        if online
          resource.get parameters, (route) ->
            #add to cache
            deferred.resolve(route)
        else
          deferred.resolve(fromCache)

        deferred.$promise

app
