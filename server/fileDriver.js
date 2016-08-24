var ObjectID = require('mongodb').ObjectID;

//Module to read and write to disk.
var fs = require('fs');

 //The constructor accepts a reference to the MongoDB database driver to use in the methods that follows.
 FileDriver = function(db) {
 	this.db = db;
 };

//looks through the files collection
FileDriver.prototype.getCollection = function(callback) {
	//in addition to the content of the file itself,
	//each file has an entry in the files collection which stores the file’s metadata including its location on disk.
	this.db.collection('files', function(error, file_collection) {
		if(error)
			callback(error);
		else
			callback(null, file_collection);
	});
};

//find a specific file
FileDriver.prototype.get = function(id, callback) {
	//fetches the files collection from the database
	this.getCollection(function(error, file_collection) {
		if (error)
			callback(error);
		else {
    		//The input to this function is a string representing the object’s _id
    		//Convert to a BSON ObjectID object.
    		var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$");
    		if (!checkForHexRegExp.test(id))
    			callback({error: "invalid id"});

            //finds a matching entity if one exists
            else file_collection.findOne({'_id':ObjectID(id)}, function(error,doc) {
            	if (error)
            		callback(error);
            	else
            		callback(null, doc);
            });
        }
    });
};

//simplifies the server code by abstracting the file handling away from index.js.
FileDriver.prototype.handleGet = function(req, res) {
	//Fetches the file entity from the database via the supplied id.
	var fileId = req.params.id;
	if (fileId) {
		//Adds the extension stored in the database entry to the id to create the filename
		this.get(fileId, function(error, thisFile) {
			if (error) {
				res.sendStatus(400, error);
			}
			else {
				if (thisFile) {
        			//Stores the file in the local uploads directory.
        			var filename = fileId + thisFile.ext;
        			var filePath = './uploads/'+ filename;

                    //Calls sendfile() on the response object
                    //this method knows how to transfer the file and set the appropriate response headers.
                    res.sendfile(filePath);
                }
                else
                	res.sendStatus(404, 'file not found');
            }
        });        
	} else {
		res.sendStatus(404, 'file not found');
	}
};

//save new file
FileDriver.prototype.save = function(obj, callback) {
	this.getCollection(function(error, the_collection) {
		if(error)
			callback(error);
		else {
			obj.created_at = new Date();

			//inserts a new object into the files collection.
			the_collection.insert(obj, function() {
				callback(null, obj);
			});
		}
	});
};

//wrapper for 'save' function for the purpose of creating a new file entity and returning id alone.
FileDriver.prototype.getNewFileId = function(newobj, callback) { //2
	this.save(newobj, function(err,obj) {
		if (err) {
			callback(err);
		} 
		else {
			// returns only _id from the newly created object.
			callback(null,obj._id);
		}
	});
};

//creates a new object in the file collection using the Content-Type to determine the file extension
//and returns the new object’s _id.
FileDriver.prototype.handleUploadRequest = function(req, res) {

	//looks up the value of the Content-Type header which is set by the mobile app
	var ctype = req.get("content-type");

    //tries to guess the file extension based upon the content type.
    //For instance, an image/png should have a png extension
    var ext = ctype.substr(ctype.indexOf('/')+1);
    if (ext) {
    	ext = '.' + ext;
    } else {
    	ext = '';
    }
    //saves Content-Type and extension to the file collection entity
    this.getNewFileId({'content-type':ctype, 'ext':ext}, function(err,id) {
    	if (err) {
    		res.sendStatus(400, err);
    	} 
    	else { 	         
    		//Create a filename by appending the appropriate extension to the new id
    		var filename = id + ext;

            //The designated path to the file is in the server’s root directory, under the uploads sub-folder.
            //__dirname is the Node.js value of the executing script’s directory.
            filePath = __dirname + '/uploads/' + filename;

            //fs includes writeStream which — as you can probably guess — is an output stream.
            var writable = fs.createWriteStream(filePath);

	     	//The request object is also a readStream so you can dump it into a write stream using the pipe() function.
	     	//These stream objects are good examples of the Node.js event-driven paradigm
	     	req.pipe(writable);

	     	//associates stream events with a callback.
	     	//In this case, the readStream’s end event occurs when the pipe operation is complete,
	     	//and here the response is returned to the Express code with a 201 status and the new file _id.
	     	req.on('end', function (){
	     		res.sendStatus(201, {'_id':id});
	     	});
	     	//If the write stream raises an error event then there is an error writing the file.
	     	//The server response returns a 500 Internal Server Error response along with the appropriate filesystem error.
            writable.on('error', function(err) {
	     		res.sendStatus(500, err);
            });
        }
    });
};

exports.FileDriver = FileDriver;