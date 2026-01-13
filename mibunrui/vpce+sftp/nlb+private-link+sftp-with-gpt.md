
あなた:
awsのnetwork load balancerって何？
ChatGPT:

https://miro.medium.com/1%2AKi7PQVUG3kJHXjsM763Ryw.png

https://d2908q01vomqb2.cloudfront.net/5b384ce32d8cdef02bc3a139d4cac0a22bb029e8/2022/02/16/image-6.png

https://exampleloadbalancer.com/assets/udp_syslog_dd1.png
4
**AWS の Network Load Balancer（NLB）**とは、レイヤー4（L4：TCP/UDP/TLS）で動作する超高性能なロードバランサです。
主に 大量トラフィック・低レイテンシ・固定IPが必要なシステム向けに設計されています。
1. NLBの位置づけ（ひとことで）
OSI参照モデル：L4
IPアドレスとポート番号のみで振り分け
HTTPの中身（URL・ヘッダ）は見ない
2. NLBの主な特徴
① 超高性能・低レイテンシ
1秒あたり 数百万リクエストを処理可能
レイテンシは ミリ秒未満
コネクションをほぼそのままバックエンドへ転送
② 固定IPアドレスを持てる
AZごとに 固定IP（Elastic IP可）
オンプレ・他社システム・FW許可設定と相性が良い
③ クライアントIPを保持
バックエンドから 実際の送信元IPが見える
X-Forwarded-For など不要
④ TCP / UDP / TLS に対応
HTTP/HTTPS以外も対応
SFTP
SMTP
独自プロトコル
gRPC（TCPベース）
⑤ PrivateLink の必須コンポーネント
PrivateLink（VPC Endpoint Service）ではNLBが必須
他社VPC・他アカウントと インターネット非経由で接続可能
3. ALB / CLB との違い
項目	NLB	ALB	CLB
レイヤー	L4	L7	L4/L7
プロトコル	TCP/UDP/TLS	HTTP/HTTPS	TCP/HTTP
固定IP	○	×	×
URL/ヘッダ分岐	×	○	×
PrivateLink	◎ 必須	×	×
レイテンシ	最低	低	高
4. 代表的なユースケース
✔ 向いているケース
SFTP（AWS Transfer Family）
PrivateLink でのサービス公開
オンプレ／他社クラウド連携
高TPSなAPI・ゲームサーバ
固定IPが必須なB2B接続
✖ 向いていないケース
URLパスで振り分けたい
HTTPヘッダを見たい
WAFを直接つけたい
→ この場合は ALB
5. セキュリティに関する重要点
NLB自体はセキュリティグループを持たない
セキュリティ制御は：
バックエンド（EC2 / ECS / ENI）のSG
NACL
上位FW
※ 「オンプレで言うと、LBの前後にFWがある構成」に近い考え方です。
6. 一文でまとめると
NLBは「中身を見ずに、超高速・固定IPで通信を中継するL4ロードバランサ」であり、PrivateLinkとB2B通信の要。
必要であれば、次のステップとして
ALBとの設計判断フロー
NLB＋PrivateLink＋Transfer Familyの構成図
マネジメントコンソールでの作成手順（画面単位）
いずれも具体的に解説できます。どこまで深掘りしますか。
あなた:
>PrivateLink（VPC Endpoint Service）ではNLBが必須
PrivateLinkとVPC Endpoint Serviceは同じ？　違うなら、関係は？
PrivateLinkを使う場合、絶対にNLBがないとだめなの？

PrivateLink経由で他社VPCのTransferFamilyを使う場合、NLBは必須？必須じゃない？
ChatGPT:

https://docs.aws.amazon.com/images/prescriptive-guidance/latest/integrate-third-party-services/images/p1_privatelink.png

https://www.devopsschool.com/blog/wp-content/uploads/2023/04/image-32.png

https://miro.medium.com/1%2Aqef4cej7hmfuL6hpjAx95g.png
4
以下、結論 → 用語整理 → 構成別の必須／非必須判定の順で、誤解が起きやすい点を正確に整理します。
結論（先に要点）
PrivateLink ≠ VPC Endpoint Service
PrivateLink：AWSが提供する「仕組み（総称）」
VPC Endpoint Service：PrivateLinkを提供側で構成するための具体的なリソース
PrivateLinkを“サービス提供”として使う場合、NLBは原則必須
VPC Endpoint Service の背後には NLB が必須
例外はほぼなく、他社VPCへサービス公開する用途では必須
PrivateLink経由で他社VPCのTransfer Familyを使う場合
NLBは必須（提供側：他社）
利用側（あなたのVPC）には NLB は不要
1. 用語の正確な関係
PrivateLink とは
AWSのネットワーク接続方式の総称
インターネットを使わずに
VPC → 他VPC / AWSサービス にプライベート接続する仕組み
VPC Endpoint Service とは
PrivateLinkを“提供する側”が作るリソース
「このサービスを PrivateLink 経由で使わせます」という公開口
👉 PrivateLinkという概念を、具体的に実現するための構成要素の一つ
関係を一言で
PrivateLink = 仕組みの名前
VPC Endpoint Service = その仕組みを提供側で実装するAWSリソース
2. PrivateLink構成の全体像（提供側／利用側）
提供側（サービスを公開する会社）
[アプリ / SFTP]
        ↓
      NLB   ← 必須
        ↓
