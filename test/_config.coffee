# This file is ran before every *.test.coffee .
beforeEach ->
  localStorage.clear() # TODO this should not be actually necessary
  module('ngCachedResource')

afterEach ->
  inject ($httpBackend) ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
  localStorage.clear()
