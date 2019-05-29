gsutil cp gs://pivotal-gpdb-concourse-resources-dev/clients/published/gpdb6/greenplum-clients-6.0.0-x86_64.msi .
Invoke-WebRequest -Uri https://aka.ms/vs/15/release/VC_redist.x64.exe -OutFile VC_redist.x64.exe
Start-Process -FilePath "VC_redist.x64.exe" -ArgumentList "/passive" -Wait -Passthru
Start-Process msiexec.exe -Wait -ArgumentList '/I greenplum-clients-6.0.0-x86_64.msi /quiet'
$env:PATH="C:\Program Files\Greenplum\greenplum-clients-6.0.0\bin;" + $env:PATH
psql -U gpadmin -p 15432 -h 127.0.0.1 -c 'select version();' postgres

