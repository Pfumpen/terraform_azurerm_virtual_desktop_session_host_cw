#Requires -Version 5.1
<#
.SYNOPSIS
    Organizes AzureRM Terraform provider documentation files into a categorized
    and module-centric directory structure based on a JSON mapping file.
.DESCRIPTION
    This script reads a list of AzureRM resource documentation filenames and
    a JSON mapping file (module_resource_mappings.json). It then organizes
    the documentation files into a new directory structure:
    Terraform Azurerm Registry Docs/[Category]/[ModuleConcept]/[ResourceName].md

    A single documentation file can be copied to multiple module concept folders
    if it's defined as a core or associated resource in the mapping file.
    Files not found in any mapping are placed in an "Other/[ResourceName]" category,
    also with a .md extension.
.PARAMETER SourceDocsPath
    Path to the directory containing the original Azurerm Registry Docs.
    Default: "Azurerm Registry Docs"
.PARAMETER DestinationRootPath
    Path to the root directory where the organized docs will be created.
    Default: "Terraform Azurerm Registry Docs"
.PARAMETER ResourceListFile
    Path to the text file containing the list of documentation filenames.
    Default: "Azure Registry Name List.txt"
.PARAMETER MappingFilePath
    Path to the JSON file that defines module-to-resource mappings.
    Default: "module_resource_mappings.json"
.NOTES
    Author: Cline
    Date: 2025-05-08
    Version: 3.0 - Implements revised naming convention (.md extension, original base names)
#>

param (
    [string]$SourceDocsPath = "Azurerm Registry Docs",
    [string]$DestinationRootPath = "Terraform Azurerm Registry Docs",
    [string]$ResourceListFile = "Azure Registry Name List.txt",
    [string]$MappingFilePath = "module_resource_mappings.json"
)

# --- Helper Functions ---
function Get-BaseResourceName([string]$Filename) {
    # Extracts a base name, e.g., "virtual_machine" from "virtual_machine.html.markdown"
    return [System.IO.Path]::GetFileNameWithoutExtension($Filename).Replace(".html", "")
}

function ConvertTo-MarkdownFileName([string]$OriginalSourceFileName) {
    # Converts "virtual_machine.html.markdown" to "virtual_machine.md"
    $baseName = Get-BaseResourceName -Filename $OriginalSourceFileName
    return "$($baseName).md"
}

function Copy-DocItem {
    param (
        [string]$SourceFilePath,
        [string]$TargetDirectoryPath,
        [string]$OriginalSourceFileName, # e.g., virtual_machine.html.markdown
        [ref]$CopiedFileInstancesCounter,
        [ref]$ErrorCounter
    )

    $destinationFileName = ConvertTo-MarkdownFileName -OriginalSourceFileName $OriginalSourceFileName
    $destinationFilePath = Join-Path -Path $TargetDirectoryPath -ChildPath $destinationFileName

    # Create Target Directory if it doesn't exist
    if (-not (Test-Path -Path $TargetDirectoryPath -PathType Container)) {
        try {
            New-Item -Path $TargetDirectoryPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Verbose "Created directory: $TargetDirectoryPath"
        }
        catch {
            Write-Warning "Failed to create directory '$TargetDirectoryPath'. Error: $($_.Exception.Message). Skipping copy of '$OriginalSourceFileName' to this location."
            $ErrorCounter.Value++
            return
        }
    }

    try {
        Copy-Item -Path $SourceFilePath -Destination $destinationFilePath -Force -ErrorAction Stop
        Write-Verbose "Copied '$OriginalSourceFileName' to '$destinationFilePath'"
        $CopiedFileInstancesCounter.Value++
    }
    catch {
        Write-Warning "Failed to copy '$OriginalSourceFileName' to '$destinationFilePath'. Error: $($_.Exception.Message). This might be a path length issue."
        # Not incrementing general error counter here as it's a specific copy failure,
        # but it's logged as a warning. The script will continue.
    }
}


# --- Main Script Logic ---

Write-Host "Starting AzureRM Documentation Organization Script (v3 - MD Naming)..."

# Validate Source Directory
if (-not (Test-Path -Path $SourceDocsPath -PathType Container)) {
    Write-Error "Source documentation directory '$SourceDocsPath' not found. Exiting."
    exit 1
}
Write-Host "Source directory: $(Resolve-Path $SourceDocsPath)"

# Validate Resource List File
if (-not (Test-Path -Path $ResourceListFile -PathType Leaf)) {
    Write-Error "Resource list file '$ResourceListFile' not found. Exiting."
    exit 1
}
Write-Host "Resource list file: $(Resolve-Path $ResourceListFile)"

# Validate and Load Mapping File
if (-not (Test-Path -Path $MappingFilePath -PathType Leaf)) {
    Write-Error "Mapping file '$MappingFilePath' not found. Exiting."
    exit 1
}
Write-Host "Mapping file: $(Resolve-Path $MappingFilePath)"
try {
    $Mappings = Get-Content -Path $MappingFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Error "Failed to parse mapping file '$MappingFilePath'. Error: $($_.Exception.Message)"
    exit 1
}