VPC Endpoint Service
利用側（サービスを使う会社）
Interface VPC Endpoint
        ↓
   Private IP で接続
3. なぜ NLB が必須なのか
AWSの仕様上の理由
VPC Endpoint Service は NLB か GWLB のみをサポート
ALB / EC2 / Transfer Family を直接紐づけることは不可
技術的な理由
L4で安定した接続
IPベースでの PrivateLink マッピング
スケール・冗長性を AWS が管理可能
4. 「PrivateLinkを使う＝必ずNLB？」の正確な答え
ケース	NLB必要？	理由
AWS公式サービスを使う（S3等）	不要	AWS側が内部で用意
自社VPCのサービスを他社に公開	必要	Endpoint Service に必須
他社VPCのサービスを使う	不要	相手側が用意
Transfer Family を PrivateLink で公開	必要	背後にNLBが必要
5. Transfer Family × PrivateLink の場合
他社VPCにある AWS Transfer Family を使う
提供側（他社）
Transfer Family
      ↓
     NLB   ← 必須
      ↓
VPC Endpoint Service
利用側（あなた）
Interface VPC Endpoint
      ↓
  sftp 接続
👉 Transfer Family 自体は PrivateLink に直接対応していないため、NLBが必須
6. よくある誤解まとめ
❌ 誤解
「PrivateLinkとVPC Endpoint Serviceは同じ」
「Transfer FamilyはそのままPrivateLinkで使える」
✅ 正解
PrivateLinkは仕組み、Endpoint Serviceは提供側リソース
Transfer FamilyをPrivateLinkで公開するにはNLB必須
最終まとめ（断言）
PrivateLink ≠ VPC Endpoint Service
VPC Endpoint Service を作るなら NLB は必須
PrivateLink経由で他社VPCのTransfer Familyを使う場合、NLBは“提供側で必須”
利用側ではNLB不要
次に進むなら、
「Transfer Family＋NLB でなぜセキュリティグループ設計が特殊になるか」
「NLBを2つ作る必要があるケース／不要なケース」
「双方向SFTP（相互PUT）のPrivateLink設計パターン」
どれを深掘りしますか。
あなた:
NLB+TransferFamilyを作れば、VPC Endpoint Serviceを作った、ということ？
NLB+TransferFamilyを作り、”VPC Endpoint Service”というものも作る、という意味じゃないよね？
ChatGPT:
結論から明確に言います。
結論（ここが最重要）
NLB＋Transfer Family を作っただけでは、VPC Endpoint Service を作ったことにはなりません。
👉 NLB＋Transfer Family を作り、
👉 さらに別途「VPC Endpoint Service」を作る必要があります。
つまり、

「NLB＋Transfer Family」
＋
「VPC Endpoint Service」
＝ PrivateLink 提供側の完成形
です。
なぜ混乱しやすいのか（構成の正体）
PrivateLink には 役割の違う3つの要素があります。
[ Transfer Family ]
        ↓
      NLB        ← ① トラフィックを受ける実体
        ↓
VPC Endpoint Service  ← ② PrivateLinkとして公開する定義
        ↓
Interface VPC Endpoint（相手VPC）
このうち、
NLB：通信を受ける「入口」
VPC Endpoint Service：
「この NLB を PrivateLink で公開します」という 宣言リソース
👉 役割が違うので、別物・別リソース
あなたの質問への Yes / No での回答
Q1.
「NLB＋Transfer Familyを作れば、VPC Endpoint Serviceを作った、ということ？」
❌ いいえ。まったく別です。

Q2.
「NLB＋Transfer Familyを作り、“VPC Endpoint Service”というものも作る、という意味じゃないよね？」
✅ いいえ、その理解は誤りです。
👉 その通りで、NLBとは別に VPC Endpoint Service を作る が正解です。

