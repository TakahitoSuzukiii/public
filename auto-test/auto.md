# auto-test

以下に、最初の条件を基にディシジョンテーブル、組み合わせ表、状態遷移表を作成しました。

## ディシジョンテーブル

ディシジョンテーブル（Decision Table）について詳しく解説しているサイトをいくつかご紹介します：

1. [Promapedia](https://ssaits.jp/promapedia/method/decision-tables.html)では、ディシジョンテーブルの構成や作成方法、実例について詳しく解説されています。特にシステム開発やテストケース作成における活用方法が分かりやすいです。
2. [Qiita](https://qiita.com/yasuro/items/f6f49a3212bab2dfeef8)では、ディシジョンテーブルを用いたテスト技法について簡潔にまとめられています。条件と結果の組み合わせを網羅する方法やメリット・デメリットが記載されています。

### ディシジョンテーブルの簡潔な解説

ディシジョンテーブルは、複数の条件とそれに対応する結果を整理するための表です。以下の特徴があります：

- **条件**：テスト対象の入力や状態を列挙。
- **結果**：条件に基づく動作や出力を記載。
- **組み合わせ**：条件と結果のすべての可能な組み合わせを網羅。

例えば、映画館の割引料金を決定する場合：

```markdown
| 条件 1: 1 日の場合 | 条件 2: 20:00 以降 | 条件 3: 65 歳以上 | 割引額  |
| :----------------: | :----------------: | :---------------: | :-----: |
|         Y          |         N          |         N         | -100 円 |
|         Y          |         Y          |         N         | -300 円 |
|         N          |         Y          |         Y         | -500 円 |
```

このように、条件と結果を明確に整理することで、テストケースの抜け漏れを防ぎ、網羅性を高めることができます。

### ディシジョンテーブル（Decision Table）

Mermaid の表記に変換すると以下のようになります：

```mermaid
table
  title ディシジョンテーブル
  header ワーカー数, サーバースペック, ドライバーバージョン, 期待される結果
  row 1, Large, 1, 結果A
  row 1, Large, 2, 結果B
  row 1, Large, 3, 結果C
  row 1, Xlarge, 1, 結果D
  row 1, Xlarge, 2, 結果E
  row 1, Xlarge, 3, 結果F
  row 2, Large, 1, 結果G
  row 2, Large, 2, 結果H
  row 2, Large, 3, 結果I
  row 2, Xlarge, 1, 結果J
  row 2, Xlarge, 2, 結果K
  row 2, Xlarge, 3, 結果L
  row 4, Large, 1, 結果M
  row 4, Large, 2, 結果N
  row 4, Large, 3, 結果O
  row 4, Xlarge, 1, 結果P
  row 4, Xlarge, 2, 結果Q
  row 4, Xlarge, 3, 結果R
```

### 組み合わせ表（Combination Table）

すべての条件の組み合わせを以下のように表します：

```mermaid
table
  title 組み合わせ表
  header 条件①ワーカー数, 条件②サーバースペック, 条件③ドライバーバージョン
  row 1, Large, 1
  row 1, Large, 2
  row 1, Large, 3
  row 1, Xlarge, 1
  row 1, Xlarge, 2
  row 1, Xlarge, 3
  row 2, Large, 1
  row 2, Large, 2
  row 2, Large, 3
  row 2, Xlarge, 1
  row 2, Xlarge, 2
  row 2, Xlarge, 3
  row 4, Large, 1
  row 4, Large, 2
  row 4, Large, 3
  row 4, Xlarge, 1
  row 4, Xlarge, 2
  row 4, Xlarge, 3
```

### 状態遷移表（State Transition Table）

状態遷移表を Mermaid で表現する場合は以下のようになります：

```mermaid
table
  title 状態遷移表
  header 現在の状態, イベント, 次の状態, 条件
  row 初期状態, ワーカー数=1, 状態A, サーバースペック=Large
  row 状態A, ドライバーバージョン=1, 状態B, 条件が満たされる場合
  row 状態B, サーバースペック変更, 状態C, Xlargeの場合
  row 状態C, ワーカー数変更, 状態D, 条件が一致する場合
```
