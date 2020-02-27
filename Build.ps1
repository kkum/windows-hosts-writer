[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $Registry
)
Push-Location $PSScriptRoot

# MSBuild .\windows-hosts-writer.sln "/p:DeployOnBuild=true;PublishProfile=FolderProfile;Configuration=Release" /t:Publish

Push-Location "./Deploy"

$WindowsVersion =(Get-ComputerInfo | Select-Object WindowsVersion).WindowsVersion 

$whwDll = (Get-Item -Path "./app/windows-hosts-writer.dll")

$ProductVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($($whwDll.FullName)).ProductVersion
$tag= "windows-hosts-writer:$ProductVersion-$WindowsVersion"
Write-Host "Building $tag"
docker image build --no-cache --tag $tag --build-arg "BASE_IMAGE=mcr.microsoft.com/dotnet/core/runtime:3.1.1-nanoserver-$($WindowsVersion)" .

if ([string]::IsNullOrEmpty($Registry))
{
    $fulltag = $tag
}
else
{
    $fulltag = "{0}/{1}" -f $Registry, $tag
    docker image tag $tag $fulltag
    docker image push $fulltag
}

Pop-Location
Pop-Location