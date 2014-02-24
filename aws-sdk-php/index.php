<?php
require "vendor/autoload.php";
use Aws\Common\Enum\Region;
use Aws\S3\S3Client;
ini_set('memory_set',-1);
/* key ==> replace your Access_ID secret ==> replace your secret_key base_url ==> your leofs service address */

$client = S3Client::factory(array(
	"key" => "05236",
	"secret" => "802562235",
	"region" => Region::US_EAST_1,
	"scheme" => "http",
	'base_url' => 'http://localhost:8080'
));

try {
	echo "-------------Bucket List-------\n";

	// List buckets
	$buckets = $client->listBuckets()->toArray();
	foreach($buckets as $bucket){
		print_r($bucket);
	}

	echo "Create New Bucket\n";
	// Create bucket
	$result = $client->createBucket(array(
		"Bucket" => "test"
	));
	echo "Bucket Created Successfully \n";

	echo "Putting object into Bucket \n";
	// PUT object
	$client->putObject(array( "Bucket" => "test", "Key" => "key-test", "Body" => "Hello, world!" ));
	echo "Successfully created data file to testi \n";

	echo "Getting object from Bucket \n ";
	// GET object
	$object = $client->getObject(array( "Bucket" => "test", "Key" => "key-test" ));
	print($object->get("Body"));
	echo "Head object\n " ;
	
	// HEAD object
	$headers = $client->headObject(array( "Bucket" => "test", "Key" => "key-test" ));
	print_r($headers->toArray());
	print("File is uploading \n");
	
	// PUT file
	$client->putObject(array( "Bucket" => "test", "Key" => "README", "Body" => fopen('README', 'r') ));
	print("File Uploaded Successfully \n");
	
	// Download object file
	$headers = $client->headObject(array( "Bucket" => "test", "Key" => "README" ));
	print_r($headers->toArray());
	print("\n\n");// GET object file
	$object = $client->getObject(array( "Bucket" => "test", "Key" => "README", "SaveAs" => "README.copy" ));
	echo "File Successfully downloaded \n ";
	
	// copy Object file
	$result = $client->copyObject(array('Bucket' => 'test','CopySource' => "{'test'}/{'key-test'}", 'Key' => 'REAME.copy',));
	echo "File copied successfully \n";

	// List objects
	print("--------------------List Objects----------------- \n");
	$iterator = $client->getIterator('ListObjects', array( "Bucket" => "test" ));
	foreach ($iterator as $object) {
		echo $object['Key']."\t".$object['Size']."\t".$object['LastModified']."\n";
	}

	// DELETE object file
	$client->deleteObject(array( "Bucket" => "test", "Key" => "README" ));
	echo "File Deleted Successfully \n";
	echo "delete bucket \n";
	
	// delete bucket
	$result = $client->deleteBucket(array( "Bucket" => "test" ));
	echo "Bucket deleted Successfully \n ";
}
catch (\Aws\S3\Exception\S3Exception $e)
{
	// Exeception messages
	echo $e->getMessage();
}
?>