正しい作業順（提供側）
Step 1：Transfer Family を作成
SFTP サーバ本体
Step 2：NLB を作成
ターゲットに Transfer Family の ENI / IP を登録
TCP 22（SFTP）など
Step 3：VPC Endpoint Service を作成
「この NLB を PrivateLink で公開する」
対象ロードバランサとして NLBを指定
Step 4：相手に Service Name を共有
com.amazonaws.vpce.ap-northeast-1.vpce-svc-xxxx
AWSコンソール上でも完全に別メニュー
リソース	コンソール
Transfer Family	AWS Transfer Family
NLB	EC2 → Load Balancers
VPC Endpoint Service	VPC → Endpoint services
一文で腹落ちさせると
NLB は「箱」、VPC Endpoint Service は「この箱をPrivateLinkで公開するという契約」
箱を置いただけでは、
「PrivateLinkで使っていいですよ」にはならない、というイメージです。
最終まとめ（断言）
NLB＋Transfer Family ≠ VPC Endpoint Service
VPC Endpoint Service は必ず別途作る
PrivateLink提供側は 3点セット
Transfer Family
NLB
VPC Endpoint Service
次に詰まりやすいポイントとして、
「Transfer Family を NLB のターゲットにどう登録するのか（IP/ENI問題）」
「承認制 Endpoint Service にするべきか」
「双方向SFTP時、Endpoint Serviceはいくつ必要か」
このあたりを整理すると、設計書レベルまで一気に固まります。
どこを深掘りしますか。
あなた:
全部お願い！
ChatGPT:
承知しました。以下は、Transfer Family（SFTP）を PrivateLink で他社に提供／他社から利用する前提で、実務で詰まりやすいポイントを 設計→構築→運用まで一気に整理します。
0. 前提の全体像（“提供側”と“利用側”）
提供側（SFTP サーバを公開する側）
Transfer Family（VPC ホステッド推奨）
NLB（PrivateLink の入口）
VPC Endpoint Service（= “この NLB を PrivateLink として公開”）
利用側（SFTP 接続する側）
Interface VPC Endpoint（= 相手の Endpoint Service につなぐ“入口”）
そのエンドポイントの DNS 名で SFTP 接続
1) 「Transfer Family を NLB のターゲットにどう登録するか（IP/ENI問題）」
ここが一番落とし穴です。結論から言うと：
結論
Transfer Family を NLB のターゲットに“直接”登録する機能はありません
一般的には Transfer Family が VPC 内に作る ENI（Elastic Network Interface）の IP を、NLB のターゲット（IP タイプ）として登録します
実務的に成立する条件（提供側）
A. Transfer Family を “VPC ホステッド” で作る
Transfer Family のエンドポイント種別が VPC（Public ではなく）
サブネットを複数 AZ で指定（冗長性のため）
B. NLB のターゲットタイプは “IP”
Target group：IP
Port：SFTPなら通常 22/TCP
C. ターゲットに登録する IP は「Transfer Family の ENI のプライベートIP」
Transfer Family を VPC で作ると、選んだサブネットに ENI が作られます
その ENI の プライベートIP を NLB ターゲットに入れるイメージです
“IP が変わったらどうする？”（運用論点）
Transfer Family を作り直す／サブネット変更するなどが起きると、ENI/IP が変わる可能性があります
その場合、NLB ターゲットの登録IPの更新が必要です
推奨策（現実解）
「Transfer Family を作り直す」運用を極力避ける（設計段階でサブネット/AZを固める）
変更があり得るなら、更新手順（または自動同期）を用意
例：変更時に ENI を洗い出してターゲットを更新する運用手順（手動でも可）
自動化するなら Lambda/Step Functions 等で “ENI→ターゲット同期” という発想（ただし必須ではありません）
2) 「承認制 Endpoint Service にするべきか（Acceptance/Allowed principals）」
これはセキュリティ・ガバナンス設計です。結論は「原則、制御を強くする」です。
Endpoint Service 側で決めること（提供側）
(1) Allowed principals（利用を許可する相手）
どの AWS アカウントが接続要求を出せるか
他社アカウントIDを指定して制限するのが基本
(2) Acceptance required（接続要求の承認を必須にするか）
ON（承認必須）推奨：B2B で勝手に接続されるリスクを潰す
OFF：許可した principal なら自動で有効化される（運用は楽だが制御は弱い）
推奨判断（実務）
他社接続（B2B）なら：
Allowed principals：必須
Acceptance required：原則 ON
例外的に OFF を検討するのは、同一企業内の厳密に管理されたアカウント群など
3) 「双方向SFTP（相互PUT）のとき、Endpoint Service はいくつ必要か」
ここは要件次第で数が変わります。まず、事実から。
事実：PrivateLink は “片方向の提供” の単位で作る
Endpoint Service は「提供側が公開するサービス」
Interface Endpoint は「利用側が接続する入口」
したがって、通信方向が増えると、原則“提供側セット”が増えます
パターン別：必要な個数
パターンA：片方向のみ（あなた→他社に PUT のみ）
他社（提供側）：Transfer Family + NLB + Endpoint Service（1セット）
あなた（利用側）：Interface Endpoint（1つ）
あなた側に NLB/Endpoint Service は不要
パターンB：双方向（あなたも他社も、それぞれ相手の Transfer Family に PUT したい）
この場合は “提供”が2回発生します。
あなた（提供側）：Transfer Family + NLB + Endpoint Service（1セット）
他社（利用側）：Interface Endpoint（1つ）
加えて、
他社（提供側）：Transfer Family + NLB + Endpoint Service（1セット）
あなた（利用側）：Interface Endpoint（1つ）
つまり合計としては：
Endpoint Service：2つ（各社1つずつ）
Interface Endpoint：2つ（各社1つずつ）
NLB：2つ（各社1つずつ）
Transfer Family：2つ（各社のSFTPサーバ）
双方向なら「各社が “提供側” と “利用側” を両方持つ」構図になります。
「NLB は 1つでまとめられないの？」
整理しておくと：
Endpoint Service は 1つのNLB に紐づきます（“このNLBを公開する” なので）
NLB は複数リスナー/ターゲットグループを持てますが、
SFTP は通常 22/TCP 固定で、ポート分岐や HTTP 的なルーティングができないため、
複数のTransfer Familyを1つのNLBでうまく分ける設計は一般に難しい（できても運用が壊れやすい）
実務では **「Transfer Family 1つにつき NLB 1つ」**が無難です。
4) セキュリティ設計で必ず押さえる点（SG/NACL/送信元IPの見え方）
重要：NLB はセキュリティグループを持たない
守りの主戦場は
Transfer Family 側の SG（または到達先 ENI を守る仕組み）
NACL
ルーティング設計
送信元 IP は “相手クライアントの実IP” にならないことが多い
PrivateLink を挟むと、到達先から見える送信元は 利用側 Interface Endpoint（ENI）のIP になることが一般的です。
（＝「相手のPC/サーバの実IPで絞る」ができない前提で設計する）
実務での許可ルール例

