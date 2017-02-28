'use strict';
var app = angular.module('dashboardApp');

app.factory("authenticationService", function($rootScope, $http, $q, $timeout, $window, $location, AUTH_EVENTS, restKeystoneUrl) {
    var userInfo;
    var scopedTokens = [];

    function getUserInfo() {
        return userInfo;
    }

    function getUnscopedToken() {
        return userInfo.access.token.id;
    }
    
    function getScopedToken(tenantId){
    	if (scopedTokens[tenantId] != null){
    		return scopedTokens[tenantId];	
    	}
    	console.log("Fetching scoped tenant for "+tenantId);
    	var promise = doAuth( {auth: {tenantId: tenantId, token: {id: getUnscopedToken()}}});
    	scopedTokens[tenantId] = promise;
    	return promise;
    }

    function doAuth(postInfo) {
        var deferred = $q.defer();
        $http.post(restKeystoneUrl + '/v2.0/tokens', postInfo, {
                withCredentials: false,
                responseType: 'application/json'
            })
            .success(function(data, status) {
                console.log('authenticated', data, status);
                userInfo = data;
                var token = userInfo.access.token.id;
                $window.sessionStorage["utoken"] = token;
                deferred.resolve(userInfo);
                $http.defaults.headers.common['X-Auth-Token'] = token;
                $rootScope.$broadcast(AUTH_EVENTS.loginSuccess);
                $rootScope.$broadcast(AUTH_EVENTS.clearAllCaches);
                return data.access;
            }).error(function(data, status) {
                console.log('error', data, status);
                if (status == 503) {
                    alertify.error("Authentication system is unavailable, please retry later");
                } else if (status == 429) {
                    var msg = "Too many attemps to authenticate";
                    if (data && data.data && data.data.blockedUntil) {
                        msg += ", you are blocked until: " + data.data.blockedUntil;
                    }
                    alertify.error(msg);
                } else {
                    console.log("Authentication error, please try again, status=" + status, data);
                }
                //window.location = "#/login";
                deferred.reject(data);
            });
        return deferred.promise;
    };

    function refreshToken(token) {
        if (token == "null" || token == undefined || token == null || "" == token) {
            var deferred = $q.defer();
            deferred.reject("no token provided");
            return deferred.promise;
        }
        var deferred = doAuth({
            auth: {
                token: {
                    id: token
                }
            }
        });
        deferred.then(function(data) {
            console.log("Token refreshed");
        }, function() {
            console.log("Token expired");
            $rootScope.$broadcast(AUTH_EVENTS.clearAllCaches);
        });
        return deferred;
    };

    function login(username, password) {
        var deferred = doAuth({
            auth: {
                passwordCredentials: {
                    username: username,
                    password: password
                }
            }
        });
        deferred.then(function() {
            alertify.success("Authentication Success");
            //window.location = "#/dashboard";	    
        }, function() {
            alertify.error("Wrong user or password");
        });
        return deferred;
    };

    var refreshingToken = false;

    var redirectOnceAuthPerformed = false;


    function tryRefreshAuthToken(redirectToLoginWhenInError) {
        var uinfo = getUserInfo();
        if (uinfo != null)
            return uinfo;
        if (refreshingToken) {
            return getUserInfo();
        }
        redirectOnceAuthPerformed = redirectOnceAuthPerformed | redirectToLoginWhenInError;
        refreshingToken = true;
        if ($window.sessionStorage["utoken"] != null) {
            console.log("Trying to refresh token...");
            var token = $window.sessionStorage["utoken"];
            refreshToken(token).then(function(res) {
                $http.defaults.headers.common['X-Auth-Token'] = res.access.token.id;
                refreshingToken = false;
                $timeout(function() {
                    $rootScope.$apply();
                });
                var parameters = $location.search();

                if (parameters.redirectTo != null)
                    $location.path(parameters.redirectTo).search({});
                else
                    $location.path('/').search({});
            }, function(err) {
                //$http.defaults.headers.common['X-Auth-Token'] = null;
                //refreshingToken = false;
                $rootScope.$broadcast(AUTH_EVENTS.sessionTimeout);
                logout();
                if (redirectOnceAuthPerformed) {
                    $location.path("#/login");
                }
            });
        }
        return getUserInfo();
    }

    //function init() {
    //  tryRefreshAuthToken(false);
    //};


    //init();

    function logout() {
        var ret = null;
        if (userInfo != null) {
            ret = "Goodbye " + userInfo.access.user.name + "(" + userInfo.access.user.email + ")";
        }
        $rootScope.$broadcast(AUTH_EVENTS.clearAllCaches);
        $window.sessionStorage["userInfo"] = null;
        $window.sessionStorage["utoken"] = null;
        userInfo = null;
        if (ret != null) {
            alertify.success(ret);
        }
        $rootScope.$broadcast(AUTH_EVENTS.logoutSuccess);
        return ret;
    };

    return {
        getUserInfo: getUserInfo,
        getUnscopedToken: getUnscopedToken,
        getScopedToken: getScopedToken,
        login: login,
        logout: logout,
        tryRefreshAuthToken: tryRefreshAuthToken
    };
});

app.controller('LoginController', function($scope, $location, authenticationService) {
    $scope.login = function(credentials) {
        authenticationService.login(credentials.username, credentials.password)
            .then(function() {
                var parameters = $location.search();
                //$location.search = {};
                console.log(parameters);
                if (parameters.redirectTo != null)
                    $location.path(parameters.redirectTo).search({});
                else
                    $location.path('/').search({});
            });
    };
});

app.controller('LogoutController', function($scope, authenticationService) {
    $scope.logout = function(credentials) {
        var ret = authenticationService.logout();
    };
});

app.directive('formAutofillFix', function($timeout) {
    return function(scope, elem, attrs) {
        // Fix autofill issues where Angular doesn't know about autofilled inputs
        if (attrs.ngSubmit) {
            $timeout(function() {
                elem.unbind('submit').submit(function(e) {
                    e.preventDefault();
                    elem.find('input, textarea, select').trigger('input').trigger('change').trigger('keydown');
                    scope.$apply(attrs.ngSubmit);
                });
            });
        }
    };
});