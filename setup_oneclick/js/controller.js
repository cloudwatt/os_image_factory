"use strict";
var app = angular.module('dashboardApp');

function destroyClickedElement(event)
{
	document.body.removeChild(event.target);
}

function saveTextAsFile(fileNameToSaveAs, data) {

    var textFileAsBlob = new Blob([data], {type: "text/plain"});
    var downloadLink = document.createElement("a");

    downloadLink.download = fileNameToSaveAs;
    downloadLink.innerHTML = "Download File";

    if (window.webkitURL != null) {

        // Chrome allows the link to be clicked programmatically.

        downloadLink.href = window.webkitURL.createObjectURL(textFileAsBlob);
        downloadLink.click();

    } else {
        // Firefox requires the user to actually click the link.
        downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
        // this hides it
        downloadLink.style.display = "none";
        downloadLink.onclick = destroyClickedElement;
        document.body.appendChild(downloadLink);
        // now it can be auto clicked like in chrome
        downloadLink.click();
    }
};

app.run(["$rootScope", "$location", "authenticationService", function($rootScope, $location, authenticationService) {
    //$rootScope.$on("$routeChangeSuccess", function(userInfo) {
    //  console.log(userInfo);
    //});
    //
    //$rootScope.$on("$routeChangeError", function(event, current, previous, eventObj) {
    //  if (eventObj.authenticated === false) {
    //    $location.path("/login");
    //  }
    //});

    $rootScope.$on("$locationChangeStart", function(event, next, current) {
        var user = authenticationService.tryRefreshAuthToken(false);
        var path = $location.path();
        var host = $location.absUrl();
        var parameters = $location.search();
        console.log('Current page : ' + current + ' ; Next page : ' + next + 'Current path : ' + path + '; current absPath : ' + host + ' ; current parameters : ', parameters);
        if (user == null && (path != '/login' && path != '/404')) {
            console.log('You are not authenticated');
            var redirectParams = {};
            if (path != '/login' && path != '/404')
                redirectParams = {
                    redirectTo: path
                };
            $location.path('/login').search(redirectParams);
        }
        if (user != null && path == '/login') {
            console.log('You are already authenticated');
        }
    });
}]);

var allCaps = null;

app.factory('CAPABILITIES', function($resource, restPublicUrl) {
    return (function() {
        if (allCaps != null) {
            return allCaps;
        }
        allCaps = {
            ACCOUNT_EDIT: 'ACCOUNT_EDIT',
            ACCOUNT_SHOW: 'ACCOUNT_SHOW',
            ACCOUNT_ROLES_EDIT: 'ACCOUNT_ROLES_EDIT',
            ACCOUNT_ROLES_LIST: 'ACCOUNT_ROLES_LIST',
            BILLING_EDIT: 'BILLING_EDIT',
            BILLING_INVOICES: 'BILLING_INVOICES',
            BILLING_PAYMENT_EDIT: 'BILLING_PAYMENT_EDIT',
            BILLING_PAYMENT_SHOW: 'BILLING_PAYMENT_SHOW',
            BILLING_SHOW: 'BILLING_SHOW',
            CONSUMPTION: 'CONSUMPTION',
            SUB_ACCOUNTS_CREATE: 'SUB_ACCOUNTS_CREATE',
            SUB_ACCOUNTS_LIST: 'SUB_ACCOUNTS_LIST',
            TENANT_EDIT: 'TENANT_EDIT',
            TENANT_SHOW: 'TENANT_SHOW',
            TENANTS_ADD: 'TENANTS_ADD',
            TENANTS_LIST: 'TENANTS_LIST',
            TICKET_CREATE: 'TICKET_CREATE',
            TICKET_LIST: "TICKET_LIST"
        };
        $resource(restPublicUrl + '/bss/1/caps').get(null, function(res) {
            allCaps = res;
        });
        return allCaps;
    });
});



//app.factory('ContactRoles', function($resource, restFrontendUrl) {
//    return $resource(restFrontendUrl + '/getContactRolesByToken');
//});

app.factory('ContactRoles', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/contact/roles');
});

app.factory('AccountDetails', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/accounts/:customerId', {
        customerId: "@customer_id"
    }, {
        put: {
            method: 'PUT'
        }
    });
});

app.factory('SubAccounts', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/accounts/:customerId/children', {
        customerId: "@customer_id"
    }, {
        list: {
            method: 'GET',
            isArray: true
        }
    });
});

app.factory('AllRolesOnAccount', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/accounts/:customerId/roles', {
    }, {
        put: {
            method: 'PUT'
        },
        list: {
        	method: 'GET',
        	isArray: true
        }
    });
});

var openstackRoles = null;

app.factory('ListOpenstackRoles', function($resource, $timeout, restPublicUrl) {
		return (function($scope) {
        if (openstackRoles != null) {
            return openstackRoles;
        }
        openstackRoles = [];
        $resource(restPublicUrl + '/openstack/1/roles?region=fr1').get(null, function(res) {
            openstackRoles = res.roles;
            $timeout(function() {
            $scope.$apply();
          });
        });
        return openstackRoles;
        });
});

app.factory('ListInvoices', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/accounts/:customerId/listInvoices?extensions=pdf,csv', {
        customerId: "customerId"
    });
});

app.factory('ListSwiftContainers', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/openstack/swift/1/listContainers?region=fr1');
});

app.factory('HorseVersion', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/ping');
});

app.factory('MyTenants', function($resource, restKeystoneUrl) {
    return $resource(restKeystoneUrl + '/v2.0/tenants');
});

app.factory('OwnedTenants', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/bss/1/accounts/:customerId/tenants', {
        customerId: "customerId"
    });
});

app.factory('AllKnownUsers', function($resource, restPublicUrl) {
    return $resource(restPublicUrl + '/openstack/1/users?region=fr1');
});

app.factory("HMacCompute", function() {

    return function(data, secret) {
        try {
            var hmacObj = new jsSHA(data, 'TEXT');

            return hmacObj.getHMAC(
                secret,
                'TEXT',
                'SHA-1',
                'HEX'
            );
        } catch (e) {
            console.log("Failed to compute hash", e);
            return e;
        }

    };
});

app.factory("HMacComputeTempURL", function(HMacCompute) {

    return function(secretKey, method, expires, rpath) {
        var data = method + '\n' + expires + '\n' + rpath;
        return HMacCompute(data, secretKey);
    }
});