Transfer Family 側では「相手の VPC のエンドポイントENIのアドレス帯」または「相手VPC CIDR」等で許可設計
さらに厳密にやるなら、接続元を IP ではなく
認証（鍵/ユーザー）
SFTP の論理ディレクトリ制御
監査ログ
で固める
5) 構築手順（提供側／利用側）チェックリスト
提供側（あなたが公開する側）
Transfer Family を VPC ホステッドで作成（複数AZ）
Transfer Family の ENI/プライベートIP を確認
NLB（internal 推奨）を作成
Target Group（IPタイプ）に Transfer Family の IP を登録（22/TCP）
NLB リスナー 22/TCP → Target Group
VPC Endpoint Service 作成（対象LBとしてNLBを指定）
Allowed principals を設定（相手アカウント）
Acceptance required を ON（推奨）
相手に Service Name（vpce-svc-xxxx）を共有
相手からの接続要求を承認
利用側（相手のサービスを使う側）
Interface VPC Endpoint を作成（接続先：相手の Service Name）
サブネット/AZ を選択（冗長化したいなら複数）
Endpoint の SG を設定（自分のクライアントからの 22/TCP を許可など）
付与される DNS 名で SFTP 接続
必要なら Route53（Private Hosted Zone）で社内用の名前にエイリアス
6) ここまでを “最小の判断表” に落とす（超短縮）
NLB＋Transfer Family を作るだけ：まだ PrivateLink 提供ではない
PrivateLink で他社に公開する：必ず Endpoint Service が要る
Endpoint Service を作る：必ず NLB（またはGWLB） が要る
双方向：基本 各社が提供側セットを1つずつ持つ（合計2セット）
必要なら次のアウトプットも、このまま作れます（会話内で完結します）：
設計書テンプレ（パラメータシート付き）：CIDR、サブネット、AZ、NLB、ターゲット、承認フロー、責任分界
双方向SFTPの作業分担表（RACI）：どちらが何を作るか、承認・変更時の連絡
運用手順：ENI/IP変更時の影響と更新手順、障害切り分け（NLBヘルスチェック、到達性、認証）
この中だと、次に欲しいのはどれですか。こちらで先回りして作るなら、私は **「設計書テンプレ＋パラメータシート」**から作るのが最短だと考えます。
あなた:
▼以下を、マネージメントコンソールで初心者でもできる詳細な手順書にして欲しい

5) 構築手順（提供側／利用側）チェックリスト
提供側（あなたが公開する側）
Transfer Family を VPC ホステッドで作成（複数AZ）
Transfer Family の ENI/プライベートIP を確認
NLB（internal 推奨）を作成
Target Group（IPタイプ）に Transfer Family の IP を登録（22/TCP）
NLB リスナー 22/TCP → Target Group
VPC Endpoint Service 作成（対象LBとしてNLBを指定）
Allowed principals を設定（相手アカウント）
Acceptance required を ON（推奨）
相手に Service Name（vpce-svc-xxxx）を共有
相手からの接続要求を承認
利用側（相手のサービスを使う側）
Interface VPC Endpoint を作成（接続先：相手の Service Name）
サブネット/AZ を選択（冗長化したいなら複数）
Endpoint の SG を設定（自分のクライアントからの 22/TCP を許可など）
付与される DNS 名で SFTP 接続
必要なら Route53（Private Hosted Zone）で社内用の名前にエイリアス
ChatGPT:

https://d2908q01vomqb2.cloudfront.net/e1822db470e60d090affd0956d743cb0e7cdf113/2020/11/05/The-following-diagram-shows-the-key-components-to-deploy-a-secure-server-endpoint-in-a-VPC-with-shared-subnets..png

https://docs.aws.amazon.com/images/elasticloadbalancing/latest/classic/images/internal_load_balancer.png

https://d2908q01vomqb2.cloudfront.net/5b384ce32d8cdef02bc3a139d4cac0a22bb029e8/2021/01/27/architecture-1.png
4
以下は、AWS マネジメントコンソールのみを使い、
AWS 初心者でも迷わず再現できるレベルまで落とした
「Transfer Family × NLB × PrivateLink（VPC Endpoint Service）」詳細手順書です。
前提：
AWS アカウントに Administrator 相当の権限がある
VPC / サブネット（複数 AZ）がすでに存在している
リージョン例：東京（ap-northeast-1）
0. 全体構成（最初に理解する図）
【提供側 VPC】
Transfer Family (VPC hosted)
        ↓
      NLB (internal)
        ↓
VPC Endpoint Service
        ↓
======== PrivateLink ========
        ↓
Interface VPC Endpoint
        ↓
