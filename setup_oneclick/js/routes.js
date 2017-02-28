"use strict";
var app = angular.module('dashboardApp');

app.constant('AUTH_EVENTS', {
  loginSuccess: 'auth-login-success',
  loginFailed: 'auth-login-failed',
  logoutSuccess: 'auth-logout-success',
  sessionTimeout: 'auth-session-timeout',
  notAuthenticated: 'auth-not-authenticated',
  clearAllCaches: 'auth-clear-caches',
  notAuthorized: 'auth-not-authorized'
});

app.config(function ($routeProvider, $locationProvider, $httpProvider, $translateProvider) {
  //$httpProvider.responseInterceptors.push('httpInterceptor');
  $httpProvider.defaults.useXDomain = true;
  delete $httpProvider.defaults.headers.common['X-Requested-With'];
  $routeProvider
    .when('/login', {
        templateUrl: 'views/login.html',
        controller: 'LoginController'
    })
    .when('/',{
        templateUrl: 'views/default.html'
    })
    .when('/logout',{
        templateUrl: 'views/logout.html',
        controller: 'LogoutController'
    })
    .when('/404', {
    	templateUrl: 'views/404.html'	    
    })
    .when('/accounts/:customerId', {
        templateUrl: 'views/sub-account.html',
        controller: 'AccountDetailController'
    })
    .when('/accounts/:customerId/tenants', {
        templateUrl: 'views/tenant-edit.html',
        controller: 'AccountDetailController'
    })
    .when('/accounts/:customerId/tenants/:tenantId', {
        templateUrl: 'views/tenant-edit.html',
        controller: 'AccountDetailController'
    })
    .when('/bssapis', {
        templateUrl: 'views/bssapis.html',
        controller: 'BssApiController'
    })
    .when('/tenants',{
        templateUrl: 'views/tenants.html'
    })
    .when('/tenants/:tenantId',{
    	templateUrl: 'views/tenant-details.html',
    	controller: 'TenantController'
    })
    .when('/tenants/:tenantId/swift',{
    	templateUrl: 'views/tenant-swift.html',
    	controller: 'TenantController'
    })
    .when('/tenants/:tenantId/consumption',{
    	templateUrl: 'views/tenant-consumption.html',
    	controller: 'TenantController'
    })
    .when('/tenants/:tenantId/swift/:region/:container',{
    	templateUrl: 'views/tenant-swift-browse.html',
    	controller: 'SwiftController'
    })
    .when('/contact',{
    	templateUrl: 'views/contact.html'
    })
    .when('/heat',{
    	templateUrl: 'views/heat.html',
    	controller: 'HeatController'
    })
    .when('/heat/:stack',{
    	templateUrl: 'views/heat.html',
    	controller: 'HeatController'
    })
    .when('/docs',{
    	templateUrl: 'views/docs.html',
    	controller: 'BssApiController'
    })
    .when('/dashboard',{
        templateUrl: 'views/dashboard.html'
    }).otherwise({
    templateUrl: 'views/default.html',
        redirectTo: '404'
    });
    
  $translateProvider.useStaticFilesLoader({
    prefix: 'js/i18n/tr/locale-',
    suffix: '.json'
  });
  $translateProvider.registerAvailableLanguageKeys(['en', 'fr'], {
    'en_US': 'en',
    'en_UK': 'en',
    'fr_FR': 'fr',
    'fr_CH': 'fr',
    'fr_CA': 'fr',
    'fr_BE': 'fr'
  });
  $translateProvider.fallbackLanguage(['en']);
  
  $translateProvider.determinePreferredLanguage();
  $translateProvider.useSanitizeValueStrategy('escapeParameters');
  //$translateProvider.preferredLanguage('en');

  //$locationProvider.html5Mode(true);
  
  $httpProvider.interceptors.push([
    '$injector',
    function ($injector) {
      return $injector.get('AuthInterceptor');
    }
  ]);
})



.factory('AuthInterceptor', function ($rootScope, $q,
                                      AUTH_EVENTS) {
  return {
    responseError: function (response) {
      $rootScope.$broadcast({
        401: AUTH_EVENTS.notAuthenticated,
        403: AUTH_EVENTS.notAuthorized
      }[response.status], response);
      return $q.reject(response);
    }
  };
})
