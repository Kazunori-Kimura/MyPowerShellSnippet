#Backup-Database.ps1
#simple backup & restore script for SQLServer2008

Param(
  [switch] $backup,
  [switch] $restore,
  [string] $database="",
  [string] $server=$env:computerName,
  [string] $file="",
  [string] $directory="",
  [switch] $help,
  [switch] $debug
)

$usage=@'

���O
    Backup-Database

�T�v
    SQL Server�f�[�^�x�[�X�̊��S�o�b�N�A�b�v���쐬/�������܂��B

�\��
    Backup-Database {-Backup | -Restore} -Database <DatabaseName> [-Server <ServerName>] [-File <BackupFile> | 
     -Directory <BackupDir>]

����
    SqlCmd�R�}���h���g�p���ASQL Server�f�[�^�x�[�X�̊��S�o�b�N�A�b�v���쐬/�������܂��B
    SQL Server�ɂ�Windows�F�؂ɂĐڑ����܂��B�X�N���v�g���s�A�J�E���g�Ƀo�b�N�A�b�v/���X�g�A�����{����
    �������Ȃ��ꍇ�A�G���[�ƂȂ�܂��B
    
    File �I�v�V�������w�肵���ꍇ�ADirectory �I�v�V�����͖�������܂��B
    �ۑ���ƃt�@�C�����̗������w�肷��ꍇ ( ���Ƃ��΁AD:\backup �� backup.db �Ƃ������O�ō쐬�������ꍇ ) ��
    File �I�v�V�����Ƀp�X���w�肵�Ă��������B
    
    Backup���� File �I�v�V���������w��̏ꍇ�� DatabaseName ���o�b�N�A�b�v�t�@�C�������쐬���܂��B
    (.\<DatabaseName>_yyyyMMddHHmmss.bak)
    Restor���� File �I�v�V���������w��̏ꍇ�͗�O���������܂��B

�֘A���郊���N
    http://msdn.microsoft.com/ja-jp/library/ms186865.aspx
    http://msdn.microsoft.com/ja-jp/library/ms186858.aspx
    http://msdn.microsoft.com/ja-jp/library/ms179313.aspx

'@

$query_backup="BACKUP DATABASE {database_name} TO DISK = '{backup_file}'"
$query_restore="RESTORE DATABASE {database_name} FROM DISK = '{backup_file}' WITH REPLACE"

# Sqlcmd�����s
function Exec-SqlCommand($query){
  Sqlcmd -S $server -Q "$query"
}

# Backup�����{
function Backup-Database(){
  # database���w�聨Error
  if( $database.length -eq 0 ){
    throw "�ΏۂƂȂ� Database ���w�肵�Ă��������B"
  }
  # file���w�聨database�� + ���t�Ƃ���
  if( $file.length -eq 0 ){
    #�J�����g�f�B���N�g�����擾
    $current_path = Convert-Path .
    
    if( $directory.length -gt 0 ){
      #�f�B���N�g���w�莞
      if( Test-Path $directory ){
        $current_path = Convert-Path $directory
      }else{
        throw "�w�肳�ꂽ�f�B���N�g�������݂��܂���B [ $directory ]"
      }
    }
    
    #yyyyMMddhhmmss
    $date_time = Get-Date -format 'yyyyMMddHHmmss'
    #����
    $file = $current_path + '\' + $database + '_' + $date_time + '.bak';
  }

  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  $msg=@"

Backup�����{���܂��B[ $now ]
`tDatabase:`t$database
`tBackupFile:`t$file

"@
  Write-Host $msg
  
  $q = $query_backup -replace '{database_name}', $database
  $q = $q -replace '{backup_file}', $file
  
  Write-Debug "query= $q"
  
  Exec-SqlCommand $q
  
  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  
  Write-Host "`nBackup���������܂����B [ $now ]`n"
}

# Restore�����{
function Restore-Database(){
  # database���w�聨Error
  if( $database.length -eq 0 ){
    throw "�ΏۂƂȂ� Database ���w�肵�Ă��������B"
  }
  # file���w�聨Error
  if( $file.length -eq 0 ){
    throw "���X�g�A����t�@�C�����w�肵�Ă��������B"
  }
  # ���݂��Ȃ�file���w��
  if( Test-Path $file ){
    $file = Convert-Path $file
  }else{
    throw "�w�肳�ꂽ�t�@�C�������݂��܂���B [ $file ]"
  }

  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  $msg=@"

Restore�����{���܂��B[ $now ]
`tDatabase:`t$database
`tBackupFile:`t$file

"@
  Write-Host $msg
  
  $q = $query_restore -replace '{database_name}', $database
  $q = $q -replace '{backup_file}', $file
  
  Write-Debug "query= $q"
  
  Exec-SqlCommand $q
  
  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  
  Write-Host "`nRestore���������܂����B [ $now ]`n"
}

# �������`�F�b�N���A�����𕪊�
function Get-CommandLineOptions(){
  if($debug){
    #�f�o�b�O�\����L���ɂ���
    $DebugPreference="continue"
  }

  if( $help ){
    # Help�̕\��
    Write-Host $usage
  }elseif( $backup -and $restore ){
    # Backup �� Resutore �̗������w�� -> Error
    throw "Backup|Restore�̂ǂ��炩���w�肵�Ă��������B"
  }elseif( $backup ){
    Backup-Database
  }elseif( $restore ){
    Restore-Database
  }else{
    # Help�̕\��
    Write-Host $usage
  }
}

Get-CommandLineOptions

