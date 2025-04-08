# 参考

## UML

- https://www.lucidchart.com/pages/ja/what-is-uml-class-diagram
- https://www.lucidchart.com/pages/ja/what-is-UML-unified-modeling-language
- https://www.edrawsoft.com/jp/uml-diagram-examples.html
- https://cacoo.com/ja/blog/what-is-uml/

### インストール

- https://qiita.com/incho9/items/d70e53c8d405098d0ae6
- https://adoptium.net/download/
- https://graphviz.org/download/

## PlantUML

- https://plantuml.com/ja/

## Mermaid

- https://qiita.com/ryamate/items/3779418172c4f5a83212
- https://zenn.dev/yasuhiroki/articles/dd0feae790ba41
- https://zenn.dev/iharuoru/articles/630ae2e4d7230d

## aws

### 公式

- https://github.com/awslabs/aws-icons-for-plantuml/tree/master

### qiita

- https://github.com/milo-minderbinder/AWS-PlantUML
- https://qiita.com/irongineer/items/23fcd55830ae2de96ca8#mermaid
- https://qiita.com/sakai00kou/items/18e389fc85a8af59d9e0
- https://qiita.com/yone_suke/items/7e026df29c50f9498a58
- https://zenn.dev/spiegel/articles/20211107-visualize-json-by-plantuml

## テストサンプル

- https://qiita.com/goataka/items/61384223da96c7e6c064

## その他

- https://qiita.com/Nakamura-Kaito/items/bda2003313fa33f4d818
  AI 駆動開発
- https://qiita.com/makishy/items/4dd3662a52851a2c5ddc
  AI コーディング例：Cline でアプリを作ろう！AI と協業する開発フローを体験
- https://dev.classmethod.jp/articles/cursor-cline/
  AI コーディング例：Cursor から Cline を使ってプログラミングをやってもらってみる
- https://qiita.com/watany/items/468313c602860f82fdde
  AI コーディング例：Cline ＋ Amazon Bedrock(Claude)で”国内要件”でも AI エージェントを諦めない
- https://dev.classmethod.jp/articles/aws-drawio-genai/
  AI コーディング例：生成 AI に draw.io の AWS 構成図を作図させてみた
- https://dev.classmethod.jp/articles/generative-ai-use-cases-jp-handson-basics/
  ※別もの：Generative AI Use Cases JP (GenU)を使って生成 AI を体験してみよう（基礎編）

## Mermaid

```mermaid
sequenceDiagram
    actor クライアント
    participant API as API Gateway<br/>Rest API
    participant Lambda as Data Get<br/>Lambda Function
    participant DataTable as Amazon DynamoDB<br/>Data Table

    クライアント ->>+ API: データ一覧取得
    API ->>+ Lambda: データ一覧取得
    Lambda ->>+ DataTable: データ一覧取得
    DataTable -->>- Lambda: 取得OK
    Lambda -->>- API: データ一覧
    API -->>- クライアント: 200 OK
```

---

```mermaid
sequenceDiagram
    actor クライアント
    participant API as API Gateway<br/>Rest API
    participant Lambda as Data Post<br/>Lambda Function
    participant DataTable as Amazon DynamoDB<br/>Data Table
    participant SES as Amazon SES

    クライアント ->>+ API: データ登録
    API ->>+ Lambda: データ登録
    Lambda ->> Lambda: バリデーション
    alt バリデーションエラーの場合
      Lambda -->> API: バリデーションエラー
      API -->> クライアント: 400 BadRequest
    end
    Lambda ->>+ DataTable: データ登録
    DataTable -->>- Lambda: 登録OK
    Lambda ->>+ SES: メール送信依頼
    SES -->> Lambda: 送信受付OK
    SES ->>- クライアント: 登録確認メール送信
    Lambda -->>- API: 登録OK
    API -->>- クライアント: 200 OK
```

```mermaid
stateDiagram
    [*] --> Task1
    Task1 --> Task2: Success
    Task1 --> Error: Failure
    Task2 --> [*]
    Error --> [*]
```