【利用側 VPC】
SFTP クライアント
【提供側】構築手順（サービスを公開する側）
Step 1. Transfer Family（VPC ホステッド）を作成する
1-1. コンソールを開く
AWS マネジメントコンソール
検索欄で Transfer Family
AWS Transfer Family を開く
1-2. サーバー作成
サーバーを作成
プロトコル
☑ SFTP
エンドポイントタイプ
⬤ VPC ホステッド
VPC
対象の VPC を選択
サブネット
異なる AZ のサブネットを複数選択（必須）
セキュリティグループ
後で調整可（まずは作成）
👉 作成
Step 2. Transfer Family の ENI / プライベート IP を確認
2-1. サーバー詳細画面
作成した Transfer Family サーバーをクリック
ネットワーク セクションを確認
2-2. ENI を特定
VPC / サブネット情報から
EC2 → ネットワークインターフェイス を開く
説明に Transfer Family が含まれる ENI を探す
2-3. プライベート IP をメモ
各 AZ ごとに 1 IP
👉 後で NLB のターゲットに登録する
Step 3. Network Load Balancer（internal）を作成
3-1. EC2 → ロードバランサー
ロードバランサーの作成
Network Load Balancer
3-2. 基本設定
名前：例 tf-sftp-nlb
スキーム：
⬤ internal
IP アドレスタイプ：
IPv4
3-3. ネットワークマッピング
VPC：Transfer Family と同じ
AZ：
Transfer Family と 同じ AZ のサブネットを選択
👉 次へ
Step 4. Target Group（IP タイプ）を作成
4-1. ターゲットグループ作成
タイプ：
⬤ IP アドレス
プロトコル：
TCP
ポート：
22
4-2. ヘルスチェック
プロトコル：TCP
ポート：22
👉 次へ
4-3. IP を登録
Step 2 で控えた
Transfer Family の プライベート IP
各 AZ 分を登録
👉 ターゲットグループ作成
Step 5. NLB リスナー設定
リスナー
TCP : 22
転送先
上記で作成した Target Group
👉 NLB 作成完了
Step 6. VPC Endpoint Service を作成
6-1. VPC → エンドポイントサービス
エンドポイントサービスを作成
6-2. 設定
対象ロードバランサー：
☑ 作成した NLB
承認が必要：
☑ ON（推奨）
👉 作成
Step 7. Allowed principals（接続許可アカウント）設定
作成した Endpoint Service を開く
Allowed principals
追加
相手の AWS アカウント ID を入力
Step 8. Service Name を相手に共有
表示される形式：
com.amazonaws.vpce.ap-northeast-1.vpce-svc-xxxxxxxx
👉 これを相手（利用側）に共有
Step 9. 接続リクエストを承認
Endpoint Service → エンドポイント接続
相手からのリクエスト
承認
【利用側】構築手順（サービスを使う側）
Step 10. Interface VPC Endpoint を作成
10-1. VPC → エンドポイント
エンドポイントを作成
10-2. 設定
サービスカテゴリ：
⬤ その他のエンドポイントサービス
サービス名：
提供側から受け取った Service Name
👉 検証 → 次へ
Step 11. ネットワーク設定
VPC：
自分の VPC
サブネット：
複数 AZ 推奨
セキュリティグループ：
SFTP クライアント → 22/TCP を許可
👉 作成
Step 12. DNS 名で SFTP 接続
作成後に表示される DNS：
vpce-xxxxxxxx.vpce-svc-xxxx.ap-northeast-1.vpce.amazonaws.com
接続例
sftp user@vpce-xxxxxxxx.vpce.amazonaws.com
Step 13. Route53（任意）
目的
DNS 名が長い → 社内用に短縮
手順
Route53 → Private Hosted Zone
VPC を関連付け
A / CNAME レコード作成
sftp.partner.internal → VPC Endpoint DNS
最終チェックリスト（運用前確認）
 Transfer Family：VPC ホステッド / 複数 AZ
 NLB：internal / 22/TCP
 Target Group：IP タイプ
 Endpoint Service：承認 ON
 Allowed principals：限定済み
 Interface Endpoint：Available
 SFTP 接続成功