# Clean and Create Destination Root Directory
if (Test-Path -Path $DestinationRootPath -PathType Container) {
    Write-Host "Removing existing destination root directory: $DestinationRootPath"
    try {
        Remove-Item -Path $DestinationRootPath -Recurse -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to remove existing destination directory '$DestinationRootPath'. Error: $($_.Exception.Message). Please remove it manually and retry."
        exit 1
    }
}
Write-Host "Creating destination root directory: $DestinationRootPath"
try {
    New-Item -Path $DestinationRootPath -ItemType Directory -ErrorAction Stop | Out-Null
}
catch {
    Write-Error "Failed to create destination root directory '$DestinationRootPath'. Error: $($_.Exception.Message)"
    exit 1
}

$fileList = Get-Content -Path $ResourceListFile
Write-Host "Processing $($fileList.Count) files from '$ResourceListFile'..."
$processedCount = 0
$copiedFileInstances = 0 # Counts each time a file is copied
$criticalErrorCount = 0 # For errors like source file not found
$unmappedCount = 0

foreach ($fileNameInList in $fileList) {
    $trimmedFileName = $fileNameInList.Trim() # This is the original e.g. virtual_machine.html.markdown
    if ([string]::IsNullOrWhiteSpace($trimmedFileName)) {
        Write-Warning "Skipping empty line in resource list."
        continue
    }

    $sourceFilePath = Join-Path -Path $SourceDocsPath -ChildPath $trimmedFileName
    if (-not (Test-Path -Path $sourceFilePath -PathType Leaf)) {
        Write-Warning "Source file '$sourceFilePath' (from list: '$trimmedFileName') not found. Skipping."
        $criticalErrorCount++
        continue
    }

    $fileProcessedByMapping = $false

    # Iterate through categories and module concepts in the mapping
    foreach ($categoryEntry in $Mappings.PSObject.Properties) {
        $categoryName = $categoryEntry.Name
        $moduleConcepts = $categoryEntry.Value

        foreach ($moduleConceptEntry in $moduleConcepts.PSObject.Properties) {
            $moduleConceptName = $moduleConceptEntry.Name
            $moduleMapping = $moduleConceptEntry.Value

            $isMatch = $false
            if ($moduleMapping.core_resource_patterns -contains $trimmedFileName) {
                $isMatch = $true
            }
            if ($moduleMapping.associated_resource_patterns -contains $trimmedFileName) {
                $isMatch = $true
            }

            if ($isMatch) {
                $fileProcessedByMapping = $true # Mark that this file has at least one mapping
                $targetModulePath = Join-Path -Path $DestinationRootPath -ChildPath $categoryName | Join-Path -ChildPath $moduleConceptName
                
                Copy-DocItem -SourceFilePath $sourceFilePath `
                             -TargetDirectoryPath $targetModulePath `
                             -OriginalSourceFileName $trimmedFileName `
                             -CopiedFileInstancesCounter ([ref]$copiedFileInstances) `
                             -ErrorCounter ([ref]$criticalErrorCount) # Pass critical error for dir creation issues
            }
        }
    }

    if ($fileProcessedByMapping) {
        $processedCount++ # Counts source files that found at least one mapping
    } else {
        # Handle unmapped files
        $unmappedCount++
        Write-Verbose "File '$trimmedFileName' not found in mappings. Placing in 'Other'."
        
        $baseResourceNameForOtherDir = Get-BaseResourceName -Filename $trimmedFileName
        $otherCategoryPath = Join-Path -Path $DestinationRootPath -ChildPath "Other"
        $otherResourceSpecificPath = Join-Path -Path $otherCategoryPath -ChildPath $baseResourceNameForOtherDir

        Copy-DocItem -SourceFilePath $sourceFilePath `
                     -TargetDirectoryPath $otherResourceSpecificPath `
                     -OriginalSourceFileName $trimmedFileName `
                     -CopiedFileInstancesCounter ([ref]$copiedFileInstances) `
                     -ErrorCounter ([ref]$criticalErrorCount)
    }
}

Write-Host "-----------------------------------------------------"
Write-Host "Script Execution Summary:"
Write-Host "Source files processed (found in mappings): $processedCount."
Write-Host "Total file copy operations performed: $copiedFileInstances."
Write-Host "Files not found in any mapping (placed in 'Other'): $unmappedCount."
Write-Host "Files skipped due to source not found or critical directory creation errors: $criticalErrorCount."
if ($criticalErrorCount -gt 0) {
    Write-Warning "There were $criticalErrorCount critical errors. Please review the output above."
}
Write-Warning "Review other warnings for potential individual copy failures (e.g., path length issues)."
Write-Host "Organized documentation is in: $(Resolve-Path $DestinationRootPath)"
Write-Host "Script finished."