app.controller('ApplicationController', function($scope, $rootScope, $location, authenticationService, AUTH_EVENTS, $timeout, HorseVersion, ConsolePublicUrl) {
    $scope.auth = null;

    $scope.requiresAuth = function() {
        var auth = authenticationService.getUserInfo();
        if (auth == null) {
            auth = authenticationService.tryRefreshAuthToken(true);
        }
        return auth;
    };

    var redirectToOnSuccess = '#/';

    function showDialog() {
        /*if (window.confirm("Authentication Error, login ?")){
  		window.location= "#/login";
  		return;
  	}*/
        //redirectToOnSuccess = $location.$$url;
        //console.log("showDialog: ", $location);
        refreshAuth();
    };
    
    $scope.consolePublicUrl = ConsolePublicUrl;	

    function refreshAuth() {
        $timeout(function() {
            console.log("refreshAuth()");
            $scope.auth = authenticationService.getUserInfo();
            $scope.$apply();
        });
    }
    var _version = null;
    $scope.version = function() {

        if (_version != null) {
            return _version;
        }
        _version = "x.x.x";
        HorseVersion.get({}, function(data) {
            _version = data.id;
            $timeout(function() {
                $scope.$apply();
            });
        });
        return _version;
    };
    $scope.$on(AUTH_EVENTS.notAuthenticated, showDialog);
    $rootScope.$on(AUTH_EVENTS.loginSuccess, refreshAuth);
    $rootScope.$on(AUTH_EVENTS.logoutSuccess, refreshAuth);
});

app.factory('AccountsData', function($rootScope, AUTH_EVENTS, $q, authenticationService, ContactRoles, ListInvoices, OwnedTenants, AccountDetails, SubAccounts, MyTenants, $timeout, CAPABILITIES, AllRolesOnAccount) {

    var myAccounts = {};

    function getDataAndRegisterCall(customerId, dataType, toCall) {
        var x = myAccounts[customerId];
        if (x == null) {
            x = {
                customerId: customerId
            };
            myAccounts[customerId] = x;
        }
        if (x[dataType] != null) {
            return x[dataType];
        }
        x[dataType] = {};
        toCall();
        return x[dataType];
    };
    
    
    /**
     * List all invoices for a given Customer
     */
    function listInvoices(customerId, $scope) {
        return getDataAndRegisterCall(customerId, 'invoices', function() {

            return ListInvoices.get({
                customerId: customerId
            }, function(data) {
                myAccounts[customerId].invoices = data.invoices;
                $timeout(function() {
                    $scope.$apply();
                });
                return data;
            });
        });
    };

    /**
     * Get a list of tenants the account owns
     */
    function ownedTenants(customerId, $scope) {
    	if (customerId == null || customerId == '')
    		return [];
        return getDataAndRegisterCall(customerId, 'ownedTenants', function() {
            return OwnedTenants.query({
                customerId: customerId
            }, function(data) {
                myAccounts[customerId].ownedTenants = data;
                $timeout(function() {
                    $scope.$apply();
                });
                return data;
            });
        });
    };

    /**
     * Get information about an account
     */
    function getAccountDetails(customerId, $scope) {
        return getDataAndRegisterCall(customerId, 'details', function() {
            return AccountDetails.get({
                customerId: customerId
            }, function(data) {
                // Here for backwards compatibility
                myAccounts[customerId].details = data.account == null ? data : data.account;
                $timeout(function() {
                    console.log("account", data);
                    $scope.$apply();
                });
                return data;
            });
        });
    };
    
    function listSubAccounts(customerId, $scope){
    	return getDataAndRegisterCall(customerId, 'children', function() {
            return     	SubAccounts.list({
                customerId: customerId
            }, function(data) {
                // Here for backwards compatibility
                myAccounts[customerId].children = data;
                $timeout(function() {
                    $scope.$apply();
                });
                return data;
            });
        });
    };
    
    /**
     * List all roles for account, need CAP ACCOUNT_ROLES_LIST
     */ 
    function getAccountRoles(customerId, $scope){
    	console.log("Getting roles information for "+customerId);
    	return getDataAndRegisterCall(customerId, 'allRoles', function() {

            return AllRolesOnAccount.list({
                customerId: customerId
            }, function(data) {
            	console.log(data);
                myAccounts[customerId].allRoles = data;
                $timeout(function() {
                    $scope.$apply();
                });
                return data;
            });
        });
    };

    /**
     * Update account information
     */
    function updateAccountDetails(account, $scope) {
        var customer_id = account.customer_id;
        var x = myAccounts[customer_id];
        if (x == null) {
            x = {
                customer_id: customer_id
            };
            myAccounts[customer_id] = x;
        }
        account.corporate_name = account.name;
        AccountDetails.put({
            customerId: account.customer_id
        }, account, function(data) {
            // Here for backwards compatibility
            x.account = data;
            $timeout(function() {
                $scope.$apply();
            });
            return data;
        });
        return x.account;
    };

    function clearCache() {
        myAccounts = {};
    }

    $rootScope.$on(AUTH_EVENTS.clearAllCaches, clearCache);

    return {
        listInvoices: listInvoices,
        ownedTenants: ownedTenants,
        getAccountDetails: getAccountDetails,
        updateAccount: updateAccountDetails,
        getAccountRoles: getAccountRoles,
        listSubAccounts: listSubAccounts
    };


});

