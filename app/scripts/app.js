'use strict';

angular.module('angularCachedResourceApp', [
  'ngResource',
  'ui.router'
], function($stateProvider, $urlRouterProvider) {

  $urlRouterProvider.otherwise("/");

  $stateProvider.state("main", {
    abstract: true,
    templateUrl: "views/main.html",
    controller: "MainCtrl"
  });

  $stateProvider.state("home", {
    parent: "main",
    url: "/",
    templateUrl: "views/home.html"
  });

  $stateProvider.state("colophon", {
    parent: "main",
    url: "/colophon",
    templateUrl: "views/colophon.html"
  });

});
