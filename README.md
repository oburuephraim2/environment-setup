# environment-setup
environment-setup
PS C:\Users\Bayport\Downloads\development> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
>> Invoke-WebRequest -Uri "https://raw.githubusercontent.com/oburuephraim2/environment-setup/main/environ.ps1" -OutFile "$env:TEMP\environ.ps1"
>> & "$env:TEMP\environ.ps1"


# apps seetup
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/oburuephraim2/environment-setup/main/apps.ps1" -OutFile "$env:TEMP\apps.ps1" ; & "$env:TEMP\apps.ps1"
