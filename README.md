ngCachedResource [![NPM version][npm-badge]][npm-link]  [![Build Status][travis-badge]][travis-link]
==============

An [AngularJS][angular] module to interact with RESTful server-side data sources, even
when the browser is offline. Uses HTML5 [localStorage][localStorage] under the hood.
Closely mimics the behavior of the core [ngResource][ngResource] module, which it requires
as a dependency.

## A simple example

```javascript
var Article = $cachedResource('article', '/articles/:id', {id: "@id"});

// GET requests:
var firstArticle = Article.get({id: 1});
firstArticle.$promise.then(function() {
  // firstArticle came from localStorage, if it has been loaded before
});
firstArticle.$httpPromise.then(function() {
  // Even if firstArticle was loaded before, now it has been fully refreshed
  // and represents the response from the /articles/1 endpoint
});

// POST/PUT/DELETE requests:

// If this fails initially, possibly because of a bad connection, we will
// try sending it again
Article.save({id: 2}, {contents: "Lorem ipsum dolor..."}, function() {
  // Reaching this callback means it successfully saved.
});
```

-------

## Usage
Provides a factory called `$cachedResource` that returns a "CachedResource" object.

```js
$cachedResource(cacheKey, url, [paramDefaults], [actions]);
```

### Arguments

- **cacheKey**, `String`<br>
  An arbitrary key that will uniquely represent this resource in localStorage.
  When the resource is instanciated, it will check localStorage for any

- **url**, `String`<br>
  Exactly matches the API for the `url` param of the [$resource][ngResource]
  factory.

- **paramDefaults**, `Object`, _(optional)_<br>
  Exactly matches the API for the `paramDefaults` param of the [$resource][ngResource]
  factory.

- **actions**, `Object`, _optional_<br>
  Exactly matches the API for the `actions` param of the [$resource][ngResource]
  factory.

### Returns

A CachedResource "class" object. This object is basically a swap-in replacement for an
object created by the `$resource` factory with the following modified or additional
properties:

 - `Resource.$promise`: For GET requests, if anything was already in the cache, this
   promise is immediately resolved (still asynchronously!) even as the HTTP request
   continues.

 - `Resource.$httpPromise`: For all requests, this promise is resolved as soon as the
   corresponding HTTP request responds.

------

## Installing

**Bower:**

```bash
bower install angular-cached-resource
```

**npm:** (intended for use with [browserify](http://browserify.org/))

```bash
npm install angular-cached-resource
```

**Manual Download:**

- development: [angular-cached-resource.js](https://raw.githubusercontent.com/goodeggs/angular-cached-resource/master/angular-cached-resource.js)
- production: [angular-cached-resource.min.js](https://raw.githubusercontent.com/goodeggs/angular-cached-resource/master/angular-cached-resource.min.js)

---

## Details

Asking for a cached resource with `get` or `query` will do the following:

1. If the request has not been made previously, it will immediately return a `resource` object,
   just like usual. The request will go through to the server, and when the server responds, the
   resource will be saved in a localStorage cache.

2. If the request has already been made, it will immediately return a `resource` object that
   is pre-populated from the cache. The request will still attempt to go through to the server,
   and if the server responds, the cache entry will be updated.

Updating a CachedResource object will do the following:

1. Add the resource update action to a queue.
2. Immediately attempt to flush the queue by sending all the network requests in the queue.
3. If a queued network request succeeds, remove it from the queue and resolve the promises
   on the associated resources (only if the queue entry was made after the page was loaded)
4. If the queue contains requests, attempt to flush it once per minute OR whenever the browser
   sends a [navigator.onOnline][onOnline] event.

------

## Development

Please make sure you run the tests, and add to them unless it's a trivial change:
```
npm install
npm test
```

------

## License

[MIT](https://github.com/goodeggs/angular-cached-resource/blob/master/LICENSE.md)

[npm-badge]: https://badge.fury.io/js/angular-cached-resource.png
[npm-link]: http://badge.fury.io/js/angular-cached-resource

[travis-badge]: https://travis-ci.org/goodeggs/angular-cached-resource.png
[travis-link]: https://travis-ci.org/goodeggs/angular-cached-resource

[angular]: http://angularjs.org/
[ngResource]: http://docs.angularjs.org/api/ngResource/service/$resource
[localStorage]: http://www.w3.org/TR/webstorage/#the-localstorage-attribute
[onOnline]: https://developer.mozilla.org/en-US/docs/Web/API/NavigatorOnLine.onLine
