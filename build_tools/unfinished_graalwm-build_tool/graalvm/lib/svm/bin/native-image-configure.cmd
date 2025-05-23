::
:: ----------------------------------------------------------------------------------------------------
::
:: Copyright (c) 2019, 2025, Oracle and/or its affiliates. All rights reserved.
:: DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
::
:: This code is free software; you can redistribute it and/or modify it
:: under the terms of the GNU General Public License version 2 only, as
:: published by the Free Software Foundation.  Oracle designates this
:: particular file as subject to the "Classpath" exception as provided
:: by Oracle in the LICENSE file that accompanied this code.
::
:: This code is distributed in the hope that it will be useful, but WITHOUT
:: ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
:: FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
:: version 2 for more details (a copy is included in the LICENSE file that
:: accompanied this code).
::
:: You should have received a copy of the GNU General Public License version
:: 2 along with this work; if not, write to the Free Software Foundation,
:: Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
::
:: Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
:: or visit www.oracle.com if you need additional information or have any
:: questions.
::
:: ----------------------------------------------------------------------------------------------------
@echo off

:: Please read file `windows.md` before making changes.

setlocal enabledelayedexpansion

call :getScriptLocation location
call :getExecutableName executablename
for /f "delims=" %%i in ("%executablename%") do set "basename=%%~ni"

set "relcp=..\..\graalvm\svm-configure.jar;..\..\graalvm\svm-enterprise-configure.jar;..\builder\native-image-base.jar;..\builder\objectfile.jar;..\builder\pointsto.jar;..\builder\svm-enterprise.jar;..\builder\svm.jar;..\library-support.jar"
set "absolute_cp="
set newline=^


:: The two white lines above this comment are significant.

:: Split on semicolon by replacing it by newlines.
for /f "delims=" %%i in ("%relcp:;=!newline!%") do (
    if "!absolute_cp!"=="" (
        set "absolute_cp=%location%%%i"
    ) else (
        set "absolute_cp=!absolute_cp!;%location%%%i"
    )
)

set "jvm_args=-Dorg.graalvm.launcher.shell=true "-Dorg.graalvm.launcher.executablename=%executablename%""
set "launcher_args="

:: Check option-holding variables.
:: Those can be specified as the `option_vars` argument of the LauncherConfig constructor.
for %%v in () do (
    if "!%%v:~0,5!"=="--vm.*" (
        call :escape_args !%%v!
        for %%o in (!args!) do (
            call :unescape_arg %%o
            call :process_arg !arg!
            if errorlevel 1 exit /b 1
        )
    )
)

call :escape_args %*
for %%a in (%args%) do (
  call :unescape_arg %%a
  call :process_arg !arg!
  if errorlevel 1 exit /b 1
)

set "module_launcher=True"
:: The list of --add-exports can easily exceed the 8191 command
:: line character limit so pass them in a command line arguments file.
if "%module_launcher%"=="True" (
  set "main_class=--module org.graalvm.nativeimage.enterprise.configure/com.oracle.svm.enterprise.configure.ConfigurationEnterpriseTool"
  set "app_path_arg=--module-path"
  set exports_file="%location%!basename!.export-list"
  set "jvm_args=!jvm_args! @!exports_file!"
) else (
  set "main_class=com.oracle.svm.enterprise.configure.ConfigurationEnterpriseTool"
  set "app_path_arg=-cp"
)

if "%VERBOSE_GRAALVM_LAUNCHERS%"=="true" echo on

"%location%..\..\..\bin\java" "--add-exports=jdk.graal.compiler/jdk.graal.compiler.phases.common=ALL-UNNAMED" "--add-exports=jdk.internal.vm.ci/jdk.vm.ci.meta=ALL-UNNAMED" "--add-exports=jdk.internal.vm.ci/jdk.vm.ci.services=ALL-UNNAMED" "--add-exports=jdk.graal.compiler/jdk.graal.compiler.core.common.util=ALL-UNNAMED" -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI %jvm_args% %app_path_arg% "%absolute_cp%" %main_class% %launcher_args%

exit /b %errorlevel%
:: Function are defined via labels, so have to be defined at the end of the file and skipped
:: in order not to be executed.

:escape_args
    set "args=%*"
    :: Without early exit on empty contents, substitutions fail.
    if "!args!"=="" exit /b 0
    set "args=%args:,=##GR_ESC_COMMA##%"
    set "args=%args:;=##GR_ESC_SEMI##%"
    :: Temporarily, so that args are split on '=' only.
    set "args=%args: =##GR_ESC_SPACE##%"
    :: Temporarily, otherwise we won't split on '=' inside quotes.
    set "args=%args:"=##GR_ESC_QUOTE##%"
    :: We can't replace equal using the variable substitution syntax.
    call :replace_equals %args%
    set "args=%args:##GR_ESC_SPACE##= %"
    set "args=%args:##GR_ESC_QUOTE##="%"
    exit /b 0

