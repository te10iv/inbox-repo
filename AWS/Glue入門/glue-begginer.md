

# AWS Glueとは（ETLツール・データクレンジング的なやつ）

## まずはこれだけ覚えよう


↓ 叩き台（今の私の理解）

▼基本的な流れ
→ETLツール（データのクレンジング、というか）
→データ検出（DB、S3）
→収集（AWS　Crawler)　
　・コード spark・python
    ・ローコード（Glue　VisualETL)、ノーコード（GlueDataBrew)   
→格納（Redshift、Athena、S3)

▼データパイプライン作成
Glue DataCatalog


▼料金（重要ポイントだけ）
基本ルール
従量課金
最小課金単位は 1分
※昔の「10分固定」は廃止済み
単位は DPU（Data Processing Unit）
代表的な単価（目安）
Glue Job
約 $0.44 / DPU / 時間
Crawler
約 $0.44 / DPU / 時間
Data Catalog
テーブル数・API 呼び出しで微課金（ほぼ無視できるレベル）
実際の使用例（概算）
例
Glue Job：2 DPU
実行時間：10分
0.44 × 2 × (10/60)
= 約 $0.15（約 20〜25円）
1日1回でも月
約 600〜700円程度
👉 小規模ならかなり安い


## GPTに概要聞いた

AWS Glue とは（結論）
AWS Glue は、サーバレスなフルマネージド ETL（ELT）基盤です。
主用途は S3 や RDS 等のデータを自動検出・加工し、分析基盤（Athena / Redshift 等）で使える形にすることです。
基本的な全体像（整理版）

① データ検出・メタデータ管理
Glue Data Catalog
Glue の中核
S3 / RDS / DynamoDB 等の
テーブル定義
スキーマ
パーティション
を一元管理
Athena / Redshift Spectrum / EMR から共通利用
Glue Crawler
データ検出の自動化ツール
S3 や DB をスキャンして
テーブル
カラム型
を自動生成 → Data Catalog に登録

② データ加工（ETL）
Glue Job
実体は Apache Spark（PySpark）
実行方式は以下の3系統
手法	位置づけ
Glue Job（PySpark / Python）	フルコード
Glue Visual ETL	ローコード（GUI）
Glue DataBrew	ノーコード（前処理特化）
役割
クレンジング
型変換
結合
パーティション分割
フォーマット変換（CSV → Parquet 等）


③ 格納・分析
S3（データレイク）
Athena（SQL分析）
Redshift（DWH）
RDS / DynamoDB（必要に応じて）
あなたの叩き台を「正確に」書き直すと
データソース
（S3 / RDS / DynamoDB など）
  ↓
Glue Crawler
  - データ検出
  - スキーマ自動生成
  ↓
Glue Data Catalog
  - メタデータ管理
  ↓
Glue Job
  - PySpark / Visual ETL / DataBrew
  - データ加工・変換
  ↓
S3 / Athena / Redshift
データパイプライン作成の要点
Data Catalog がハブ
Glue 単体というより
Athena / Redshift / EMR とセットで価値を発揮
EventBridge や Step Functions と組み合わせて
定期実行
イベント駆動
も可能
料金（重要ポイントだけ）
基本ルール
従量課金
最小課金単位は 1分
※昔の「10分固定」は廃止済み
単位は DPU（Data Processing Unit）
代表的な単価（目安）
Glue Job
約 $0.44 / DPU / 時間
Crawler
約 $0.44 / DPU / 時間
Data Catalog
テーブル数・API 呼び出しで微課金（ほぼ無視できるレベル）
実際の使用例（概算）
例
Glue Job：2 DPU
実行時間：10分
0.44 × 2 × (10/60)
= 約 $0.15（約 20〜25円）
1日1回でも月
約 600〜700円程度
👉 小規模ならかなり安い
Glue が向いているケース
S3 データレイク前提
Athena / Redshift を使う
バッチ処理中心
インフラ管理を極力したくない
向いていないケース
リアルタイム処理（→ Kinesis / Lambda）
軽い変換だけ（→ Lambda）
単純 SQL だけ（→ Athena CTAS）

## Lambdaと比較すると？


1) まず根本的な違い（機能設計）
特性	AWS Glue	AWS Lambda
目的	大量データの ETL / データレイク準備	軽量コード実行（イベント駆動）
実行時間の上限	最大 48 時間	最大 15 分（タイムアウト）
並列処理	分散処理（Spark）	単一関数並列（起動ごと）
スケール	大量バッチ向き	小さめ処理向き

2) 料金体系の大きな違い

AWS Glue の料金（ETLジョブ）
DPU（Data Processing Unit）× 実行時間で課金（2025年時点）
例：1 DPU-hour = 約 $0.44（東京リージョン想定） 
Amazon Web Services, Inc.
実行時間は 秒単位で請求（最低 1 分） 
Amazon Web Services, Inc.
あなたの例（1日1回、10 分、2DPU）：
0.44 × 2 × 10/60  ≒ $0.15（約 20～25 円）
→ 月額 ≒ 600～700 円程度（目安） ＊データ量や DPU 数による。 
要点
並列処理・大規模処理に向く
起動オーバーヘッドがあるため短時間の処理は割高になりがち


AWS Lambda の料金
リクエスト数 × 実行時間 × メモリ割当量 で課金 
Amazon Web Services, Inc.
例（2025年の目安）：
128MB で x ミリ秒実行 → 微小コスト
リクエスト数 1M 回までは無料枠あり（1M 無料/月） 
Amazon Web Services, Inc.
実行時間は ミリ秒単位で課金 → 短時間・少量処理は非常に安いケースが多い



1) 料金比較（実例で分かる違い）


ケース A：短い軽い処理
Lambda：関数実行数が少なく短ければ ほぼ無料（無料枠が大きい） 
Amazon Web Services, Inc.


Glue：1分未満でも最低 1分分請求 → 結果的に割高
結論
短時間・小データ処理は Lambda の方が圧倒的に安くなる可能性が高い。 
Databeat
ケース B：中〜大量データ処理
Lambda：15 分制限 + メモリ制約あり→ 大量処理はそもそも実行不可 or 分割が必要 
Zenn
Glue：長時間実行可能、並列処理で処理効率が良い
結論
大量データ・長時間のバッチ処理は Glue が適している。 
Databeat


1) コスト傾向整理（要点）
項目	Lambda	Glue
実行時間単位	ミリ秒	秒（最低 60sec）
無料枠	あり（1M リクエスト＆ GB-秒）	なし（Data Catalog は無料枠あり） 
Amazon Web Services, Inc.
短時間処理	非常に安い	相対的に高い
大量処理	不向き（タイムアウト）	向いている
初期オーバーヘッド	低い	高い（Spark 起動含む）


1) 何を使うべきか簡潔判断
Lambda を選ぶ場合
単発の軽い処理（ファイル単位のイベントなど）
イベントトリガーでリアルタイム処理
少量データの整形や通知系処理
Glue を選ぶ場合
大量データのバッチ ETL（GB〜TB）
複雑なデータ変換・結合
スケジュールバッチ・定期処理


1) 補足
Lambda には 15分制限があるため、それ以上の処理は Glue や EMR へ回す必要あり。 
Databeat
Lambda はメモリに応じて料金変動が大きく、重い処理では高額になる可能性あり。 
Kuix
Glue は Data Catalog の保有オブジェクト数やリクエストにも微課金あり（ただし多くの場合は小額）。


