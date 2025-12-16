# WorkshopのReadme

## 内容
Confluentの基本的な利用方法、Topic、Connector、Flinkを実際に利用して理解を深める。


### 操作内容
Confluent
- Confleunt CloudのUIをブラウザから利用する。
- AWS EC2インスタンスのコンソールからConfluent cliを利用する。

AWS EC2
- AWS consoleからEC2 instance connectでブラウザ経由でEC2 instanceのコンソールを操作する。


## 環境に関して


### 作成される環境

AWS region : us-east-1

AWS VPC : defaultのVPCに作成される。

EC2 instance : 
 - Confluent-Client-Consumer (Aamazon linux)
 - Confluent-Client-Producer (Aamazon linux)

RDS instance :
 - postgresql 16.10


## 環境準備

### 一式ダウンロード
```
> git clone https://github.com/kumay/CC_workshop_basic
```
あるいは
```
> wget https://github.com/kumay/CC_workshop_basic/archive/refs/heads/main.zip
```

内容チェック
```
> unzip main.zip

> cd CC_workshop_basic

> ls
1_kafka_workshop.md
2_connector_workshop.md
3_flink_workshop.md
4_dsp_workshop.md
5_ai_demo.md
MEMO.md
README.md
sample_avro.py
sample_dsp_data.py
terraform/

```


### Terraformの実行

```
ConfluentのCloud api用のapikey/secretを環境変数に設定。

# Linux
> export TF_VAR_confluent_cloud_api_key="your_actual_api_key"
> export TF_VAR_confluent_cloud_api_secret="your_actual_secret_key"

# Windows
> $Env:TF_VAR_confluent_cloud_api_key="your_actual_api_key"
> $Env:TF_VAR_confluent_cloud_api_secret="your_actual_secret_key"

AWSのクレデンシャルを取得して環境変数に入れる。 (Cloud consoleの場合は不必要)

# Linux
> export AWS_DEFAULT_REGION="us-east-1"
> export AWS_ACCESS_KEY_ID="<AWS Consoleから取得>"
> export AWS_SECRET_ACCESS_KEY="<AWS Consoleから取得>"
> export AWS_SESSION_TOKEN="<AWS Consoleから取得>"

#Windows
$Env:AWS_DEFAULT_REGION="us-east-1"
$Env:AWS_ACCESS_KEY_ID="<AWS Consoleから取得>"
$Env:AWS_SECRET_ACCESS_KEY="<AWS Consoleから取得>"
$Env:AWS_SESSION_TOKEN="<AWS Consoleから取得>"


terraformディレクトリに移動
> cd terraform

terraformを初期化
> terraform init


terraformの実行準備
> terraform plan


terraformの実行（環境作成）
> terrafrom apply


作成環境の削除
> terraform destroy
```

### 確認事項

作成後にworkshop.txtというファイルが出力されます。
**confluent_environment**
の値を確認してください、環境が構築された環境の名前になります。


### 環境の動作確認

１. RDSのセキュリティグループを確認
```
aurora-sgに以下がある事を確認
172.31.0.0/16

複数の/32のcidrがある事を確認
xxx.xxx.xxx.xxx/32

```

2. Confluent-Client-Producerのインスタンスに入って以下を実行する。

RDSのホスト名はAWS ConsoleからRDS画面に行き、**aurora-cluster-demo**を探しホスト名を確認する。

```
> psql -h <RDSのホスト名> -p 5432 -U postgres -d mydb

パスワードは → SuperSecurePassword123!  （デフォルト設定、変更した場合は変更したpasswordを入力してください。）

psql (16.11, server 16.10)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

mydb =>
```
上記のような表示が出ればOK.


3. Confluent cliの接続確認
Confluent Cloudのログインemailとパスワードを入力する。
```
> confluent login
Enter your Confluent Cloud credentials:
Email:

```
ログインができたらOK.