:replace_equals
    setlocal
    :: The argument passed to this function was split on =, because all other
    :: delimiters were replaced in escape_args.
    set "arg=%1"
    if "!arg!"=="" goto :end_replace_equals
    set "args=%1"
    shift
    :loop_replace_equals
        set "arg=%1"
        if "!arg!"=="" goto :end_replace_equals
        set "args=%args%##GR_ESC_EQUAL##%arg%"
        shift
        goto :loop_replace_equals
    :end_replace_equals
        endlocal & ( set "args=%args%" )
        exit /b 0

:unescape_arg
    set "arg=%*"
    set "arg=%arg:##GR_ESC_COMMA##=,%"
    set "arg=%arg:##GR_ESC_SEMI##=;%"
    set "arg=%arg:##GR_ESC_EQUAL##==%"
    exit /b 0

:is_quoted
    setlocal
    set "args=%*"
    set /a argslen=0
    for %%a in (%args%) do set /a argslen+=1
    if %argslen% gtr 1 (
        set "quoted=false"
    ) else (
        if "!args:~0,1!!args:~-1!"=="""" ( set "quoted=true" ) else ( set "quoted=false" )
    )
    endlocal & ( set "quoted=%quoted%" )
    exit /b 0

:unquote_arg
    :: Sets %arg% to a version of the argument with outer quotes stripped, if present.
    call :is_quoted %*
    setlocal
    set "maybe_quoted=%*"
    if %quoted%==true ( set "arg=%~1" ) else ( set "arg=!maybe_quoted!" )
    endlocal & ( set "arg=%arg%" )
    exit /b 0

:: Unfortunately, parsing of `--vm.*` arguments has to be done blind:
:: Maybe some of those arguments where not really intended for the launcher but were application
:: arguments.

:process_vm_arg
    if %arg_quoted%==false (
        call :is_quoted %*
        set "arg_quoted=%quoted%"
    )
    call :unquote_arg %*
    set "vm_arg=%arg%"
    set "custom_cp="

    if "!vm_arg!"=="cp" (
        set "part1='--%prefix%.cp' argument must be of the form"
        set "part2='--%prefix%.cp=..\..\graalvm\svm-configure.jar;..\..\graalvm\svm-enterprise-configure.jar;..\builder\native-image-base.jar;..\builder\objectfile.jar;..\builder\pointsto.jar;..\builder\svm-enterprise.jar;..\builder\svm.jar;..\library-support.jar', not two separate arguments."
        >&2 echo !part1! !part2!
        exit /b 1
    ) else if "!vm_arg!"=="classpath" (
        set "part1='--%prefix%.classpath' argument must be of the form"
        set "part2='--%prefix%.classpath=..\..\graalvm\svm-configure.jar;..\..\graalvm\svm-enterprise-configure.jar;..\builder\native-image-base.jar;..\builder\objectfile.jar;..\builder\pointsto.jar;..\builder\svm-enterprise.jar;..\builder\svm.jar;..\library-support.jar', not two separate arguments."
        >&2 echo !part1! !part2!
        exit /b 1
    ) else if "!vm_arg:~0,3!"=="cp=" (
        call :unquote_arg %vm_arg:~3%
        set "absolute_cp=%absolute_cp%;!arg!"
    ) else if "!vm_arg:~0,10!"=="classpath=" (
        call :unquote_arg %vm_arg:~10%
        set "absolute_cp=%absolute_cp%;!arg!"
    ) else if "!vm_arg:~0,1!"=="@" (
        if %arg_quoted%==true ( set "arg="%vm_arg%"" ) else ( set "arg=%vm_arg%" )
        set "jvm_args=%jvm_args% !arg!"
    ) else (
        if %arg_quoted%==true ( set "arg="-%vm_arg%"" ) else ( set "arg=-%vm_arg%" )
        set "jvm_args=%jvm_args% !arg!"
    )
    exit /b 0

:process_arg
    set "original_arg=%*"
    call :unquote_arg !original_arg!
    set "arg_quoted=%quoted%"

    if "!arg:~0,5!"=="--vm." (
        set prefix=vm
        call :unquote_arg !arg:~5!
        call :process_vm_arg !arg!
        if errorlevel 1 exit /b 1
    ) else (
        if "!arg!"=="--native" (
            >&2 echo The native version of %basename% does not exist: cannot use '!arg!'.
            set "extra="
            if "!basename!"=="polyglot" set "extra= --language:all"
            set "part1=If native-image is installed, you may build it with"
            set "part2='native-image --macro:native-image-configure-launcher!extra!'."
            >&2 echo !part1! !part2!
            exit /b 1
        ) else (
            :: Use !original_arg! instead of !arg! to preserve surrounding quotes if present.
            set "launcher_args=%launcher_args% !original_arg!"
        )
    )
    exit /b 0

:: If this script is in `%PATH%` and called quoted without a full path (e.g., `"js"`), `%~dp0` is expanded to `cwd`
:: rather than the path to the script.
:: This does not happen if `%~dp0` is accessed in a subroutine.
:getScriptLocation variableName
    set "%~1=%~dp0"
    exit /b 0

:getExecutableName variableName
    set "%~1=%~f0"
    exit /b 0

endlocal
