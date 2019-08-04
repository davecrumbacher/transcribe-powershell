<#
.SYNOPSIS
    TranscribeFromS3
.DESCRIPTION
    PowerShell script to automate the submission of jobs to the AWS Transcribe service.
    Source audio files are in an S3 bucket and the output is saved in another S3 bucket.
.PARAMETER InputBucket
    S3 bucket where source audio files reside (required).
.PARAMETER InputKeyPrefix
    S3 prefix (folder path) to the source audio files (optional).
.PARAMETER AudioFormat
    Format of source audio files (wav, mp3, mp4, flac) (required).
.PARAMETER LanguageCode
    Language code for the language used in the source audio (optional).
.PARAMETER SampleRate
    Sample rate, in Hertz, of the source audio (optional).
.PARAMETER CustomVocabulary
    Custom vocabulary to use when processing the transcription job (optional).
.PARAMETER OutputBucket
    S3 bucket where to save transcription output (optional).
.PARAMETER MaxSpeakers
    Maximum number of speakers to recognize (optional).
.PARAMETER ChannelIdentification
    Process each audio channel separately (optional).
.EXAMPLE
    C:\PS> .\TranscribeFromS3.ps1 -InputBucket my-audio-bucket -InputKeyPrefix subdir -AudioFormat mp3
.NOTES
    Author: Dave Crumbacher
    Date:   August 3, 2019   
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="S3 bucket where source audio files reside")][string]$InputBucket,
    [Parameter(HelpMessage="S3 prefix (folder path) to the source audio files")][string]$InputKeyPrefix,
    [Parameter(Mandatory=$true, HelpMessage="Format of source audio files (wav, mp3, mp4, flac")][string]$AudioFormat,
    [Parameter(HelpMessage="Language code for the language used in the source audio")][string]$LanguageCode = "en-us",
    [Parameter(HelpMessage="Sample rate, in Hertz, of the source audio")][string]$SampleRate,
    [Parameter(HelpMessage="Custom vocabulary to use when processing the transcription job")][string]$CustomVocabulary,
    [Parameter(HelpMessage="S3 bucket where to save transcription output")][string]$OutputBucket,
    [Parameter(HelpMessage="Maximum number of speakers to recognize")][int]$MaxSpeakers,
    [Parameter(HelpMessage="Process each audio channel separately")][Switch]$ChannelIdentification
)

$args = @{}
if ($InputKeyPrefix.length -gt 0) {
    $args["KeyPrefix"] = $InputKeyPrefix
}

$files = @()
foreach ($obj in (Get-S3Object -BucketName $InputBucket @args)) {
    if ($obj.Key -NotLike "*/") {
        $files += $obj.Key
    }
}

$num_files = $files.count
Write-Output "`nThere are $num_files files to be transcribed in s3://$InputBucket/$InputKeyPrefix :`n"

foreach ($file in $files) {
    [IO.Path]::GetFileName($file)
}

$confirmation = Read-Host "`nProceed? [Y]"
if ($confirmation -eq $null -Or $confirmation -eq '') {
  $confirmation = 'y'
}
if ($confirmation.ToLower() -ne 'y' -And $confirmation.ToLower() -ne 'yes') {
    Write-Output "Aborting.`n"
    Exit
}

Write-Output "`nTranscribing $num_files files in s3://$InputBucket/$InputKeyPrefix ..."

$args = @{}
if ($SampleRate.length -gt 0) {
    $args["MediaSampleRateHertz"] = $SampleRate
}
if ($CustomVocabulary.length -gt 0) {
    $args["Settings_VocabularyName"] = $CustomVocabulary
}
if ($OutputBucket.length -gt 0) {
    $args["OutputBucketName"] = $OutputBucket
}
if ($MaxSpeakers -gt 1) {
    $args["Settings_MaxSpeakerLabel"] = $MaxSpeakers
    $args["Settings_ShowSpeakerLabel"] = $True
}
if ($ChannelIdentification) {
    $args["Settings_ChannelIdentification"] = $True
}

$num_processed = 0
foreach ($file in $files) {
    $filename = [IO.Path]::GetFileName($file)
    $slug= [IO.Path]::GetFileNameWithoutExtension($file)
    $uri = "https://s3.amazonaws.com/$InputBucket/" + $file

    #Define a unique guid to be used as the job name and the output results file.
    $guid = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
    $jobname = "$slug-$guid"

    $response = Start-TRSTranscriptionJob -TranscriptionJobName $jobname -Media_MediaFileUri $uri -MediaFormat $AudioFormat -LanguageCode $LanguageCode -Force @args

    Write-Output " "
    Write-Output "Media File URL       : $($response.Media.MediaFileUri)"
    Write-Output "Job Name             : $($response.TranscriptionJobName)"
    Write-Output "Creation Time        : $($response.CreationTime)"
    Write-Output "Language Code        : $($response.LanguageCode)"
    Write-Output "Media Format         : $($response.MediaFormat)"
    if ($SampleRate.length -gt 0) {
        Write-Output "Sample Rate          : $($response.MediaSampleRateHertz)"
    }

    if ($OutputBucket.length -gt 0) {
        Write-Output "Output Location Type : CUSTOMER_BUCKET"
    }
    else {
        Write-Output "Output Location Type : SERVICE_BUCKET"
    }
    Write-Output "Job Status           : $($response.TranscriptionJobStatus)"


    if ($job.FailureReason.Length -gt 0) {
        Write-Output "*** FailureReason    : $($response.FailureReason)"
    }

    $num_processed++
}

Write-Output "`nFinished submitting $num_processed jobs."
if ($OutputBucket.length -gt 0) {
    Write-Output "Output will be saved in S3 bucket '$OutputBucket'."
}
Write-Output ""