app.factory('ContactData', function($rootScope, $q, authenticationService, ContactRoles, ListInvoices, OwnedTenants, AccountDetails, MyTenants, $timeout, CAPABILITIES, AUTH_EVENTS, AllKnownUsers) {

    function createEmptyContactData() {
        return {
            /**
             * Internal
             */
            _resolved: false,
            /**
             * Array of named roles indexed by customerId
             */
            roles: [],
            /**
             * Function that tells whether the cap is present for given account
             */
            hasCap: function(customerId) {
                return false;
            },

            capabilities: function(customerId) {
                return new Array();
            },
            /**
             * Contact information
             */
            contact: {}
        }
    };

    /**
     * Account-Role information
     */
    var contactData = createEmptyContactData();

    function _fetchContactInfo() {
        var defer = $q.defer();
        console.log("Getting contact information...");
        ContactRoles.get({}, function(res) {
            if (res.accounts) {
                // New style API
                contactData._fullResult = res;
                contactData.contact = res.contact;
                contactData.accounts = {};
                contactData.roles = {};
                for (var i = 0; i < res.accounts.length; i++) {
                    var acc = res.accounts[i];
                    contactData.accounts[acc.account] = acc;
                    contactData.roles[acc.account] = {
                        customer_id: acc.account,
                        usage_type: acc.roles
                    };
                }
                console.log("accounts", contactData.accounts);
                contactData.findAccount = function(customerId) {
                    var x = contactData.accounts[customerId];
                    return x == null ? {} : x;
                };
                contactData.capabilities = function(customerId) {
                    var x = contactData.findAccount(customerId);
                    if (x.caps)
                        return x.caps;
                    return [];
                };
                contactData.hasCap = function(customerId, cap) {
                    //console.log("hasCap", customerId, cap);
                    return contactData.capabilities(customerId).indexOf(cap) != -1;
                };

            } else {
                var hashRoles = {};

                var newRoles = new Array();
                // Filter roles
                for (var i in res.roles) {
                    var role = res.roles[i];
                    var x = hashRoles[role.customer_id];
                    if (x == null) {
                        x = {
                            customer_id: role.customer_id,
                            usage_type: new Array()
                        };
                        hashRoles[role.customer_id] = x;
                        newRoles.push(x);
                    }
                    x.usage_type.push(role.usage_type);
                }
                contactData._fullResult = res;
                contactData.roles = newRoles;
                contactData.contact = res.contact;
                var theNewCaps = function(customerId) {
                    var x = res.accountsCaps[customerId];
                    return x == null ? new Array() : x;
                };
                contactData.capabilities = theNewCaps;
                contactData.hasCap = function(customerId, cap) {
                    return (theNewCaps(customerId)).indexOf(cap) != -1;
                };
            }
            console.log("contact information resolved to ", contactData);
            contactData._resolved = true;
            defer.resolve(contactData);

        });
        return defer.promise;
    }
    
    
    var allKnownUsers = null;
    
    function getAllKnownUsers(scopeToRefresh){
    	if (allKnownUsers!=null){
    		return allKnownUsers;
    	}
    	allKnownUsers = [];
    	AllKnownUsers.get({}, function(data) {
            // Here for backwards compatibility
            allKnownUsers = data.users;
            if (scopeToRefresh){
            	 $timeout(function() {
                    scopeToRefresh.$apply();
                });	
            }
            return data;
        });
        return allKnownUsers;    
    };

    var promise = null;

    function getContactData($scope, callOnceResolve) {
        if (contactData._resolved) {
            //console.log("return directly");
            return contactData;
        }
        if (promise == null) {
            promise = _fetchContactInfo();
        }
        if ($scope) {
            promise.then(function() {
                $timeout(function() {
                    console.log("refreshing scope...", $scope);
                    $scope.$apply();
                    if (callOnceResolve)
                        callOnceResolve(contactData);
                });
            });
        }
        return contactData;
    }

    function listMyTenants() {
        var defer = $q.defer();
        MyTenants.get({}, function(data) {
            // Here for backwards compatibility
            defer.resolve(data);
            return data;
        });
        return defer.promise;
    }

    function clearCache() {
        contactData = createEmptyContactData();
        allKnownUsers = null;
        promise = null;
    }

    $rootScope.$on(AUTH_EVENTS.clearAllCaches, clearCache);

    return {
        getContactData: getContactData,
        listTenants: listMyTenants,
        listAllUsers: getAllKnownUsers
    };

});

app.controller('ContactController', function($scope, $rootScope, ListOpenstackRoles, ContactData, AccountsData, $q, authenticationService, ContactRoles, ListInvoices, OwnedTenants, AccountDetails, MyTenants, $timeout, CAPABILITIES, AUTH_EVENTS) {

    $scope.ContactRoles = ContactData.getContactData($scope, function(res) {
        $scope.ContactRoles = res;
    });
    
      $scope.listOpenstackRoles = function(){
    	return ListOpenstackRoles($scope);
    };


    var _baseCaps = CAPABILITIES();
    $scope.allPossibleCaps = function() {
        return CAPABILITIES();
    };


    $scope.capabilities = function(customerId) {
        return $scope.ContactRoles.capabilities(customerId);
    };

    $scope.hasCap = function(customerId, cap) {
        return $scope.ContactRoles.hasCap(customerId, cap);
    };

    $scope.listInvoices = function(customerId) {
        return AccountsData.listInvoices(customerId, $scope);
    };

    $scope.ownedTenants = function(customerId) {
        return AccountsData.ownedTenants(customerId, $scope);
    };
    

    $scope.updateAccount = function(account) {
        return AccountsData.updateAccount(account, $scope);
    };
    
   

    $scope.tenants = null;

    function listMyTenants() {
        if ($scope.tenants != null)
            return $scope.tenants;
        $scope.tenants = {
            tenants: []
        };
        ContactData.listTenants().then(function(data) {
            $scope.tenants = data;
            $timeout(function() {
                $scope.$apply();
            });
        });
        return $scope.tenants;
    };

    /**
     * get a tenant the contact can access to using its id.
     * Return null if the contact has no access to the tenant
     */
    $scope.getTenantById = function(tenantId) {
        var myTenants = listMyTenants();
        var d = myTenants.tenants;
        for (var i = 0; i < d.length; i++) {
            if (d[i].id == tenantId) {
                return d[i];
            }
        }
        return null;
    }

    $scope.listTenants = listMyTenants;

    $scope.accountDetails = function(customerId) {
        return AccountsData.getAccountDetails(customerId, $scope);
    };
    
    $scope.listSubAccounts = function (customerId){
    	return AccountsData.listSubAccounts(customerId, $scope);
    };
    
     $scope.getAccountRoles = function (customerId) {
    	return AccountsData.getAccountRoles(customerId, $scope);
    };
    
    $scope.listAllUsers = function() {
    	return ContactData.listAllUsers($scope);
    }

    function clearCache() {
        $scope.ContactRoles = ContactData.getContactData($scope, function(res) {
            $scope.ContactRoles = res;
        });
        $scope.tenants = null;
    }

    $rootScope.$on(AUTH_EVENTS.clearAllCaches, clearCache);

});


