@echo off
setlocal enabledelayedexpansion

:: Get parameters
set "BASE_DIR=%~1"
set "NEW_DIR=%~2"
set "JAR_FILE=%~3"
set "BUILD_TOOLS_DIR=%~4"
set "GRAALVM_DIR=%~5"

echo Starting GraalVM native image build process...

:: Set GraalVM environment variables
set "JAVA_HOME=%GRAALVM_DIR%"
set "GRAALVM_HOME=%GRAALVM_DIR%"
set "PATH=%GRAALVM_DIR%\bin;%PATH%"

:: Initialize the Visual Studio environment
call "%BUILD_TOOLS_DIR%\path\msvc\vcvars64.bat"

:: Create reflection configuration file for JavaFX
echo Creating reflection configuration for JavaFX...
echo [ > "%BASE_DIR%javafx-reflect-config.json"
echo   { >> "%BASE_DIR%javafx-reflect-config.json"
echo     "name": "com.sun.javafx.tk.quantum.QuantumToolkit", >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%javafx-reflect-config.json"
echo   }, >> "%BASE_DIR%javafx-reflect-config.json"
echo   { >> "%BASE_DIR%javafx-reflect-config.json"
echo     "name": "com.sun.prism.d3d.D3DPipeline", >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%javafx-reflect-config.json"
echo   }, >> "%BASE_DIR%javafx-reflect-config.json"
echo   { >> "%BASE_DIR%javafx-reflect-config.json"
echo     "name": "com.sun.javafx.application.LauncherImpl", >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%javafx-reflect-config.json"
echo   }, >> "%BASE_DIR%javafx-reflect-config.json"
echo   { >> "%BASE_DIR%javafx-reflect-config.json"
echo     "name": "com.sun.prism.GraphicsPipeline", >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%javafx-reflect-config.json"
echo   }, >> "%BASE_DIR%javafx-reflect-config.json"
echo   { >> "%BASE_DIR%javafx-reflect-config.json"
echo     "name": "scala.runtime.LazyVals$", >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%javafx-reflect-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%javafx-reflect-config.json"
echo   } >> "%BASE_DIR%javafx-reflect-config.json"
echo ] >> "%BASE_DIR%javafx-reflect-config.json"

:: Create the JNI configuration file
echo Creating JNI configuration...
echo [ > "%BASE_DIR%jni-config.json"
echo   { >> "%BASE_DIR%jni-config.json"
echo     "name": "scala.runtime.LazyVals$", >> "%BASE_DIR%jni-config.json"
echo     "allDeclaredConstructors": true, >> "%BASE_DIR%jni-config.json"
echo     "allPublicConstructors": true, >> "%BASE_DIR%jni-config.json"
echo     "allDeclaredMethods": true, >> "%BASE_DIR%jni-config.json"
echo     "allPublicMethods": true >> "%BASE_DIR%jni-config.json"
echo   } >> "%BASE_DIR%jni-config.json"
echo ] >> "%BASE_DIR%jni-config.json"

echo Running native-image build with JavaFX support...
"%GRAALVM_DIR%\bin\native-image.cmd" ^
  --no-fallback ^
  -jar "%JAR_FILE%" ^
  -H:Name=game ^
  -o "%NEW_DIR%\game" ^
  -H:+UnlockExperimentalVMOptions ^
  -H:ReflectionConfigurationFiles="%BASE_DIR%javafx-reflect-config.json" ^
  -H:JNIConfigurationFiles="%BASE_DIR%jni-config.json" ^
  --enable-url-protocols=http,https ^
  --add-exports=java.base/java.lang=ALL-UNNAMED ^
  --enable-native-access=ALL-UNNAMED ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\cppwinrt" ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\msvc" ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\shared" ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\ucrt" ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\um" ^
  -H:CCompilerOption="/I%BUILD_TOOLS_DIR%\include\winrt" ^
  -H:+ReportExceptionStackTraces ^
  -H:+PrintClassInitialization ^
  --allow-incomplete-classpath ^
  -H:IncludeResourceBundles=com.sun.javafx.tk.quantum.QuantumMessagesBundle ^
  -H:EnableURLProtocols=http,https,file,jar ^
  -H:+AddAllCharsets

:: Always return success to ensure the main script continues
exit /b 0