一言まとめ
PrivateLink は「NLBを作るだけでは完成しない」
Endpoint Service を作って初めて “PrivateLink 提供” になる
次におすすめなのは：
双方向 SFTP の場合の “2社分フル構成図”
設計書（パラメータシート／責任分界）テンプレ
障害時の切り分けフロー（NLB / Endpoint / Transfer）
どれを次に仕上げますか。
あなた:
＞設計書（パラメータシート／責任分界）テンプレ
ChatGPT:
以下に、**Transfer Family × NLB × PrivateLink（VPC Endpoint Service）**向けの
**設計書テンプレ（パラメータシート／責任分界込み）**を、コピペしてそのまま使える形で提示します。
（Markdown 前提。Excel にしたい場合はこの表をそのまま貼れます）
1. 文書情報
項目	値
文書名	PrivateLink（SFTP/Transfer Family）接続設計書
版数	v0.1
作成日	2026-01-14
作成者	
関係者	提供側：＿＿＿ / 利用側：＿＿＿
対象リージョン	ap-northeast-1（東京）
目的	他社VPC上のTransfer Family（SFTP）をPrivateLinkで利用（または提供）する
2. スコープ
2.1 対象
Transfer Family（SFTP）
Network Load Balancer（NLB）
VPC Endpoint Service（提供側）
Interface VPC Endpoint（利用側）
Route53（任意：Private Hosted Zone）
CloudWatch（ログ、メトリクス）
セキュリティ（SG/NACL/鍵・ユーザー）
2.2 非対象（例）
SFTP クライアントアプリ実装（WinSCP/CLI等）
データ連携の業務要件（ファイル命名規則、再送制御）
監査要件（別紙）
3. 構成概要
3.1 通信フロー（論理）
利用側クライアント → Interface VPC Endpoint（TCP/22）
Interface VPC Endpoint → 提供側 Endpoint Service
Endpoint Service → NLB（TCP/22）
NLB → Transfer Family ENI（TCP/22）
3.2 冗長化方針
Transfer Family：複数 AZ サブネット選択
Interface Endpoint：複数 AZ で作成
NLB：複数 AZ にマッピング
4. 設計方針（重要）
4.1 セキュリティ方針
NLB は SG を持たないため、許可制御は主に以下：
Transfer Family（到達先）の SG / NACL
Interface Endpoint の SG
送信元 IP の取り扱い：
PrivateLink では、提供側から見える送信元が 利用側VPCEのENI になる前提で設計
クライアント実IPベースの厳格制限は採らず、認証（鍵/ユーザー）と監査で担保
4.2 承認・接続制御
Endpoint Service：Acceptance required = ON（推奨）
Allowed principals：利用側 AWS アカウントIDを限定
4.3 運用方針（IP/ENI変動）
Transfer Family を作り直す等で ENI/IP が変わる場合：
NLB ターゲット（IP）の更新が必要
変更時の手順／責任者を明記（後述）
5. パラメータシート（提供側）
5.1 共通（提供側VPC）
項目	値	備考
提供側 AWSアカウントID		12桁
提供側 VPC ID		vpc-...
AZ/サブネット（SFTP配置）		例：a/b の2AZ
ルートテーブル		
NACL		
5.2 Transfer Family（提供側）
項目	値	備考
Server ID		s-...
プロトコル	SFTP	固定
エンドポイントタイプ	VPC hosted	必須
VPC		
サブネット		複数AZ
セキュリティグループ		到達許可を記載
ログ（CloudWatch）		ON/OFF、Log Group
認証方式		Service managed / Identity provider 等
ユーザー/鍵管理方針		鍵配布/ローテ
5.3 Transfer Family ENI / IP（提供側）
項目	値	備考
ENI（AZ-a）		eni-...
Private IP（AZ-a）		NLBターゲット登録
ENI（AZ-b）		eni-...
Private IP（AZ-b）		NLBターゲット登録
IP変更時の対応	手順	「運用手順」参照
5.4 NLB（提供側）
項目	値	備考
NLB 名		例：tf-sftp-nlb
スキーム	internal	推奨
VPC		
サブネット/AZ		Transferと同等AZ
リスナー	TCP:22	固定
アクセスログ		任意（S3）
Cross-zone		方針記載
5.5 Target Group（提供側）
項目	値	備考
Target type	IP	必須
Protocol/Port	TCP:22	
登録ターゲット	Transfer ENI IP 群	5.3参照
Health check	TCP:22	
5.6 VPC Endpoint Service（提供側）
項目	値	備考
Endpoint Service 名		vpce-svc-...
対象LB	NLB	必須
Acceptance required	ON	推奨
Allowed principals		利用側アカウントID
共有する Service Name		com.amazonaws.vpce...vpce-svc-...
6. パラメータシート（利用側）
6.1 共通（利用側VPC）
項目	値	備考
利用側 AWSアカウントID		12桁
利用側 VPC ID		vpc-...
利用側 クライアント配置サブネット		
DNS 方針		既定DNS/Route53
6.2 Interface VPC Endpoint（利用側）
項目	値	備考
接続先 Service Name		提供側から受領
Endpoint ID		vpce-...
サブネット/AZ		複数AZ推奨
Private DNS	OFF（推奨）	“その他サービス”は通常OFF運用が多い
SG（Endpoint用）		クライアント→22許可
ステータス		Available / PendingAcceptance
6.3 DNS（任意：Route53 Private Hosted Zone）
項目	値	備考
PHZ 名		例：partner.internal
レコード名		例：sftp.partner.internal
レコード種別	CNAME（推奨）	VPCE DNS へ
参照先	VPCE DNS 名	
7. セキュリティ設計詳細（SG/NACL）
7.1 提供側（到達先）セキュリティグループ
方向	許可元	プロトコル/Port	備考
Inbound	利用側VPCEのENI/利用側CIDR 等	TCP/22	実環境に合わせて具体化
Outbound	必要最小限		
7.2 利用側（VPCE）セキュリティグループ
方向	許可元	プロトコル/Port	備考
Inbound	利用側クライアントSG/CIDR	TCP/22	
Outbound	提供側へ	TCP/22	通常は全許可でも可（方針次第）
7.3 NACL（任意）
22/TCP の入出力許可
エフェメラルポートの扱い（クライアント側は動的ポートが必要）
8. 責任分界（RACI）
8.1 RACI定義
R：実行責任（Responsible）
A：最終責任（Accountable）
C：協議（Consulted）
I：報告（Informed）
8.2 作業別RACI
作業	提供側	利用側	備考
Transfer Family 作成（VPC hosted）	R/A	I	
Transfer ENI/IP 特定	R	I	
NLB/Target Group 作成	R/A	I	
Endpoint Service 作成	R/A	I	
Allowed principals 設定	R/A	C	利用側アカウントID受領
接続要求の承認	R/A	I	PendingAcceptance を承認
Interface Endpoint 作成	I	R/A	
VPCE SG 設定	C	R/A	クライアント要件反映
SFTP 疎通確認	C	C	共同
DNS（PHZ）作成	I	R/A	任意
変更（ENI/IP更新）	R/A	I	更新連絡は必須
障害一次切り分け	R/A（提供側内）	R/A（利用側内）	共同で相互確認
9. 運用手順（変更・障害）
9.1 接続追加（利用者追加）
提供側：Allowed principals に利用側アカウント追加
利用側：Interface Endpoint 作成
提供側：接続要求を承認
双方：疎通確認
9.2 Transfer ENI/IP 変更（作り直し等が発生した場合）
提供側：Transfer Family の ENI/IP を再取得
提供側：Target Group のターゲット IP を差し替え
提供側：ヘルスチェック正常化を確認
利用側：影響有無（SFTP疎通）確認
9.3 障害切り分け（最短ルート）
利用側VPCE：Status（Availableか）
提供側Endpoint Service：接続状態（Rejected/Accepted）
NLB：Target health（Healthyか）
Transfer：ログ（認証失敗/到達不可）
10. テスト項目（受入）
No	観点	手順	期待結果
1	接続確立	利用側から VPCE DNS へ sftp	接続できる
2	認証	誤鍵/誤ユーザーで接続	拒否されログが残る
3	冗長性	AZ片系を疑似障害（可能範囲で）	片系で継続
4	監査	CloudWatch logs 確認	接続ログが残る
11. 付録（埋めるべき情報一覧）
互いの AWS アカウントID（Allowed principals 用）
利用側のクライアント配置 CIDR / SG
受け渡しする Service Name
ユーザー/鍵の受け渡し方式（安全な経路、ローテ）
次に私から提案（そのまま使える“完成形”へ）
このテンプレを **「双方向SFTP」用に拡張した版（2セット分）」**も作れます。
また、あなたがよく作る形式に合わせて、
parameter-sheet.md
raci.md
runbook.md
の3ファイルに分割した形でも出せます。
あなた:
> parameter-sheet.md
ChatGPT:
---
title: "parameter-sheet.md | PrivateLink (Transfer Family SFTP) パラメータシート"
version: "v0.1"
date: "2026-01-14"
region: "ap-northeast-1"
---

