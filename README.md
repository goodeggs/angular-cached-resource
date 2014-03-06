ng-cached-resource [![NPM version](https://badge.fury.io/js/ng-cached-resource.png)](http://badge.fury.io/js/ng-cached-resource) [![Build Status](https://travis-ci.org/goodeggs/ng-cached-resource.png)](https://travis-ci.org/goodeggs/ng-cached-resource)
==============

Work with [$resources](http://docs.angularjs.org/api/ngResource/service/$resource) offline
using [localStorage](http://www.w3.org/TR/webstorage/#the-localstorage-attribute)!

This module provides a service called `cacheResource` that will wrap arbitrary `$resource` objects.
Asking for a cached resource with `get` or `query` will do the following:

1. If the request has not been made previously, it will immediately return a `resource` object,
   just like usual. The request will go through to the server, and when the server responds, the
   resource will be saved in a localStorage cache.

2. If the request has already been made, it will immediately return a `resource` object that
   is pre-populated from the cache. The request will still attempt to go through to the server,
   and if the server responds, the cache entry will be updated.

Here's an example:

```javascript
var app = angular.module('example', ['ngResource', 'cachedResource']);

app.config(function($resource, cacheResource) {

  // create a resource object
  var userResource = cacheResource($resource('/api/user/:userId', {userId: '@id'}));

  // use it just like you would a regular resource, but now caching is enabled!
  var user = userResource.get({id: 203});

});
```
