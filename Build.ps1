[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $Registry,
    [switch] $ForceBuild,
    [switch] $Push
)
Push-Location $PSScriptRoot

if ($ForceBuild.IsPresent) {
    nuget restore .\windows-hosts-writer.sln
    MSBuild .\windows-hosts-writer.sln "/p:DeployOnBuild=true;PublishProfile=FolderProfile;Configuration=Release" /t:Publish
}

Push-Location "./Deploy"

$whwDll = (Get-Item -Path "./app/windows-hosts-writer.dll")
$ProductVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($($whwDll.FullName)).ProductVersion
$WindowsVersion = (Get-ComputerInfo | Select-Object WindowsVersion).WindowsVersion 

$tag = "windows-hosts-writer:$ProductVersion-$WindowsVersion"
Write-Host "Building $tag" 
docker image build --no-cache --tag $tag --build-arg "BASE_IMAGE=mcr.microsoft.com/dotnet/core/runtime:3.1.1-nanoserver-$($WindowsVersion)" .
Write-Host "$tag was build!" 
Pop-Location

if ($Registry) {
    $RegistryTag = "$($Registry).azurecr.io/$($tag)" ;
    $tagId = $(docker images "$tag" --format "{{.ID}}")
    $RegistryTagId = $(docker images "$RegistryTag" --format "{{.ID}}")
    
    # (re)tag the file for repository if necessary
    if ( ($null -eq $RegistryTagId) -or ($tagId -ne $RegistryTagId)) {
        docker image tag $tag $RegistryTag;
    }
    
    if($Push){
        #Ensure login
        # push the image
        az acr login --name $Registry ;
        docker image push $RegistryTag;
    }
}

Pop-Location