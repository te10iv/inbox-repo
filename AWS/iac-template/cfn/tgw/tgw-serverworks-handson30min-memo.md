### serverworks blog,youtube
### 【30分AWSハンズオン(7)】Transit Gatewayを使ってVPC間通信をしてみよう
### https://blog.serverworks.co.jp/30min-handson-tgw
### https://www.youtube.com/watch?v=HwctHgf_P8A&t=522s
### 作成されるもの・・・①vpc1+2subnet+ec2,②vpc2+2subnet+ec2
#### 参考サイト　AWS Transit Gatewayを図解しながら理解する　https://qiita.com/jowoooon/items/93affe30a80224826cde


# 1.Transit Gateway を設定
- 1.Transit Gateway を設定
  - Amazon 側の自律システム番号 (ASN) 
    - →空欄のままでよい
  - DNS サポート
    - 有効
  - セキュリティグループ参照サポート
    - 有効
  - VPN ECMP サポート
    - 有効
  - デフォルトルートテーブルの関連付け
    - 有効
  - デフォルトルートテーブル伝播
    - 有効
  - マルチキャストサポート
    - 無効
- 作成をクリック
  - 2分ほど待つ（avalableになるまで）


- [補足]デフォルト動作
  - デフォルトの設定では、「デフォルトルートテーブルの関連付け」、「デフォルトルートテーブル伝播」が有効になっています。
  - この設定が有効になっていると、アタッチメントしたVPCがデフォルトで作成されるルートテーブルに、自動でアソシエーションとプロパゲーションされます。


# 2. Transit Gateway アタッチメントを作成

## 2-1. Transit Gateway アタッチメント-1を作成
  - 名前タグ
  - Transit Gateway ID
    - 先ほど作成したものを選択
  - アタッチメントタイプ
    - VPC ★今回はこれを選ぶ
    - VPN
      - Site-to-Site VPNをぶら下げるためのアタッチメント
    - Peering connection
      - 別リージョンのTGWとつなぐ場合はこれを選択
    - Connect
      - SD-WANアプライアンス
    - Site-to-Site VPN concentrator

- 補足
  - AWS Transit Gateway がそもそも何かというと「L3ルータのハブ」です。
  - この「TGWに何をぶら下げるか」がアタッチメントタイプです。

---------------------------------
       VPC
         |
VPN -- TGW -- VPC
         |
        DX
---------------------------------

- Transit Gateway (TGW) は、同じ AWS アカウント内または複数の AWS アカウント間でアタッチメント (VPC と VPN) を相互接続するネットワーク中継ハブです。
- 名前タグ - オプション
  - 20260215-tgw-attach-1
- Transit Gateway ID
  - tgw-0598359b936d52e4b
- アタッチメントタイプ
  - VPC
- VPC アタッチメント
  - DNS サポート
    - 有効（デフォルト）
  - セキュリティグループ参照サポート
    - 有効（デフォルト）
  - IPv6 サポート
    - 無効（デフォルト）
  - アプライアンスモードサポート
    - 無効（デフォルト）
  - VPC ID
    - vpc1を選択
  - subnet
    - ここではprivate-aを選択
  - 作成をクリック



## 2-2. Transit Gateway アタッチメント-2を作成
２－１同様にvpc2のprivate-aサブネットにアタッチメントを作成


# 3.ルートテーブル設定

CFNで作成してあるパブリックのルートテーブルにTGW宛てのルートを設定


## 3-1. ＶＰＣ１のパブリック用ルートテーブルにTGW宛てのルートを追加
- ＶＰＣ１のパブリック用ルートテーブルを選択
-  10.0.2.0/24、ターゲットに Transit Gateway を選択し、先ほど作成したTransit Gatewayアタッチメント(yyyymmdd-handson1-vpc) を選択
-  [変更を保存] をクリック


## 3-2. ＶＰＣ２のパブリック用ルートテーブル設定
- ＶＰＣ２のパブリック用ルートテーブルを選択
-  10.0.1.0/24、ターゲットに Transit Gateway を選択し、先ほど作成したTransit Gatewayアタッチメント(yyyymmdd-handso2-vpc) を選択
-  [変更を保存] をクリック





# 用語
- ルートテーブル
  - いわゆるルートテーブルです。通信経路を制御します。
    - なお、デフォルトの状態では、1つのTransit Gatewayあたりに作成可能なルートテーブルは20までです。
- アソシエーション
  - アタッチメントとルートテーブルを関連付けする作業です。これによりアタッチメント間で通信を行うことができます。
    - 1つのアタッチメント（1つのVPC）が、複数のルートテーブルにアソシエーションすることはできません。
- プロパゲーション
  - アタッチメントしたVPCをルートテーブルに伝播する機能です。
  - これにより、スタティックルートを定義せずに自動でルートテーブルを更新することができます
    - Transit Gateway peeringは、プロパゲーションができないので注意が必要です。


# 備忘・気づき
- 今回のAttachmentは、パブリックサブネットではなくプライベートサブネットに作るべき。VPC間TGW接続は、インターネット関連のものじゃないから。
  - 細かいことをいうと、なぜこのハンズオンでパブリックサブネット使っているかというと、『パブリックIPもったEC2にサクッとInstanceConnectして疎通確認したかったから。』
- ENIはVPCメニューにない。ENIはEC2の左ペインでネットワークインターフェースとして存在する
  - TransitGatewayのAttachmentも、ここにある。IPは割り当てされる
    - 今回の場合はprivatesubnetにattachment作って、IPも払い出される
      - 蛇足だが、privateにEC2作ってarpテーブル見ても、実際は別L3だからarpテーブルに乗らないらしい？？（gptいわく）
- この手順はなぜEC2にInstanceConnectで接続できるのか？ CFNに特別な記述もない。鍵も指定していない
  - →AL2023はデフォルトでEIC（EC2 Instance Connect）エージェントがデフォルト搭載だから
  - あとは２２番空いていればOK？　
    - →IP制限していなければOK
  - EIC（instanceConnectとしては、①public-ipあり　②鍵は指定すべき。さすがにIP絞ってないので。ただしマネージドコンソールからは鍵なしで接続可能（一時カギが生成されるっぽい）
    - ちなみにprivate-ipしかない場合はEIC-endpointというのを作らないとinstanceconnectできないっぽい


# その他
- Transit Gatewayポリシーテーブルとは？？
  - CloudWANとの制御に使う？
    - CloudWANとは
    - https://blog.serverworks.co.jp/cloud-wan-vpc
  - 参考
    - Transit GatewayポリシーテーブルでCloud WANのコアネットワークに接続しました
    - https://www.yamamanx.com/transit-gateway-cloud-wan-policytable/
