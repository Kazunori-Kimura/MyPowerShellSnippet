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

名前
    Backup-Database

概要
    SQL Serverデータベースの完全バックアップを作成/復元します。

構文
    Backup-Database {-Backup | -Restore} -Database <DatabaseName> [-Server <ServerName>] [-File <BackupFile> | 
     -Directory <BackupDir>]

説明
    SqlCmdコマンドを使用し、SQL Serverデータベースの完全バックアップを作成/復元します。
    SQL ServerにはWindows認証にて接続します。スクリプト実行アカウントにバックアップ/リストアを実施する
    権限がない場合、エラーとなります。
    
    File オプションを指定した場合、Directory オプションは無視されます。
    保存先とファイル名の両方を指定する場合 ( たとえば、D:\backup に backup.db という名前で作成したい場合 ) は
    File オプションにパスを指定してください。
    
    Backup時に File オプションが未指定の場合は DatabaseName よりバックアップファイル名を作成します。
    (.\<DatabaseName>_yyyyMMddHHmmss.bak)
    Restor時に File オプションが未指定の場合は例外が発生します。

関連するリンク
    http://msdn.microsoft.com/ja-jp/library/ms186865.aspx
    http://msdn.microsoft.com/ja-jp/library/ms186858.aspx
    http://msdn.microsoft.com/ja-jp/library/ms179313.aspx

'@

$query_backup="BACKUP DATABASE {database_name} TO DISK = '{backup_file}'"
$query_restore="RESTORE DATABASE {database_name} FROM DISK = '{backup_file}' WITH REPLACE"

# Sqlcmdを実行
function Exec-SqlCommand($query){
  Sqlcmd -S $server -Q "$query"
}

# Backupを実施
function Backup-Database(){
  # database未指定→Error
  if( $database.length -eq 0 ){
    throw "対象となる Database を指定してください。"
  }
  # file未指定→database名 + 日付とする
  if( $file.length -eq 0 ){
    #カレントディレクトリを取得
    $current_path = Convert-Path .
    
    if( $directory.length -gt 0 ){
      #ディレクトリ指定時
      if( Test-Path $directory ){
        $current_path = Convert-Path $directory
      }else{
        throw "指定されたディレクトリが存在しません。 [ $directory ]"
      }
    }
    
    #yyyyMMddhhmmss
    $date_time = Get-Date -format 'yyyyMMddHHmmss'
    #結合
    $file = $current_path + '\' + $database + '_' + $date_time + '.bak';
  }

  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  $msg=@"

Backupを実施します。[ $now ]
`tDatabase:`t$database
`tBackupFile:`t$file

"@
  Write-Host $msg
  
  $q = $query_backup -replace '{database_name}', $database
  $q = $q -replace '{backup_file}', $file
  
  Write-Debug "query= $q"
  
  Exec-SqlCommand $q
  
  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  
  Write-Host "`nBackupが完了しました。 [ $now ]`n"
}

# Restoreを実施
function Restore-Database(){
  # database未指定→Error
  if( $database.length -eq 0 ){
    throw "対象となる Database を指定してください。"
  }
  # file未指定→Error
  if( $file.length -eq 0 ){
    throw "リストアするファイルを指定してください。"
  }
  # 存在しないfileを指定
  if( Test-Path $file ){
    $file = Convert-Path $file
  }else{
    throw "指定されたファイルが存在しません。 [ $file ]"
  }

  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  $msg=@"

Restoreを実施します。[ $now ]
`tDatabase:`t$database
`tBackupFile:`t$file

"@
  Write-Host $msg
  
  $q = $query_restore -replace '{database_name}', $database
  $q = $q -replace '{backup_file}', $file
  
  Write-Debug "query= $q"
  
  Exec-SqlCommand $q
  
  $now = Get-Date -format 'yyyy/MM/dd HH:mm:ss'
  
  Write-Host "`nRestoreが完了しました。 [ $now ]`n"
}

# 引数をチェックし、処理を分岐
function Get-CommandLineOptions(){
  if($debug){
    #デバッグ表示を有効にする
    $DebugPreference="continue"
  }

  if( $help ){
    # Helpの表示
    Write-Host $usage
  }elseif( $backup -and $restore ){
    # Backup と Resutore の両方を指定 -> Error
    throw "Backup|Restoreのどちらかを指定してください。"
  }elseif( $backup ){
    Backup-Database
  }elseif( $restore ){
    Restore-Database
  }else{
    # Helpの表示
    Write-Host $usage
  }
}

Get-CommandLineOptions

