# Set variables
If (Test-Path 'env:APPVEYOR_BUILD_FOLDER') {
    $projectRoot = Resolve-Path -Path $env:APPVEYOR_BUILD_FOLDER
}
Else {
    # Local Testing 
    $projectRoot = Resolve-Path -Path (((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName)
}
If ($Null -eq $module ) { $module = "LatestUpdate" }
$moduleParent = Join-Path $projectRoot $module
$manifestPath = Join-Path $moduleParent "$module.psd1"
$modulePath = Join-Path $moduleParent "$module.psm1"
$modulePrivate = Join-Path $moduleParent "Private"
$modulePublic = Join-Path $moduleParent "Public"
Import-Module (Join-Path $projectRoot $module) -Force

Describe "General project validation" {
    $scripts = Get-ChildItem (Join-Path $projectRoot $module) -Recurse -Include *.ps1, *.psm1

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object { @{file = $_ } }         
    It "Script <file> should be valid PowerShell" -TestCases $testCase {
        param($file)

        $file.fullname | Should Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should Be 0
    }
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule
    It "<file> should pass ScriptAnalyzer" -TestCases $testCase {
        param($file)
        $analysis = Invoke-ScriptAnalyzer -Path  $file.fullname -ExcludeRule @('PSAvoidGlobalVars', 'PSAvoidUsingConvertToSecureStringWithPlainText', 'PSAvoidUsingWMICmdlet') -Severity @('Warning', 'Error')   
        
        ForEach ($rule in $scriptAnalyzerRules) {        
            If ($analysis.RuleName -contains $rule) {
                $analysis |
                Where-Object RuleName -EQ $rule -outvariable failures |
                Out-Default
                $failures.Count | Should Be 0
            }
        }
    }
}

Describe "Function validation" {
    $scripts = Get-ChildItem (Join-Path $projectRoot $module) -Recurse -Include *.ps1
    $testCase = $scripts | ForEach-Object { @{file = $_ } }         
    It "Script <file> should only contain one function" -TestCases $testCase {
        param($file)   
        $file.fullname | Should Exist
        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $describes = [Management.Automation.Language.Parser]::ParseInput($contents, [ref]$null, [ref]$null)
        $test = $describes.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) 
        $test.Count | Should Be 1
    }
    It "<file> should match function name" -TestCases $testCase {
        param($file)   
        $file.fullname | Should Exist
        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $describes = [Management.Automation.Language.Parser]::ParseInput($contents, [ref]$null, [ref]$null)
        $test = $describes.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) 
        $test[0].name | Should Be $file.basename
    }
}

# Test module and manifest
Describe 'Module Metadata Validation' {      
    It 'Script fileinfo should be OK' {
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should Not Throw
    }   
    It 'Import module should be OK' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should Not Throw
    }
}