# 1. 概要

本書は、AWS Transfer Family（SFTP）を Network Load Balancer（NLB）および VPC Endpoint Service（PrivateLink）経由で公開し、利用側は Interface VPC Endpoint 経由で接続する構成の **パラメータシート**である。

- 対象：Transfer Family（VPC hosted）、NLB（internal）、Target Group（IP）、Endpoint Service、Interface Endpoint、（任意）Route53 Private Hosted Zone
- 備考：本シートは **提供側（Provider）** と **利用側（Consumer）** を分けて記載する。

---

# 2. 共通情報

| 項目 | 値 | 備考 |
|---|---|---|
| 接続用途 |  | 例：B2B SFTP 連携（相手 Transfer Family へ PUT） |
| 対象リージョン | ap-northeast-1 | 東京 |
| 主要ポート | TCP/22 | SFTP |
| 冗長化方針 |  | 例：2AZ（a/b）以上 |
| 命名規則（prefix） |  | 例：`pl-sftp-<partner>-<env>` |

---

# 3. 提供側（Provider）パラメータ

## 3.1 アカウント / VPC

| 項目 | 値 | 備考 |
|---|---|---|
| 提供側 会社名/組織名 |  |  |
| 提供側 AWSアカウントID |  | 12桁 |
| 提供側 VPC ID |  | `vpc-xxxxxxxx` |
| 提供側 VPC CIDR |  | 例：10.10.0.0/16 |
| 提供側 サブネット（Transfer 用） |  | 例：subnet-a / subnet-b |
| 提供側 AZ |  | 例：ap-northeast-1a / 1c |
| ルートテーブル |  | RTB ID |
| NACL（該当サブネット） |  | NACL ID |

---

## 3.2 Transfer Family（SFTP Server）

| 項目 | 値 | 備考 |
|---|---|---|
| Transfer Server 名 |  | 例：`pl-sftp-provider-tf` |
| Transfer Server ID |  | `s-xxxxxxxx` |
| プロトコル | SFTP | 固定 |
| エンドポイントタイプ | VPC hosted | **必須** |
| VPC ID |  | 3.1 と同じ |
| サブネット |  | **複数AZ必須** |
| Transfer Family SG |  | `sg-xxxxxxxx` |
| ログ出力（CloudWatch） |  | ON/OFF、Log Group 名 |
| 認証方式 |  | Service managed / Custom / AD 等 |
| ユーザー管理方針 |  | 例：最小権限、個人別ユーザー |
| SSH 公開鍵配布方針 |  | 例：相手提供鍵を登録 |
| ホームディレクトリ |  | 例：`/bucket/partnerA/in` |
| S3 バケット（格納先） |  | 例：`sftp-provider-bucket` |
| IAM ロール（Transfer 用） |  | `role-...` |

---

## 3.3 Transfer Family ENI / プライベートIP（NLBターゲット用）

> 注：NLB Target Group（IP type）に登録するため、各AZの ENI / IP を控える。

| AZ | サブネットID | ENI ID | Private IP | 備考 |
|---|---|---|---|---|
|  |  |  |  | 例：Transfer が作成した ENI |
|  |  |  |  |  |

### IP変更時の扱い
| 項目 | 値 | 備考 |
|---|---|---|
| ENI/IP 変更が起きる条件 |  | 例：Transfer 作り直し、サブネット変更 |
| 変更時の更新対象 | Target Group ターゲットIP | NLB ではなく TG |
| 更新手順書 |  | `runbook.md` 参照（別途） |
| 連絡先（提供側） |  |  |
| 連絡先（利用側） |  |  |

---

## 3.4 Network Load Balancer（NLB）

