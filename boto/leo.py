from boto.s3.connection import S3Connection, OrdinaryCallingFormat
from boto.s3.bucket import Bucket
from boto.s3.key import Key
import time

AWS_ACCESS_KEY = "05236"
AWS_SECRET_ACCESS_KEY = "802562235"
BUCKET_NAME = "test" + time.strftime("%H%M%S")  #Dynamic BucketName

conn = S3Connection(AWS_ACCESS_KEY,
    AWS_SECRET_ACCESS_KEY,
    host = "localhost",
    port = 8080,
    calling_format = OrdinaryCallingFormat(),
    is_secure = False
)

try:
    # Create bucket
    buckets = conn.create_bucket(BUCKET_NAME)
    print "Bucket Created Successfully"

    # Show buckets
    print "--------Bucket List------"
    for bucket in conn.get_all_buckets():
        print bucket

    # Get Bucket
    bucket = conn.get_bucket(BUCKET_NAME,validate=False)
    print "Get Bucket Successfully"

    # Get-Put ACL
    print "#####Default ACL#####"
    acp = bucket.get_acl()
    print acp
    print "Owner ID : " + acp.owner.id
    print "Owner Display name : " + acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all( x in permissions for x in ["FULL_CONTROL"]):
        raise "Permission is Not full_control"
    else:
        print "Bucket ACL permission is  'private'.\n"

    print "########:public_read ACL########"
    bucket.set_acl("public-read")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all( x in permissions for x in ["READ","READ_ACP"]):
         raise Exception("Permission is Not public_read")
    else:
        print "Bucket ACL Successfully changed to 'public-read'.\n"

    print "#####:public_read_write ACL#####"
    bucket.set_acl("public-read-write")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all( x in permissions for x in ["READ","READ_ACP","WRITE", "WRITE_ACP"]):
        raise "Permission is Not public_read_write"
    else:
        print "Bucket ACL Successfully changed to 'public-read-write'.\n"

    print "##########:private ACL##########"
    bucket.set_acl("private")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all( x in permissions for x in ["FULL_CONTROL"]):
        raise "Permission is Not full_control"
    else:
        print "Bucket ACL Successfully changed to 'private'.\n"

    # Create object
    s3_object = bucket.new_key("text")
    s3_object.set_contents_from_string("This is a text.")
    print "File Created Successfully"

    # Get Object
    s3_object = bucket.get_key("text")
    print "Object Data is :"
    print s3_object

    # Read object
    print s3_object.read()

    # Write from file
    print "Uploading file.."
    s3_object = bucket.new_key("testFile")
    s3_object.set_contents_from_filename("../temp_data/testFile")

    # Print multipart_upload.upload()
    print "File uploaded Successfully"

    # File Download
    s3_object.get_contents_to_filename("testFile.copy")
    print "File Downloaded Successfully"

    # File copy
    bucket.copy_key( "testFile.copy", BUCKET_NAME, "testFile" )
    print "File copied successfully"

    # Show Objects
    print"--------------------------------List Objects-----------------------------------"
    for key in bucket.list():
        print key.name , "\t\t" , key.size , "\t\t" , key.last_modified

    # Delete objects
    print"--------------------------------Delete Objects---------------------------------"
    for key in bucket.list():
        print key.name , "Deleted Successfully", key.delete()

    # Get deleted key
    s3_object = bucket.get_key("testFile")

    # It should print None
    print s3_object

except Exception,e :
    print e

finally:
    # Delete Bucket
    bucket = conn.get_bucket(BUCKET_NAME,validate=False)
    bucket.delete()
    print "Bucket deleted Successfully \n"
