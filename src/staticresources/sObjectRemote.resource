var sObject = function (sObjectType,fieldValues){
	//Set the sObjectType
	this.attributes = {sObjectType: sObjectType};

	//If field values were passed in to constructor populate the field values in the sObject
	if(fieldValues) {
		for(var key in fieldValues) {
			this[key] = fieldValues[key];
		}
	}
}

//---Insert Methods---
sObject.insert = function(sObjects,callbackOrOptions,callback){
	
	var objectsToInsert = sObject.buildArray(sObjects); //Create array of objects that will be inserted
	var objectStore = new Array(); //Create array that will store child objects of the sObject, these must be removed before DML
	var callback = sObject.setCallback(callbackOrOptions,callback); //Determine which argument is the callback function
	var options = sObject.setOptions(callbackOrOptions); //Set the options object

	//Prep the objects for DML by removing the unnecessary and adding necessary properties
	sObject.prepForDML(objectsToInsert,objectStore,'insert');

	//Perform the insert operation
	Visualforce.remoting.Manager.invokeAction(sObjectInsertMethodName, objectsToInsert, options, function(result, event){
        
		//Reattach the the child objects that were removed before the DML
		sObject.handleDMLResult(result,objectsToInsert,objectStore,'insert');

        //Call the provided callback function with result and event objects
       	callback(result,event);
       
   	},{escape: options.escape});
}

//Insert one instance of a sObject
sObject.prototype.insert = function(callbackOrOptions,callback){
	sObject.insert(this,callbackOrOptions,callback);
}

//---Query Method---
sObject.query = function(soql,callbackOrOptions,callback){
	var callback = sObject.setCallback(callbackOrOptions,callback);
	var options = sObject.setOptions(callbackOrOptions);

	//Perform the query
	Visualforce.remoting.Manager.invokeAction(sObjectQueryMethodName, soql, function(QueryResult, event){
        //Return array of queried sObjects
        var sObjects = [];

        //Populate list of sObjects if query was a success
        if(event){
        	for(var i = 0; i < QueryResult.sObjects.length; i++){
        		sObjects.push(new sObject(QueryResult.sObjectAttributes.sObjectType, QueryResult.sObjects[i]));
        	}
        }
       	
       	//Return array of queried sObjects to the callback
        callback(sObjects,event);

	},{escape: options.escape});
}

//---Update Methods---
sObject.update = function(sObjects,callbackOrOptions,callback){

	var objectsToUpdate = sObject.buildArray(sObjects);
	var objectStore = new Array();
	var callback = sObject.setCallback(callbackOrOptions,callback);
	var options = sObject.setOptions(callbackOrOptions);

	sObject.prepForDML(objectsToUpdate,objectStore,'update');
	
	//Perform the update operation
	Visualforce.remoting.Manager.invokeAction(sObjectUpdateMethodName, objectsToUpdate, options, function(result, event){

		//Convert result to object if necessary
		if(event.status && options.resultAsObject){
			result = sObject.convertResultToObject(result,objectsToUpdate);
		}

		sObject.handleDMLResult(result,objectsToUpdate,objectStore,'update');
       	callback(result,event);

   	},{escape: options.escape});
}

//Update one instance of a sObject
sObject.prototype.update = function(callbackOrOptions,callback){
	sObject.update(this,callbackOrOptions,callback);
}

