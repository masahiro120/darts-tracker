# darts-tracker

ソフトダーツのカウントアップを1本ずつ記録し、刺さった位置から分析するための静的サイトです。データは Supabase に保存し、Claude に練習の相談ができるチャットも付いています。

## ページ

- `index.html`：記録と分析
  - ボードをタップして1本ずつ入力（狙いは BULL / T20〜T15 から選ぶ）
  - 狙いの中心からの平均のずれ・外れ幅・ブレ幅・距離・ラウンド内のまとまり・左右の行ったり来たりなどを集計
  - 刺さった位置のプロット、指標を切り替えられる推移グラフ、ゲーム一覧、同じ狙いのゲーム同士の比較
  - 右下の「Chat」で相談チャットをパネルとして開く
- `chat.html`：相談チャット（登録したアカウントでログインした本人だけが使える）

## 構成

- `css/site.css`、`icon.png`：共通のスタイルとアイコン
- `sql/`：Supabase の SQL Editor で実行する定義
  - `darts_supabase.sql`：ゲームと投げの表、アクセス制限、保存用の関数（新しく作る場合）
  - `darts_target_migration.sql`：既存の環境にゲームごとの「狙い」を追加する移行用
  - `darts_chat_supabase.sql`：チャットの会話を保存する表（本人だけが読み書きできる）
- `supabase/functions/darts-chat/index.ts`：チャットのサーバー側（Supabase Edge Function）。Claude API を呼び出す
  - 秘密の設定：`ANTHROPIC_API_KEY`（Claude の API キー）、`ALLOWED_EMAIL`（チャットを使えるアカウントのメールアドレス）

## ローカルで確認する

```bash
python3 -m http.server 8000
```

ブラウザで http://localhost:8000/ を開きます。
