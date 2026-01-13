他社AWS環境とprivate link経由でSFTPでやりとりしたい。
private link構築手順を紹介しているwebサイトを複数教えて
以下は 他社（別アカウント）との AWS 環境で PrivateLink 経由で SFTP を連携（やり取り）する構築手順を含む解説 をしている Web サイト・ドキュメントです。特に AWS Transfer Family（SFTP）に AWS PrivateLink を使った構成 や クロスアカウントで AWS PrivateLink サービスを提供／接続する手順例 が参考になります。
1. AWS 公式ドキュメント（PrivateLink × AWS Transfer Family）
■ AWS Transfer Family で PrivateLink 経由で接続する方法（手順）
AWS Transfer Family API エンドポイントに Interface VPC Endpoint（PrivateLink）を作成して PrivateLink 経由の接続を設定する公式ガイド
VPC エンドポイントの作成方法や VPC 内からの接続方法が記載されています。
https://docs.aws.amazon.com/transfer/latest/userguide/vpc-api-endpoints.html
2. AWS ブログ（Cross-Account PrivateLink でのサービス公開と接続例）
■ AWS PrivateLink による企業間プライベートネットワーク接続の例
AWS アカウント A（Consumer）と B（Provider）の例。
B 側で Network Load Balancer（NLB）を設定し、エンドポイントサービスとして公開 → A 側で VPC Endpoint を作成
エンドポイントの承認プロセスやアカウント間でのアクセス手順が詳細に解説されています。
https://aws.amazon.com/jp/blogs/news/aws-privatelink-cross-account-connection/
3. Classmethod（Developers.IO）事例記事 — AWS Transfer for SFTP ＋ PrivateLink
■ Transfer for SFTP が PrivateLink に対応したので（手順例）
Transfer for SFTP 用 VPC エンドポイントの作成手順
Internal NLB を作成し、PrivateLink を使ったクロスアカウント接続構成例
記事内に設定画面やステップごとの手順もあり、実装時のリファレンスになります（日本語）
https://dev.classmethod.jp/articles/transfer_for_sftp_support_privatelink/
4. Developers.IO 記事 — Transfer Family Endpoint における構成例
■ AWS Transfer for SFTP の構成例まとめ（PrivateLink／VPC Endpoint）
AWS Transfer Family のエンドポイントタイプや構成パターン
VPC (Internal) など VPC エンドポイントタイプの選び方と PrivateLink の差分などが整理されています。
https://dev.classmethod.jp/articles/trasfer-for-sftp-endpoint-types-202004/
5. クロスアカウント AWS PrivateLink 構築手順（汎用 / Terraform 例）
■ How to Set Up Cross-Account Service Integrations with AWS PrivateLink（Terraform 例）
AWS Provider（サービス側）と Consumer（クライアント側）で PrivateLink を構築するステップを Terraform で説明。
サービスプロデューサー側でエンドポイントサービス公開 → Consumer 側で VPC Endpoint を作成 → 承認手順までカバー。
https://www.sls.guru/blog/how-to-set-up-cross-account-service-integrations-with-aws-privatelink
6. AWS 公式 Transfer Family サーバー作成と VPC 連携（補助参考）
■ Transfer Family サーバーを VPC 内で構築する手順
AWS Transfer for SFTP サーバーを VPC 内で構築する公式手順書
PrivateLink 用エンドポイントとの関連がある VPC 内構成を理解する上でも有用です。
https://docs.aws.amazon.com/ja_jp/transfer/latest/userguide/create-server-in-vpc.html
補足・関連情報
AWS PrivateLink は VPC 間のプライベート通信を可能にする仕組みで、NLB や Interface VPC Endpoints を使用して別アカウント同士で安全な接続ができます。
AWS Transfer for SFTP は PrivateLink を活用することでインターネットを経由せずに安全にファイル転送できます。
上記リンクは手順／概念を含む構築ガイドあり、クロスアカウント接続の実装リファレンスとして活用可能です。
必要であれば、構築手順の要点まとめ（ステップ・AWS コンソール画面手順） や Terraform での Infrastructure as Code 例 も作成できます。希望する形式を教えてください。