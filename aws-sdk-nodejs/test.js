var AWS = require('aws-sdk');
AWS.config.update({ 
        httpOptions: { proxy: 'http://localhost:8080' }, 
        accessKeyId: "05236", secretAccessKey: "802562235", 
        region: "us-east-1", 
        endpointi: "http://test.localhost:8080"
        });
var s3 = new AWS.S3();
//create bucket and create text objects        
        s3.createBucket({Bucket: 'test'}, function() {
                var params = {Bucket: 'test', Key: 'myKey', Body: 'Hello!', ContentType: 'text/plain', ContentEncoding: 'utf8'};                
                s3.putObject(params, function(err, data) {                        
                        if (err)                                
                            console.log(err)                        
                        else                                
                            console.log("Successfully uploaded data to test/myKey");                
                });
 
        });
 
//List objects
        s3.listObjects({Bucket: 'test'}, function(err, data) {
        for (var index in data.Contents ) {
                var content = data.Contents[index];
                console.log("List Files : Key: ", content.Key, ' : ', content.LastModified , ' : ' , content.Size );
                 }
        });
//List buckets
        s3.listBuckets(function(err, data) {
        for (var index in data.Buckets) {
                var bucket = data.Buckets[index];
                console.log("Bucket: ", bucket.Name, ' : ', bucket.CreationDate);
                 }
        });
