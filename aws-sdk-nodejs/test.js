var AWS = require('aws-sdk');
var fs = require('fs');
var bucket = 'test';
AWS.config.update({
  httpOptions: { proxy: 'http://localhost:8080' },
  accessKeyId: '05236', secretAccessKey: '802562235',
  region: 'us-east-1',
  endpoint: 'http://test.localhost:8080'
});
var s3 = new AWS.S3();

// Create bucket and create text objects
s3.createBucket({Bucket: bucket}, function(err,data) {
  if(err)
    console.log('Bucket creation error');
  else
    console.log('Bucket Created Successfully');
});

// Create text file
var params = {Bucket: bucket, Key: 'myKey', Body: 'Hello!', ContentType: 'text/plain', ContentEncoding: 'utf8'};
s3.putObject(params, function(err, data) {
  if (err)
    console.log(err);
  else
    console.log('File Created Successfully');

  // Multipart Upload
  var startTime = new Date();
  var partNum = 0;
  var fileKey = 'testFile';
  var buffer = fs.readFileSync('../temp_data/'+fileKey);
  var partSize = 1024 * 1024 * 5; // Minimum 5MB per chunk
  var numPartsLeft = Math.ceil(buffer.length / partSize);
  var maxUploadTries = 3;
  var multiPartParams = { Bucket: bucket, Key: fileKey, };
  var multipartMap = { Parts: [] };
  function completeMultipartUpload(s3, doneParams) {
    s3.completeMultipartUpload(doneParams, function(err, data) {
      if (err) {
        console.log('An error occurred while completing the multipart upload');
        console.log(err);
      }
      else {
        var delta = (new Date() - startTime) / 1000;
        console.log('Completed upload in', delta, 'seconds');
        console.log('Final upload data:', data);

        // Download File
        console.log('File Downloading has been started ');
        var stream = fs.createWriteStream('testFile.copy', { flags: 'w', mode: 0666 });
        s3.getObject({ Bucket: bucket, Key: fileKey}).
        on('httpData', function(chunk) {  stream.write(chunk); }).
        on('httpDone', function() { stream.end(); console.log('File Successfully downloaded  ');

        // List objects
        console.log('=====================File List==================== \n');
        s3.listObjects({Bucket: bucket}, function(err, data) {
          if (err) console.log(err);
          for (var index in data.Contents ) {
            var content = data.Contents[index];
            console.log('List Files : Key: ', content.Key, ' : ', content.LastModified , ' : ' , content.Size );
          }

          // Copy file
          s3.copyObject({ Bucket: bucket, CopySource: '/' + bucket + '/' + fileKey , Key: fileKey + '.copy' },
            function(err, data) {
              if(err)
                console.log('Error in copy object file :'+err);
              else
                console.log('File copied successfully');

              //re-list files
              console.log('=====================File Re-List====================/n');
              s3.listObjects({Bucket: bucket}, function(err, data) {
                for (var index in data.Contents ) {
                  var content = data.Contents[index];
                  console.log('List Files : Key: ', content.Key, ' : ', content.LastModified , ' : ' , content.Size );
                }

                //delete all  objects
                console.log('=====================File Deleted==================== \n');
                s3.listObjects({Bucket: bucket}, function(err, data) {
                  if (err) console.log(err);
                  for (var index in data.Contents ) {
                    var content = data.Contents[index];
                    console.log(' Files : Key: ', content.Key, ' : ', content.LastModified , ' : ' , content.Size + '  Deleted Successfully');
                    s3.deleteObject( {Bucket: bucket, Key: content.Key }, function(err, data){ if(err) console.log(err); } );
                  }
                  
                  //delete bucket
                  s3.deleteBucket({Bucket: bucket}, function(err, data) { if (err) console.log(err); else console.log('Bucket  Deleted'); } );
                });//Delete file block over
              }); // Re-List file block over
            }); // Copy file block over
          }); // List object block over
        }).send();//Else block over
      }
    });
  }

  function uploadPart(s3, multipart, partParams, tryNum) {
    var tryNum = tryNum || 1;
    s3.uploadPart(partParams, function(multiErr, mData) {
      if (multiErr){
        console.log('multiErr, upload part error:', multiErr);
        if (tryNum < maxUploadTries) {
          console.log('Retrying upload of part: #', partParams.PartNumber)
          uploadPart(s3, multipart, partParams, tryNum + 1);
        }
        else {
          console.log('Failed uploading part: #', partParams.PartNumber)
        }
        return;
      }
      multipartMap.Parts[this.request.params.PartNumber - 1] = { ETag: mData.ETag, PartNumber: Number(this.request.params.PartNumber) };
      console.log('Completed part', this.request.params.PartNumber);
      console.log('mData', mData);
      if (--numPartsLeft > 0) return; // complete only when all parts uploaded

      var doneParams = {
        Bucket: bucket,
        Key: fileKey,
        MultipartUpload: multipartMap,
        UploadId: multipart.UploadId
      };
      console.log('Completing upload...');
      completeMultipartUpload(s3, doneParams);
    });
  }

  // Multipart
  console.log('Creating multipart');
  s3.createMultipartUpload(multiPartParams, function(mpErr, multipart){
    if (mpErr) { console.log('Error!', mpErr); return; }
    console.log('Got upload ID', multipart.UploadId);

    // Grab each partSize chunk and upload it as a part
    for (var rangeStart = 0; rangeStart < buffer.length; rangeStart += partSize) {
      partNum++;
      var end = Math.min(rangeStart + partSize, buffer.length), partParams = { Body: buffer.slice(rangeStart, end), Bucket: bucket, Key: fileKey, PartNumber: String(partNum), UploadId: multipart.UploadId };
      
      // Send a single part
      console.log('Uploading part: #', partParams.PartNumber, ', Range start:', rangeStart);
      uploadPart(s3, multipart, partParams);
    }
  });

});