# パッケージ図

```mermaid
graph LR
    PackageA[Package A]
    PackageB[Package B]
    PackageC[Package C]
    PackageD[Package D]

    PackageA --> PackageB
    PackageA --> PackageC
    PackageB --> PackageD
    PackageC --> PackageD
```

---

### 解説
- **パッケージ**:
  各モジュールやサブシステムをパッケージとして表現しています（例: `Package A`, `Package B`）。
- **依存関係**:
  矢印でパッケージ間の依存関係を示しています。例えば、`Package A`は`Package B`と`Package C`に依存し、それらはさらに`Package D`に依存しています。

このようなパッケージ図は、システム設計の際に構造を視覚的に把握するのに役立ちます。具体的なプロジェクトに応じてカスタマイズ可能ですので、さらに詳細な図が必要であれば教えてください！

# アクティビティ図

### 1. **ディレクトリツリー図**

```mermaid
graph LR
    root[Project Root]
    root --> src[Source Code]
    src --> components[Components]
    src --> utils[Utilities]
    root --> public[Public Assets]
    public --> images[Images]
    public --> css[CSS]
    root --> tests[Test Files]
    root --> README[README.md]
```

```mermaid
graph LR
    A[env] --> B[商用環境]
    A[env] --> C[開発環境]
    B[商用環境] --> D[main.tf]
    B[商用環境] --> E[variables.tf]
    B[商用環境] --> F[output.tf]
    B[商用環境] --> G[terraform.tfvars]
    C[開発環境] --> H[main.tf]
    C[開発環境] --> I[variables.tf]
    C[開発環境] --> J[output.tf]
    C[開発環境] --> K[terraform.tfvars]
    L[modules] --> M[web]
    M[web] --> N[main.tf]
    M[web] --> O[variables.tf]
    M[web] --> P[output.tf]
    M[web] --> Q[terraform.tfvars]
```

---

### 2. **レイヤー構造図**

```mermaid
graph LR
    Application[Application Layer]
    Application --> Controllers
    Application --> Views
    Core[Core Layer]
    Core --> Models
    Core --> Services
    Core --> Repositories
    Infrastructure[Infrastructure Layer]
    Infrastructure --> Configurations
    Infrastructure --> Database
```

---

### 3. **ファイルの依存関係図**

```mermaid
graph LR
    index.js --> app.js
    app.js --> database.js
    app.js --> routes.js
    routes.js --> controllers.js
    controllers.js --> services.js
```

---

### 4. **状態遷移の視点で表現する場合**

```mermaid
stateDiagram
    [*] --> InitialSetup
    InitialSetup --> Development: Add Code
    Development --> Testing: Write Tests
    Testing --> Deployment: Deploy Code
    Deployment --> [*]
```

```mermaid
stateDiagram
    [*] --> CLOSED
    CLOSED -->|受信開始| LISTEN
    CLOSED -->|終了| SYN_SENT
    LISTEN -->|SYN受信| SYN_RECEIVED
    LISTEN -->|送信開始| SYN_SENT
    SYN_SENT -->|SYN/ACK受信| ESTABLISHED
    SYN_SENT -->|ACK受信| SYN_RECEIVED
    SYN_RECEIVED -->|RST受信| CLOSED
    SYN_RECEIVED -->|SYN受信| SYN_SENT
    SYN_RECEIVED -->|ACK受信| ESTABLISHED
    ESTABLISHED -->|FIN受信| CLOSE_WAIT
    ESTABLISHED -->|終了| FIN_WAIT1
    FIN_WAIT1 -->|FIN受信| CLOSING
    FIN_WAIT1 -->|ACK受信| FIN_WAIT2
    FIN_WAIT2 -->|FIN受信| TIME_WAIT
    CLOSE_WAIT -->|切断処理開始| LAST_ACK
    LAST_ACK -->|ACK受信| CLOSED
    CLOSING -->|ACK受信| TIME_WAIT
    TIME_WAIT -->|終了| CLOSED
```
