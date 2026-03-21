
## sshコマンド

ssh -i my-ec2-key.pem ec2-user@<EC2のIP>



## ec2のSSH鍵について
以下コマンドで作成

---------------------------------
aws ec2 create-key-pair \
  --key-name my-ec2-key \
  --query 'KeyMaterial' \
  --output text > my-ec2-key.pem

chmod 400 my-ec2-key.pem
--------------------------------------


## windowsでchmodするには

Windows では chmod は不要です。
代わりに NTFS のアクセス権（ACL）を制限します。

SSH（OpenSSH）は
Linux / macOSなら → chmod 400
Windows → 「自分以外が読めない ACL」

でチェックしています。

一番簡単・確実な方法（推奨）
① .pem ファイルを右クリック → プロパティ

.pem ファイルを右クリック

プロパティ → セキュリティ タブ

詳細設定 をクリック

② 継承を無効化

「継承を無効にする」をクリック

「継承されたアクセス許可をこのオブジェクトから削除」 を選択

③ 自分だけ残す

表示されているユーザーのうち、

❌ Users

❌ Everyone

❌ Authenticated Users

❌ Administrators（※後述）

を 削除し、

✅ 自分のユーザーアカウント

アクセス許可：読み取り（Read） のみ

だけを残します。

※ Administrators が残っていると
UNPROTECTED PRIVATE KEY FILE エラーになることがあります

④ OK → OK

これで Linux の chmod 400 と同等になります。

コマンドでやる方法（PowerShell）

GUI が面倒なら、**PowerShell（管理者）**で以下。

# 継承を無効化
icacls .\my-ec2-key.pem /inheritance:r
  
# 自分に読み取りのみ許可
icacls .\my-ec2-key.pem /grant:r "$($env:USERNAME):(R)"

# 他のユーザーを削除
icacls .\my-ec2-key.pem /remove "Users" "Authenticated Users" "Everyone"


※ my-ec2-key.pem は実際のファイル名に置き換えてください。

正しく設定できているかの確認
icacls my-ec2-key.pem


理想形：

my-ec2-key.pem YOUR-PC\yourname:(R)


これだけなら OK です。

よくあるエラーと原因
❌ UNPROTECTED PRIVATE KEY FILE

→ 権限が広すぎる
→ 上記 ACL 制限を再確認

❌ Permission denied (publickey)

→ 鍵は正しいが

KeyPair 名が違う

EC2 側のユーザー違い（AL2023 は ec2-user）

SSH コマンド例（Amazon Linux 2023）
ssh -i my-ec2-key.pem ec2-user@<EC2のIP>