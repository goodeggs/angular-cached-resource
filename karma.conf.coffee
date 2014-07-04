module.exports = (config) ->

  config.set
    frameworks: [
      'mocha'
      'sinon-chai'
    ]

    files: [
      'bower_components/angular/angular.js'
      'bower_components/angular-mocks/angular-mocks.js'
      'bower_components/angular-resource/angular-resource.js'

      'angular-cached-resource.js'

      'test/*.test.coffee'
    ]

    browsers: [
      'PhantomJS'
    ]

    preprocessors:
      '**/*.coffee': ['coffee']
