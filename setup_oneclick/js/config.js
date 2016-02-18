'use strict';

var environment = "prd1" ;
//environment = "local" ;
//environment = "dev38" ;
//environment = "stg0" ;

var app = angular.module('dashboardApp');

function buildConfigForUrl(horseUrl, consoleUrl){
   var publicURL = horseUrl+"/public";
   app.constant('restKeystoneUrl', horseUrl+'/kspublic/keystone');
   app.constant('restPublicUrl', publicURL);
   // public API documentation
   app.constant('PublicApiUrl', publicURL+'/apidocs/public.api.notes.json');
   app.constant('ConsolePublicUrl', consoleUrl)
}

function buildConfigForTestEnvironment(dev3x){
   var horseUrl = 'https://horse-'+dev3x+'.cwpriv.net/rest';
   var consoleUrl = 'http://console-'+dev3x+'.cwpriv.net'
   buildConfigForUrl(horseUrl, consoleUrl);
}


function buildForProduction(){
	  // URL for Keystone
	  app.constant('restKeystoneUrl', 'https://identity2.fr1.cloudwatt.com');

	  var publicURL = 'https://bssapi.fr1.cloudwatt.com';
      // URL for public API
      app.constant('restPublicUrl', publicURL);

      // public API documentation
      app.constant('PublicApiUrl', publicURL+'/apidocs/public.api.notes.json');
      
      app.constant('ConsolePublicUrl', 'https://console.cloudwatt.com')
}

function buildForStg0(){
	  // URL for Keystone
	  app.constant('restKeystoneUrl', 'https://identity2.fr0.cwpriv.net');

	  var publicURL = 'https://bssapi.fr0.cwpriv.net';
      // URL for public API
      app.constant('restPublicUrl', publicURL);

      // public API documentation
      app.constant('PublicApiUrl', publicURL+'/apidocs/public.api.notes.json');
      
      app.constant('ConsolePublicUrl', 'https://console.cwpriv.net')
}



switch (environment){
case "prd1":
case "production":
	buildForProduction();
	break;
case "stg0":
case "promote":
case "staging":
	buildForStg0();
	break;
case "local":
case "localhost":
	 buildConfigForUrl("http://127.0.0.1:9479/rest", 'https://console.cloudwatt.com');
	 break;
default:
	buildConfigForTestEnvironment(environment);
}

//buildConfigForUrl("http://127.0.0.1:9479/rest", 'https://console.cloudwatt.com');

