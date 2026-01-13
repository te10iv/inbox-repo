すべてのAWSサービスがvpceポリシーに対応しているわけではなく、リージョンごとに、サポートしているかどうかは異なる
らしい。
network loadbalancerやtransfer familyは東京リージョンで対応しているか？
amazon公式で調べて！

むしろ、東京リージョンでvpceポリシーに対応しているAWSサービス一覧のURLあれば教えてくれると嬉しい
調査したところ、AWS公式ドキュメントでも「東京リージョン（ap-northeast-1）でどのサービスが VPC エンドポイントポリシーに対応しているか」の固定一覧ページそのものは公開されていません。ただし、公式に利用できる手段と関連情報を以下にまとめます。
1. 公式で「東京リージョンの VPC Endpoint ポリシー対応サービス」を確認する方法（推奨）
AWS CLI で確認する方法（公式推奨）
AWS 公式ドキュメントにもあるとおり、describe-vpc-endpoint-services を使うと、リージョンごとのサービスと VPC エンドポイントポリシー対応状況を確認できます。
「VpcEndpointPolicySupported」フィールドが true のサービスがポリシー対応サービスです。
例（東京リージョンで実行）:

aws ec2 describe-vpc-endpoint-services \
  --filters Name=service-type,Values=Interface Name=owner,Values=amazon \
  --region ap-northeast-1 \
  --query "ServiceDetails[?VpcEndpointPolicySupported==\`true\`].ServiceName"
上記の結果が、東京リージョンでポリシー対応している AWS サービスの一覧になります（インターフェイスエンドポイントのみ）。
2. 東京リージョンでの対応例：Transfer Family と NLB
AWS Transfer Family
AWS Transfer Family は インターフェイス VPC エンドポイントに対して VPC エンドポイントポリシーがサポートされている と公式で発表されています（一般提供中）。
要点

AWS Transfer Family のインターフェイスエンドポイントは VPC Endpoint Policy に対応（VpcEndpointPolicySupported=true）。
このサポートはリージョン固有制限なく一般提供されていますので、東京リージョンでも対応可能です。
Network Load Balancer（NLB）の場合
Network Load Balancer 自体は ゲートウェイロードバランサーエンドポイント / プライベートリンクサービスのターゲットとして使われますが、以下点に注意が必要です：
Network Load Balancer を使った VPC Endpoint Service（PrivateLink）の公開・利用自体は可能（NLB をサービスにする構成）。
しかし NLB そのものには AWS 側の “VPC Endpoint Policy Supported” 属性はありません。
→ 実際には NLB はエンドポイント ターゲット 役割（Endpoint Service Provider）であり、NLB はポリシーの対象ではありません。
実際のアクセス制御は、NLB を使って公開したエンドポイントサービスの VPC Endpoint Policy 側で制御します（＝ VPC 内からの利用者側で制御可能）。
つまり 「Network Load Balancer がポリシー対応サービスか」ではなく、
VPCエンドポイントとして接続する AWS サービス（例：EC2、Transfer Family API 等）に対してポリシー制御をする形になります。
3. 公式ドキュメント／ページ（参考）
公式の VPC エンドポイント統合サービス一覧（ポリシー対応情報含む）
AWS PrivateLink 対応サービス一覧（ポリシー対応も CLI で確認可能と明記）
https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html
このページには、

対象リージョンの VPC エンドポイント対応サービス一覧
CLI で “VpcEndpointPolicySupported” を確認する方法
が記載されています。
サマリー（結論）
サービス	東京リージョンで VPC エンドポイントポリシー対応
AWS Transfer Family (インターフェイスエンドポイント)	対応（VpcEndpointPolicySupported = true）※公式アナウンスあり
Network Load Balancer	NLB 自体はエンドポイントポリシー属性を持たない（エンドポイント ターゲット として機能）。
追加ポイント
AWS はすべてのリージョンで同じ名称のサービスを提供していても、CLI で各リージョンの describe-vpc-endpoint-services 結果を確認しないと、ポリシー対応 or 非対応を確定できません。公式で地域ごとの固定表は存在しません。
AWS マネジメントコンソール側でも、VPC → Endpoints → Create Endpoint の画面でサービスを選ぶと、ポリシー対応/非対応の表示が出る場合があります（ただし CLI が最も確実です）。
必要であれば、東京リージョンの具体的なサービス一覧（ポリシー対応 true/false）を CLI で出力する例もお示しできます。ご希望ですか？
双方向sftpでprivatelink使う構成で、オーソドックスな構成だとする。
（バックエンドはS3、クライアントはVPC内EC2、オンプレからのSFTP要件なし）

