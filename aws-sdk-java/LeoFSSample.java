import java.io.BufferedReader;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.amazonaws.AmazonClientException;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3Client;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.GetObjectRequest;
import com.amazonaws.services.s3.model.ListObjectsRequest;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.DeleteObjectsRequest;
import com.amazonaws.services.s3.model.DeleteObjectsResult;
import com.amazonaws.services.s3.model.Bucket;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.ObjectListing;
import com.amazonaws.services.s3.model.S3ObjectInputStream;
import com.amazonaws.services.s3.model.S3ObjectSummary;
import com.amazonaws.services.s3.model.DeleteObjectsRequest.KeyVersion;
import com.amazonaws.services.s3.model.DeleteObjectsResult.DeletedObject;
import com.amazonaws.ClientConfiguration;
import com.amazonaws.Protocol;
public class LeoFSSample {
    public static void main(String[] args) throws IOException {
        /* ---------------------------------------------------------
         * You need to set 'Proxy host', 'Proxy port' and 'Protocol'
         * --------------------------------------------------------- */
        ClientConfiguration config = new ClientConfiguration();
        config.setProxyHost("localhost"); // LeoFS Gateway's Host
        config.setProxyPort(8080);        // LeoFS Gateway's Port
        config.withProtocol(Protocol.HTTP);
        final String accessKeyId = "05236";
        final String secretAccessKey = "802562235";
        AWSCredentials credentials = new BasicAWSCredentials(accessKeyId, secretAccessKey);
        AmazonS3 s3 = new AmazonS3Client(credentials, config);
        final String bucketName = "test";
        final String key = "test-key";
        final String fileName = "README";
        try {
            // Create a bucket
            s3.createBucket(bucketName);
            System.out.println("Bucket Created Successfully");
            // Retrieve list of buckets
            System.out.println("-----List Buckets----");
            for (Bucket bucket : s3.listBuckets()) {
                System.out.println("Bucket:" + bucket.getName());
            }
            // PUT an object into the LeoFS
            s3.putObject(new PutObjectRequest(bucketName, key, createFile()));
            System.out.println("Successfully created text file");

            // GET an object from the LeoFS
            S3Object object = s3.getObject(new GetObjectRequest(bucketName, key));
            dumpInputStream(object.getObjectContent(),key);

            // File Upload to LeoFS
            System.out.println("Uploading a new object to S3 from a file\n");
            File file = new File("../temp_data/"+fileName);
            s3.putObject(new PutObjectRequest(bucketName, file.getName(), file));
            System.out.println("File Uploaded Successfully");

            //File Download from LeoFS
            object = s3.getObject(new GetObjectRequest(bucketName, fileName));
            dumpInputStream(object.getObjectContent(),fileName+".copy");

            // File copy bucket internally
            s3.copyObject( bucketName, file.getName(), bucketName, fileName+".copy");
            System.out.println("File copied successfully");

            // Retrieve list of objects from the LeoFS
            ObjectListing objectListing =
                s3.listObjects(new ListObjectsRequest().withBucketName(bucketName));
            System.out.println("-----List objects----");
            //List<KeyVersion> keys = new ArrayList<KeyVersion>();
            for (S3ObjectSummary objectSummary : objectListing.getObjectSummaries()) {
                System.out.println(objectSummary.getKey() + " \t  Size:" + objectSummary.getSize());
               //keys.add(new KeyVersion(objectSummary.getKey()));
            }

            // DELETE an object from the LeoFS for future use
            //DeleteObjectsRequest multiObjectDeleteRequest = new DeleteObjectsRequest(bucketName).withKeys(keys);
            //DeleteObjectsResult delObjRes= s3.deleteObjects(multiObjectDeleteRequest);
            //System.out.println("File deleted Successfully :" + delObjRes.getDeletedObjects().size());
            s3.deleteObject(bucketName, key);
            s3.deleteObject(bucketName, fileName);
            s3.deleteObject(bucketName, fileName+".copy");
            System.out.println("File deleted Successfully :" );

            // DELETE a bucket from the LeoFS
            s3.deleteBucket(bucketName);
            System.out.println("Bucket deleted Successfully");
        } catch (AmazonServiceException ase) {
              System.out.println(ase.getMessage());
              System.out.println(ase.getStatusCode());
        } catch (AmazonClientException ace) {
              System.out.println(ace.getMessage());
        }
    }
    /**
     * Creates a temporary file with text data to demonstrate uploading a file
     * to LeoFS 
     *
     * @return A newly created temporary file with text data.
     *
     * @throws IOException
     */
    private static File createFile() throws IOException {
        File file = File.createTempFile("leofs_test", ".txt");
        file.deleteOnExit();
        Writer writer = new OutputStreamWriter(new FileOutputStream(file));
        writer.write("Hello, world!\n");
        writer.close();
        return file;
    }
    /**
     * Displays the contents of the specified input stream as text.
     *
     * @param input
     * The input stream to display as text.
     *
     * @throws IOException
     */
    private static void dumpInputStream(InputStream input,String fileName) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(input));
        File file=new File(fileName);
        OutputStreamWriter writer = new OutputStreamWriter(new FileOutputStream(file));
        int read = -1;
        while (( read = (byte) reader.read() ) != -1 )  {
            writer.write(read);
        }
        writer.flush();
        writer.close();
        reader.close();
    }
}
