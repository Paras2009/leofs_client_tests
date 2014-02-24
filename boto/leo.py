#!/usr/bin/python
# coding: utf8

from boto.s3.connection import S3Connection, OrdinaryCallingFormat
from boto.s3.bucket import Bucket
from boto.s3.key import Key

AWS_ACCESS_KEY = "05236"
AWS_SECRET_ACCESS_KEY = "802562235"
BUCKET_NAME = "test"

conn = S3Connection(AWS_ACCESS_KEY,
                    AWS_SECRET_ACCESS_KEY,
                    host = "localhost",
                    port = 8080,
                    calling_format = OrdinaryCallingFormat(),
                    is_secure = False
       )

try:
#Create bucket
	bucket = conn.create_bucket(BUCKET_NAME)
	print "Bucket Created Successfully"

#show buckets
	print "--------Bucket List------"
	for bucket in conn.get_all_buckets():
		print bucket

#create object 
	s3_object = bucket.new_key("text")
	s3_object.set_contents_from_string("This is a text.")
	print "Successfully created text file"
	
#get Object 	
	s3_object = bucket.get_key("text")
	print "Object Data is :"
	print s3_object

#read
	print s3_object.read()

#write from file
	print "Uploading file.."
	s3_object = bucket.new_key("photo.jpg")
	s3_object.set_contents_from_filename("photo.jpg")
#	print multipart_upload.upload()
	print "File uploaded Successfully"
	
#File Download
	s3_object.get_contents_to_filename("photo.jpg.copy")
	print "File Downloaded Successfully"
#File copy
	bucket.copy_key('photo.jpg.copy',BUCKET_NAME, 'photo.jpg')
	print "File copied successfully"
	
#Show Objects
	print"--------------------------------List Objects-----------------------------------"
	for key in bucket.list():
		print key.name , "\t\t" , key.size , "\t\t" , key.last_modified

#Delete objects
	print"--------------------------------Delete Objects---------------------------------"
	for key in bucket.list():
		print key.name , "Deleted Successfully", key.delete()

#get deleted key
	s3_object = bucket.get_key("image")
#It should print None
	print s3_object\
finally:
	bucket = conn.get_bucket(BUCKET_NAME)
	bucket.delete()
	print "Bucket deleted Successfully \n"





