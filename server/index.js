
var http = require('http');

var express = require('express');

var path = require('path');
// add the following line to the top of your index.js
var bodyParser = require('body-parser');

var MongoClient = require('mongodb').MongoClient;
var Server = require('mongodb').Server;
var CollectionDriver = require('./collectionDriver').CollectionDriver;

var FileDriver = require('./fileDriver').FileDriver;

var app = express();
//Use app at port 3000 by default
app.set('port', process.env.PORT || 3000);

//specifies where the view templates live
app.set('views', path.join(__dirname, 'views'));
//sets Jade as the view rendering engine.
app.set('view engine', 'jade');


//This tells Express to parse the incoming body data; if it’s JSON, then create a JSON object with it.
//By putting this call first, the body parsing will be called before the other route handlers
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

//assumes the MongoDB instance is running locally on the default port of 27017
var mongoHost = 'localHost';
var mongoPort = 27017;
var fileDriver;
var collectionDriver;

//creates a new MongoClient 
var mongoClient = new MongoClient(new Server(mongoHost, mongoPort));

/* Alternative
var url = 'mongodb://localhost:27017/MyDatabase';
// Use connect method to connect to the server
MongoClient.connect(url, function(error, db) {
	if (error) {
		console.error("Unable to connect to MongoDB. Please make sure mongod is running on %s.", url);
		process.exit(1);
	}
	console.log("Connected to MongoDB successfully.");
	collectionDriver = new CollectionDriver(db);
});
*/


//establish a connection
mongoClient.open(function(err, mongoClient) {
	//most likely failed because haven’t yet started your MongoDB server
	if (!mongoClient) {
		console.error("Error! Exiting... Must start MongoDB first");
		process.exit(1);
	}
	//open "MyDatabase" database, a MongoDB instance can contain multiple databases, all which have unique namespaces and unique data
	var db = mongoClient.db("MyDatabase");

  	fileDriver = new FileDriver(db);

	collectionDriver = new CollectionDriver(db); //F
});


//Tell express to use the middleware express.static which serves up static files in response to incoming requests.
//path.join(__dirname, 'public') maps the local subfolder public to the base route "/"; it uses the Node.js path module to create a platform-independent subfolder string.
app.use(express.static(path.join(__dirname, 'public')));


/*Using http module
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end('<html><body><h1>Hello World</h1></body></html>');
}).listen(3000);
console.log('Server running on port 3000.');
*/

/*Using simple route of Express
//route handler
app.get('/', function (req, res) {
  res.send('<html><body><h1>Hello World</h1></body></html>');
});

app.get('/:a?/:b?/:c?', function (req,res) {
	res.send(req.params.a + ' ' + req.params.b + ' ' + req.params.c);
});
*/

//Putting this before the generic /:collection routing means that
//files are treated differently than a generic files collection
app.use(express.static(path.join(__dirname, 'public')));
app.get('/', function (req, res) {
	res.send('<html><body><h1>Hello World</h1></body></html>');
});
app.post('/files', function(req,res) {
	fileDriver.handleUploadRequest(req,res);
});
app.get('/files/:id', function(req, res) {
	fileDriver.handleGet(req,res);
});


//call the collectionDriver.findAll and collectionDriver.get methods respectively
//and return either the JSON object or objects, an HTML document, or an error depending on the result.
app.get('/:collection', function(req, res) {
	//get params of routes
	var params = req.params;
	//In this case, define the endpoint to match any URL to a MongoDB collection using findAll of CollectionDriver
	collectionDriver.findAll(req.params.collection, function(error, objs) {
		if (error) {
			res.sendStatus(400, error);
		}
	  	//checks if the request specifies that it accepts an HTML result in the header
	  	else {
	  		if (req.accepts('html')) {
	  			//stores the rendered HTML from the data.jade template in response
	  			//This simply presents the contents of the collection in an HTML table.
	  			res.render('data',{objects: objs, collection: req.params.collection}); //F
	  		} else {
	  			//By default, web browsers specify that they accept HTML in their requests.
	  			//When other types of clients request this endpoint such as iOS apps using NSURLSession,
	  			//this method instead returns a machine-parsable JSON document
	  			res.set('Content-Type','application/json');
	  			res.sendStatus(200, objs);
	  		}
	  	}
	  });
});

//"collection" and "entity" is a params, not a "collection" or "entity" like the way express use when don't have ":" sign
//collection name and entity _id.
app.get('/:collection/:entity', function(req, res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if (entity) {
		//request the specific entity
		collectionDriver.get(collection, entity, function(error, objs) {
			if (error) {
				res.sendStatus(400, error);
			}
			else {
	       		//return entity as a JSON document 
	       		res.sendStatus(200, objs);
	       	}
	       });
	}
	else {
		res.sendStatus(400, {error: 'bad url', url: req.url});
	}
});

//inserts the body as an object into the specified collection by calling save()
app.post('/:collection', function(req, res) {
	//object can be passed directly to the driver code as a JavaScript object by called "app.use(express.bodyParser());"
	var object = req.body;
	var collection = req.params.collection;
	collectionDriver.save(collection, object, function(err,docs) {
		if (err){
			res.sendStatus(400, err);
		}
		else {
			//returns the success code of HTTP 201 when the resource is created.
			res.sendStatus(201, docs);
		}
	});
});

//match on the collection name and _id as shown
app.put('/:collection/:entity', function(req, res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if (entity) {
    	//passes the JSON object from the body to the new collectionDriver‘s update() method
    	collectionDriver.update(collection, req.body, entity, function(error, objs) {
    		if (error) {
    			res.sendStatus(400, error);
    		}
    		else {
    			//The updated object is returned in the response,
    			//so the client can resolve any fields updated by the server such as updated_at.
    			res.sendStatus(200, objs);
    		}
    	});
    } else {
    	var error = { "message" : "Cannot PUT a whole collection" };
    	res.sendStatus(400, error);
    }
});

//match on the collection name and _id as shown
app.delete('/:collection/:entity', function(req, res) {
	var params = req.params;
	var entity = params.entity;
	var collection = params.collection;
	if (entity) {
    	//pass the parameters to collectionDriver‘s delete() method 
    	collectionDriver.delete(collection, entity, function(error, objs) {
    		if (error) {
    			res.sendStatus(400, error);
    		}
    		else {
    			res.sendStatus(200, objs);
    		}
    	});
    } else {
    	var error = { "message" : "Cannot DELETE a whole collection" };
    	res.sendStatus(400, error);
    }
});

app.use(function (req,res) {
	res.render('404', {url:req.url});
});


http.createServer(app).listen(app.get('port'), function(){
	console.log('Express server listening on port ' + app.get('port'));
});