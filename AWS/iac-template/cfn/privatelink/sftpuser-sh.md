### 動作確認

# id sftpuser
uid=1001(sftpuser) gid=1001(sftpuser) groups=1001(sftpuser)
# 失敗
id: ‘sftpuser’: no such user
ls -ld /home/sftpuser
drwxr-xr-x  root     root     /home/sftpuser
ls -ld /home/sftpuser/upload
drwx------  sftpuser sftpuser /home/sftpuser/upload
grep -A5 -n "Match User sftpuser" /etc/ssh/sshd_config
# 期待値
Match User sftpuser
  ChrootDirectory /home/sftpuser
  ForceCommand internal-sftp
  AllowTcpForwarding no
  X11Forwarding no
  PasswordAuthentication yes
grep "^Subsystem sftp" /etc/ssh/sshd_config
Subsystem sftp internal-sftp
systemctl status sshd
#EC2 ローカルで SFTP 接続テスト（重要）
sftp sftpuser@localhost
パスワードを聞かれ、ログインできれば成功。
pwd
ls
cd upload
put /etc/hostname test.txt
ls
exit


## ec2がサーバとして利用できるか（①http ②sftp put)

- sv-ec2でlocal sftp put -> OK
- SGの穴あけは完了していることを確認
- 1.自pcのからのみ許可してweb見れるか
    - ブラウザからアクセス
        - http://3.112.44.224:8080/　-> OK
- 2.自pcからのみ許可してsftp可能か
    - sftp sftpuser@<EC2のパブリックIP>
    - パスワードを入力
    - cd upload
    - put c:\user-name/current-directory/test-put.txt
    - put c:\user-name/current-directory/test-put.txt test-put-same.tx
    - exit


