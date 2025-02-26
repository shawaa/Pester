﻿function Context {
    <#
    .SYNOPSIS
    Provides logical grouping of It blocks within a single Describe block.

    .DESCRIPTION
    Provides logical grouping of It blocks within a single Describe block.
    Any Mocks defined inside a Context are removed at the end of the Context scope,
    as are any files or folders added to the TestDrive during the Context block's
    execution. Any BeforeEach or AfterEach blocks defined inside a Context also only
    apply to tests within that Context .

    .PARAMETER Name
    The name of the Context. This is a phrase describing a set of tests within a describe.

    .PARAMETER Tag
    Optional parameter containing an array of strings. When calling Invoke-Pester,
    it is possible to specify a -Tag parameter which will only execute Context blocks
    containing the same Tag.

    .PARAMETER Fixture
    Script that is executed. This may include setup specific to the context
    and one or more It blocks that validate the expected outcomes.

    .PARAMETER ForEach
    Allows data driven tests to be written.
    Takes an array of data and generates one block for each item in the array, and makes the item
    available as $_ in all child blocks. When the array is an array of hashtables, it additionally
    defines each key in the hashatble as variable.

    .EXAMPLE
    ```powershell
    BeforeAll {
        function Add-Numbers($a, $b) {
            return $a + $b
        }
    }

    Describe 'Add-Numbers' {
        Context 'when adding positive values' {
            It '...' {
                # ...
            }
        }

        Context 'when adding negative values' {
            It '...' {
                # ...
            }
            It '...' {
                # ...
            }
        }
    }
    ```

    Example of how to use Context for grouping different tests

    .LINK
    https://pester.dev/docs/commands/Context

    .LINK
    https://pester.dev/docs/usage/test-file-structure

    .LINK
    https://pester.dev/docs/usage/mocking

    .LINK
    https://pester.dev/docs/usage/testdrive
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Alias('Tags')]
        [string[]] $Tag = @(),

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ScriptBlock] $Fixture,

        # [Switch] $Focus,
        [Switch] $Skip,

        $ForEach
    )

    $Focus = $false
    if ($Fixture -eq $null) {
        if ($Name.Contains("`n")) {
            throw "Test fixture name has multiple lines and no test fixture is provided. (Have you provided a name for the test group?)"
        }
        else {
            throw 'No test fixture is provided. (Have you put the open curly brace on the next line?)'
        }
    }

    if ($ExecutionContext.SessionState.PSVariable.Get('invokedViaInvokePester')) {
        if ($state.CurrentBlock.IsRoot -and $state.CurrentBlock.Blocks.Count -eq 0) {
            # For undefined parameters in container, add parameter's default value to Data
            Add-MissingContainerParameters -RootBlock $state.CurrentBlock -Container $container -CallingFunction $PSCmdlet
        }

        if ($PSBoundParameters.ContainsKey('ForEach')) {
            if ($null -ne $ForEach -and 0 -lt @($ForEach).Count) {
                New-ParametrizedBlock -Name $Name -ScriptBlock $Fixture -StartLine $MyInvocation.ScriptLineNumber -Tag $Tag -FrameworkData @{ CommandUsed = 'Context'; WrittenToScreen = $false } -Focus:$Focus -Skip:$Skip -Data $ForEach
            }
            else {
                # @() or $null is provided do nothing

            }
        }
        else {
            New-Block -Name $Name -ScriptBlock $Fixture -StartLine $MyInvocation.ScriptLineNumber -Tag $Tag -FrameworkData @{ CommandUsed = 'Context'; WrittenToScreen = $false } -Focus:$Focus -Skip:$Skip
        }
    }
    else {
        Invoke-Interactively -CommandUsed 'Context' -ScriptName $PSCmdlet.MyInvocation.ScriptName -SessionState $PSCmdlet.SessionState -BoundParameters $PSCmdlet.MyInvocation.BoundParameters
    }
}
