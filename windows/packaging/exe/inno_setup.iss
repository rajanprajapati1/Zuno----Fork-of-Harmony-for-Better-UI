[Setup]
AppId=B9F6E402-0CAE-4045-BDE6-14BD6C39C4EA
AppVersion=1.12.2+27
AppName=Zuno
AppPublisher=anandnet
AppPublisherURL=https://github.com/rajanprajapati1/Zuno----Fork-of-Harmony-for-Better-UI
AppSupportURL=https://github.com/rajanprajapati1/Zuno----Fork-of-Harmony-for-Better-UI
AppUpdatesURL=https://github.com/rajanprajapati1/Zuno----Fork-of-Harmony-for-Better-UI
DefaultDirName={autopf}\zuno
DisableProgramGroupPage=yes
OutputDir=..\..\.\installers
OutputBaseFilename=zuno-setup-1.12.2
Compression=lzma
SolidCompression=yes
SetupIconFile=..\..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=lowest
LicenseFile=..\..\..\LICENSE
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\..\build\windows\x64\runner\Release\zuno.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\Zuno"; Filename: "{app}\zuno.exe"
Name: "{autodesktop}\Zuno"; Filename: "{app}\zuno.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\zuno.exe"; Description: "{cm:LaunchProgram,{#StringChange('Zuno', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
