## This code supports "aws-sdk v1.9.5"
require "aws-sdk"

Endpoint = "localhost"
Port = 8080
# set your s3 key
AccessKeyId = "05236"
SecretAccessKey = "802562235"
Bucket = "test"
class LeoFSHandler < AWS::Core::Http::NetHttpHandler
  def handle(request, response)
    request.port = ::Port
    super
  end
end

SP = AWS::Core::CredentialProviders::StaticProvider.new(
{
    :access_key_id     => AccessKeyId,
    :secret_access_key => SecretAccessKey
})

AWS.config(
  access_key_id: AccessKeyId,
  secret_access_key: SecretAccessKey,
  s3_endpoint: Endpoint,
  http_handler: LeoFSHandler.new,
  credential_provider: SP,
  s3_force_path_style: true,
  use_ssl: false
)

s3 = AWS::S3.new

# create bucket
	#s3.buckets.create(Bucket)
	print "Bucket Created Successfully \n"

# get bucket
	bucket = s3.buckets[Bucket]

# create a new object
	object = bucket.objects.create("image", "value")
	print "Successfully created text file \n"
# retrieve an object
	print "Your object is :"
	object = bucket.objects["image"]

 # insert an object
	object.write(
		file: "test.txt",
		content_type: "text/plain"
	)
# read image
	image = object.read
	p image
	print "File MetaData\n"
# HEAD
    metadata = object.head
    p metadata

# Multi part
    
    file_path_for_multipart_upload = '32M.dat'
    print "File is being upload : \n "
    open(file_path_for_multipart_upload) do |file|
      counter = file.size / 20242880
      uploading_object = bucket.objects[File.basename(file.path)]
      uploading_object.multipart_upload do |upload|
        while !file.eof?
	  puts " #{upload.id} \t\t  #{counter} " 
	  counter -= 1
          upload.add_part(file.read 20242880) ## 20MB ##
          p('Aborted') if upload.aborted?
        end
      end
    end
   print "File Uploaded Successfully \n"
    large_object = bucket.objects["32M.dat"]
# HEAD    
	metadata = large_object.head 
	p metadata

# GET(To be handled at the below rescure block)
    image = object.read
    p image

# Copy object
	bucket.objects["32M.dat.copy"].copy_from("32M.dat") 
	print "File copied successfully \n"

# Rename object or move object
        bucket.objects["image"].move_to("new_image");
	#bucket.objects["image"].rename_to("new_image");
	print "File rename or move Successfully \n"

# show objects in the bucket
	print "----------List Files--------- \n"
	bucket.objects.with_prefix("").each do |obj|
          puts "  #{obj.key} \t #{obj.content_length} " 
	end

#Download File
	File.open('32M.dat.copy', 'wb') do |file|
	bucket.objects['32M.dat'].read do |chunk|
	    file.write(chunk)
	  end
	print "File Downloaded Successfully \n "	
	end

# Delete objects one by one
	  print "--------------------Delete Files-------------------- \n"
        bucket.objects.with_prefix("").each do |obj|
		obj.delete
        	print " #{obj.key} \t\t File Deleted Successfully.. \n" 
        end
       bucket.clear!  #clear the versions only

#       bucket.delete
       print "Bucket deleted Successfully \n"
