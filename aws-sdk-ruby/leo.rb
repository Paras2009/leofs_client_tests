## This code supports "aws-sdk v1.9.5"
require "aws-sdk"
require "content_type"

# set your s3 key and variable 
Endpoint = "localhost"
Port = 8080
AccessKeyId = "05236"
SecretAccessKey = "802562235"
FileName = "testFile"
ChunkSize = 20242880
time=Time.new
Bucket = "test" + time.strftime("%dd%H%M%S")   #Dynamic BucketName

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
  print "Bucket Created Successfully\n"

  # Get bucket
  bucket = s3.buckets[Bucket]
  print "Get Bucket Successfully\n\n"

  # PUT Object
  file_path = "../temp_data/" + FileName
  file =  open(file_path)

  # PUT object using single-part method
  obj = bucket.objects[FileName + ".single"].write(file: file_path, content_type: file.content_type)

  # PUT object using multi-part method
  print "File is being upload :\n "
  counter = file.size / ChunkSize
  uploading_object = bucket.objects[File.basename(file.path)]
  uploading_object.multipart_upload(:content_type => file.content_type.to_s) do |upload|
    while !file.eof?
      puts " #{upload.id} \t\t #{counter} "
      counter -= 1
      upload.add_part(file.read ChunkSize) ## 20MB Default size is 5242880 Byte  ##
      p("Aborted") if upload.aborted?
    end
  end
  print "File Uploaded Successfully\n\n"

  # Get object 
  obj = bucket.objects[FileName]

  # HEAD object
  metadata = obj.head
  print "File MetaData : "
  p  metadata

 # GET object(To be handled at the below rescue block)
  if file.content_type.eql? "text/plain"
    print "\nSingle Part Upload object data : \t" + bucket.objects[FileName + ".single"].read
    print "Multi Part Upload object data : \t" +  obj.read + "\n"
  else
    print "File Content type is :" + obj.content_type + "\n"
  end

  # Copy object
  bucket.objects[FileName + ".copy"].copy_from(FileName)
  if !bucket.objects[FileName + ".copy"].exists?
    raise "File could not Copy Succesfully\n"
  end
  print "File copied successfully \n"

  # List objects in the bucket
  print "----------List Files---------\n"
  bucket.objects.with_prefix("").each do |obj|
    puts "#{obj.key} \t #{obj.content_length}"
  end

  # Move object 
  obj = bucket.objects[FileName + ".copy"].move_to(FileName + ".org");
  if !obj.exists?
    raise "File could not Moved Succesfully\n"
  end
  print "\nFile move Successfully \n"

  # List objects in the bucket
  print "----------List Files---------\n"
  bucket.objects.with_prefix("").each do |obj|
    puts "#{obj.key} \t #{obj.content_length}"
  end

  # Rename object 
  obj = bucket.objects[FileName + ".org"].rename_to(FileName + ".copy");
  if !obj.exists?
    raise "File could not Rename Succesfully\n"
  end
  print "\nFile rename Successfully \n"

 # List objects in the bucket
  print "----------List Files---------\n"
  bucket.objects.with_prefix("").each do |obj|
    puts "#{obj.key} \t #{obj.content_length}"
  end

  # Download File
  File.open(FileName + ".copy", "wb") do |file|
    bucket.objects[FileName].read do |chunk|
      file.write(chunk)
    end
    print "\nFile Downloaded Successfully \n\n"
  end

  # Delete objects one by one and check if exist
  print "--------------------Delete Files--------------------\n"
  bucket.objects.with_prefix("").each do |obj|
    obj.delete
    print "#{obj.key} \t File Deleted Successfully..\n"
    if obj.exists?
      raise "Object is not Deleted Succesfully\n"
    end
  end

  # Get-Put ACL
  puts "\n#####Default ACL#####"
  puts "Owner ID : #{bucket.acl.owner.id} "
  puts "Owner Display name : #{bucket.acl.owner.display_name} "
  permissions = []
  bucket.acl.grants.each do |grant|
    puts "Bucket ACL is :  #{grant.permission.name} "
    puts "Bucket Grantee URI is : #{grant.grantee.uri} "
    permissions << grant.permission.name
  end
  if !permissions.include? :full_control
    raise "Permission is Not full_control"
  else
    print "Bucket ACL permission is 'private'\n\n"
  end

  puts "#####:public_read ACL#####"
  bucket.acl = :public_read
  puts "Owner ID : #{bucket.acl.owner.id} "
  puts "Owner Display name : #{bucket.acl.owner.display_name} "
  permissions = []
  bucket.acl.grants.each do |grant|
    puts "Bucket ACL is :  #{grant.permission.name} "
    puts "Bucket Grantee URI is : #{grant.grantee.uri} "
    permissions << grant.permission.name
  end
  if !( (permissions.include? :read ) && (permissions.include? :read_acp ) )
    raise "Permission is Not public_read"
  else
    print "Bucket ACL Successfully changed to 'public-read'\n\n"
  end

  puts "#####:public_read_write ACL#####"
  bucket.acl = :public_read_write
  puts "Owner ID : #{bucket.acl.owner.id} "
  puts "Owner Display name : #{bucket.acl.owner.display_name} "
  permissions = []
  bucket.acl.grants.each do |grant|
    puts "Bucket ACL is :  #{grant.permission.name} "
    puts "Bucket Grantee URI is : #{grant.grantee.uri} "
    permissions << grant.permission.name
  end  if !( (permissions.include? :read ) && (permissions.include? :write ) && (permissions.include? :read_acp ) && (permissions.include? :write_acp ) )
    raise "Permission is Not public_read_write"
  else
    print "Bucket ACL Successfully changed to 'public-read-write'\n\n"
  end

  puts "#####:private ACL#####"
  bucket.acl = :private
  puts "Owner ID : #{bucket.acl.owner.id} "
  puts "Owner Display name : #{bucket.acl.owner.display_name} "
  permissions = []
  bucket.acl.grants.each do |grant|
    puts "Bucket ACL is :  #{grant.permission.name} "
    puts "Bucket Grantee URI is : #{grant.grantee.uri} "
    permissions << grant.permission.name
  end
  if  !permissions.include? :full_control
    raise "Permission is Not full_control"
  else
    print "Bucket ACL Successfully changed to 'private'\n\n"
  end
rescue
  # Unexpected error occured
  p $!
  exit(-1)
ensure
  # Bucket Delete
  bucket = s3.buckets[Bucket]
  bucket.clear!  #clear the versions only
  bucket.delete
  print "Bucket deleted Successfully \n"
end          
