# zmk-config-roBa

## JIS配列対応

[zmk-layout-shift](https://github.com/kot149/zmk-layout-shift) を使用してJIS配列に対応しています。

OSがJIS配列に設定されている場合でも、記号キーが正しく入力されます。

### JIS/US配列の切り替え

Layer 6 の左上キーに `tog_ls`（Toggle Layout Shift）を割り当てています。

| 状態 | 説明 |
|------|------|
| Layout Shift OFF | US配列として動作（デフォルト） |
| Layout Shift ON | JIS配列として動作 |

OSの設定がJIS配列の場合は `tog_ls` を押してLayout Shiftを有効にしてください。

## Auto Mouse Layer

トラックボールを動かすと自動的にMOUSEレイヤー（Layer 4）が有効になります。

Input Processor方式を採用しており、以下の機能があります：

| 設定 | 値 | 説明 |
|------|-----|------|
| タイムアウト | 10秒 | 操作がないと自動で解除 |
| 誤爆防止 | 200ms | キー入力直後のカーソル移動では発動しない |
| 除外キー | マウスボタン | マウスボタンを押してもレイヤーは解除されない |

## Mod-Tap / Layer-Tap 設定

`&mt`（mod-tap）と `&lt`（layer-tap）に以下の設定を適用しています：

| 設定 | 値 | 説明 |
|------|-----|------|
| flavor | balanced | ホールド/タップの判定方式 |
| quick-tap-ms | 150ms | 連続タップ時に即タップとして認識する間隔 |

- **balanced**: 他のキーを押すとホールド、離すとタップとして判定
- **quick-tap-ms**: 素早い連続入力（例: "aa"）がしやすくなる

## Keymap

<img src="keymap-drawer/roBa.svg" >
