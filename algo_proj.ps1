param (
    [Parameter(Mandatory=$false, Position=0, ParameterSetName='Create')]
    [switch]$Create,
    [Parameter(Mandatory=$true, ParameterSetName='Create')]
    [string]$cname,
    [Parameter(Mandatory=$true, ParameterSetName='Create')]
    [string]$testcommon,
    [Parameter(Mandatory=$true, ParameterSetName='Create')]
    [string]$testdata,
    [Parameter(Mandatory=$false, Position=0, ParameterSetName='Add')]
    [switch]$Add,
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='Add')]
    [string]$solution_file,
    [Parameter(Mandatory=$true, Position=2, ParameterSetName='Add')]
    [string]$type,
    [Parameter(Mandatory=$true, Position=3, ParameterSetName='Add')]
    [string]$file_to_add
)

function Create-Project {
	param (
		$cname,
        $tc_proj,
		$testdata_path,
		$gradedtests
    )

	$console_proj="$(Resolve-Path ".")/$cname/$cname/$cname.csproj"
	$test_proj="$(Resolve-Path ".")/$cname/$cname.Tests/$cname.Tests.csproj"

	dotnet new sln -o $cname
	cd $cname
	"Creating console project $cname..."
	dotnet new console -o $cname
	"Adding console project $cname to solution..."
	dotnet sln add $console_proj 
	"Creating mstest project $cname.Tests..."
	dotnet new mstest -o "$cname.Tests" 
	"Adding mstest project $cname to solution..."
	dotnet sln add $test_proj
	"Adding Testcommon..."
	dotnet sln add $tc_proj
	"Adding references..."
	dotnet add $test_proj reference $console_proj
	dotnet add $test_proj reference $tc_proj
	dotnet add $console_proj reference $tc_proj
	"Adding TestData..."
	Copy-Item -Path $test_data_path -Destination "$cname.Tests" -Recurse

	$test_output_policy=@'
	<ItemGroup>
		<Content Include="TestData\**">
		<CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
		</Content>
	</ItemGroup>
'@

	"Changing output policy..."
	$fileContent = Get-Content $test_proj
	$fileContent[$lineNumber-2] += $test_output_policy
	$fileContent | Set-Content $test_proj
}

if ($Create) {
	$tc_proj=Resolve-Path $testcommon
	$test_data_path=Resolve-Path $testdata
	Create-Project -cname $cname -tc_proj $tc_proj -testdata_path $testdata_path -gradedtests $gradedtests
} elseif ($Add) {
	$file_to_add_path = Resolve-Path $file_to_add
	$solution_file_resolved = Resolve-Path $solution_file
	$solution_path = Split-Path -Path $solution_file_resolved
	$cname_tmp = (Split-Path $solution_path -Leaf)
	$fname = (Split-Path $file_to_add_path -Leaf)

	if ($type -eq "problem") {
		Copy-Item $file_to_add_path -Destination "$solution_path/$cname_tmp/"
		"Added problem $fname"
	} elseif ($type -eq "test") {
		Copy-Item $file_to_add_path -Destination "$solution_path/$cname_tmp.Tests/"
		"Added test $fname"
	}
}

cd $PSScriptRoot