//---Delete Methods---
sObject.del = function(sObjects,callbackOrOptions,callback){

	var objectsToDelete = sObject.buildArray(sObjects);
	var callback = sObject.setCallback(callbackOrOptions,callback);
	var options = sObject.setOptions(callbackOrOptions);
	var deleteObjects = new Array();

	//Construct a list of super simple objects that only have an Id attribute, as this is all that is needed for delete operation
	for(var i = 0; i < objectsToDelete.length; i++){
		deleteObjects.push({Id: objectsToDelete[i].Id});
	}

	//Perform the delete operation
	Visualforce.remoting.Manager.invokeAction(sObjectDeleteMethodName, deleteObjects, options, function(result, event){

		//Delete operation was success and if purge option was set to true, null object or clean out array
		if(event.status && options.purge){

			//If sObjects has length it was an array
			if(sObjects.length){
				
				var originalArrayLength = sObjects.length;

				//Add objects to the end of the array that were not deleted
				for(var i = 0; i < originalArrayLength; i++){
					if(result[i].success == false){
						sObjects.push(sObjects[i]);
					}
				}

				//Trim off original objects in the array, leaving only those objects that failed to delete
				sObjects.splice(0,originalArrayLength);

			}else{
				//Single sObject
				if(result[0].success == true){
					sObjects = null;
				}
			}
		}

		//Convert result to object if necessary
		if(event.status && options.resultAsObject){
			result = sObject.convertResultToObject(result,deleteObjects);
		}
		
       	callback(result,event);

   	},{escape: options.escape});
}

//Delete one instance of a sObject
sObject.prototype.del = function(callbackOrOptions,callback){
	sObject.del(this,callbackOrOptions,callback);
}

//---Utility Methods---
//If only one sObject is provided for DML it is converted to an array
sObject.buildArray = function(objects){
	//If objects has length its already an array
	if(objects.length){
		return objects;
	}else{
		//Single record, add it to array
		return new Array(objects);
	}
}

//Inspects the callbackOrOptions to see if it is a function (callback) or object (options), sets callback appropriately
sObject.setCallback = function(callbackOrOptions,callback){
	if(typeof callbackOrOptions == 'object'){
		return callback;
	}else{
		return callbackOrOptions;
	}
}

//Default options if none are set
sObject.setOptions = function(callbackOrOptions){
	if(typeof callbackOrOptions == 'object'){

		//Default escape option to true if it was not set
		if(callbackOrOptions.escape == 'undefined'){
			if(sObjectEscapeOverride == 'false'){
				callbackOrOptions.escape = false;
			}else{
				callbackOrOptions.escape = true;
			}
		}
		return callbackOrOptions;

	}else{
		//No options define. Default escape option to true if component option was not set to false
		if(sObjectEscapeOverride == 'false'){
			return {escape: false};
		}else{
			return {escape: true};
		}
	}
}

//Salesforce does not like DML on sObjects if they have child objects. Remove them for the dml operation
sObject.prepForDML = function(sObjects,objectStore,dmlType){

	for(var i = 0; i < sObjects.length; i ++){

		//Store the sObject we are currently processing in a var for easy access
		var sObject = sObjects[i];

		//Set sObjectType for INSERT operations
		if(dmlType == 'insert'){
			sObject.sObjectType = sObjects[i].attributes.sObjectType;
		}

		//Loop through sObjects keys and store any child objects in a childObjects object
		var childObjects = {};

		for(var key in sObject){
			if(typeof sObject[key] == 'object'){
				childObjects[key] = sObject[key];
				delete sObject[key];
			}
		}

		//Store the child objects in the objectStore array so they can be added back to the sObject after DML, http://jsperf.com/object-clone-vs-modify
		objectStore.push(childObjects);
	}
}

//Updated Id form inserted records and reattaches and child objects that where removed for the DML
sObject.handleDMLResult = function(result,sObjects,objectStore,dmlType){

	//Loop through results, update the Id for inserts, add back child objects that were removed for DML
    for(var i = 0; i < sObjects.length; i++){

    	//Remove the sObjectType property that may be present on the main sObject
    	delete sObjects[i]['sObjectType'];
    	
    	//If record was inserted successfully, update the id
    	if(dmlType == 'insert' && result[i].success){
    		sObjects[i].Id = result[i].id;
    	}

    	//Add the child objects back to the main sObject
    	var sObject = sObjects[i];
    	var childObjects = objectStore[i];

    	for(var key in childObjects[i]){
    		sObject[key] = childObjects[key];
    	}
    }
}

//Create save/delete result array to JavaScript object with the key as the record Id
sObject.convertResultToObject = function(result,sObjects){

	var resultObj = {};

	for(var i = 0; i < result.length; i++){
		var id = sObjects[i].Id;
		delete result[i]['id'];
		resultObj[id] = result[i];
	}
	return resultObj;
}