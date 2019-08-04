<#
.SYNOPSIS
    ListTranscribeJobs
.DESCRIPTION
    PowerShell script to list Transcribe jobs.
.PARAMETER JobNameContain
    Filters the jobs to those whose name contains the specified string (optional).
.PARAMETER Status
    Filters the jobs to those with the specified status (IN_PROGRESS, COMPLETED, FAILED) (optional).
.PARAMETER Details
    Include extra job details (media format, sample rate, output URL). Requires additional API call for each job. (optional).
.EXAMPLE
    C:\PS> .\ListTranscribeJobs.ps1 -JobNameContain sample -Status COMPLETED -Details
.NOTES
    Author: Dave Crumbacher
    Date:   August 3, 2019   
#>

param (
    [Parameter(HelpMessage="Filters the jobs to those whose name contains the specified string")][string]$JobNameContain,
    [Parameter(HelpMessage="Filters the jobs to those with the specified status (IN_PROGRESS, COMPLETED, FAILED)")][string]$Status,
    [Parameter(HelpMessage="Include extra job details (media format, sample rate, output URL)")][Switch]$Details
)

$args = @{}

if ($JobNameContain.length -gt 0) {
    $args["JobNameContain"] = $JobNameContain
}

if ($Status.length -gt 0) {
    $args["Status"] = $Status
}

$response = Get-TRSTranscriptionJobList @args
$num_jobs= $response.count

if ($num_jobs -lt 1) {
    Write-Output "No jobs found."
    Exit
}

foreach ($job in $response) {

    if ($Details) {
        $response = Get-TRSTranscriptionJob -TranscriptionJobName $job.TranscriptionJobName
    }

    Write-Output " "
    Write-Output "Job Name             : $($job.TranscriptionJobName)"
    Write-Output "Creation Time        : $($job.CreationTime)"
    if ($job.TranscriptionJobStatus -ne "IN_PROGRESS") {
        Write-Output "Completion Time      : $($job.CompletionTime)"
    }
    Write-Output "Language Code        : $($job.LanguageCode)"
    Write-Output "Output Location Type : $($job.OutputLocationType)"
    Write-Output "Job Status           : $($job.TranscriptionJobStatus)"

    if ($Details) {
        Write-Output "Media Format         : $($response.MediaFormat)"
        Write-Output "Sample Rate Hertz    : $($response.MediaSampleRateHertz)"
        Write-Output "Transcript File URL  : $($response.Transcript.TranscriptFileUri)"
    }

    if ($job.FailureReason.Length -gt 0) {
        Write-Output "*** FailureReason    : $($job.FailureReason)"
    }


    Write-Output " "
}