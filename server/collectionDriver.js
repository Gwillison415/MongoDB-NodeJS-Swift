//Use ObjectID function of mongoDB module.
//ObjectID (BSON-type) is just like primary key that mongoDB automatically create for optimized lookup and insertion
var ObjectID = require('mongodb').ObjectID;
//Constructor method, store mongoDB client
CollectionDriver = function(db) {
	this.db = db;
}

//"getCollection" method to obtain a Mongo collection by name
CollectionDriver.prototype.getCollection = function(collectionName, callback) {
	//fetches the collection object and returns the collection, or an error, to the callback.
	this.db.collection(collectionName, function(error, the_collection) {
		if( error )
			callback(error);
		else
			callback(null, the_collection);
	});
};

//"findAll" method returns all of the found objects.
CollectionDriver.prototype.findAll = function(collectionName, callback) {
	//Get the collection
	this.getCollection(collectionName, function(error, the_collection) {
		if( error )
			callback(error);
		else {
    		//find() returns a data cursor that can be used to iterate over the matching objects.
    		//find() can also accept a selector object to filter the results. 
    		//toArray() organizes all the results in an array and passes it to the callback
    		the_collection.find().toArray(function(error, results) {
    			if( error )
    				callback(error);
    			else
    				callback(null, results);
    		});
    	}
    });
};

//obtains a single item from a collection by its _id.
CollectionDriver.prototype.get = function(collectionName, id, callback) {
	//call first obtains the collection object then performs a findOne against the returned object.
	this.getCollection(collectionName, function(error, the_collection) {
		if (error)
			callback(error);
		else {
	        var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$");
			//ObjectID require appropriate hex string or it will return an error
			//This doesn’t guarantee there is a matching object with that _id, but it guarantees that ObjectID will be able to parse the string
	        if (!checkForHexRegExp.test(id))
	        	callback({error: "invalid id"});
	        else
	        {
	        	//ObjectID() takes a string and turns it into a BSON ObjectID to match against the collection
	            the_collection.findOne({'_id':ObjectID(id)}, function(error,doc) {
	            	if (error)
	            		callback(error);
	            	else
	            		callback(null, doc);
	            });
	        }
	    }
	});
};

//save new object
CollectionDriver.prototype.save = function(collectionName, obj, callback) {
	//retrieves the collection object
    this.getCollection(collectionName, function(error, the_collection) {
    	if( error )
    		callback(error)
    	else {
    		//adds a field to record the date it was created
	        obj.created_at = new Date();
	        //insert the modified object into the collection
	        //insert automatically adds _id to the object
	        the_collection.insert(obj, function() {
	        	callback(null, obj);
	        });
    	}
	});
};

//update a specific object
CollectionDriver.prototype.update = function(collectionName, obj, entityId, callback) {
	//retrieves the collection object
    this.getCollection(collectionName, function(error, the_collection) {
        if (error)
        	callback(error);
        else {
        	//convert to a real obj id
            obj._id = ObjectID(entityId); 
            //adds an updated_at field with the time the object is modified
            obj.updated_at = new Date();
            //insert the modified object into the collection
            the_collection.save(obj, function(error,doc) {
                if (error)
                	callback(error);
                else
                	callback(null, obj);
            });
        }
    });
};

//delete a specific object
CollectionDriver.prototype.delete = function(collectionName, entityId, callback) {
	//retrieves the collection object
    this.getCollection(collectionName, function(error, the_collection) {
        if (error)
        	callback(error);
        else {
        	//call remove() with the supplied id 
            the_collection.remove({'_id':ObjectID(entityId)}, function(error,doc) {
                if (error)
                	callback(error);
                else
                    callback(null, doc);
            });
        }
    });
};

//declares the exposed, or exported, entities to other applications that list collectionDriver.js as a required module.
exports.CollectionDriver = CollectionDriver;
