@echo off
for /f "delims=" %%i in (Config.ini) do (
    set %%i
)

set date0=%date:~0,10%
set time0=%time:~1,7%
set dttm=%date0%_%time0::=%
set dttm=%dttm:/=%
set log_file=log\log_%dttm%.txt

set script="option batch continue"
set script=%script% "open sftp://%user_name%:%password%@%upload_host% -hostkey=*"
set script=%script% "put jar\%jar_name% %upload_dir%" "call cd %upload_dir%"
set script=%script% "call hadoop fs -rm -r %hadoop_output%"
set script=%script% "call hadoop jar %jar_name% %package_name%"
set script=%script% "call mkdir %upload_dir%/output"
set script=%script% "call hadoop fs -get %hadoop_output% %upload_dir%/output"
set script=%script% "get %upload_dir%/output %~dp0\result\%dttm%" "exit"

rem set script=%script% "call hadoop jar %jar_name% %package_name% %hadoop_input% %hadoop_output%" "exit"
rem set script=%script% "call hadoop jar %jar_name% %package_name% %hadoop_option%" "exit"

echo Running...
cd /d %~dp0
md result\%dttm%
%~dp0/WinSCP.com /command %script% > %log_file%
type %log_file%
pause