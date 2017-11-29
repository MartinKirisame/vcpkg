[CmdletBinding()]
param (
    $libraries = @()
)

$scriptsDir = split-path -parent $MyInvocation.MyCommand.Definition

function Generate()
{
    param (
        [string]$Name,
        [string]$Hash,
        [string]$Options = "",
        $Depends = @()
    )

    $controlDeps = ((@("boost-modularscripts") + @($Depends | ? {
        # Boost contains cycles, so remove a few dependencies to break the loop.
        (($Name -notmatch "core|assert|mpl|detail|type_traits") -or ($_ -notmatch "utility")) `
        -and `
        (($Name -notmatch "lexical_cast") -or ($_ -notmatch "math"))`
        -and `
        (($Name -notmatch "functional") -or ($_ -notmatch "function"))`
        -and `
        (($Name -notmatch "detail") -or ($_ -notmatch "integer|mpl|type_traits"))`
        -and `
        (($Name -notmatch "property_map") -or ($_ -notmatch "mpi"))`
        -and `
        (($Name -notmatch "spirit") -or ($_ -notmatch "serialization"))`
        -and `
        (($Name -notmatch "utility|concept_check") -or ($_ -notmatch "iterator"))
    } | % { "boost-$_" -replace "_","-" })) | sort) -join ", "

    if ($Name -eq "python")
    {
        $controlDeps += ", python3"
    }
    elseif ($Name -eq "iostreams")
    {
        $controlDeps += ", zlib, bzip2"
    }

    $sanitizedName = $name -replace "_","-"

    mkdir "$scriptsDir/../boost-$sanitizedName" -erroraction SilentlyContinue | out-null
    $(gc "$scriptsDir/CONTROL.in") `
        -replace "@NAME@", "$sanitizedName" `
        -replace "@DEPENDS@", "$controlDeps" `
    | out-file -enc ascii "$scriptsDir/../boost-$sanitizedName/CONTROL"

    $(gc "$scriptsDir/portfile.cmake.in") `
        -replace "@NAME@", "$Name" `
        -replace "@HASH@", "$Hash" `
        -replace "@OPTIONS@", "$Options" `
    | out-file -enc ascii "$scriptsDir/../boost-$sanitizedName/portfile.cmake"

    if ($Name -eq "locale")
    {
        "`nFeature: icu`nDescription: ICU backend for Boost.Locale`nBuild-Depends: icu`n" | out-file -enc ascii -append "$scriptsDir/../boost-$sanitizedName/CONTROL"
    }
}

if (!(Test-Path "$scriptsDir/boost"))
{
    "Cloning boost..."
    pushd $scriptsDir
    try
    {
        git clone https://github.com/boostorg/boost
    }
    finally
    {
        popd
    }
}

$libraries_found = ls $scriptsDir/boost/libs -directory | % name | % {
    if ($_ -match "numeric")
    {
        "numeric_conversion"
        "interval"
        "odeint"
        "ublas"
    }
    else
    {
        $_
    }
}

mkdir $scriptsDir/downloads -erroraction SilentlyContinue | out-null

if ($libraries.Length -eq 0)
{
    $libraries = $libraries_found
}

foreach ($library in $libraries)
{
    "Handling boost/$library..."
    $archive = "$scriptsDir/downloads/$library-1.65.1.tar.gz"
    if (!(Test-Path $archive))
    {
        "Downloading boost/$library..."
        Invoke-WebRequest "https://github.com/boostorg/$library/archive/boost-1.65.1.tar.gz" -OutFile $archive
    }
    $hash = vcpkg hash $archive
    $unpacked = "$scriptsDir/libs/$library-boost-1.65.1"
    if (!(Test-Path $unpacked))
    {
        "Unpacking boost/$library..."
        mkdir $scriptsDir/libs -erroraction SilentlyContinue | out-null
        pushd $scriptsDir/libs
        try
        {
            cmake -E tar xf $archive
        }
        finally
        {
            popd
        }
    }
    pushd $unpacked
    try
    {
        $groups = $(
            findstr /si /C:"#include <boost/" include/*
            findstr /si /C:"#include <boost/" src/*
        ) |
        % { $_ -replace "^[^:]*:","" -replace "boost/numeric/conversion/","boost/numeric_conversion/" -replace "boost/detail/([^/]+)/","boost/`$1/" -replace "#include ?<boost/([a-zA-Z0-9\._]*)(/|>).*", "`$1" -replace "/|\.hp?p?| ","" } | group | % name | % {
            # mappings
            Write-Verbose "${library}: $_"
            if ($_ -match "aligned_storage") { "type_traits" }
            elseif ($_ -match "noncopyable|ref|swap|get_pointer|checked_delete|visit_each") { "core" }
            elseif ($_ -eq "type") { "core" }
            elseif ($_ -match "unordered_") { "unordered" }
            elseif ($_ -match "cstdint") { "integer" }
            elseif ($_ -match "call_traits|operators|current_function|cstdlib|next_prior") { "utility" }
            elseif ($_ -eq "version") { "config" }
            elseif ($_ -match "shared_ptr|make_shared|intrusive_ptr|scoped_ptr|pointer_to_other|weak_ptr|shared_array|scoped_array") { "smart_ptr" }
            elseif ($_ -match "iterator_adaptors|generator_iterator|pointee") { "iterator" }
            elseif ($_ -eq "regex_fwd") { "regex" }
            elseif ($_ -eq "make_default") { "convert" }
            elseif ($_ -eq "foreach_fwd") { "foreach" }
            elseif ($_ -eq "cerrno") { "system" }
            elseif ($_ -eq "archive") { "serialization" }
            elseif ($_ -eq "none") { "optional" }
            elseif ($_ -eq "integer_traits") { "integer" }
            elseif ($_ -eq "limits") { "compatibility" }
            elseif ($_ -eq "math_fwd") { "math" }
            elseif ($_ -match "polymorphic_cast|implicit_cast") { "conversion" }
            elseif ($_ -eq "nondet_random") { "random" }
            elseif ($_ -eq "memory_order") { "atomic" }
            elseif ($_ -eq "blank") { "detail" }
            elseif ($_ -match "is_placeholder|mem_fn") { "bind" }
            elseif ($_ -eq "exception_ptr") { "exception" }
            elseif ($_ -eq "multi_index_container") { "multi_index" }
            elseif ($_ -eq "lexical_cast") { "lexical_cast"; "math" }
            elseif ($_ -eq "numeric" -and $library -notmatch "numeric_conversion|interval|odeint|ublas") { "numeric_conversion"; "interval"; "odeint"; "ublas" }
            else { $_ }
        } | group | % name | ? { $_ -ne $library }

        #"`nFor ${library}:"
        "      [known] " + $($groups | ? { $libraries_found -contains $_ })
        "    [unknown] " + $($groups | ? { $libraries_found -notcontains $_ })
        Generate `
            -Name $library `
            -Hash $hash `
            -Depends @($groups | ? { $libraries_found -contains $_ })
    }
    finally
    {
        popd
    }
}

"Source: boost`nVersion: 1.65.1`nBuild-Depends: $($($libraries_found | % { "boost-$_" -replace "_","-" }) -join ", ")`n" | out-file -enc ascii $scriptsDir/../boost/CONTROL
"set(VCPKG_POLICY_EMPTY_PACKAGE enabled)`n" | out-file -enc ascii $scriptsDir/../boost/portfile.cmake

return