app.controller('AccountDetailController', function($scope, restPublicUrl, authenticationService, $resource, $routeParams, ContactData, AccountsData, ListOpenstackRoles, $timeout) {

    var contactInfo = null;
    contactInfo = ContactData.getContactData($scope, function(res) {
        contactInfo = res;
    });

    var customerId = $routeParams.customerId;
    $scope.customerId = $routeParams.customerId;
    
    $scope.tenantId = $routeParams.tenantId;

    $scope.details = function() {
        return AccountsData.getAccountDetails(customerId, $scope);
    };
    
    $scope.listSubAccountsOnCurrentAccount = function (){
    	return AccountsData.listSubAccounts(customerId, $scope);
    };

    $scope.hasCapOnCurrentAccount = function(cap) {
        return contactInfo.hasCap(customerId, cap);
    };

    $scope.listInvoicesOnCurrentAccount = function() {
        return AccountsData.listInvoices(customerId, $scope);
    };
    
    

    $scope.listOwnedTenantsOnCurrentAccount = function() {
    	if ( customerId ) {
    		return AccountsData.ownedTenants(customerId, $scope);
    	} else {
    		return [];	
    	}
    };
    
    var myTokens = [];
    
    function getScopedTokenAccess(tenantId) {
        if (myTokens[tenantId]) {
            return myTokens[tenantId];
        }
        myTokens[tenantId] = {};
        //console.log("Need scoped token !");
        authenticationService.getScopedToken(tenantId).then(function(res) {
            myTokens[tenantId] = res;
            $timeout(function() {
                $scope.$apply();
            });
        });
        return myTokens[tenantId];
    };

    $scope.getScopedTokenAccess = getScopedTokenAccess;

    $scope.getScopedTokenId = function(tenantId) {
        var x = getScopedTokenAccess(tenantId);
        if (x.access) {
            return x.access.token.id;
        }
        return null;
    };
    
    $scope.tenantRoles = null;

    function refreshRoles(){
    	$resource(restPublicUrl + '/bss/1/tenants/:tenantId/users').get({
           tenantId: $scope.tenantId
        }, function(data){
        	$scope.tenantRoles = data;
        	$timeout(function() {
        			$scope.$apply();
        	});
        });
    }
    
    if ($scope.tenantId){
    	refreshRoles();
        
    };
    
    $scope.roleToAdd = null;
    
    $scope.userToAdd = null;
    
    $scope.listOpenstackRolesToAdd = function(){
    	var daRoles = ListOpenstackRoles($scope);
    	if (daRoles!=null && daRoles.length > 0){
    		if ($scope.roleToAdd == null){
    			$scope.roleToAdd = daRoles[0].id;	
    		}
    	}
    	return daRoles;
    };
        
    $scope.addRoleToTenant = function(tenantId, userId, roleId){
    		($resource(restPublicUrl + '/openstack/1/tenants/:tenantId/users/:userId/roles/:roleId?region=fr1', {userId: userId, roleId: roleId, tenantId: tenantId}, {
                'put': {
                    method: 'PUT',
                    isArray: false,
                    headers: {
                        'X-Auth-Token': authenticationService.getUnscopedToken()
                    }
                }
            }))
            .put({}, function(res) {
            	refreshRoles();
                $timeout(function() {
                    $scope.$apply();
                });
            }, function (err){
            	if (err.status == 409){
            		alertify.error("This user already has this role");
            	} else {
            		alertify.error("Cannot add user: "+err);
            		console.log(err);
            	}
            }
            );
    };
    
    

});

//app.controller("SwiftController", function

