<?php
require "vendor/autoload.php";
use Aws\Common\Enum\Region;
use Aws\S3\S3Client;
ini_set("memory_set",-1);
/* key ==> replace your Access_ID secret ==> replace your secret_key base_url ==> your leofs service address */

$client = S3Client::factory(array(
    "key" => "05236",
    "secret" => "802562235",
    "region" => Region::US_EAST_1,
    "scheme" => "http",
    "base_url" => "http://localhost:8080"
));

try {
    print "-------------Bucket List-------\n";

    // List buckets
    $buckets = $client->listBuckets()->toArray();
    foreach($buckets as $bucket){
        print_r($bucket);
    }

    // Create bucket
    print "Create New Bucket\n";
    $bucket_name="test";
    $result = $client->createBucket(array(
        "Bucket" => $bucket_name
    ));
    print "Bucket Created Successfully \n";

    // PUT object
    print "Putting object into Bucket \n";
    $client->putObject(array( "Bucket" => $bucket_name, "Key" => "key-test", "Body" => "Hello, world!" ));
    print "Successfully created data file to testi \n";


    // GET object
    print "Getting object from Bucket \n ";
    $object = $client->getObject(array( "Bucket" => $bucket_name, "Key" => "key-test" ));
    print($object->get("Body"));
    print "Head object\n " ;

    // HEAD object
    $headers = $client->headObject(array( "Bucket" => $bucket_name, "Key" => "key-test" ));
    print_r($headers->toArray());
    print("File is uploading \n");

    // PUT file
    $client->putObject(array( "Bucket" => $bucket_name, "Key" => "testFile", "Body" => fopen("../temp_data/testFile", "r") ));
    print("File Uploaded Successfully \n");

    // Download object file
    $headers = $client->headObject(array( "Bucket" => $bucket_name, "Key" => "testFile" ));
    print_r($headers->toArray());
    print("\n\n");

    // GET object file
    $object = $client->getObject(array( "Bucket" => $bucket_name, "Key" => "testFile", "SaveAs" => "testFile.copy" ));
    print "File Successfully downloaded \n ";

    // Copy Object file
    $result = $client->copyObject(array( "Bucket" => $bucket_name, "CopySource" => "/{$bucket_name}/testFile", "Key" => "testFile.copy",));
    print "File copied successfully \n";

    // List objects
    print("--------------------List Objects----------------- \n");
    $iterator = $client->getIterator( "ListObjects" , array( "Bucket" => $bucket_name ));
    foreach ($iterator as $object) {
        print $object["Key"]."\t".$object["Size"]."\t".$object["LastModified"]."\n";
    }

    // DELETE object file
    $client->deleteObject(array( "Bucket" => $bucket_name, "Key" => "testFile" ));
    print "File Deleted Successfully \n";
    print "delete bucket \n";

    // DELETE bucket
    $result = $client->deleteBucket(array( "Bucket" => $bucket_name ));
    print "Bucket deleted Successfully \n ";
}
catch (\Aws\S3\Exception\S3Exception $e)
{
    // Exeception messages
    print $e->getMessage();
}
?>
