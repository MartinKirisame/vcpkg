$scriptsDir = split-path -parent $MyInvocation.MyCommand.Definition

pushd $scriptsDir/../../packages
try
{
    $pkgs = ls boost-*_x64-windows

    foreach ($pkg in $pkgs)
    {
        pushd $pkg
        try
        {
            $includes = findstr /si /C:"#include <boost/" include/* | % { $_ -replace "^[^:]*:","" }
            $groups = $includes | % { $_ -replace "#include <boost/([a-zA-Z\._]*)(/|>).*", "`$1"} | group

            "`nFor ${pkg}:"
            $groups
        }
        finally
        {
            popd
        }
    }
}
finally
{
    popd
}