この場合、
iamポリシー、vpceポリシー、s3ポリシーはどうするべき？

思考時間: 45s
以下は「双方向 SFTP（両社とも Transfer Family、バックエンド S3、クライアントは各社 VPC 内 EC2、オンプレ要件なし）」「PrivateLink を使って相互接続する“オーソドックス”」という前提で、IAM / VPC エンドポイント（VPCE）/ S3 バケットポリシーをどう設計すべきかを、実務で破綻しにくい形に落とします。
0. 先に結論（重要ポイントだけ）
SFTP のデータ面（put/get）は IAM / VPCE ポリシーでは直接制御できません。
SFTP 接続は L4/L7 的には PrivateLink + SG（と場合により NACL）で閉じる。
S3 への put/get は Transfer が AssumeRole する IAM ロール権限で閉じる。
VPCE ポリシーが効く典型は「S3 Gateway Endpoint」（＋一部 AWS サービスの Interface Endpoint）。
一方、相手の NLB を公開した “PrivateLink（Endpoint Service）” 接続そのものには VPCE ポリシーは基本的に使いません（そこで効くのは Endpoint Service の許可 Principal と Interface Endpoint の SG）。
S3 バケットポリシーで aws:SourceVpce を安易に必須化すると Transfer Family の S3 アクセスが止まることがあります。
よって、aws:SourceVpce を使うなら EC2 など“人間側アクセス”だけに適用し、Transfer 用ロールは例外として許可する設計が安全です。
1. IAM ポリシー（Transfer Family が S3 に触るための最小権限）
1-1. ロールの考え方（推奨）
各社とも、Transfer のユーザー単位（またはサーバ単位）で S3 prefix を固定し、最小権限にします。
例：A 社バケット a-sftp-bucket
A→B へ出す（put される側＝B から見ると受信）: s3://a-sftp-bucket/inbox/
B→A へ入れる（B が put できる領域）: s3://a-sftp-bucket/from-partner-b/
※ Transfer の「論理ディレクトリ（HomeDirectory）」で prefix をマッピングする想定（Service-managed users でも Custom IdP でも同様の方針は取れます）。
1-2. 信頼ポリシー（Trust policy）
Transfer が AssumeRole できるようにします。
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "transfer.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
1-3. 権限ポリシー（Permissions）例：prefix 限定（最小）
ここでは「特定 prefix に対して List/Get/Put を許可」し、他は不可にします。
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucketOnlyAllowedPrefix",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::a-sftp-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "from-partner-b/*",
            "from-partner-b"
          ]
        }
      }
    },
    {
      "Sid": "ObjectRWOnlyAllowedPrefix",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::a-sftp-bucket/from-partner-b/*"
    }
  ]
}
よくある追加（要件がある場合のみ）
SSE-KMS を使うなら kms:Encrypt/Decrypt/GenerateDataKey を対象キーに付与（KMS キーポリシー側も調整）
監査要件が強いなら s3:PutObject に s3:x-amz-server-side-encryption 条件を付けて強制
2. VPCE ポリシー（どこに適用するべきか）
2-1. PrivateLink（相手 NLB の Endpoint Service）には VPCE ポリシーは基本使わない
相互接続の PrivateLink は、制御点が次です。
Provider 側（公開側）: Endpoint Service の “Allowed principals”（この AWS アカウント/ロールだけ許可）
Consumer 側（利用側）: Interface Endpoint の Security Group（接続元 EC2 の SG などに限定）
（必要なら）NACL / ルート / DNS 設計
ここが “回線の門番” です。
2-2. VPCE ポリシーを使う本命：S3 Gateway Endpoint
各社 VPC 内の EC2 が S3 に直接アクセスするなら、S3 Gateway Endpoint の Endpoint Policyで強く縛れます。
（Transfer が S3 を触る経路とは切り分けて考えるのが安全）
例：VPC 内から「特定バケットのみ」許可する Endpoint policy（S3 GW Endpoint）
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOnlySpecificBuckets",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::a-sftp-bucket",
        "arn:aws:s3:::a-sftp-bucket/*"
      ]
    }
  ]
}
さらに厳しくするなら：
Action を GetObject/PutObject/ListBucket のみに
Resource を prefix まで絞る（ただし運用の利便性とトレードオフ）
2-3. Transfer の “Interface Endpoint policy” は「運用 API」を縛るもの（データ面ではない）
Transfer Family が（もし）Interface Endpoint 経由で利用される場合、VPCE ポリシーで縛れるのは概ね
Create/Update server
List/Describe
User 作成/更新
などの API 操作です。
SFTP の put/get を VPCE ポリシーで縛る発想は外し、
SFTP は PrivateLink + SG、S3 は IAM ロールで縛るのが王道です。
3. S3 バケットポリシー（どう設計すると事故りにくいか）
3-1. バケットポリシーの役割分担（推奨）
Transfer 用ロール: そのロールだけ許可（prefix 限定は IAM でも可、バケットポリシーでも二重化可）
VPC 内 EC2 等の“人間/アプリ”: aws:SourceVpce で「VPC Endpoint 経由のみ」に縛る
共通のセキュリティ強制: TLS 強制（aws:SecureTransport）、必要なら暗号化強制
3-2. 例：安全に共存させるバケットポリシー（Transfer ロールは例外許可）
ポイント
Deny は強いので、Transfer ロールまで巻き込まない条件設計にする
例外は aws:PrincipalArn で分岐させる
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::a-sftp-bucket",
        "arn:aws:s3:::a-sftp-bucket/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    },
    {
      "Sid": "AllowTransferRoleToPartnerPrefix",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/A-Transfer-PartnerB-Role"
      },
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::a-sftp-bucket",
      "Condition": {
        "StringLike": { "s3:prefix": ["from-partner-b/*", "from-partner-b"] }
      }
    },
    {
      "Sid": "AllowTransferRoleObjectRW",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/A-Transfer-PartnerB-Role"
      },
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::a-sftp-bucket/from-partner-b/*"
    },
    {
      "Sid": "DenyNonVpceForHumansExceptTransferRole",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::a-sftp-bucket",
        "arn:aws:s3:::a-sftp-bucket/*"
      ],
      "Condition": {
        "StringNotEquals": { "aws:SourceVpce": "vpce-0abc123def4567890" },
        "ArnNotEquals": {
          "aws:PrincipalArn": "arn:aws:iam::123456789012:role/A-Transfer-PartnerB-Role"
        }
      }
    }
  ]
}
この設計の意図
Transfer ロールは VPCE 経由でなくても（AWS サービス側の実装都合で）S3 に到達できるようにする
一方で、VPC 内 EC2 が誤ってインターネット経由で S3 に行く、別経路で行く、を aws:SourceVpce で潰す
4. 双方向（A⇄B）での実装の型
両社とも同じ型で揃えると運用が楽です。
A 側
A-Transfer-PartnerB-Role（B が A の SFTP に put するための S3 権限）
S3 GW Endpoint policy（A VPC の EC2 が S3 に行く場合）
バケットポリシー（Transfer ロール許可 + 人間系は SourceVpce 強制）
B 側
B-Transfer-PartnerA-Role
同様
そして、PrivateLink 側はポリシーではなく
Provider: Endpoint Service allowed principals（相手アカウントのみ）
Consumer: Interface Endpoint SG（送信元は EC2 SG のみ）
で閉じます。
5. 追加で確認したい “落とし穴” チェックリスト
S3 バケットに aws:SourceVpce を必須化していて、Transfer の put/get が失敗しないか（最頻出事故）
KMS を使っているなら、KMS キー側（Key policy / Grants）まで整合しているか
prefix 設計（from-partner-x/ と to-partner-x/）が双方で混乱しない命名になっているか
「削除（DeleteObject）」を許すか（通常は不要。要件がなければ外す）
必要なら、あなたの現状に合わせて次を“そのまま貼れる”形で作れます。
A/B 両社ぶんのロール名・バケット名・prefix 名を埋めた IAM/バケット/VPCE ポリシー一式
「SSE-S3」「SSE-KMS」別のテンプレ
“アップロード専用（Put only）” “ダウンロード専用（Get only）” の分離設計（監査が強い現場で有効）