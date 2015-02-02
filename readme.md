sObject-Remote
======

**sObject-Remote** is a small JavaScript library for simplifying DML operations on sObjects when using the JavaScript Remoting feature of Visualforce. Here is a tasty little preview that creates and inserts a new Account record:

```js
var acct = new sObject('Account',{Name: 'test', Industry: 'Aerospace'});

acct.insert(function(result,event){
	console.log(result[0].Id);
});
```
This is a very new library and the current status should definitely be considered **Beta**. Options, syntax, and method names may change in the near term based on bugs and community feedback. Please report any issues you come across and I'll get them fixed as soon as possible, or feel free to fix and submit pull requests as well.

## Features

* Super simple sObject management for JavaScript
* Currently supports 4 basic CRUD operations (more DML operations to come)
* Works with any JavaScript framework
* No 3rd party JavaScript library dependencies

## Setup

To use the **sObject-Remote** library you can pull the code from this repository to your target org or you can install the unmanaged package with this link: [sObject-Remote Unmanaged Package](https://login.salesforce.com/packaging/installPackage.apexp?p0=04ti000000050sf).

Once installed you will need to add the sObjectRemote Visualforce Component to your page. This includes everything you need to get started. Be sure to add the component before any other JavaScript files that may use the **sObject-Remote** library.

```html
<apex:page>
	<c:sObjectRemote/>
	<script type="text/javascript" src="app.js"/>
	<!-- Rest of page below -->
</apex:page>
```	

#### Component Attributes

* `escape` - This library defaults all JavaScript Remoting calls to be escaped, `true`. If you are in a trusted environment with trusted users you may set this default to `false` and all JavaScript Remoting calls will be unescaped. Any escape option set in a specific sObject() operation will override this component attribute.

## Usage

### Create New - new sObject(sObjectAPIname,[fieldValues]);

You can create an sObject variable in two ways. The first requires two arguments, the API name of the sObject and a key value pair object of field names and values.

```js
var acct = new sObject('Account',{Name: 'TehNrd Industries', BillingCity: 'Seattle'});
```

The second option is to only provide the API name of the sObject and populate the field values with dot or bracket notation.

```js
var acct = new sObject('Account');
acct.Name = 'TehNrd Industries';
acct.BillingCity = 'Seattle';
acct['PostalCode'] = '98119';
```
Now that we have created our Account sObject we are ready to insert it.

### Insert - sObject.insert(sObject || sObjectArray,[dmlOptions],callback);

The first argument for ```sObject.insert()``` is always a single sObject or an array of sObjects. The last argument is always the callback function that will process the results of the insert. There is also a third, optional, argument for dmlOptions and other options specific to this library. The dmlOptions argument will be the second argument if present and the callback function will be the last argument. See the section below on DML Options.

##### Insert our Account 
```js
//If inserting one or many sObjects
sObject.insert(acct,function(result,event){
	//Handle results, see call back section for more information
});

//Or if inserting one sObject only we can call the insert method directly on that variable/sObject. 
acct.insert(function(result,event){
	//Handle result, see call back section for more information
});
```

### Query - sObject.query(queryString,callback);

There are two arguments required by the `sObject.query()` method. The first is the SOQL query string and the second is a callback function that will handle the records returned by the query. In the callback function the sOjects argument is an array of sObject records and the event argument is the standard [event](http://www.salesforce.com/us/developer/docs/pages/Content/pages_js_remoting.htm#handling_remote_response) object returned by a JavaScript Remoting call.

```js
sObject.query('select Id, Name, Owner.Name from Account where Industry = \'Aerospace\' limit 5',function(sObjects,event){
	//Loop through the records returned by the query
	for(var i = 0; i < sObjects.length; i++){
		console.log(sObjects[i]);
	}
});
```

### Update - sObject.update(sObject || sObjectArray,[dmlOptions],callback);

Updating a sObject is very similary to inserting a sObject. Notice here that we changed the variable name of the first callback argument to better describe the type of objects being returned.

```js
var acctsToUpdate = new Array();

//Query some accounts in which we want to change the Industry field
sObject.query('select Industry from Account where Industry = \'Planes and Spaceships\'',function(accts,event){
	if(event.status){
		for(var i = 0; i < accts.length; i++){
			//Change the Industry add to array we will update
			accts[i].Industry = 'Aerospace';
			acctsToUpdate.push(accts[i]);
		}
	}else{
		//Error handling
	}
});

/*Pretend there is a long break here and these are two different operations. Or if you want this to update 
immediately after the query it should be placed in the callback function of the query*/

//Update the accounts
sObject.update(acctsToUpdate,function(results,event){
	if(event.status){
		//All good, update success
	}else{
		//Error handling.
	}
});
```

### Upsert - sObject.del(sObject || sObjectArray,[dmlOptions],callback);

Upsert follows similar structures as insert and updates but in addition you have the option to send externalIds.

```js
//init a account
var acct = new sObject('Account');
acct.Name = 'TehNrd Industries';
acct.BillingCity = 'Seattle';
acct.My_External_Id__c = '12345';

sObject.upsert(acct,function(results,event){
	if(event.status){
		//All good, update success
	}else{
		//Error handling.
	}
});
```

### Delete - sObject.del(sObject || sObjectArray,[dmlOptions],callback);

Delete follows the same structure as inserts and updates. Even though you pass an entire sObject or array of sObjects to the `sObject.delete()` method the sObject-Remote library will only send the Id values to the server as this is all that is needed for a delete operation and therefore also improves performance. In this example we also set some DML options to allow partial success of the records being deleted.

It is **important** to note the method name for delete is `del`. This is because delete is a reserved keyword in JavaScript.

```js
var acctsToDelete = new Array();

//Query some accounts that are flagged for deletion
sObject.query('select Id from Account where Flagged_for_Delete__c = true',function(accts,event){
	if(event.status){
		acctsToDelete = accts;
	}else{
		//Error handling
	}
});

//Pretend there is a long break here and these are two different operations

//Create a DML options object
var dmlOptions = {optAllOrNone: false};

//Do the delete
sObject.delete(acctsToDelete,dmlOptions,function(results,event){
	if(event.status){
		//Inpect the results object to determine which accounts were successfully deleted
	}else{
		//Error handling.
	}
});
```
### Callback

#### Query
The callback function for a query has two arguments. The first is an Array of sObject objects which is the result of the query. An sObject is simply the JSON representation of a salesforce.com standard or custom object with a little extra functionality added on such as the insert() and update() instance methods that can be called on an sObject for easier DML. The second argument is the JavaScript Remoting event object and it can help you determine if the remoting call was successful. You can learn more about the event object [here](http://www.salesforce.com/us/developer/docs/pages/Content/pages_js_remoting.htm#handling_remote_response). Make note that you can name these arguments to what ever you want to make the code more understandable as the only thing that matters is the order.

#### Insert, Update, and Delete
The callback function for inserts, updates, and deletes also has two arguments. The first is an array of SaveResult or DeleteResult objects. You can learn more about these objects in the Apex Reference Guide [here](http://www.salesforce.com/us/developer/docs/apexcode/index.htm). Below is and example of what this may look like if you set the DML option `optAllOrNone` to false and their is partial success.

```js
[{success:true,id:"001i0000003WM2lAAG"},
{success:true,id:"001i0000003WM2mAAG"},
{success:false,
 errors:[
 			{status:"FIELD_CUSTOM_VALIDATION_EXCEPTION",message:"This account is locked and cannot be updated."}
 		]
}] 
```

The second argument in the callback is the JavaScript Remoting event object and it can help you determine if the remoting call was successful. You can learn more about the event object here: [Handling the Remote Response](http://www.salesforce.com/us/developer/docs/pages/Content/pages_js_remoting.htm#handling_remote_response). 

### DML Options / Options
This is a JavaScript object that allows you to set DML options which you can learn more about [here](http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_methods_system_database_dmloptions.htm). Let's say we want to update a list of Lead records, allow partial success, and also force assignment rules to run.

```js
var leads = //List of sObjects, queried or inserted

//Create a DML options object
var dmlOpt = {
	optAllOrNone: false,
	useDefaultRule: true
};

//Update leads and pass in dmlOptions object
sObject.update(leads,dmlOpt,function(result,event){
	if(event.status){
		//Inspect result object to see which leads were updated successfully
	}else{
		//error handling
	}
});
```

#### Other Options

In addition to DML Options this object can take special values unique to **sObject-Remote**.

* `escape` - `true` or `false` Sets the escape option on the JavaScript Remoting call to control if response is escaped. Default to `true`.
* `purge` - `true` or `false` For Deletes only. If the delete for a single sObject is successful it will set the original sObject to null. If Delete was an array of sObjects it will remove successfully deleted sObjects from the original array. Defaults to `false`.
* `resultAsObject` - `true` or `false` Instead of the result object being returned as an array of SaveResult/DeleteResults objects this will return a JavaScript object with the record Id as the key and the value will be the result object. Depending on the use case this may make it easier to identity success and failures. This option only works with **update** and **delete** methods. Defaults to `false`. Example below:

```js
//This is what a normal result array would look like
[{success:true,id:"001i0000003WM2lAAG"},{success:true,id:"001i0000003WM2mAAG"}];

//When the resultAsObject option is set to true
{001i0000003WM2lAAG:{success:true},
001i0000003WM2mAAG:{success:true}} 
```

* `externalId` - Lets you define external Id field API name, you can also define this for multiple objects by doing something like `Account=MyAccountExternalId__c,Contact=MyContactExternalId__c`

### Tips, Tricks, and FAQ

#### Case sensitivity

Don't forget JavaScript is case sensitive and salesforce.com returns the API names as they are defined by the setup metadata. Let's say you have the following query:

```js
sObject.query('select name, industry from account limit 1',function(acct,event){ //Query will work fine
	console.log(acct[0].name); //Will output undefined as Salesforce returns the name as 'Name'
	console.log(acct[0].Name); //Will output correct value		
});
```
This is also true for custom fields so be sure the name is exactly the same as what is defined in the setup areas of salesforce.com.

#### Extra Object Properties

JavaScript makes it easy to add dynamic properties to an object but you need to take special care when doing this with sObjects. Salesforce.com will not be able to handle DML operations if you add invalid properties. To avoid problems **never add extra properties to the top level object** as this will cause errors. Instead add extra attributes to a child object. Every `sObject` already comes with a child object called `attributes` that can be used for this purpose. A classic example is keeping track of whether an object is selected. 

```js
sObject.query('select Name, Industry from Account limit 10',function(accts,event){ 
	//Default the selected property to false
	for(var i = 0; i < accts.length; i++){
		accts[i].attributes.selected = false; // GOOD

		//accts[i].selected = false; !!! BAD DO NOT DO THIS !!!
	}
});
```

#### Variable Name Conflict

This library creates a global variable called `sObject`. You should not have any other variables in your script with this name. This may be an issue and I am open to community feedback regarding this.

#### How is this different from [Force.com JavaScript REST Toolkit](https://github.com/developerforce/Force.com-JavaScript-REST-Toolkit)?

Ya...so it's really not that different. I didn't realize the library already existed before I started working on this but some of the difference are:

* sObject-Remote is focused only on Visualforce JavaScript Remoting
* Does bulk DML. Insert, update, and delete many records at once. The JavaScript REST Toolkit is, in its purest form, a wrapper for the REST API and the REST API currently only supports single record DML for many operations.
* Doesn't require a 3rd party library like jQuery, 
* Supports DML Options (maybe I missed it, but didn't see this in the Toolkit)
* Has some other nifty utility options

**sObject-Remote** is another tool in the toolbox depending on the functionality you require. Both are great so play with each and choose which ever meets your requirements, are most comfortable with, or meshes well with your development style.