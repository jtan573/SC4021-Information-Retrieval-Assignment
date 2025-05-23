@REM
@REM  Licensed to the Apache Software Foundation (ASF) under one or more
@REM  contributor license agreements.  See the NOTICE file distributed with
@REM  this work for additional information regarding copyright ownership.
@REM  The ASF licenses this file to You under the Apache License, Version 2.0
@REM  (the "License"); you may not use this file except in compliance with
@REM  the License.  You may obtain a copy of the License at
@REM
@REM      http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM  Unless required by applicable law or agreed to in writing, software
@REM  distributed under the License is distributed on an "AS IS" BASIS,
@REM  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM  See the License for the specific language governing permissions and
@REM  limitations under the License.

@echo off

set ERROR_CODE=0

:init
@REM Decide how to startup depending on the version of windows

@REM -- Win98ME
if NOT "%OS%"=="Windows_NT" goto Win9xArg

@REM set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" @setlocal

@REM -- 4NT shell
if "%eval[2+2]" == "4" goto 4NTArgs

@REM -- Regular WinNT shell
set CMD_LINE_ARGS=%*
goto WinNTGetScriptDir

@REM The 4NT Shell from jp software
:4NTArgs
set CMD_LINE_ARGS=%$
goto WinNTGetScriptDir

:Win9xArg
@REM Slurp the command line arguments.  This loop allows for an unlimited number
@REM of agruments (up to the command line limit, anyway).
set CMD_LINE_ARGS=
:Win9xApp
if %1a==a goto Win9xGetScriptDir
set CMD_LINE_ARGS=%CMD_LINE_ARGS% %1
shift
goto Win9xApp

:Win9xGetScriptDir
set SAVEDIR=%CD%
%0\
cd %0\..\..
set BASEDIR=%CD%
cd %SAVEDIR%
set SAVE_DIR=
goto repoSetup

:WinNTGetScriptDir
set BASEDIR=%~dp0..

:repoSetup

IF NOT "%JAVA_HEAP%"=="" set JAVA_MEM=-Xms%JAVA_HEAP% -Xmx%JAVA_HEAP%
IF "%JAVA_MEM%"=="" set JAVA_MEM=-Xms512m -Xmx512m
IF "%GC_TUNE%"=="" set GC_TUNE=-XX:+UseG1GC

if "%JAVACMD%"=="" set JAVACMD=java

if "%REPO%"=="" set REPO=%BASEDIR%\lib

set CLASSPATH=%REPO%\*;%BASEDIR%\conf;%BASEDIR%\..\server\lib\ext\*;%BASEDIR%\..\server\solr-webapp\webapp\WEB-INF\lib\*

@REM Convert Environment Variables to Command Line Options
set EXPORTER_ARGS=

IF NOT "%CONFIG_FILE%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% --config-file %CONFIG_FILE%
IF NOT "%PORT%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% -p %PORT%
IF NOT "%SCRAPE_INTERVAL%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% --scrape-interval %SCRAPE_INTERVAL%
IF NOT "%NUM_THREADS%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% --num-threads %NUM_THREADS%
IF NOT "%ZK_HOST%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% -z %ZK_HOST%
IF NOT "%SOLR_URL%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% -b %SOLR_URL%
IF NOT "%CLUSTER_ID%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% --cluster-id "%CLUSTER_ID%"
IF NOT "%CREDENTIALS%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% -u "%CREDENTIALS%"
IF NOT "%SSL_ENABLED%"=="" set EXPORTER_ARGS=%EXPORTER_ARGS% -ssl "%SSL_ENABLED%"
goto endInit

@REM Reaching here means variables are defined and arguments have been captured
:endInit

%JAVACMD% %JAVA_MEM% %GC_TUNE% %JAVA_OPTS% %ZK_CREDS_AND_ACLS% -classpath "%CLASSPATH_PREFIX%;%CLASSPATH%" -Dapp.name="solr-exporter" -Dapp.repo="%REPO%" -Dbasedir="%BASEDIR%" org.apache.solr.prometheus.exporter.SolrExporter %EXPORTER_ARGS% %CMD_LINE_ARGS%
if ERRORLEVEL 1 goto error
goto end

:error
if "%OS%"=="Windows_NT" @endlocal
set ERROR_CODE=1

:end
@REM set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" goto endNT

@REM For old DOS remove the set variables from ENV - we assume they were not set
@REM before we started - at least we don't leave any baggage around
set CMD_LINE_ARGS=
goto postExec

:endNT
@endlocal

:postExec

if "%FORCE_EXIT_ON_ERROR%" == "on" (
  if %ERROR_CODE% NEQ 0 exit %ERROR_CODE%
)

exit /B %ERROR_CODE%