app.controller("TenantController", function($scope, $resource, $timeout, $routeParams, ContactData, AccountsData, authenticationService, ListSwiftContainers, restPublicUrl) {

    var contactInfo = null;
    contactInfo = ContactData.getContactData($scope, function(res) {
        contactInfo = res;
    });

    var tenantId = $routeParams.tenantId;

    $scope.tenantId = tenantId;

    $scope.tenants = null;

    function listMyTenants() {
        if ($scope.tenants != null)
            return $scope.tenants;
        $scope.tenants = {
            tenants: []
        };
        ContactData.listTenants().then(function(data) {
            //console.log("allTenant", data);
            var d = data.tenants;
            for (var i = 0; i < d.length; i++) {
                //console.log("tenant " + i, d[i]);
                if (d[i].id == tenantId) {
                    //console.log("found tenant " + tenantId, d[i]);
                    $scope.tenantInfo = d[i];
                    return $scope.tenantInfo;
                }
            }
            $timeout(function() {
                $scope.$apply();
            });
        });
        return $scope.tenants;
    };

    var myToken = null;

    function getScopedTokenAccess() {
        if (myToken != null) {
            return myToken;
        }
        myToken = {};
        //console.log("Need scoped token !");
        return authenticationService.getScopedToken(tenantId).then(function(res) {
            myToken = res;
            $timeout(function() {
                $scope.$apply();
            });
        });
        return myToken;
    };

    $scope.getScopedTokenAccess = getScopedTokenAccess;

    $scope.getScopedTokenId = function() {
        var x = getScopedTokenAccess();
        if (x.access) {
            return x.access.token.id;
        }
        return null;
    };

    $scope.getScopedTokenRoles = function() {
        var x = getScopedTokenAccess();
        if (x.access) {
            return x.access.user.roles;
        };
        return null;
    };
    

    var myContainers = null;

    $scope.listContainers = function() {
        if (myContainers != null) {
            return myContainers;
        }
        var x = getScopedTokenAccess();
        if (x.access) {
            myContainers = {};
            var scopedToken = x.access.token.id;
            ($resource(restPublicUrl + '/openstack/swift/1/listContainers?region=fr1', {}, {
                'list': {
                    method: 'GET',
                    isArray: true,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            }))
            .list({}, function(res) {
                myContainers = res;
                $timeout(function() {
                    $scope.$apply();
                });
            });

        }
        return new Array();
    };
    
    
    
    if ( !Date.prototype.toISOString ) {
  ( function() {
    
    function pad(number) {
      if ( number < 10 ) {
        return '0' + number;
      }
      return number;
    }
 
    Date.prototype.toISOString = function() {
      return this.getUTCFullYear() +
        '-' + pad( this.getUTCMonth() + 1 ) +
        '-' + pad( this.getUTCDate() ) +
        'T' + pad( this.getUTCHours() ) +
        ':' + pad( this.getUTCMinutes() ) +
        ':' + pad( this.getUTCSeconds() ) +
        '.' + (this.getUTCMilliseconds() / 1000).toFixed(3).slice(2, 5)+'Z'
        ;
    };
  
  }() );
}
    
    var consumption = null;
    
    function setupDefaultDate(){
    	var dx = new Date();
            	dx.setHours(0);
            	dx.setMinutes(0);
            	dx.setSeconds(0);
            	dx.setMilliseconds(0);
        dx = new Date(dx.getTime() - 24 * 3600000);
        return dx;
    };
    
    $scope.maxDate = new Date();
    $scope.maxDate.setSeconds(0);
    $scope.maxDate.setMilliseconds(0);
    
    $scope.consumptionParams = { page : 0,
                            fromDate: ($routeParams.fromDate == null ? setupDefaultDate() : $routeParams.fromDate),
    						limit: 100 }
    						
    
    
    $scope.invalidateConsumption = function(){
    	consumption = null;
    	$scope.listConsumption();
    	$timeout(function() {
                    $scope.$apply();
                });
    };   
	
    
    $scope.chartObject = {};


    $scope.chartObject.data = {"cols": [
    	{id: "d", label: "Day", type: "date"},
        {id: "f", label: "Floating IPs", type: "number"},
        {id: "i", label: "Instances", type: "number"},
        {id: "o", label: "Swift Outgoing bytes (Gb)", type: "number"},
        {id: "r", label: "Swift Requests", type: "number"}
    ], "rows": []};


    // $routeParams.chartType == BarChart or PieChart or ColumnChart...
    $scope.chartObject.type = "LineChart";
    $scope.chartObject.options = {
        'title': 'Consumption Overview',
        'tooltip': {isHtml: true}
    };
  
  	function recomputeSeries(res){
  	   var data = new Array();
  	   var start;
  	   var currentLength = 0;
  	   var prevIndex
  	   for (var i = 0; i < res.events.length; i++){
  	   	   var event = res.events[i];
  	   	   if (i == 0){
  	   	      start = event.computeDate;   
  	   	   }
  	   	   var index = (event.computeDate - start) / 3600000;
  	   	   if (data[index] == null){
  	   	   		data[index] = {c: [
        	{v: new Date(event.computeDate)},
            {v: 0},
            {v: 0},
            {v: 0},
            {v: 0}
        ]};
  	   	   		
  	   	   }
  	   	   if (event.type == 'HourInstanceOpenstackAggregatedMetricEvent'){
  	   	   	   data[index].c[1].v++;
  	   	   } else if (event.type == 'HourMaxFloatingIpsOpenstackAggregatedMetricEvent'){
  	   	   	   data[index].c[2].v=event.size;   
  	   	   } else if (event.type == 'HourObjectOutgoingBytesOpenstackAggregatedMetricEvent'){
  	   	   	   data[index].c[3].v=event.size / 1000000;
  	   	   	   data[index].c[4].v=event.counter;   
  	   	   }
  	   }
  	   
  	   
  	   $timeout(function() {
  	   		   $scope.chartObject.data["rows"] = data;
                $scope.$apply();
            });
  	   
  	}
    

    $scope.listConsumption = function(){
    	if (consumption){
    		return consumption;	
    	}
    	var x = getScopedTokenAccess();
        if (x.access) {
            consumption = [];
            var scopedToken = x.access.token.id;
            if ($scope.consumptionParams.page == null || $scope.consumptionParams.page < 0){
            	$scope.consumptionParams.page = 0;	
            }
            if ($scope.consumptionParams.fromDate == null){
            	$scope.consumptionParams.fromDate = setupDefaultDate();
            }
            var endDate = new Date($scope.consumptionParams.fromDate.getTime() + 3600000 * 24 * 31);
            if (endDate.getTime() > $scope.maxDate){
            	endDate = $scope.maxDate;
            }
            ($resource(restPublicUrl + '/bss/accounts/1/rawConsumption/tenant/:tenantId', {toDate: endDate, fromDate: $scope.consumptionParams.fromDate.toISOString(), page: $scope.consumptionParams.page, limit:$scope.consumptionParams.limit, tenantId:tenantId}, {
                'list': {
                    method: 'GET',
                    isArray: false,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            })).list({}, function(res) {
            	//alertify.success("Consumption retrieved for "+tenantId);
                consumption = res.events;
                $timeout(function() {
                    $scope.$apply();
                });
                recomputeSeries(res);
            }, function (err){
               alertify.error("Failed to list consumption for "+tenantId+":"+err);

            });

        }
        return consumption;
    };
    
    
    


    listMyTenants();

    $scope.tenantInfo = {};

});

if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
}


app.controller("SwiftController", function($window, $location, HMacComputeTempURL, $scope, $resource, $timeout, $routeParams, ContactData, AccountsData, authenticationService, ListSwiftContainers, restPublicUrl) {

    var contactInfo = null;
    contactInfo = ContactData.getContactData($scope, function(res) {
        contactInfo = res;
    });

    var swiftResourceSummary = null;


    var tenantId = $routeParams.tenantId;

    var region = $routeParams.region;

    var container = $routeParams.container;

    $scope.container = container;

    $scope.region = region;

    $scope.tenantId = tenantId;

    $scope.tenants = null;

    $scope.prefixes = [];

    $scope.swiftResourceSummary = null;

    var myToken = null;

    function getScopedTokenAccess() {
        if (myToken != null) {
            return myToken;
        }
        myToken = {};
        return authenticationService.getScopedToken(tenantId).then(function(res) {
            myToken = res;
            $timeout(function() {
                $scope.$apply();
            });
        });
    };

    function getScopedTokenId() {
        var x = getScopedTokenAccess();
        if (x.access) {
            return x.access.token.id;
        }
        return null;
    };

    function getSwiftResourceSummary() {
        var scopedToken = getScopedTokenId();
        if (!scopedToken) {
            return {};
        }
        if ($scope.swiftResourceSummary != null)
            return $scope.swiftResourceSummary;
        $scope.swiftResourceSummary = {};
        ($resource(restPublicUrl + '/openstack/swift/:region/1/containers/:container/cors?region=fr1', {
            region: region,
            container: container
        }, {
            'post': {
                method: 'POST',
                isArray: false,
                headers: {
                    'X-Auth-Token': scopedToken
                }
            }
        }))
        .post({
            origin: $location.protocol() + "://" + $location.host()
        }, function(res) {
            $scope.swiftResourceSummary = res;
            $scope.secret = res.tempUrlKey;

            $timeout(function() {
                $scope.$apply();
            });
        });
        return $scope.swiftResourceSummary;

    };

    var swiftEndPoint = null;

    function findSwiftURL(region) {
        if (swiftEndPoint != null) {
            return swiftEndPoint;
        }
        var catalog = getScopedTokenAccess().access.serviceCatalog;
        for (var i = 0; i < catalog.length; i++) {
            var endP = catalog[i];
            if (endP.type == 'object-store') {
                var urls = endP.endpoints;
                //console.log("Found object store", endP, urls);
                for (var j = 0; j < urls.length; j++) {
                    var cur = urls[j];
                    if (cur.region == region) {
                        swiftEndPoint = {
                            href: cur.publicURL,
                            path: cur.publicURL.substr(cur.publicURL.indexOf('/v1/AUTH_'))
                        };
                        //console.log("Found", endP.endpoints, swiftEndPoint);
                        return swiftEndPoint;
                    };
                }
            }
        }
        throw "Swift URL has not been found";
    };

    var files = null;

    function listFilesAsync(prefix) {
        var scopedToken = getScopedTokenId();
        if (!scopedToken) {
            return [];
        }
        ($resource(findSwiftURL(region).href + '/' + container, {
            region: region,
            container: container
        }, {
            'get': {
                method: 'GET',
                params: {
                    delimiter: '/',
                    prefix: prefix
                },
                isArray: true,
                headers: {
                    'X-Auth-Token': scopedToken
                }
            }
        }))
        .get({}, function(res) {
            files = res;
            $timeout(function() {
                $scope.$apply();
            });
        });
    }

    $scope.upDir = function() {
        $scope.prefixes.pop();
        if ($scope.prefixes.length < 1) {
            $scope.prefix = "";
        } else {
            $scope.prefix = $scope.prefixes.join('/') + '/';
        }
        $timeout(function() {
            $scope.$apply();
        });
        listFilesAsync($scope.prefix);
    };



    $scope.subdir = function(toAppend) {
    	if (toAppend.length > 0 && toAppend[toAppend.length-1]!='/'){
    		toAppend = toAppend+"/";
    	}
        var sx = toAppend.split('/');
        var arr = new Array();
        var p = "";
        for (var i = 0 ; i < sx.length; i++){
            p+=sx[i]+"/";
            if (sx[i]!='')
              arr.push({path: p, name:sx[i]});
        }
        $scope.prefixes = arr;
        $scope.prefix = toAppend;
        $timeout(function() {
            $scope.$apply();
        });
        listFilesAsync($scope.prefix);
    }

    $scope.listFiles = function() {
        if (files != null) {
            return files;
        }

        if (!($scope.swiftResourceSummary) || !($scope.swiftResourceSummary.region)) {
            return [];
        }
        files = [];
        listFilesAsync($scope.prefix);
        return files;

    }

    $scope.getSwiftResourceSummary = getSwiftResourceSummary;

    function listMyTenants() {
        if ($scope.tenants != null)
            return $scope.tenants;
        $scope.tenants = {
            tenants: []
        };
        ContactData.listTenants().then(function(data) {
            //console.log("allTenant", data);
            var d = data.tenants;
            for (var i = 0; i < d.length; i++) {
                //console.log("tenant " + i, d[i]);
                if (d[i].id == tenantId) {
                    //console.log("found tenant " + tenantId, d[i]);
                    $scope.tenantInfo = d[i];
                    return $scope.tenantInfo;
                }
            }
            $timeout(function() {
                $scope.$apply();
            });
        });
        return $scope.tenants;
    };


    $scope.getScopedTokenAccess = getScopedTokenAccess;

    $scope.getScopedTokenId = getScopedTokenId;

    $scope.getScopedTokenRoles = function() {
        var x = getScopedTokenAccess();
        if (x.access) {
            return x.access.user.roles;
        };
        return null;
    };

    var myContainers = null;

    $scope.listContainers = function() {
        if (myContainers != null) {
            return myContainers;
        }
        var x = getScopedTokenAccess();
        if (x.access) {
            myContainers = {};
            var scopedToken = x.access.token.id;
            ($resource(restPublicUrl + '/openstack/swift/1/listContainers?region=fr1', {}, {
                'list': {
                    method: 'GET',
                    isArray: true,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            }))
            .list({}, function(res) {
                myContainers = res;
                $timeout(function() {
                    $scope.$apply();
                });
            });

        }
        return new Array();
    };

    function computeTempURL(secretKey, method, expires, path) {
        return HMacComputeTempURL(secretKey, method, expires, path);
    };

    $scope.secret = null;

    $scope.computeName = function(name) {
        var path = container + "/" + name;
        var expires = ((new Date()).getTime()) + 3600000;
        var fullPath = findSwiftURL().path + '/' + path;
        var tmpUrl = findSwiftURL().href + '/' + path + '?temp_url_expires=' + expires + '&temp_url_sig=' + computeTempURL($scope.secret, 'GET', expires, fullPath);
        return tmpUrl;
    };

    $scope.openOutside = function(href) {
        $window.open(href, '_blank');
    };

    listMyTenants();

    $scope.tenantInfo = {};

});


app.controller("HeatController", function($window, $location, HMacComputeTempURL, $scope, $resource, $timeout, $routeParams, ContactData, AccountsData, authenticationService, ListSwiftContainers, restPublicUrl) {
    $scope.heat = null;

    $scope.heatTenantId = {id: null, value: []};
    
    var currentKeyPair = null;
    
    function initTenants() {
        ContactData.listTenants().then(function(data) {
            //console.log("allTenant", data);
            var d = data.tenants;
            if ($scope.heatTenantId.id==null){
				for (var i = 0; i < d.length; i++) {
					if (d[i].enabled){
					 // Only setup tenant if tenant is enabled
					 $scope.heatTenantId.id = d[i].id;
					 return;
					}
				}
				$timeout(function() {
					$scope.$apply();
				});
            }
        });
    };
    
    
    
    $scope.stack = $routeParams.stack ;
    
    $scope.myStacks = null;
    
    function loadHeatTemplate() {
    	if (!$scope.stack){
    		$scope.heat = null;
    		return;
    	}
    	
        $resource("stacks/:stack.json", {stack: $scope.stack}).get({}, function(res) {
            $scope.heat = res;
            for (var i in res.guiGroups) {
            	var grp = res.guiGroups[i];
            	for (var j in grp.inputs) {
            		var inp = grp.inputs[j];
            		if (inp.attributes.name == "keypair_name"){
            			console.log("Found keypair_name", inp);
            			currentKeyPair = inp.attributes;
            			break;
            		}
            	}
            }
            $timeout(function() {
                $scope.$apply();
            });
        });
    	initTenants();

    };
    
    function getScopedToken( tenantId ){
    	if (tenantId == null || '' == tenantId){
    		return null;
    	}
    	if ($scope.heatTenantId.value[tenantId]!=null){
    		return $scope.heatTenantId.value[tenantId];
    	}
    	$scope.heatTenantId.id = tenantId;
    	$scope.heatTenantId.value[tenantId] = {};
    	authenticationService.getScopedToken(tenantId).then(function(res){
    			$scope.heatTenantId.value[tenantId] = res;
    			$timeout(function() {
            	   $scope.$apply();
            	});
    			
    	});
    	return $scope.heatTenantId.value[tenantId];
    };
    
    
    $scope.getScopedToken = getScopedToken;
    
    $scope.canListKeypairs = true;
    
    $scope.myKeypairs = null;
    
    $scope.keypairCreated = null;
    
    $scope.createKeypair = function(name, comment){
    		var theTenantId = $scope.heatTenantId.id;
    	    var s_scopedToken = getScopedToken( theTenantId );
    		if (s_scopedToken == null){
    			return null;
    		}
    		if (name == null){
    			name = "cloudwatt_ssh_keypair";
    		}
    		var access = s_scopedToken.access;
    		if (access == null)
    			return null;
    		var scopedToken = ""+access.token.id;
    		var stacksCreate = $resource(restPublicUrl + '/openstack/nova/os-keypairs?region=fr1', {}, {
                'create': {
                    method: 'POST',
                    isArray: false,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            });
            alertify.success("Creating keypair...");
            stacksCreate.create({keypair:{name:name}}, function(res){
            		alertify.success("Keypair "+name+" created");
            		$scope.keypairCreated = res;
            		refreshKeypairs(true);
            		$timeout(function() {
            						$scope.$apply();
            		});
            		saveTextAsFile("id_rsa", res.keypair.private_key);
            		//saveTextAsFile("id_rsa_public.txt", res.keypair.public_key);
            }, function(err){
            		
            		console.log("Failed to create keypair", err);
            		if (err.status == 409){
            				alertify.error("Failed to create keypair, this keypair name '"+name+"' already exists!");
            		} else {
            				alertify.error("Failed to create keypair due to HTTP : '"+err.status);
            		}
            });
    }
    
    function refreshKeypairs(forceRefresh){
    		var theTenantId = $scope.heatTenantId.id;
    		if ($scope.myKeypairs != null){
    			if (!forceRefresh && $scope.myKeypairs.tenantId == theTenantId){
    				return $scope.myKeypairs;
    			}
    		}
    	    var s_scopedToken = getScopedToken( theTenantId );
    		if (s_scopedToken == null){
    			return null;
    		}
    		var access = s_scopedToken.access;
    		if (access == null)
    			return null;
    		var scopedToken = ""+access.token.id;

    	    var stacksFinder = $resource(restPublicUrl + '/openstack/nova/os-keypairs?region=fr1', {}, {
                'list': {
                    method: 'GET',
                    isArray: false,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            });
            $scope.myKeypairs = { keypairs:[], tenantId: theTenantId};
            stacksFinder.list({}, function(res){
            				res.tenantId = theTenantId;
            				$scope.myKeypairs = res;
            				if (currentKeyPair != null){
            					if (currentKeyPair.value == null || currentKeyPair.value == ''){
            						// Get first keypair
            						if (res.keypairs.length > 0){
            							console.log("Init first keypair");
            							currentKeyPair.value = res.keypairs[0].keypair.name;
            						}
            					}
            				}
            				
            				$timeout(function() {
            						$scope.$apply();
            				});
            		}, function (err){
            			alertify.error("Failed to list keypairs for "+theTenantId);
            			$scope.canListKeypairs = false;
            			//$scope.myKeypairs = { keypairs:[], tenantId: theTenantId};
            			$timeout(function() {
            						$scope.$apply();
            			});
            		});
            return $scope.myKeypairs;
            
    };
    
    function refreshStacks(forceRefresh){
    		var theTenantId = $scope.heatTenantId.id;
    		if ($scope.myStacks != null){
    			if (!forceRefresh && $scope.myStacks.tenantId == theTenantId){
    				return $scope.myStacks;
    			}
    		}
    		
    	    var s_scopedToken = getScopedToken( theTenantId );
    		if (s_scopedToken == null){
    			return null;
    		}
    		var access = s_scopedToken.access;
    		if (access == null){
    			return null;	
    		}
    		var scopedToken = access.token.id;
    	    var stacksFinder = $resource(restPublicUrl + '/openstack/orchestration/stacks?region=fr1', {}, {
                'list': {
                    method: 'GET',
                    isArray: false,
                    headers: {
                        'X-Auth-Token': scopedToken
                    }
                }
            });
            if ( ! ($scope.myStacks) || ! ($scope.myStacks.stacks) || ($scope.myStacks.tenantId != theTenantId )){
            	$scope.myStacks = { stacks:{}, tenantId: theTenantId};
            	$scope.myStacksDetails = {};
            }
            
            stacksFinder.list({}, function(res){
            				// alertify.success("Listing stacks done for "+theTenantId);
            				res.tenantId = theTenantId;
            				$scope.myStacks = res;
            				var shouldRefresh = false;
            				for (var i = 0; i < res.stacks.length; i++){
            					var s = res.stacks[i];
            					if (s.stack_status == "CREATE_COMPLETE" && !($scope.myStacksDetails[s.id])){
            						console.log("Refreshing stack Details", s.stack_name, s.id);
            						
								var stacksDetails = $resource(restPublicUrl + '/openstack/orchestration/stacks/:name/:id?region=fr1', {}, {
												'get': {
													method: 'GET',
													isArray: false,
													headers: {
														'X-Auth-Token': scopedToken
													}
												}
											});
								stacksDetails.get({name: s.stack_name, id: s.id}, function (resStack){
											$scope.myStacksDetails[resStack.stack.id] = resStack;
											$timeout(function() {
													$scope.$apply();
            								});
								});
								
								} else if (s.stack_status == "CREATE_IN_PROGRESS"){
									shouldRefresh = true;	
								}
            				}
            				$timeout(function() {
            						$scope.$apply();
            				});
            				if (shouldRefresh){
            					// We are still waiting for stack changes, autorefresh in 10secs
            					$timeout(function() {
            						$scope.refreshStacks(true);
            					}, 10000);	
            				}
            		}, function(err ){
            			console.log("Cannot list stacks", err);
            			var strErr = "Cannot list the stacks ";
            			if (err){
            				if (err.status){
            					strErr+= " HTTP "+err.status;	
            				}
            				if (err.statusText){
            				    strErr+= " HTTP "+err.statusText;
            				}
            				if (err.data.description){
            					strErr+= "\n- "+err.data.description;
            				}
            			}
            		    alertify.error(strErr);

            		});
            return $scope.myStacks;
            
    };
    $scope.refreshKeypairs = refreshKeypairs;
    $scope.refreshStacks = refreshStacks;
    
    $scope.extractHeatEndpoint=function(){
    	    var token = $scope.heatTenantId.value[$scope.heatTenantId.id];
    		if (token == null || token.access == null || token.access.serviceCatalog == null)
    			return null;
    		var access = token.access;
    		for (var i = 0 ; i < access.serviceCatalog.length; i++){
    			var endPoint = access.serviceCatalog[i];
    			if (endPoint.type == 'orchestration'){
    				for (var e in endPoint.endpoints){
    					var endPUrl = endPoint.endpoints[e];
    					return endPUrl.publicURL;
    				}
    			}
    		}
    		return null;
    };
    
    $scope.stack_name = { value: ('stack' + ($routeParams.stack ? "-"+$routeParams.stack : "")) };
        
    $scope.startStack = function(){    		
    		var s_scopedToken = getScopedToken( $scope.heatTenantId.id);
    		if (s_scopedToken == null){
    			return null;
    		}
    		var access = s_scopedToken.access;
    		var scopedToken = access.token.id;
    	    var stacksFinder = $resource(restPublicUrl + '/openstack/orchestration/stacks?region=fr1', {}, {
                'create': {
                	method: 'POST',
                	headers: {
                		'Content-Type': "application/json",
                	    'X-Auth-Token': scopedToken
                	}
                }
            });
            alertify.success("Launching new stack "+$scope.stack_name.value+"\u2026");
            stacksFinder.create($scope.recompute(), function(res){
            		alertify.success("Launching new stack... Success !");
            		var reg = /(.*)([0-9]+)$/;
            		var match = reg.exec($scope.stack_name.value);
            		if (match){
            			$scope.stack_name.value = match[1] + ((1*match[2])+1)
            		} else {
            			$scope.stack_name.value = $scope.stack_name.value + "_2";
            		}
            		$timeout(function() {
            		    $scope.$apply();
                    });
            		refreshStacks(true);
            }, function (err){
            	console.log("Error launching stack ",err)
                alertify.error("Failed to launch stack, sorry");
                refreshStacks(true);
            });
    };
    
    $scope.recompute = function(){
    	if ($scope.heat){
    		var params = {};
    		var groups = $scope.heat.guiGroups;
    		for (var x in groups){
    			for (var y in groups[x].inputs){
    			  var input = groups[x].inputs[y];
    			  params[input.attributes.name] = input.attributes.value;
    			}
    		}
    		return {stack_name: $scope.stack_name.value, template: $scope.heat.descriptor, parameters: params};
    	} else {
    		return { stack_name: $scope.stack_name.value, parameters: {}};	
    	}
    };

    loadHeatTemplate();
});


/**
 * Public API
 */

app.factory('PublicApi', function($resource, PublicApiUrl) {
    return $resource(PublicApiUrl, {}, {'list': {
                    method: 'GET',
                    isArray: true
                }});
});

app.controller('BssApiController', function($scope, $timeout, PublicApi, $sce, $anchorScroll, authenticationService, restPublicUrl){
	
	$scope.publicApi = {};
	
	$scope.tenantId = null;
	
	$scope.groupsDescriptions = {
		account: "Get / Update information about Business Accounts, unscoped token required",
		auth: "Get information about my Identity and my roles, unscoped token required",
		"no-auth": "Pubic calls without required authentication",
		"resource-scoped": "Calls authenticated with scoped tokens on a specific tenant"
	};
	
	$scope.trustHtml = function (data){
		return $sce.trustAsHtml( data );
	}
	
	$scope.result = {};
	
	$scope.scrollTo = function(anchor){
		$location.hash(anchor);
		$anchorScroll();
	};
	
	$scope.computeCurl = function( op, customerId ){
		var ret = 'curl -X'+ op.httpMethod +' -H X-Auth-Token:'+authenticationService.getUnscopedToken()+' '+ restPublicUrl;
		var rep;
		if (op.path.indexOf("/public/") == 0){
			rep = op.path.substring(7);
		} else {
			rep = op.path;
		} 
		if (customerId){
			rep = rep.replace("{customerId}", customerId);
			rep = rep.replace("{parentCustomerId}", customerId);
		}
		ret+=rep;
		if (op.httpMethod == 'PUT' || op.httpMethod == 'POST'){
			ret+=' -H Content-Type:application/json --data \'{}\'';	
		}
		return ret;
	}
	
	function fetch(){
		console.log("Loading public APIs...");
		PublicApi.list({}, function(data){
				console.log("Done loading public APIs.");
				var obj = {};
				for (var i = 0 ; i < data.length; i++){
						var x = data[i];
						var group = x.publicGroup;
						var grp = obj[group];
						if (grp == null){
							obj[group] = new Array();
							grp = obj[group];
						}
						grp.push(x);
				}
				$scope.publicApi = obj;
				$timeout(function() {
                    $scope.$apply();
                });
                return data;
		});
	};
		
	fetch();
});
