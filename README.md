# transcribe-powershell
This repo contains PowerShell scripts for interacting with the [Amazon Transcribe](https://aws.amazon.com/transcribe/) service. The [Transcribe console](https://us-east-1.console.aws.amazon.com/transcribe/home) is very useful, but it only allows you to work with one transcription job at a time. The scripts in this repo provide an automated way of submitting multiple transcription requests, listing jobs, and deleting jobs -- all within PowerShell.

## Setup
Before you begin, you will need to setup your AWS credentials and your Windows environment to use those credentials. You only need to do this once.

### AWS Credentials
In order to access the Transcribe service from your Windows computer, you will need AWS credentials. This is done by generating an AWS access key ID and secret key pair. You can create access keys using your root AWS account, but it is not recommended because those keys will have full access to your account. That is way more privilege than you need for this exercise.
Instead, I recommend you create the AWS keys in an IAM (Identity and Access Management) user that has limited access. In fact, the most secure way to do this is to create a new IAM user that has exactly the permissions needed for this task (i.e. access to S3 and Transcribe). Here’s how:
1. Login to the [AWS console](https://aws.amazon.com/console/) as an administrator.
2. Choose your preferred region by selecting it in the top-right of the screen.2. Click the Services drop down menu at the top of the screen, type IAM, then select the IAM service.3. Click Users in the left navigation.4. Click Add user button.5. Provide a name for the user, for example **transcribe_user**.6. For Access type, click the checkbox next to Programmatic access. You can leave the checkbox unchecked next to AWS Management Console access if you won't be logging into the console with this user.7. Click the Next: Permissions button at the bottom of the screen.8. Click “Attach existing policies directly” box.9. Type S3 in the Filter policies text box.10. Check the box next to AmazonS3FullAccess. If you don't plan to write Transcribe output to an S3 bucket, you can select AmazonS3ReadOnlyAccess. (Note: these permissions are for all S3 buckets in your AWS account. More granular permissions are recommended. You can learn more [here](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html)).
11. Type Transcribe in the Filter policies text box.
12. Check the box next to AmazonTranscribeFullAccess. (Note: Just clicking the checkbox activates that item. There is no "apply" button.)11. Click Next: Tags button.12. There’s no need to add tags, so click the Next: Review button.13. Click Create user button to create the user.14. On the resulting page, copy the Access key ID and the Secret access key to be used later. Click the Show link to reveal the Secret access key. Note this is the only time the Secret access key will be available to be copied.15. Click the Close button.

### Setup AWS Tools for Windows PowerShell
Go to <https://aws.amazon.com/powershell/> and click the “AWS Tools for Windows Installer” button to download the installer.
2. Run the installer that was downloaded. Use all of the defaults in the installer.3. Launch the Windows PowerShell from the Start menu. To find it, click the Start menu, type PowerShell, and it should appear in the results.4. Configure your AWS credentials by typing this command at the PowerShell prompt:

`Initialize-AWSDefaultConfiguration -AccessKey AWS_ACCESS_KEY_ID-SecretKey AWS_SECRET_ACCESS_KEY`	
Where `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are the keys you saved in the prior section when you created the IAM user. This will save your credentials so you won’t have to re-enter them each time you launch the PowerShell.

More information on AWS Tools for Windows PowerShell is [here](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-welcome.html).

## Transcribe Commands

### Submitting Jobs
The [TranscribeFromS3.ps1](TranscribeFromS3.ps1) script submits Transcribe jobs for media files in S3. You simply provide the S3 bucket information and it will submit a transcription job for every object in the specified bucket/prefix.

```
C:\PS> .\TranscribeFromS3.ps1 -InputBucket my-audio-bucket -InputKeyPrefix subdir -AudioFormat mp3

There are 3 files to be transcribed in s3://my-audio-bucket/subdir :

sample1.mp3
sample2.mp3
sample3.mp3

Proceed? [Y]: y

Transcribing 3 files in s3://my-audio-bucket/audio ...

Media File URL       : https://s3.amazonaws.com/my-audio-bucket/subdir/sample1.mp3
Job Name             : sample1-0a06767c-69c9-4c4a-ab78-86670afd0b11
Creation Time        : 08/04/2019 17:56:05
Language Code        : en-US
Media Format         : mp3
Output Location Type : SERVICE_BUCKET
Job Status           : IN_PROGRESS

Media File URL       : https://s3.amazonaws.com/my-audio-bucket/subdir/sample2.mp3
Job Name             : sample2-2f8ae170-5032-4fae-9d9e-689acbeee2d5
Creation Time        : 08/04/2019 17:56:05
Language Code        : en-US
Media Format         : mp3
Output Location Type : SERVICE_BUCKET
Job Status           : IN_PROGRESS

Media File URL       : https://s3.amazonaws.com/my-audio-bucket/subdir/sample3.mp3
Job Name             : sample3-bfdd3739-4c0a-468a-86b0-d131452340bd
Creation Time        : 08/04/2019 17:56:06
Language Code        : en-US
Media Format         : mp3
Output Location Type : SERVICE_BUCKET
Job Status           : IN_PROGRESS

Finished submitting 3 jobs.
```

If you specify an output bucket (OutputBucket parameter), it will save the output in the S3 bucket that you specify. Otherwise it will save the output in a bucket provided by the Transcribe service and provide you with a signed URL to access it.

For more options, see the help documentation by issuing this command:

`Get-Help .\TranscribeFromS3.ps1`

### Listing Jobs
The [ListTranscribeJobs.ps1](ListTranscribeJobs.ps1) script lists the Transcribe jobs and provides details for each job. When using the `-IncludeDetails` parameter, it provides extra information on each job, including media format, sample rate, and output URL. Note that this option requires an extra API call for each job that is listed.

```
C:\PS> .\ListTranscribeJobs.ps1 -JobNameContain sample -Status COMPLETED -IncludeDetails

Job Name             : sample3-bfdd3739-4c0a-468a-86b0-d131452340bd
Creation Time        : 08/04/2019 17:56:06
Completion Time      : 08/04/2019 17:57:51
Language Code        : en-US
Output Location Type : SERVICE_BUCKET
Job Status           : COMPLETED
Media Format         : mp3
Sample Rate Hertz    : 44100
Transcript File URL  : https://s3.amazonaws.com/aws-transcribe-us-east-1-prod/...


Job Name             : sample2-2f8ae170-5032-4fae-9d9e-689acbeee2d5
Creation Time        : 08/04/2019 17:56:05
Completion Time      : 08/04/2019 17:57:31
Language Code        : en-US
Output Location Type : SERVICE_BUCKET
Job Status           : COMPLETED
Media Format         : mp3
Sample Rate Hertz    : 44100
Transcript File URL  : https://s3.amazonaws.com/aws-transcribe-us-east-1-prod/...


Job Name             : sample1-0a06767c-69c9-4c4a-ab78-86670afd0b11
Creation Time        : 08/04/2019 17:56:05
Completion Time      : 08/04/2019 17:57:31
Language Code        : en-US
Output Location Type : SERVICE_BUCKET
Job Status           : COMPLETED
Media Format         : mp3
Sample Rate Hertz    : 22050
Transcript File URL  : https://s3.amazonaws.com/aws-transcribe-us-east-1-prod/...
```

For more options, see the help documentation by issuing this command:

`Get-Help .\ListTranscribeJobs.ps1`

### Deleting Jobs
The [DeleteTranscribeJobs.ps1](DeleteTranscribeJobs.ps1) script deletes multiple Transcribe jobs. A filter is available to match the job name. Jobs currently in progress cannot be deleted.

```
C:\PS> .\DeleteTranscribeJobs.ps1 -JobNameContain sample

Jobs to delete:

sample3-bfdd3739-4c0a-468a-86b0-d131452340bd
sample2-2f8ae170-5032-4fae-9d9e-689acbeee2d5
sample1-0a06767c-69c9-4c4a-ab78-86670afd0b11

There are 3 jobs to be deleted. Proceed? [Y]: y

Deleting 3 jobs ...

sample3-bfdd3739-4c0a-468a-86b0-d131452340bd
sample2-2f8ae170-5032-4fae-9d9e-689acbeee2d5
sample1-0a06767c-69c9-4c4a-ab78-86670afd0b11

Finished deleting 3 jobs.
```

For more options, see the help documentation by issuing this command:

`Get-Help .\DeleteTranscribeJobs.ps1`
