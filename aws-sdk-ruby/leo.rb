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
begin
  # Create bucket
  s3.buckets.create(Bucket)
  print "Bucket Created Successfully \n"

  # Get bucket
  bucket = s3.buckets[Bucket]

  # Get-Put ACL
  puts "#####Default ACL#####"
  p "Owner ID : #{bucket.acl.owner.id} "
  p "Owner Display name : #{bucket.acl.owner.display_name} "
  bucket.acl.grants.each do | grant |
    p "Bucket ACL is :  #{grant.permission.name} "
    p "Bucket Grantee URI is : #{grant.grantee.uri} "
  end

  puts "#####:public_read ACL#####"
  p "Owner ID : #{bucket.acl.owner.id} "
  p "Owner Display name : #{bucket.acl.owner.display_name} "
  p bucket.acl.owner.id
  print "Bucket ACL Successfully changed to 'public-read'.\n"
  bucket.acl.grants.each do | grant |
    p "Bucket ACL is :  #{grant.permission.name} "
    p "Bucket Grantee URI is : #{grant.grantee.uri} "
  end

  puts "#####:public_read_write ACL#####"
  p "Owner ID : #{bucket.acl.owner.id} "
  p "Owner Display name : #{bucket.acl.owner.display_name} "
  p bucket.acl.owner.id
  print "Bucket ACL Successfully changes to 'public-read-write'.\n"
  bucket.acl.grants.each do | grant |
    p "Bucket ACL is :  #{grant.permission.name} "
    p "Bucket Grantee URI is : #{grant.grantee.uri} "
  end

  puts "#####:private ACL#####"
  bucket.acl = :private
  p "Owner ID : #{bucket.acl.owner.id} "
  p "Owner Display name : #{bucket.acl.owner.display_name} "
  print "Bucket ACL Successfully changed to 'private'.\n"
  bucket.acl.grants.each do | grant |
    p "Bucket ACL is :  #{grant.permission.name} "
    p "Bucket Grantee URI is : #{grant.grantee.uri} "
  end
  
  # Create a new object
  object = bucket.objects.create("image", "value")
  print "Successfully created text file \n"
  
  # Retrieve an object
  print "Your object is :"
  object = bucket.objects["image"]
  
  # Insert an object
  object.write(
    file: "test.txt",
    content_type: "text/plain"
  )
  
  # Read image
  image = object.read
  p image
  print "File MetaData\n"
  
  # HEAD
  metadata = object.head
  p metadata

  # Multi part
  file_path_for_multipart_upload = "../temp_data/testFile"
  print "File is being upload : \n "
  open(file_path_for_multipart_upload) do |file|
    counter = file.size / 20242880
    uploading_object = bucket.objects[File.basename(file.path)]
    uploading_object.multipart_upload do |upload|
      while !file.eof?
        puts " #{upload.id} \t\t  #{counter} "
        counter -= 1
        upload.add_part(file.read 20242880) ## 20MB ##
        p("Aborted") if upload.aborted?
      end
    end
  end
  print "File Uploaded Successfully \n"
  large_object = bucket.objects["testFile"]
  
  # HEAD
  metadata = large_object.head
  p metadata

  # GET(To be handled at the below rescure block)
  image = object.read
  p image

  # Copy object
  bucket.objects["testFile.copy"].copy_from("testFile")
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
  File.open("testFile.copy", "wb") do |file|
    bucket.objects["testFile"].read do |chunk|
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
rescue AWS::S3::Errors::NoSuchKey
  exit
rescue
  
  # unexpected error occured
  p $!
  exit(-1)
ensure
  
  # Bucket Delete
  bucket = s3.buckets[Bucket]
  bucket.clear!  #clear the versions only
  bucket.delete
  print "Bucket deleted Successfully \n"
end
