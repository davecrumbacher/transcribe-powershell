<#
.SYNOPSIS
    DeleteTranscribeJobs
.DESCRIPTION
    PowerShell script to automate the deletion of multiple Transcribe jobs.
    Jobs still in progress cannot be deleted, so those are skipped.
.PARAMETER JobNameContain
    Filters the jobs to those whose name contains the specified string (optional).
.EXAMPLE
    C:\PS> .\DeleteTranscribeJobs.ps1 -JobNameContain sample
.NOTES
    Author: Dave Crumbacher
    Date:   August 3, 2019   
#>

param (
    [Parameter(HelpMessage="Filters the jobs to those whose name contains the specified string")][string]$JobNameContain
)

$args = @{}

if ($JobNameContain.length -gt 0) {
    $args["JobNameContain"] = $JobNameContain
}

$response = Get-TRSTranscriptionJobList @args

$num_jobs= $response.count
if ($num_jobs -lt 1) {
    Write-Output "No jobs found."
    Exit
}

$jobs_to_delete = @()
$num_skipped = 0
foreach ($job in $response) {
    $status = $job.TranscriptionJobStatus
    if ($status -eq "IN_PROGRESS") {
        $num_skipped++
    }
    else {
        $jobs_to_delete += $job
    }
}
if ($num_skipped -gt 0) {
    if ($num_skipped -eq 1) {
        Write-Output "`nSkipping 1 job that is still in progress."
    }
    else {
        Write-Output "`nSkipping $num_skipped jobs that are still in progress."
    }
}

$num_jobs= $jobs_to_delete.count
if ($num_jobs -lt 1) {
    Write-Output "There are no other jobs that can be deleted at this time.`n"
    Exit
}

Write-Output "`nJobs to delete:`n"

foreach ($job in $jobs_to_delete) {
    $job.TranscriptionJobName
}

if ($num_jobs -eq 1) {
    $confirmation = Read-Host "`nThere is 1 job to be deleted. Proceed? [Y]"
}
else {
    $confirmation = Read-Host "`nThere are $num_jobs jobs to be deleted. Proceed? [Y]"
}

if ($confirmation -eq $null -Or $confirmation -eq '') {
  $confirmation = 'y'
}
if ($confirmation.ToLower() -ne 'y' -And $confirmation.ToLower() -ne 'yes') {
    Write-Output "Aborting.`n"
    Exit
}

if ($num_jobs -eq 1) {
    Write-Output "`nDeleting 1 job ...`n"
}
else {
    Write-Output "`nDeleting $num_jobs jobs ...`n"
}

$num_deleted = 0
foreach ($job in $jobs_to_delete) {
    Write-Output($job.TranscriptionJobName)
    Remove-TRSTranscriptionJob -TranscriptionJobName $job.TranscriptionJobName -Force
    $num_deleted++
}

if ($num_deleted -eq 1) {
    Write-Output "`nFinished deleting 1 job.`n"
}
else {
    Write-Output "`nFinished deleting $num_deleted jobs.`n"
}