| 項目 | 値 | 備考 |
|---|---|---|
| NLB 名 |  | 例：`pl-sftp-provider-nlb` |
| NLB ARN |  |  |
| スキーム | internal | **推奨** |
| IP アドレスタイプ | IPv4 |  |
| VPC ID |  |  |
| サブネット/AZ |  | 3.1 と整合 |
| クロスゾーン負荷分散 |  | ON/OFF（方針記載） |
| アクセスログ |  | ON/OFF、S3 バケット |

---

## 3.5 Target Group（IP タイプ）

| 項目 | 値 | 備考 |
|---|---|---|
| Target Group 名 |  | 例：`pl-sftp-provider-tg-22` |
| Target type | IP | **必須** |
| プロトコル/ポート | TCP/22 |  |
| 登録ターゲット |  | 3.3 の Private IP |
| ヘルスチェック | TCP:22 |  |

---

## 3.6 NLB リスナー

| 項目 | 値 | 備考 |
|---|---|---|
| リスナー | TCP:22 |  |
| 転送先 | Target Group | 3.5 を指定 |

---

## 3.7 VPC Endpoint Service（提供側）

| 項目 | 値 | 備考 |
|---|---|---|
| Endpoint Service 名 |  | コンソール表示名 |
| Service ID |  | `vpce-svc-xxxxxxxx` |
| Service Name（共有する文字列） |  | `com.amazonaws.vpce....vpce-svc-...` |
| 対象 Load Balancer | NLB | 3.4 |
| Acceptance required | ON | **推奨** |
| Allowed principals |  | 3.8 で記載 |
| 接続ログ/監査 |  | 監査方針があれば記載 |

---

## 3.8 Allowed principals（接続許可：利用側アカウント）

| 項目 | 値 | 備考 |
|---|---|---|
| 許可する AWSアカウントID（利用側） |  | 12桁 |
| 追加日 |  |  |
| 承認者 |  |  |

---

# 4. 利用側（Consumer）パラメータ

## 4.1 アカウント / VPC

| 項目 | 値 | 備考 |
|---|---|---|
| 利用側 会社名/組織名 |  |  |
| 利用側 AWSアカウントID |  | 12桁（提供側の Allowed principals 用） |
| 利用側 VPC ID |  | `vpc-xxxxxxxx` |
| 利用側 VPC CIDR |  | 例：10.20.0.0/16 |
| クライアント配置サブネット |  | 例：subnet-client-a / subnet-client-b |
| クライアント SG |  | `sg-xxxxxxxx` |
| DNS 方針 |  | Route53利用有無など |

---

## 4.2 Interface VPC Endpoint（利用側）

| 項目 | 値 | 備考 |
|---|---|---|
| 接続先 Service Name |  | 3.7 の Service Name |
| VPC Endpoint ID |  | `vpce-xxxxxxxx` |
| エンドポイント種別 | Interface | 固定 |
| VPC ID |  | 4.1 |
| サブネット/AZ |  | **複数AZ推奨** |
| Private DNS | OFF（推奨） | “その他サービス”は通常 OFF |
| Endpoint SG |  | 4.3 参照 |
| ステータス |  | PendingAcceptance / Available |

---

## 4.3 Endpoint Security Group（利用側：VPCE 用）

| 方向 | 許可元 | プロトコル/ポート | 備考 |
|---|---|---|---|
| Inbound | クライアントSG または CIDR | TCP/22 | SFTP クライアント→VPCE |
| Outbound | 0.0.0.0/0 または提供側宛 | TCP/22 | 方針で絞る |

---

## 4.4 接続先DNS情報（利用側）

| 項目 | 値 | 備考 |
|---|---|---|
| VPCE DNS 名（主要） |  | `vpce-xxxx.vpce-svc-xxxx.ap-northeast-1.vpce.amazonaws.com` |
| 接続確認コマンド例 | `sftp user@<VPCE_DNS>` | ユーザー名は提供側で払い出し |
| 接続元（クライアント） |  | EC2 / オンプレ / 他 |

---

## 4.5 Route53（任意：Private Hosted Zone）

| 項目 | 値 | 備考 |
|---|---|---|
| PHZ 名 |  | 例：`partner.internal` |
| 関連付けVPC |  | 4.1 |
| レコード名 |  | 例：`sftp.partner.internal` |
| 種別 | CNAME（推奨） |  |
| 値 | VPCE DNS 名 | 4.4 |
| TTL |  |  |

---

# 5. 疎通・受入テスト（最低限）

| No | テスト観点 | 手順 | 期待結果 | 備考 |
|---|---|---|---|---|
| 1 | 接続要求 | 利用側で Interface Endpoint 作成 | PendingAcceptance |  |
| 2 | 承認 | 提供側で接続を承認 | Available |  |
| 3 | TCP到達 | 利用側クライアント→VPCE DNS:22 | 接続開始できる |  |
| 4 | 認証 | 正しい鍵で SFTP | ログイン成功 |  |
| 5 | 誤認証 | 誤鍵で SFTP | 拒否・ログ記録 |  |

---

# 6. 変更管理（最小）

| 変更イベント | 影響 | 更新箇所 | 実施者 | 連絡先 |
|---|---|---|---|---|
| Transfer 再作成 | ENI/IP 変更の可能性 | 3.3 / 3.5 | 提供側 |  |
| サブネット変更 | 冗長性・到達性 | 3.1 / 4.1 | 各社 |  |
| 追加接続先（新利用側） | Principal追加・承認 | 3.8 / 承認 | 提供側 |  |