from boto.s3.connection import S3Connection, OrdinaryCallingFormat
from boto.s3.bucket import Bucket
from boto.s3.key import Key
from cStringIO import StringIO
import boto
import hashlib
import os
import mimetypes
import random
import traceback
import magic

AWS_ACCESS_KEY = "05236"
AWS_SECRET_ACCESS_KEY = "802562235"
FileName = "testFile"
CHUNK_SIZE = 5 * 1024 * 1024
mime = magic.open(magic.MAGIC_MIME)
BUCKET_NAME = "test" + str(random.randint(1,99999))  ## Dynamic BucketName

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
    print "Get Bucket Successfully\n"

    # Put Object
    file_path = "../temp_data/" + FileName
    fileObject = open(file_path, "r")
    fileDigest = hashlib.md5(fileObject.read()).hexdigest()
    fileSize = os.path.getsize(file_path)
    mime.load()
    fileType =  mime.file(file_path)

    # PUT Object using single-part method
    bucket.new_key(FileName).set_contents_from_filename(file_path)

    # HEAD Object
    obj = bucket.get_key(FileName)
    if not(obj.exists()):
        raise "Object doesn't exists"
    if not(fileSize == obj.size and fileDigest == obj.etag[1:-1]):
        raise "File Metadata could not match"
    else:
        print "File MetaData : Content_type:", obj.content_type, "Content_encoding:", obj.content_encoding
        print "etag:", obj.etag, "Size:", obj.size, "Name:", obj.name, "\n"

    # GET object
    if not fileSize == obj.size:
        raise "Upload File content is not equal\n"
    if "text/plain" in fileType:
        print "Uploaded object data : \t", obj.read()
    else:
        print "File Content type is :", obj.content_type + "\n"

    # Show Objects
    print"--------------------------------List Objects-----------------------------------"
    for key in bucket.list():
        if not(fileSize == key.size):
            raise "Content length is changed for :", key.size
        print key.name, "\t\t", key.size, "\t\t", key.last_modified
    print "File Uploaded Successfully\n"

    # File copy
    obj =  bucket.copy_key(FileName + ".copy", BUCKET_NAME, FileName)
    if not(obj.exists()):
       raise "File could not Copy Successfully\n"

    # Show Objects
    print"--------------------------------List Objects-----------------------------------"
    for key in bucket.list():
        if not(fileSize == key.size):
            raise "Content length is changed for :", key.size
        print key.name, "\t\t", key.size, "\t\t", key.last_modified
    print "File copied successfully\n"

    # File Download
    thisfile_path = FileName + ".copy"
    obj.get_contents_to_filename(thisfile_path)
    thisfileObject = open(thisfile_path, "r")
    thisfileDigest = hashlib.md5(thisfileObject.read()).hexdigest()
    thisfileSize = os.path.getsize(thisfile_path)
    thisfileType = mime.file(thisfile_path)
    if not(thisfileSize == obj.size and thisfileDigest == fileDigest):
        raise "Downloaded File Metadata could not match\n"
    print "File Downloaded Successfully\n"

    # Delete objects one by one and check if exist
    print"--------------------------------Delete Objects---------------------------------"
    for key in bucket.list():
        print key.name, "Deleted Successfully", key.delete()
        if key.exists():
            raise "Object is not Deleted Successfully\n"

    # Get-Put ACL
    print "\n#####Default ACL#####"
    acp = bucket.get_acl()
    print acp
    print "Owner ID :" + acp.owner.id
    print "Owner Display name : " + acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all(x in permissions for x in ["FULL_CONTROL"]):
        raise "Permission is Not full_control"
    else:
        print "Bucket ACL permission is  'private'\n"

    print "########:public_read ACL########"
    bucket.set_acl("public-read")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all(x in permissions for x in ["READ","READ_ACP"]):
         raise Exception("Permission is Not public_read")
    else:
        print "Bucket ACL Successfully changed to 'public-read'\n"

    print "#####:public_read_write ACL#####"
    bucket.set_acl("public-read-write")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all(x in permissions for x in ["READ","READ_ACP","WRITE", "WRITE_ACP"]):
        raise "Permission is Not public_read_write"
    else:
        print "Bucket ACL Successfully changed to 'public-read-write'\n"

    print "##########:private ACL##########"
    bucket.set_acl("private")
    acp = bucket.get_acl()
    print "Owner ID :", acp.owner.id
    print "Owner Display name :", acp.owner.display_name
    permissions = []
    for grant in acp.acl.grants:
        print "Bucket ACL is :", grant.permission,"\nBucket Grantee URI is :", grant.uri
        permissions.append(grant.permission)
    if not all(x in permissions for x in ["FULL_CONTROL"]):
        raise "Permission is Not full_control"
    else:
        print "Bucket ACL Successfully changed to 'private'\n"
except Exception,e :
    print traceback.format_exc()
finally:
    # Delete Bucket
    bucket = conn.get_bucket(BUCKET_NAME,validate=False)
    bucket.delete()
    print "Bucket deleted Successfully\n"