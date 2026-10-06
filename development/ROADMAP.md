# ldfreq：研究根拠・利用手順・検証を結ぶロードマップ

更新日：2026-10-06、5資源の配布一覧・3 OSの導入整合、140作文の語族比較、日本語作文1,777件の読込を確認。J-UniMorphの複数token範囲を28実作文で照合。英語140作文の同じ31,902出現へMorphoLex／MorphyNetを接続し、語族所属・資源候補・出現判断を分離。c788d909のCI全9 jobが成功。導入revisionの固定、取得したGitHub sourceの一致・新規導入、公開用サイト128ページを確認。Public化・main統合・gh-pages公開を完了。最終CI全9 job成功、公開128ページと匿名main取得345ファイルの一致を確認。対象：Rパッケージ0.2.0の開発checkout。

## 現在の優先順位と統合計画

公開後の利用例：ユーザーの依頼に基づき、既存のreport guideへ431語の作成英文・
25/50/100語窓の局所TTR重ね描き・白黒切替・PNG/PDF保存コードを追加。ホームに
図と直接リンクを置く。API・計算処理・依存は不変。変更ガイドと独立コピー実行を確認し、
既存のmain保護に従って一度のPRへまとめ、サイト公開まで進める。

**研究上の最優先は、元の文書を保持し、注釈・語の数え方・参照資源の選択が
結果をどう変えるかを原文の出現まで追って検証することである。利用者提供表による
word familyの照合・集計と既存レビューによる出現別判断の適用は実装済み。
語根・接辞は提供表の集計とMorphoLex読込を明示実行のexampleとして実装した。
MorphoLexは非商用条件を明記して全34シートを同梱し、`morpholex_data()`で参照できる。
Nation BNC/COCA Level 6の25,000語族をCC BY-SA 4.0で同梱し、`bnccoca_data()`から
既存語族APIへ接続した。MorphyNet派生表は`morphynet_read_derivations()`で読み、
出現別の選択／保留へ接続するexampleを追加。J-UniMorphのローカル読込と複数token範囲の判断例も実装済み。
追加済み資源と配布一覧・検査の不整合は修正し、Macで配布物と導入後の一致を確認した。
公開工程ではc788d909のCI全9 jobが成功し、WindowsのUnicode作成fixture修正も確認した。
ユーザーの明示承認に基づき既存repoをPublicへ変更し、準備済みpkgdownをgh-pagesへ配備した。
最終文書を含む600debeeの必須CI全9 job成功後、PR #21をmainのbbab3eeへ統合済み。
main treeは検証済みPRと同一であり、匿名取得した345ファイルも一致する。
公開サイト全128 HTML・関連ファイルを含む246件が準備済み成果物とbyte一致した。
CRAN投稿はユーザーから明示的に禁止されており、この公開作業に含めない。
研究作業は既存ICNALE全文書の語族比較と形態候補の同一出現への接続まで完了した。
候補選択の効果は再配布可能な作成例で示し、実作文の文脈判断は未実施として保持する。
日本語ではJ-UniMorphの候補と複数tokenにまたがる出現範囲の対応を明示exampleとして実装した。
独立した文脈判断の正確さと公開API化は未評価であり、動作確認と区別する。
完全な形成構造・汎用parts API化はその利用例から必要性を判断する。
既存0.2.0の公開準備は、これらの後続機能・研究の完了を待たずに進める。**

この統合計画を着手順序・採否・完了判断の正本とする。後半の「実装・調査の履歴」は
根拠と過去の判断を保存したものであり、その中の「次」「未実装」「最新CI」は各記録時点の
情報である。旧M0–M6と注釈評価の段階1–5は参照用の識別子として維持するが、
番号順の実行や全項目の一括完成を求めない。workspaceの旧 `r-package/` 計画より本節を優先する。
実装・配布証拠は [PUBLICATION-20261004.md](PUBLICATION-20261004.md)、
API判断は [API-NAMING.md](API-NAMING.md) と [API-SURFACE.md](API-SURFACE.md) を参照する。

### 目的・対象読者・貢献

利用者が困るのは、同じ文章でも分割、見出し語化、除外、表記統合、語族、参照表によって
「語彙が多様／高度」という結果が変わり、得点だけから理由を説明できないことである。
ldfreqは、その条件・分母・未照合・人の判断と原文の出現を結び、Rで再集計・比較・報告できる
研究手順を提供する。対象はSLA、コーパス研究、心理言語学、教材・語彙テスト研究である。
学習者作文に限定せず、母語話者資料、発話、学術文、刺激語・項目表も扱う。

英語の基本分析はR内で完結させ、モデル・Python・有料GUIを必須にしない。日本語は
既存の形態解析器・辞書からの実験的入力経路と規準表照合を育てる。同じAPIの利用と、
英日での測定等価性は区別する。個々の指標、KWIC、n-gram、Rの利用、日本語対応自体を
新規性とせず、条件変更の影響を追跡できる統合と、その実用性を示すことに貢献を置く。
速度・精度・使いやすさの優越、能力得点としての妥当性は別の証拠が得られるまで主張しない。

### 現在地：何が動き、何が未確認か

2026-10-06にcheckoutを再確認：57 exports、34 S3登録、38 Rdファイル、21 Rmdガイド。
これらは規模の記述であり完成率ではない。公開API、明示実行のexample helper、研究scriptを
区別する。後二者の実行成功を公開APIへの昇格や一般的な精度保証としない。

| 領域 | 実装・確認済みの範囲 | 未完了・主張できない範囲 |
|---|---|---|
| 多様性と比較 | 12指標、定義別比較、plan/grid、batch、局所MATTR、分母・計算不能理由 | 普遍的な最良指標・窓幅、全課題での信頼性・妥当性 |
| 英語前処理 | 英語tokenizer、明示lemma/flemma、完全な外部注釈import、位置・注釈比較 | 汎用POS/NER/GECの自作、同梱TUBELEXとの完全な分割互換 |
| 語族・接辞 | `lexdiv_family_profile()`で提供表の照合、候補／KWIC、語形内訳、文書別coverage・語族数・TTR。`review`で既存レビューの出現別選択／保留を適用し、自動照合・判断者・理由を保持。作成例で4単位比較と保存復元。別のexampleで語根・接辞の提供表集計、部分解析・候補・KWICと同梱／任意のローカルMorphoLex読込。Nation BNC/COCA実表の語族接続。MorphyNetの一段形成関係の読込。語族・MorphoLex・MorphyNetを同じ出現へ接続し、個別のKWIC判断を適用する明示example | 広範なinventory比較・対象への適合性、多段階の形成構造、汎用API化、学習者の語彙知識・生産性の推定 |
| 誤り・数え方 | 承認済み修正を適用する例、原文／修正版比較、英米表記の例示alias、PROPN/NUM/PUNCT/SYMの選択例 | 自動修正の正確さ、包括的変種辞書、名前の匿名化、数値意味解析 |
| 頻度・心理規準 | NJ8/TUBELEX、generic normのsingle/batch、診断、項目ID・欠測を保った照合 | 頻度＝親密度＝既知率＝employabilityという換算、異種規準の総合得点 |
| 複語 | 隣接bigram/trigramの抽出・参照構築・比較、文書単位の分割集計、quantedaによる長い句の例 | 汎用MWE認定、MI/t-score、語義別慣用性、大規模標準参照の確立 |
| 注釈・構文 | 同一分割のラベル評価、異分割の対応、基本UDのADJ–amod–NOUN、任意UDPipe例 | 全依存関係・全UD構造の対応、全文書・全レジスターでの精度保証 |
| 実資料での評価 | ICNALE 140原作文の表層／lemma・校閲版比較、辞書変更、Nation語族の共通token比較あり。ESLSpok 232文・2,266 token、修正設定で55 TP・6 FP・5 FN、独立算術照合あり | ICNALEの変更判断は独立人手参照ではない。Nation照合は固定表との計算照合で、文脈上の正確さの独立評価ではない。MorphoLex／MorphyNet候補を31,902出現へ結び、全件の参照表照合数を確認したが、文脈上の形態解析精度は未評価。ESLSpokは同一testを使った開発時確認で、全文書の下流評価・未使用最終評価・L1や日本語への一般化は未完了 |
| MASC/OANC | MASC 392文書の受入れ点検、受入れ122文書・79,059 tokenの位置と集計の独立照合。OANCは配布物・層構成点検 | MASC残270文書、OANC reader・全体処理、資料重複、代表性、OANC規模のメモリ |
| 日本語 | gibasa/UniDic実例、分割比較、TUBELEX・WLSP・AoA・BOIの項目照合、WLSP多義性と選択理由の保存。仮名／漢字表記の出現別語彙ID比較、原文を保持する境界見直し→KWIC再作成の例。実gibasaによる8作成文の位置確認と1文の境界／語彙判断接続。作文対訳DB全1,777件の明示文字コード読込、実作文28件・10,932注釈の原文対応と集計 | 無料規準によるNTT全体の代替、同音・多義の自動解決、実作文の仮名分割・語彙同定の精度、漢字知識の推定、L2への規準適合、言語間尺度の同等性 |
| 意味・文脈 | KWIC判断、判断比較、外部埋め込み取込、頻度／centroid基準、評価・再集計の研究フォルダ | 独立標本での意味判別性能、未知語への一般化、候補辞書の網羅性 |
| 記述・可視化・統計 | 文書／項目別表、条件別記述例、11 plotのAPA設定・カラー／白黒、元の分布の重ね描き | 自動的な妥当性・CI付与、汎用ネットワーク分析API、検証済みLexOPS接続 |
| 公開 | 5資源の一覧・COPYRIGHTS整合と3 OSのsource／platform／install照合。Public化・main統合・pkgdown配備済み。匿名main取得345ファイル、公開サイト128 HTMLを含む246件のbyte一致。必須CI全9 job成功 | 開発版として公開。正式RCではない。CRAN投稿は明示的に対象外 |

最新の採用CIは[600debee / run 37456525303](https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37456525303)。
公開説明4ファイルを含む最終PR HEADであり、runtime／testsはc788d909と同一。
全9 job成功。Windows／macOS／Linux現行・開発版は各7,785 assertions、失敗・警告・skipなし、Status: OK。
R 4.1は7,710 assertions成功、任意textstem関係8 skipと依存未導入・installed sizeの2 NOTE。
資源照合は3 OSとも56 member一致（Linux／Mac各2,017、Windows2,018 assertions）。
初回8183addではWindowsのUnicode作成fixtureが1件失敗し、文字構築だけを修正して成功した。
[PR #21](https://github.com/Ryuya-dot-com/ldfreq/pull/21)はmain `bbab3ee37ded00e247b90ffaab27f1f87195ed87`へ統合済み。
Pagesはgh-pages `2094951948b18000212f8e67f41d7a937e4ace9a`を配信。既存のmain保護を維持し、
同一treeのマージ時だけ重複CIを省いた。CRAN投稿・release tag作成は行っていない。
Release candidateの分類job成功・artifact job skipと、正式な候補配布物検査を区別する。

公開経路の準備結果は`reviews/ldfreq-publication-path-20261006/evidence/`。
公開準備時のmainとPagesは`5466bb88`（2026-09-22）で、package versionは同じ0.2.0でも公開APIは30だった。
READMEのGitHub導入例を検証済み`c788d909`へ固定し、345 source fileのGitHub取得結果を全件照合、
新規導入後の57 exports・初回分析・同梱辞書・描画を確認。GitHub導入でガイドが省略される場合を明記した。
空の出力先へpkgdownを構築し、128 HTML page・247 fileのリンク・fragment・内部path不在を確認。
`.nojekyll`付きサイトZIPは2,439,531 bytes、SHA256
`b78bc7e8911ad9309c0e6fc992782c77642ec6f30edaf8bc373411eefe35932e`。
ホーム上部のChrome描画を目視。全ページ・全画面幅の目視とはしない。

最新の公開用source archiveは`reviews/ldfreq-publication-path-20261006/evidence/package/ldfreq_0.2.0.tar.gz`。
5,612,146 bytes、SHA256 `22a09bf5885182f890d517dc9b831fcbb7cf6f61007b3cda7d303f450995e170`。
直前archiveとの差はREADMEとDESCRIPTION build情報だけ。275 source file一致、155 inst member不変。
CONTRIBUTINGの完全検査手順もinstalled-package検査へ修正（package外、サイト側へ反映）。
変更は文書と公開記録のみ。mainのrulesetはPRと必須チェックを要求するため、
最終文書を一回のPR更新へまとめて全9 job成功を確認。保護を迂回せず、同一treeのmainマージ時だけ重複CIを省いた。
2026-10-06に既存repoのPublic化・main反映・Pages公開への明示承認を得た。
CRAN投稿はしない。正式release-candidateの状態変更・配布物検査は今回の範囲外。

直前のCI対象source archiveは`reviews/ldfreq-morphology-link-20261006/evidence/final/ldfreq_0.2.0.tar.gz`。
5,611,817 bytes、SHA256 `c4b11c1b15a81cfd303dcf97deb07b4604e87fd1a74d9ab5acb51d7f93d69e9f`。
直前の形態接続archiveとの差はUnicode作成fixtureのtestとDESCRIPTIONのbuild情報だけである。
275 source fileがcheckoutと一致し、155 inst member・21 compiled guide・runtime・資源は不変。
対象50 assertionsが成功。既存の導入後再現・数値・文書・資源照合の証拠を再利用する。

形態接続初版のsource archiveは`reviews/ldfreq-morphology-link-20261006/evidence/ldfreq_0.2.0.tar.gz`。
形態接続helper・作成例・対象testとguide／NEWSを追加。275 source fileがcheckoutとbyte一致、
導入後155 inst memberも一致。40 assertions、変更guideのrenderと導入後script、実140作文の
全候補件数の直接照合・保存復元を確認。20の不変guideと108の不変runtime／help／資源／license
memberの証拠を再利用。archiveは5,611,720 bytes、SHA256
`e891bf10e54ab08cf25988b29ed18705690a6217d95e7e42e2cb57029adfe6d0`。
Windows改行変換から新資源のbyte契約を保護し、登録済み21 memberの一致を確認した。
公開APIは57のまま。private PR #21へ統合する範囲であり、一般公開・CRAN投稿とは区別する。

直前のJ-UniMorph source archiveは`reviews/ldfreq-junimorph-spans-20261006/evidence/ldfreq_0.2.0.tar.gz`。
J-UniMorph形式reader、複数token範囲のKWIC判断と作成例、guide・NEWS・対象testを含む。
272 source fileがcheckoutとbyte一致し、DESCRIPTIONはfield値で照合。導入後153 inst memberも一致。
新規50 assertionsと導入後同50 assertions、変更guideのrender／抽出script、実28作文の全1,309範囲の
独立検索・境界照合、実解析した作成例の判断・保留、exact archiveでの保存結果の再現を確認した。
archiveは5,600,278 bytes、SHA256
`42ce455b83829d7df16cedda383a02dc721a507ac2729e7949655a6b818495d4`。
R本体・help・資源・license等108 memberは直前archiveと不変。20の不変guideは原稿一致に基づき再利用し、
直前の対象test・限定checkの証拠を保持した。今回は全体check・新platform binary・remote CI・公開を実施していない。
実作文の文脈判断は未実施で、完全一致やtoken境界一致を言語学的な正しさと解釈しない。

直前の実作文入力archiveは`reviews/ldfreq-ninjal-input-20261006/evidence/ldfreq_0.2.0.tar.gz`。
作文対訳DBのローカルreader、作成文だけのZIP fixture、CR/LF部分注釈のimport修正、guide・help・NEWSを含む。
269 source fileがcheckoutとbyte一致し、build時に整形されるDESCRIPTIONの値も照合した。
導入後の151 inst memberもarchiveと一致。関連745 assertions、導入後の対象84 assertions、
変更guideのrender／抽出script、exact archiveで全1,777件の読込結果と28作文の注釈の再現を確認。
archiveは5,586,141 bytes、SHA256
`49fb056fdbfacada735064c75458ec7ec83bd93dc069166f3d941fe95ab3d0d9`。
新規API・必須依存はない。変更していない20 guideの生成物を原稿一致に基づき再利用した。
`R CMD check --no-tests --no-manual --ignore-vignettes`はStatus: OK。対象testと変更guideの検証は上記の別工程。
全体test・全guideの再構築・新platform binary・remote CI・公開は今回未実施。言語学的精度の評価ではない。

直前の表記／境界archiveは`reviews/ldfreq-japanese-boundaries-20261006/evidence/`にある。
8作成文、1文の境界判断→語彙選択、46 assertionsの証拠を保持する。新しい実作文の入力検証で置き換えない。

直前の語族比較で検証したsource archiveは`reviews/ldfreq-family-comparison-20261006/evidence/`にある。
語族比較のexample helper・作成例・guide・NEWS・対象testを追加／更新。公開APIは57のまま。
264 source fileがcheckoutとbyte一致し、導入後の149 inst memberもarchiveと一致。
変更したguideをrender・導入後の抽出R scriptで確認し、20の不変guideは再利用した。
archiveは5,560,690 bytes、SHA256
`620bb962116f22425fb3628536db555b96325a165c4d005a8a0e55d699a87436`。
R本体・help・データ・licenseは直前archiveから不変。既存の数値・資源変換の証拠を再利用した。
対象test、exact archiveの作成例と保存再読込、ローカルarticle／NEWS生成まで成功。
全体check・他OS・remote CI・公開は今回実行していない。

初回の日本語表記例（24 assertions）は`reviews/ldfreq-japanese-orthography-20261006/evidence/`。
その後の境界例を含む現版は上記最新archiveを参照する。以下のarchive同一性・配布検査は
それぞれ記載した成果物に対する証拠として保持する。

5資源の一覧修正時のarchiveはworkspaceの`reviews/ldfreq-resource-inventory-20261006/evidence/`にある。
Mac（R 4.6.1、aarch64-apple-darwin23）で5資源・56ファイルをsource／platform package／install後に
照合し、2,317 assertionsが成功。16 CLIケースと3つの公開記録の検査、installed resource testの
101 assertionsも成功。公開記録の検査は実際の生成・集約コードへのfixture検査であり、
全OSのrelease workflowを実行したという意味ではない。NEWSのローカルページも更新した。
263 source fileがcheckoutとbyte一致。runtime・help・データ・license・例・guide原本の156ファイルは
前段から不変で、全21 compiled guideを再利用。archive 5,554,356 bytes、extdata 4,521,543 bytes、
SHA256 `6d293b51d7f20706902d0a55aca39330e9d70b503aa73d6100007d821928de9f`。
語彙計算や全表変換の検証は同一性に基づき再利用した。全体check・remote CI・公開は今回実行していない。

直前のMorphyNet archiveはworkspaceの`reviews/ldfreq-morphynet-20261006/evidence/`にある。
MorphyNet新規52期待値と既存ambiguity-reviewの73期待値が成功。完全英語v1の225,131行を
独立照合し、exact archiveのfresh installで全表・保存example・KWIC判断・help・smoke・guideを再現。
限定checkはStatus OK（全体test／全OS／as-cranではない）。263 source fileのbyte一致、
21 compiled guideの包含、20未変更guide・86既存runtime/data/specの再利用を確認。
archive 5,552,330 bytes、extdata 4,521,543 bytes、SHA256は
`2aaca4fc8ab68c7eebb62379f9dfe4e27f3241a01f85975cf8e4fd65d497f1e2`。
原文と選択関係の接続例は確認済みだが、言語学的な正解率や複語対応を保証しない。
ローカルサイトを更新し、遠隔公開は未実施。

直前のNation archiveはworkspaceの`reviews/ldfreq-bnccoca-20261006/evidence/`にある。
Nationの基本75,679行と補助29,798行、source catalog 34行を独立Python読込と全行照合した。
新規29期待値と既存語族テストが成功。guide・help・offline smoke・完全RDS再現を
正確なarchiveからのfresh installで確認した。限定checkはStatus OK（全体test／全OS／as-cranではない）。
255 source fileのbyte一致、21 compiled guideの包含、20未変更guideと84既存runtime/data/specの
証拠再利用を確認。archive 5,535,445 bytes、extdata 4,520,501 bytes、SHA256は
`888021b7bcac0f04bd72295e2f747c3c30dc5a9ca22b71a0bc95e27bd3d92997`。
出典・license・reference・guideのローカルサイトも更新。遠隔公開は未実施。

直前のMorphoLex実装の保存証拠はworkspaceの
`reviews/ldfreq-morpholex-bundle-20261006/evidence/`。同梱MorphoLexの全34シートについて
Excel XMLと953,978セルを照合し、文字列・論理値・欠損と数値の一致を確認した。
数値は文字列表現の桁差を許すrelative tolerance 1e-14、absolute tolerance 1e-15で比較。
元のWord欄の論理値TRUE/FALSEも保持し、help・noticeに明記した。
対象テスト133期待値（新規45、既存word-parts 88）が成功。全セルの保持は変換の検証であり、
元資源の形態分析精度・学習者知識の妥当化ではない。

その段階のアーカイブは5,012,796 bytes、extdata全体は4,010,789 bytes。248 source memberがcheckoutと一致し、
全21 compiled guideを収録。変更ガイドを実行し、20未変更ガイドは原本のbyte一致を確認して再利用。
全既存runtime R、NJ8/TUBELEX、specは前回archiveと同一であり、既存の有効な証拠を再利用した。
`R CMD check --no-tests --no-manual --no-vignettes --no-examples`はStatus OK。
対象テスト、help例、ガイド実行、installed offline smokeは別に成功した工程であり、一括全体検証ではない。
checkの外部repository索引取得はネットワーク制限で不成立だが、導入済み依存を用いた検査は完了。

このarchiveからのfresh installで全sheetの値を再照合し、旧Excel読込経路の選択行・全profileと
完全一致を確認。保存結果もreadxl/quanteda未読込で再現した。DESCRIPTIONの全fieldも整合。
変更したローカル紹介・license・reference・NEWS・guideのページを構築し、利用条件・private path不在を点検。
遠隔CI・サイト配備・CRAN投稿は未実施で、一般公開を確認したとはしない。
過去の「PRIVATE」「Pagesはmain参照」は確認時点の記録として扱い、公開工程で再確認する。

今回の再点検で、次の二点を現状判断に加えた。

- **配布物の生成成功と、資源一覧の完全性を分ける（発見した不整合は今回修正済み）。**
  `inst/spec/ldfreq-installed-resource-manifest.json` と
  `experiments/resource-admission/ldfreq-release-resource-inventory.json` は、再点検時点ではTUBELEXとNJ8のみを記載。
  MorphoLex、Nation BNC/COCA、MorphyNet抜粋の収録後も、`COPYRIGHTS`の記録は1,401 bytesで、
  現物は3,066 bytes。SHA-256も不一致である。二つのvalidatorには資源数2の固定検査があり、
  package-resource-inventoryは未登録extdataも拒否する。静的な一覧・実ファイル・コード照合で
  確認した不整合であり、今回remote CIを実行して失敗を観測したという意味ではない。
  上記限定check・変換忠実性・保存再現の証拠は維持し、配布一覧の検査まで成功済みとはしない。
  その後、二つの一覧と参照先の検査を5資源へ更新。公開記録の古い「1資源」「全体MIT」前提も修正した。
  上記の最新archiveでローカル配布照合を完了したが、全OSと公開工程の完了は別に確認する。
- **全文書評価を未着手に戻さない。** workspaceの`analysis/icnale-gra/results/`には
  140文書のmetadataと既存指標があり、`dictionary-review/paired-results.csv`は140行。
  同`summary.csv`では、55出現・43文書のlemma変更に対しMATTR50とHD-D42の変化は0、
  NJ8の平均token coverageは0.962918から0.964650へ変化した。
  `dictionary-sensitivity.R`はAIによる文脈確認・独立人手検証なしと記録している。
  既存研究の限定した感度分析として再利用し、語族・形態分析の正確さや一般的な無影響を意味させない。

### 着手順序と、各作業で変える判断

公開整合、研究評価、新機能は別の完了軸である。研究の全条件を公開の前提にせず、
公開チェックの成功を研究上の妥当性としない。新機能は一つの入出力経路を終えてから次へ進める。
下記の順序は新しい資源を列挙した順ではなく、公開整合と中心的貢献への不足で決めた。
M0の開発版公開は完了しており、後続研究の未完了を公開失敗としない。
公開操作が待ちになっても、ローカルの研究例や入力例は独立に進められる。

| 優先・既存項目 | 今回解く問い／成果物 | 必要な入力・依存 | 完了条件と結果による判断 |
|---|---|---|---|
| 1. 開発版の一般公開完了：M0 | 同梱内容・出典・検査が同じ候補を表すか | 5資源の一覧、既存notice・変換証拠、修正済みの検査と公開記録 | 600debeeのCI全9 job成功。3 OSの56 member一致、Public化・保護付きmain統合・128ページ配備・匿名取得の同一性まで確認。開発版公開を完了し、CRAN投稿は対象外 |
| 2. 語族比較・形態接続完了：M1・段階5 | 同じ全文書の語単位・候補判断を変えると、どの結果が変わるか | ICNALEの保存済み原文・lemma・語族集計。MorphoLex／MorphyNetの固定版 | Nationによる140文書・31,902 tokenの比較に、同じ出現IDのMorphoLex／MorphyNet候補を接続済み。個別KWIC判断の作成例、件数の直接照合、保存復元を確認。実作文の文脈判断・独立精度評価は未実施 |
| 3. 限定経路を実装済み：M1/M2・日本語 | 複数短単位にまたがる活用形を、元の位置と複数候補を保って判断できるか | 点検済みJ-UniMorph、既存gibasa/UniDic出力、作成文の期待位置、保存済み28作文 | ローカル読込→出現範囲対応→KWIC選択／保留→保存再読込を明示exampleで確認。実作文では全1,309文字範囲を別実装と照合し、境界一致587／不一致722を保持。文脈上の正確さは未評価。API化、語彙同定・語族・英日共通尺度への拡張は別判断 |
| 4. 上の実例から選択：M1/M2・形態構造 | 一段の形成関係だけでは答えられない問いは何か | 語基／結果の品詞、接辞ID、複数段階・対立分析、出現レビュー | 必要な問いに限り段階別集計とレビュー適用を例示。API化は下記構造条件とAPI命名規約を満たした場合。資源間不一致を多数決で正解にしない |
| 5. 既存結果を使いやすく：M2/M3/M6 | 作文比較・刺激選定を既存R解析へ誤結合なく渡せるか | 文書／参加者／項目ID、頻度・規準の定義と欠測、既存21ガイド | 二つの主要利用手順と既存ツールによる同条件の手順を比較。記述表・方法記載・保存復元を整える。新規wrapperや性能優越を前提にしない |
| 6. 入力条件が揃った拡張：M4 | n-gram関連度を適切な標本空間で計算できるか | 境界・共同／周辺度数・総機会数の揃う参照。必要な場合にMASC/OANCを拡張 | 手計算可能な例と独立集計を一致させ、ゼロ・打切り・未収録を区別。全コーパス同梱やMASC全件受入れは必須にしない |
| 7. 独立した研究課題：M3/M5 | 意味判別・employability・ネットワークは何を測るか | 独立人手参照／参加者反応、候補・辺・汎化先を定めた研究設計 | 単純基準・coverage・対象集団を含めて増分を評価。API例の存在だけで妥当化完了にせず、汎用パッケージ公開の一律条件にしない |

1の一覧修正・Mac配布照合と、2・3の明示example経路は完了した。次の作業単位は残る公開工程である。
研究課題は候補の文脈判断が必要な主張を先に定めてから選ぶ。公開API化や独立精度評価を0.2.0公開の一律条件にしない。
5の既存ガイド・出力表の改善は1・2に必要な範囲で同時に行い、独立した大規模なUI開発にしない。
日付や完成率を推測で約束せず、下記の成果物と受入条件で完了を判断する。
新しい話題が出ても主課題を置き換えず、本表との対応を確認する。

#### 直近の成果物1：同梱資源を漏れなく検査できる公開候補

一覧・validator・公開記録生成の修正とMac配布照合は完了。以下は維持する受入条件であり、
同じ一覧修正を再度行う指示ではない。候補状態は引き続き`development`である。

- 既存の二つのJSON一覧を更新し、TUBELEX、NJ8、MorphoLex、Nation BNC/COCA、MorphyNet抜粋の
  内容・版・notice・license・加工元・実ファイルを明示する。MorphyNet全表の同梱とは記載しない。
  共通COPYRIGHTSの重複登録を避け、必要なschemaの変更だけを行う。
- 二つのvalidatorの「2資源」固定部分を現候補と一致させる。未宣言ファイルの検出は維持し、
  単に件数やhashの検査を外して通さない。破損・未宣言・欠落を検出する確認と、
  正しいsource／配布物／導入後の一致を受入条件にする。
- 新規公開APIの追加をこの候補へ重ねず、現時点の57 exportsと例・help・NEWS・licenseを整える。
  内部文言とprivate pathの点検は実際のarchiveとサイトを対象にする。
  新しい日本語・形成構造の機能は別の変更単位として扱う。
- 現在の`experiments/release-candidate/state.dcf`は`development`。
  Release candidate workflowはこの状態では候補build以降を実行しない。
  分類jobの成功を配布物検証と数えず、候補確定後に採用revision・archiveのhash・必要jobを対応付ける。

これは帰属情報と配布工程の整合修正であり、NJ8の許可や既に採用したNC/SA方針を取り直す工程ではない。
変換済み全表の内容が同一なら既存の独立全行照合を再利用する。変更される一覧・検査・成果物の
未完了部分を確かめ、同じ数値計算・モデル推論を一式やり直さない。

#### 直近の成果物2：語の数え方から原文へ戻れる全文書分析

**2026-10-06：下記1–4の限定した実装・照合・保存復元は完了。実作文の文脈判断と独立精度評価は含まない。**
`analysis/icnale-gra/results/family-comparison/`に文書別件数、840行の単位比較、原文KWIC、
候補・補助リスト、完全RDS、入力／コードhash、別Rセッションでの再現記録を保存した。
31,902 token中30,892が本表に一致、1,010が未収録、複数語族候補は0。
135/140文書の全文書語族V/TTRは未確定のためNAのまま保持し、同じ照合済み出現集合での
平均種類数は表層108.99、lemma100.69、語族97.45。作成例と同じrecipeで分母を明示する。
全文字を保持する入力へ保存語列を対応付け、文脈用の隙間3,654箇所を集計へ加えずに
原文の位置を検証した。今回の入力で成立した一対一の文字位置対応を、任意のUnicode正規化へ
一般化しない。lemmaは保存済み初回textstem条件を固定し、後続の55出現レビューは混ぜていない。
形態接続結果は`analysis/icnale-gra/results/morphology-link/`に保存。MorphoLexに30,690出現、
MorphyNetに4,592出現が一致し、後者の401出現に複数候補がある。候補表の単位・範囲が異なるため
この件数差を精度比較としない。実作文は全候補未判断で、完全な接辞数はNAのまま保持する。
作成例では同じ出現IDで語族所属を保ち、MorphoLexとMorphyNetの判断を別々に適用する。
以下は維持する設計・受入条件であり、完了した語族計算を再実行する指示ではない。

**問い**は「語族にまとめたときに減る種類数と、未収録・曖昧な出現による集計対象の変化を
区別して説明できるか」。最初は既存ICNALE 140原作文（136 L2、4 ENS）と保存済みlemmaを使う。
4 ENSを母語話者一般の基準やL1/L2差の検証標本にはしない。原文／校閲版の比較結果も保存済みなので、
新しい条件を追加する理由がある場合だけ拡張し、全要因の総当たりや評定相関の再計算は行わない。

1. 文書ID・原文・分割・対象tokenを固定し、既存表層／lemma結果にNation Level 6による語族結果を追加する。
   flemmaやPOSによる区別は出典のある注釈が利用できる範囲だけにし、未注釈を推測で補わない。
   固有名詞等の補助リストは頻度帯とは別に示す。未収録語をすべて別familyに置く暗黙の補完はしない。
2. 同じtoken集合で比較できる範囲を明示し、N、語形／lemma／familyの種類数、対応するTTR、
   eligible・照合・曖昧・未収録・除外の件数を文書別に保存する。
   既存MATTR50／HD-D42は比較基準として再利用する。familyの移動窓指標は現APIの対応と
   未解決tokenの扱いを確認する前に計算済み・比較可能としない。
3. MorphoLexの形態区分とMorphyNetの一段形成関係を、同じ出現IDへ別々に付ける。
   重複候補を観測接辞数として合計せず、屈折／派生、接頭／接尾、語根、解析不能を区別する。
   語族表の所属を接辞分解の正解にせず、候補の選択／保留で分母・結果がどう変わるかを示す。
4. 成果物は、既存ローカル分析フォルダ内の条件表、文書別集計、出現別の照合・判断表、完全なRDS、
   既存ガイドへ組み込む再配布可能な作成例とする。制限付き本文・評定・文脈抜粋は同梱しない。
   手計算できる小例、同一ID集合、件数の整合、別セッションでの保存結果再現を確認する。

公開資料でのICNALEの説明は、資料名・版（ICNALE GRA V2.1）、検証対象・実施結果、
簡潔な出典に絞る（2026-10-06のユーザー方針）。本文・個別評定はローカルに保持し、
既存の入力manifest・設定・保存結果を検証根拠として再利用する。利用者向けの再現例には
再配布可能な作成文を使う。公式資料の網羅的照合やdraftと刊行版の全文比較を、
現在のR処理の検証・パッケージ公開の完了条件にしない。評定との関係や収集条件に
依存する研究上の主張を行う場合に、その主張に必要な箇所を確認する。

まず得る証拠は分析条件への感度と手順の再現性である。実資源の注釈精度を主張する段階では、
無作為出現と問題候補に偏らせた確認を分け、非候補も含む独立参照を用意する。
辞書一致率をprecisionと呼ばず、AIの確認を独立人手注釈として報告しない。
広いL1資料への適用は、その後に既存MASC受入れ範囲等の文書構成・欠落層を確認して追加する。
語族化の影響が小さければ、その範囲で十分な手順を残す。大きければ該当出現とcoverageから説明し、
指標の一律推奨や熟達度の総合scoreへ飛躍しない。

#### 限定経路を実装済み：日本語の活用候補と出現範囲

[J-UniMorph公式資料](https://github.com/cl-tohoku/J-UniMorph)は活用形と特徴の資源であり、
英語の教育的word family一覧の代替ではない。点検済み版の12,687行・107 lemmaを保存したまま読み、
「食べられる」の可能／受身／尊敬等を複数レコードとして保持する。ローカルreaderは明示exampleに実装し、資源本体は同梱しない。

最初の成果物は、短い作成文と既存UniDic注釈を使う明示実行のexampleである。以下の設計で実装した。原文文字範囲、
tokenの開始・終了、候補record IDを対応表で結び、複数短単位を一つの活用形候補として参照する。
元のtokenを上書き・再分割せず、正規化キーと元文字位置を分ける。重なる候補と未解決を残し、
最長一致だけで正解を確定しない。既存の単一token APIは維持し、別のexampleで原文の文字範囲に対するKWICを返す。

受入条件は、反復出現・複数候補・複数token・重なり・未照合・空文書・UTF-8の元位置と、
選択／保留の保存再読込が手作業の期待値と一致すること。形態的曖昧性、読みの同音性、語義候補を
別の関係として保持する。公開API化はこの経路が動いてから判断し、一般的な自動曖昧性解消は約束しない。

**2026-10-06 実装・検証**：`inst/examples/junimorph-spans.R`に`read_junimorph()`と
`review_morphology_spans()`、同`junimorph-spans-demo.R`に完全な作成例を追加した。
原文の文字範囲・元tokenの開始／終了・参照表の元行ID・feature文字列を保持する。
token両端に一致しないsubstringは`boundary_mismatch`として残し、境界の見直し前の候補選択を拒否する。
重なる範囲、候補なし、未確認、選択、保留を区別し、source／候補表／対象語形が変われば旧判断を拒否する。
KWICは元のcodepoint幅であり、既存quantedaのtoken窓とは区別する。正規化・仮名漢字変換は行わない。
作成例では対象5範囲中2範囲を選択し、その同じ集合で語形2種類／lemmaラベル1種類。
全対象のlemma種類数はNA、元26tokenは判断前後で不変。活用候補の範囲を単語数へ自動換算しない。

保存済み28作文へ全12,687行・10,848語形を照合すると1,309完全一致範囲があり、
token境界一致587（うち複数token409、複数候補98）、境界不一致722。重なる範囲は619あり、
これらを独立した語の出現数として加算しない。Rでの全一致範囲・境界・token列の復元を確認し、
Pythonの独立したsubstring検索と境界対応でも同じ全件になった。実作文の候補は未判断のまま。
実gibasaによる5作成文＋空文書でも、実資源の候補・宣言済み判断・保留・保存復元を確認した。
新規50 assertions、導入後同50 assertions、変更guideと抽出scriptが成功。公開APIは57のまま。
精度の参照となる人手判断、任意の語彙／語義の複数tokenレビュー、集計単位の自動変更は未実装／未評価。

#### 日本語作文の実資料候補と検証範囲（2026-10-06）

今回の依頼に基づき、無料で利用できる学習者作文を公式サイトで調べた。これは上記の日本語経路を
実資料へつなぐ入力候補の選定であり、英語の既存検証を置き換えたり、全コーパスの評価を公開条件に
加えたりする作業ではない。初回は配布案内・規約まで確認した。その後、作文対訳DBを取得して
下記の入力検証を実施した。他の候補の本文取得・申請・解析は未実施。

| 候補 | 公式資料で確認した入力・無料利用の範囲 | この計画での役割と留保 |
|---|---|---|
| [作文対訳データベース](https://mmsrv.ninjal.ac.jp/essay/essay_05.html) | 作文TXT、作文／書き手のXLSX、一部の添削XMLを直接配布。CC BY-NC-ND 4.0 | 最初のローカル読込・分割・添削比較の候補。原文と添削をIDで結び、文字コードと添削の有無を確認する。添削を全作文の唯一の正解とはしない |
| [W-CoLeJa](https://www2.ninjal.ac.jp/jll/writing/data.html) | 現行202603版。日本語作文、学習者自身のL1作文、能力テスト、背景・執筆環境情報。テーマ別／一括ZIP | 縦断の語彙変化と、入力・辞書利用条件の検討。形態素・誤用・印象評価データは今後の公開予定で、現版の利用可能な正解注釈には数えない |
| [B-JAS](https://www2.ninjal.ac.jp/jll/bjas/bjasindex.html) | 中国語母語の大学生を4年間追跡。2024.03版の作文TXTと背景情報。非対面作文は2026-03-11にUTF-8（BOMなし）へ統一 | 書き手・課題・時点を保つ縦断入力の候補。一つの母語集団での処理確認と、広いL2集団への一般化を区別する |
| [I-JAS](https://www2.ninjal.ac.jp/jll/lsaj/ihome2.html) | 12母語・1,000学習者と日本語母語話者を含む。登録制の無料検索、能力・背景情報、ストーリー作文等 | 母語・熟達度・課題を分ける後続比較。エッセイとメールは任意課題で、全員・全課題が揃うとは仮定しない。本文取得は正規の配布経路を確認してから行う |

[W-CoLeJaの規約](https://www2.ninjal.ac.jp/jll/writing/data/download.html)は研究・教育目的での無料利用、
非商用・再配布制限を定め、AIモデルとその出力の第三者提供にも制限を置く。通常のR集計と
モデル開発・公開を別に判断する。[B-JASの規約](https://www2.ninjal.ac.jp/jll/bjas/download/B-JAS_%E5%88%A9%E7%94%A8%E8%A6%8F%E7%B4%84_202607.pdf)は
利用目的等の申告、研究目的、出典表示・成果報告を定める。公開リンクがあることを申告不要と解釈しない。
[I-JASオンライン版の規約](https://chunagon.ninjal.ac.jp/static/I-JAS_TermsOfService.pdf)（2026-10-01施行）は
語の検索を超える全部・大部分のダウンロードを禁じる。無料検索と全文一括取得を混同せず、
検索結果の収集で全文版を再構成しない。これを別途正式に配布される資料への一律禁止とも解釈しない。
課題の任意性は[公式調査概要](https://www2.ninjal.ac.jp/jll/lsaj/ijas-survey-outline.html)で確認した。

誤用候補の「なたね」は[Web検索](https://hinoki-project.org/natane/)と
[GSKのXML一括配布](https://www.gsk.or.jp/catalog/gsk2021-c/)を分ける。後者は会員条件付き無料／
非会員有料であり、誰でも無料の一括コーパスとして上表に含めない。
L1作文の後続候補は[JASWRIC](https://language.sakura.ne.jp/jaswric/)（700人・1,400作文、V1.1）。
I-JASのストーリー作文と同じ図版課題、素書き起こしと校閲版を提供し、取得は利用申請を経る。
児童から大学生を含むため、全件を成人母語話者の基準にしない。付属の形態素解析は校閲版に基づくので、
原文の解析結果と混ぜない。W-CoLeJaの「L1作文」は学習者の母語作文であり、このL1日本語資料とは異なる。

実装の入口は既存の `gibasa`／UniDic → `lexdiv_import_annotations()` とし、専用解析器を新設しない。
最初の問いは「表記・活用・誤用による分割／同一語判定の違いが、語数・種類数・照合率をどう変えるか」。
作文対訳DBを最初の対象とし、文書・書き手・課題IDと原文を保持して次を確認する。

1. 語形・書字形基本形・語彙素を別の数え方として出す。読みだけで同音語を統合せず、元の品詞・
   語彙素情報を残す。文字数と形態素token数を分け、助詞・助動詞・記号等の採否を明記する。
2. 未知語と誤用候補を区別してKWICへ結び、原文と添削後を別条件にする。自動修正で原文を上書きせず、
   挿入・削除で文字位置が変わる場合も原文への対応を保つ。辞書にある誤用もあり、未知語率を誤用率と呼ばない。
3. 上記J-UniMorphの限定実装で、複数tokenにまたがる候補・未照合・保留を記録する。
   活用候補の処理確認を、派生語族の網羅的分析や日本語の自動語義判別の検証としない。

実資料はローカルに置き、公開例は作成文を使う。結果の説明は使用コーパス・版・対象・実施結果を簡潔に示す。
縦断モデルやL1/L2比較は、それぞれ必要な問いが生じた段階で書き手内反復、課題、年齢等を考慮する。
日本語の得点が計算できることを、英語と同一尺度の熟達度得点である根拠にはしない。

**作文対訳DBの実入力検証（2026-10-06）**：公式TXT ZIPと2種類のXLSXを取得し、
ローカルの`analysis/ninjal-essay/`へ出典・取得日・SHA256とともに保持した。
取得したZIP／作文表は全1,777件で一致した（概要ページの旧総数1,754件とは区別）。
UTF-8 1,764件、明示的に確認したCP932 13件、UTF-8 BOM 179件。書き手表との未照合1件を
欠測のまま保持し、ファイル名からL1や書き手IDを推測しない。全件の復号結果・raw bytesのハッシュは
RとPythonの独立した読込で一致した。公開物にはデータを入れず、`inst/examples/ninjal-essays.R`で
利用者のローカルファイルを読む例と、作成文のみのtest fixtureを追加した。

同じ課題から7つの報告L1（日本語を含む）につき4件、ID順で計28作文を選んだ診断用標本を、
既存gibasa 1.1.3／unidic-lite 1.0.8で解析した。MeCabがCRのみ出しLFを省く箇所で
importが停止する不具合を発見し、空白だけを越えて最初の完全一致位置へ対応づけるよう修正。
非空白の脱落は引き続き拒否する。原文の改行を書き換えず、全10,932注釈の位置と非空白文字の被覆を確認した。
補助記号・空白を除き助詞・助動詞を含む9,554 tokenのうち、lemma欠測は139。
共通9,415 tokenで表層・書字形基本形・語彙素ラベルを比較し、欠測を含む全体の語彙素種類数はNAにした。
仮名表層／漢字を含むlemmaの候補等はローカルの未判断表に保持し、誤用・漢字知識とは扱わない。
本文は配布TXT全体（題名・転記記号を含む）であり、整形済み作文本文ではない。
これは入力・原文対応・集計の検証で、分割／語彙同定の独立精度評価、L1群比較、添削XMLとの比較ではない。
今後の語彙候補判断では、この出現表から独立に確認した範囲だけを参照とし、未判断候補を正解に昇格させない。

**仮名・漢字表記の作成例（2026-10-06）**：ユーザーの指摘に対応し、
`inst/examples/japanese-orthography.R`と既存日本語注釈ガイドへ実行例を追加した。
既存import／KWICレビューを使い、原文・位置と選択した語彙IDを分ける。
「りんご／リンゴ／林檎」は同じ3出現で表記3種類／語彙1種類。
「はし」は渡る／食べる文脈で別ID、見る文脈では保留し、全3出現の語彙種類数はNA。
同じ選択済み2出現では表記1種類／語彙2種類。未知候補、未判断、保留、空文書を区別する。
これは手作業で用意した単一tokenの注釈・候補・判断による手順確認であり、
自動漢字変換、解析精度の検証、語族分析ではない。この表記例は単一tokenを対象とする。
活用候補の複数tokenレビューは上記J-UniMorph例で別に実装した。

[UniDicの階層](https://clrd.ninjal.ac.jp/unidic/glossary.html)を利用する際も、書字形基本形だけで
全表記が統合できるとはせず、語彙素化による活用の統合と表記のみの統合を分ける。
仮名使用から漢字を書けない理由を推定しない。漢字産出を評価する場合は、課題・手書き／入力・
補助手段、漢字表記が期待される対象語と許容表記、独立の産出資料が必要になる。
カタカナ語を一律に漢字化せず、表層頻度と語彙素頻度も別条件とする。

**境界から語彙判断への接続（2026-10-06）**：同じexampleを拡張し、
`lexdiv_align_annotations()`で原文の4–5文字目「はし」に「は／し」と「はし」を対応付けた。
原文を保った完全な別注釈を再importし、その上でKWICを再作成する。境界の選択と語彙候補の
選択理由を別々に保存し、旧review IDの持込みは拒否される。句点のみ除外した全文列で
N/Vは7/7と6/5。一致spanだけの共通集合へ切り詰めて分割変更の影響を隠さない。
実gibasa 1.1.3／unidic-lite 1.0.8でも8作成文を処理し、全原文位置を照合した。
上記の分割を出力した1文で、境界見直し→語彙判断→保存復元まで確認した。
別の文の「すん→済む」等の出力も保存したが、これらは診断用作成例であり、
無作為標本に対する誤り率・独立正解・学習者一般への精度評価ではない。
利用者が供給する完全な代替注釈の受入れ例であり、自動境界修正や複数token候補の直接reviewは追加していない。

#### 形成構造・規準・新規性の次の判断

Nationの包含範囲、MorphoLexの語構造、MorphyNetの形成関係は同じ対象の別名ではない。
[MorphyNet公式の派生表](https://github.com/kbatsuren/MorphyNet)も語基・結果・品詞・接辞の関係を示す。
まず`reusability`等の対立分析と`teachers`等の派生＋屈折を、段階ごとの関係と選択状態で扱う。
形成経路のあるグラフを、そのまま教育的familyや心理的な意味ネットワークに変換しない。
Level 3 partialとの比較は、利用可能な表の範囲と包含定義を確認した後の別条件とする。

心理言語学の利用例では、頻度・親密度・AoA・形態情報を同じ項目IDへ結び、未照合や一対多結合で
刺激が黙って落ちたり複製されたりしないことを先に確かめる。規準の集団・尺度が未確認の資源は
その列を保留する。TUBELEXとのtokenization対応も固定し、頻度の高さを形態知識・意味透明性・
employabilityに読み替えない。必要になった段階でLexOPSや既存統計パッケージへの任意接続を示す。

パッケージの貢献は、同じ課題をquanteda等の集計と通常の表結合で実施する手順との比較で示す。
比較条件は同じ原文・分割・語単位・参照表・出力要件に揃え、(a) 未照合と分母、(b) 候補と
原文位置、(c) 判断の適用範囲、(d) 保存後の再現を両方で確認する。
既存ツールで可能な計算を「初めて可能」と宣伝せず、何の記録・確認・再集計を一貫して提供するかを
READMEと二つの主要利用手順で示す。利用時間短縮や誤り削減の優越を主張するには独立利用者の実測が必要で、
この手順比較だけでは十分としない。

MASC全体やOANCへの対応は、すべてのn-gram利用・関連度実装の必須条件ではない。
必要な定義・度数・分母・利用条件を満たす別の参照表でも進められる。
資源の取得や人手評価が待ちになる場合は、その課題を未完了と明示し、依存しない工程を進める。

### 原文から報告まで保持するもの

同じテキストについて、次の情報を分けて保持する。これは入出力の共通原則であり、
全機能を一つの巨大な新オブジェクトへ作り替える計画ではない。

1. 原文・版・document/participant/item/task IDと、その資料を分析対象／参照のどちらに使うか。
2. 完全なtoken列・文／区間・元の文字位置、解析器と辞書の版、lemma/POS等の注釈。
3. 採否、除外理由、数えるためのキー、参照表に照合するキー。表層・lemma・flemma・familyは別単位。
4. 語義・語族・規準レコードの候補、判断者・理由・未解決状態。参照資源のID・版・尺度・出典。
5. 指標値とN/V、計算可能数、各種coverage、除外、設定。CSVの表示用表と完全なRDSを保存する。

綴り誤りの修正と英米表記の統合は別の処理である。原文／綴りのみ修正／文法や語境界を含む修正を
区別し、主分析の版は研究の問いから選ぶ。注釈訂正は原文変更と分ける。未照合を誤字や高度語と
決めつけず、proper noun除外とNER、数字パターンとNUM、記号除去と匿名化も同一視しない。
除外後に位置を詰めた語列から隣接n-gramを作らず、MATTRの窓が何のtoken列を指すかを報告する。
参照表の全観測項目を収録したときの標本ゼロ、頻度打切りによる未掲載、照合不能、
分母ゼロによる未定義を区別する。共有語だけの平均と対象全体のcoverageを併記する。

語族ではuseとreusabilityを同じUSE族に含めても2 token・1 familyであり、原文出現を圧縮しない。
族内語形の内訳を残し、未収録を無断で独立familyにしない。未解決がある全体の値と、照合部分の
条件付き値を区別する。Bauer–Nationの包含段階と頻度帯は別列である。接辞ではteachersの-er/-sを
両方保持し、reusabilityの綴り変化を単純な部分文字列切出しで代用しない。
短い作文の接辞種類数を形態的生産性と呼ばず、族への所属を本人の理解・産出能力としない。

### 接辞分析の実装条件：位置・文法機能・構造を分ける

2026-10-06の接頭辞／接尾辞・屈折／派生に関する質問を受け、既存M1/M2の接辞項目を
具体化した。本節は汎用API化へ向けた設計条件である。以下の限定exampleが実装されたが、
全条件の実装・実資源の精度検証完了を意味しない。
現在の語族APIは `record_id`／`form`／`family_id` と任意POSを照合する。
追加列の保存と、接辞の分類・妥当性検査・専用集計は異なる。`family_definition` の申告だけで
語形成上の関係を検証したとはせず、直前の275期待値もソフトウェア検証として位置付ける。

初期経路は提供済みの形態分析を読む・検証する・原文出現へ結ぶところに絞る。
独自の汎用形態解析器や、接辞文字列の前後一致による自動語族生成は作らない。

| 保持する区別 | 入力・設計上の扱い | 作成例による受入れ条件 |
|---|---|---|
| 接辞の位置と過程 | `affix_position`（prefix/suffix）と `process`（inflection/derivation）は別列。接辞なし・分類不明は別状態 | `replay` の re-は接頭・派生、`teacher` の-erは接尾・派生、`teachers` の-sは接尾・屈折として区別 |
| 接辞の同形性 | 表記と接辞ID・機能を分離し、語基／結果の品詞・必要な文法特徴を保持 | `teacher` と比較級 `smaller` の-erを同一接辞IDへ無断統合しない。派生は必ず品詞が変わるという判定をしない |
| 複数接辞と構造 | 一つの分析IDに複数の段階を結び、語基と形成結果、順序または親子関係を保持。対立する分析は別ID | `teachers` は1 token、派生接辞1回、屈折接辞1回、接辞総出現2回。語全体を「屈折／派生」のどちらか一方に入れない |
| 抽象形と実現形 | 接辞ID・語基の見出し形と、原文での綴り・位置を分ける。綴り変化を明示 | `reusability` の-able/-ityを単純に原文から切り出せると仮定しない。字面の分割と形成関係の照合を分ける |
| 非接辞的関係と不足 | 不規則屈折、ゼロ形、品詞転換、複合語は、接辞なし・未掲載・未解析と区別する。対応できない分析は明示的に保留 | `went` を-ed付きと捏造しない。`bottle` の名詞／動詞を、接辞が見えないという理由だけで同じ分析にしない。初期版で全面自動解析を必須化しない |
| 言語学的判断と資源 | 同期的／通時的な分析、理論上の分類、候補、出典・版を宣言し、語族所属とは別の根拠を保持 | 語源の共通性だけから現代の派生関係を認定しない。語族レビューの成功を接辞分析の正解としない |
| 集計単位と欠測 | corpus token数、接辞を含むtoken数、接辞の延べ出現、接辞種類数、解析coverageの分母を明示 | 多重接辞では「接辞出現/token」が1を超え得る。未解析を接辞0個と扱わず、部分分析を完全な種類数・割合として報告しない |

SLAでは語族へまとめた語彙量と、使用された屈折／派生・接頭／接尾の分布を並べて示す。
心理言語学では語全体・語基・接辞の頻度やfamily sizeを異なる変数として接続する。
後者のfamily sizeと教育的word familyの構成員数、文書内で観察された種類数も区別する。
接辞を含む語の出現は、学習者が規則を生産的に運用できることの証明ではない。
最初の出力は頻度・種類数・coverageまでとし、能力得点や形態的生産性の推定を追加しない。

根拠として今回再確認した一次資料と役割：

- [Bauer & Nation (1993)](https://openaccess.wgtn.ac.nz/articles/journal_contribution/Word_families/12560408)：
  屈折と派生を含む教育的な語族の包含条件。頻度・規則性・生産性・予測可能性による段階は
  参照するが、それ自体を汎用形態解析器や学習者個人の知識判定にしない。
- [Plagの英語語形成概説（著者公開preprint）](https://www.anglistik.hhu.de/fileadmin/redaktion/Fakultaeten/Philosophische_Fakultaet/Anglistik_und_Amerikanistik/Ang3_Linguistics/Dateien/Detailseiten/Plag/Plag2011_English.pdf)：
  §2、§4–5の語形成・屈折の境界、品詞を維持する接頭辞、語幹交替、品詞転換、分析上の争点を確認。
  -ly等の分類が争われる場合は採用した注釈基準を明示する。
- [MorphyNetの公式仕様](https://github.com/kbatsuren/MorphyNet)と
  [Batsuren et al. (2021)](https://aclanthology.org/2021.sigmorphon-1.5/)：
  屈折のlemma–form–features、派生のsource/target・両品詞・morpheme・prefix/suffixという区別を
  入力設計に利用する。MorphyNetの連結成分をそのまま教育的語族と認定しない。
- [Sánchez-Gutiérrez et al. (2018), MorphoLex](https://link.springer.com/article/10.3758/s13428-017-0981-8)：
  今回は公開抄録で、語基・接辞の別々の変数と語彙判断課題への接続を確認した。
  全文・実データをこの段階で検証済みとはしない。CobbのLextutor Morpholexとは別資源である。

前回の設計具体化では実資源取得・同梱・API追加を行わなかった。今回の語根に関する質問では、
下記の仕様書と実ファイルをローカルで点検し、続く実装で原文に結ぶ限定exampleを追加した。
同梱・公開API追加・研究上の妥当化は未実施である。

#### 語根・word parts：資源ごとの分解を保持する

語根の利用は既存M1/M2の形態分析入力を具体化する。独立した語源解析器の開発や、
語源を共有する全語の自動family統合を追加課題にしない。`transmit` の `trans-` は接頭辞であり、
語根として検討するのは `mit`／`miss` の関係である。ただし、現代の形態的関係、歴史的由来、
学習のための意味の手がかりを同一視しない。
[Aronoffの著者公開章](https://linguistics.stonybrook.edu/faculty/mark.aronoff/files/Morphology%20and%20Words%20a%20Memoir.pdf)
のpp.7–8では、`mit`／`miss` の規則的な交替と、それを含む英語動詞の意味的不透明性が論じられる。
語源の「send」を各語・各語義の共通の現代的意味として自動付与しない。

2026-10-06に公式配布物をローカル取得し、以下を確認した。これは選定した項目の点検であり、
全収録語の正確さ・対象コーパスのcoverageを検証した結果ではない。

| 資源 | 今回確認できた情報 | 採用時の制約 |
|---|---|---|
| [MorphoLex-en](https://github.com/hugomailhot/MorphoLex-en) | 3ページのdata dictionary、語根・接頭辞・接尾辞の別列、標準形による分解、語根のfamily size／累積HAL頻度。実データでは `transmit` は `{(transmit)}`、`transport` は `{<trans<(port)}`、`transmission` は `{(transmit)}>ion>` | 語根の意味を網羅する語源辞典ではない。`teacher` と `teachers` はともに `{(teach)}>er>` で、複数形-sを含む総形態素数へ転用できない。CC BY-NC-SA 4.0のため初期経路は利用条件を明示して同梱する（当初のローカル読込限定方針は下記のとおり変更） |
| [MorphyNet英語派生表](https://github.com/kbatsuren/MorphyNet/blob/main/eng/eng.derivational.v1.tsv) | 225,131行。`transmit` → `retransmit`（re/prefix）、`transmit` → `transmitter`（er/suffix）等を確認 | この版に `mit` → `transmit` はなく、不掲載を「語根・接辞がない」の証拠にしない。`mission` → `transmission`（trans/prefix）もあり、MorphoLexの分析と自動合成しない。公式表示はCC BY-SA 3.0 |
| [EtymDB 2.1](https://github.com/clefourrier/EtymDB) | 公式仕様と[開発元Inriaの利用条件](https://almanach.inria.fr/software_and_resources/EtymDB-en.html)を確認。Wiktionary由来の語彙項目・言語・語義説明と語源関係、データはCC BY-SA 4.0 | 語源関係の補助候補。今回実ファイルやtransmitの収録関係は未点検。現代英語の完全な語根分割表として扱わない |
| [CELEX2](https://catalog.ldc.upenn.edu/LDC96L14) | 公式catalogで派生・複合構造、屈折等を確認 | 個別のCELEX Agreementに従う資源。無料・無制限な同梱候補とは位置付けない。今回データ未取得 |

MorphoLexの原ファイル `MorphoLEX_en.xlsx` のSHA256は
`5bc425fbb710f3d63cab69e77ee731fa466653ed0ace94937cac6c1fd6de52c6`、
仕様書は `af01e0db5e953ad3b7bbc06ea06b3c8a1af6dac60e7600d826a5e079e4068575`。
MorphyNetの `eng.derivational.v1.tsv` は
`5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50`。
原ファイルはworkspaceの `tmp/morphology-resources-20261006/` に置き、package外で読取専用の点検に使用した。

入力設計では、語根・接辞の**役割**と、自由／拘束の**性質**を別に持たせる。
語基は形成段階ごとの入力として保持し、最小の語根と混同しない。語根ID、標準形、表面上の異形、
言語・語源言語、資源・分析IDを区別する。`mit`／`miss` の統合は根拠付き対応表で明示し、
綴りの類似だけで行わない。語義説明や意味的透明性の評定は別の出典・評定集団を持つ任意情報とし、
分解表から自動的に生成しない。複合語の複数語根、未解析、対立分析も保持する。

初期成果物は、提供表から語根・接辞情報を原文の各出現へ結び、KWIC・種類数・頻度・coverageを
返す一経路とする。語全体のTUBELEX頻度、参照表における語根の累積頻度／family size、対象文書内の
語根出現数を別々に報告する。参照表の変数定義・屈折の包含・頻度の出所を変えた値は別名で記録する。
語根を含む語の使用から、語根知識・未知語推測力・心理的分解処理を認定しない。
まず `transmit`／`transport`／`transmission`、`teacher`／`teachers` の分析差を保存・再集計する
受入例を用い、汎用API化の前に不足を確かめる。既存0.2.0公開の追加必須条件にはしない。

#### 実装した初期経路と残る境界（2026-10-06）

- `inst/examples/word-parts.R`：`word_parts_profile()`を明示的にsourceして使う。
  完全import済み原文、analysis表とpart表、資源・scope・basisを入力する。
  exact surface／任意UD POSで照合し、接頭／語根／接尾・屈折／派生・自由／拘束／不明を分ける。
  原文KWIC、候補、part出現、文書別頻度・coverage、完全結果と観測部分を保持する。
  複数候補を合算せず、部分解析・未解析・未収録・未知POS・除外・空文書を区別する。
- `word-parts-demo.R`：作成例5 tokenに7 affix出現、affix/token=7/5。
  transmitを全体語根とする別の作成例では6出現。mit/missの対応は明示表による。
  両条件を完全RDSで保存再現。これらはMorphoLex等の実inventoryの複製・精度評価ではない。
- `morpholex-word-parts.R`：既存Suggestsのreadxlで利用者取得のworkbookから指定sheet／語を読む。
  元の選択行・全列、原分解、PRS／Nmorph照合、未対応・未収録、workbook hashを保持する。
  `complete`は元資源の派生分析scope内であり、屈折を補わない。rootの自由／拘束は不明を保つ。
  実5語transmit/transport/transmission/teacher/teachersで5 root・4 affix出現、3 root type・3 affix typeを確認した。
- 初回境界テストで空referenceから余計な集計行が生じることを検出し、空の複合キー生成を修正。
  最終88期待値が成功。UTF-8位置、複数語根・反復、同形接辞、部分解析、候補・展開上限、
  不正表、未知POS、RDS／文字ID CSV、readerの未対応構文・不一致計数を含む。
- 今回は一覧の部品を数える経路に限定する。part_indexは表示順であり付加順ではない。
  形成の段階・親子構造の検証、非接辞的関係の専用分析、出現別レビューの適用、
  広範な資源精度評価は未完了。自動分解・語根意味の付与・学習者知識推定を行わない。
  この境界を既存guide／README／NEWSにも明記し、public exportsは54のまま維持した。

#### MorphoLex同梱方針の変更と実装（2026-10-06）

ユーザーの指摘に基づき、非商用条件を本体同梱回避の主因とした判断を撤回した。
商用利用可能性は本計画の必須要件ではない。CRANは非商用ライセンスを一律禁止しておらず、
CC BY-NC-SA 4.0はRのlicense.dbに登録されている。ただし、個々の配布構成の受理は未確認。
`DESCRIPTION`は`file LICENSE`を参照し、非FOSS・利用制限ありを明示する。独立コードはMIT、
MorphoLexデータ・仕様書はCC BY-NC-SA 4.0とし、適用対象、出典、改変、条件を区別する。
これはパッケージの研究目的の変更ではなく、M1/M2の参照資源を使いやすく配布する作業である。

- 全34シートの使用セル領域を文字列data frameとしてRDSに収録。68,624語、接頭辞142行、
  接尾辞240行、語根15,471行、Presentationを保持。PDF仕様書と元ライセンスも同梱する。
- `morpholex_data(sheets = NULL)`は全シートまたは指定順の部分集合を返す。source SHA、
  変換、license、全sheetの寸法・Excel開始位置を保持。新規class・依存・自動解析は追加しない。
- 既存parts recipeは同梱データを既定で利用し、readxl不要。path指定の外部workbook読込も維持。
  原文照合・未対応・scopeは変更しない。Word欄の元の論理セルTRUE/FALSEは補正せず文書化。
- 全sheetのXMLと変換値を独立照合する。これは変換忠実性の確認であり、資源の言語学的
  正確さ・屈折網羅性・英語変種間の適合性・学習者知識の妥当化ではない。
- 前節の54 exports／非同梱という記述は初期example実装時点の記録。現在は本節を優先する。
  配布物の最終検証は`PUBLICATION-20261004.md`のMorphoLex同梱記録に集約する。

#### Nation・MorphyNet・日本語：今回の採用判断（2026-10-06）

既存M1/M2の「どの定義で同じ語と数え、どの情報を失うか」を具体化する。
三資源を一つのword familyへ無断変換せず、一経路を完了してから拡張する。
汎用パッケージ公開や全文書評価の目的を、新しい形態解析器の開発へ置き換えない。

| 資源と実ファイル | 今回確認した内容・利用条件 | 採用と次の判断 |
|---|---|---|
| Nation BNC/COCA Level 6, Version 1.0.0 | 公式archiveの25帯すべて各1,000 family、計75,679語形行。固有名詞・marginal words・透明な複合語・略語は別の29,798行。基本表の語形重複0。公式包括ページはCC BY-SA 4.0又は資源に応じGPLと明示 | データにCC BY-SA 4.0を適用し本体同梱。`bnccoca_data()`のdictionary/resourceを既存APIへ入力。slots 26–30の仮置き行、Range実行ファイルは含めない。原語形・行番号・hash・出典を保存 |
| MorphyNet英語派生v1 | 225,131行、6列、接頭105,639／接尾119,492行、CC BY-SA 3.0。15言語に日本語はない。`transmit → retransmit`、`transmit → transmitter`を実表確認 | 次はsource/target・原POS・接辞・関係IDを保つ形成段階表と原文候補の接続。単一辺を完全分解とせず、連結成分を教育的familyにしない。今回の当初判断は未同梱・未API化。その後の読込・KWIC接続は下節を参照 |
| J-UniMorphのfiltered `jpn` | 12,687行・107 lemma・10,848表層形、CC BY 4.0。同形に複数行がある表層は1,439。`食べられる`は可能／受身／尊敬、`開ける`はlemmaも複数候補 | 日本語の最初の実装候補。英語語族の移植でなく活用・文法特徴の参照。元feature bundleを保存し、明示的な語形／原文span単位でKWIC候補へ結ぶ。短単位tokenとの対応を確認するまでは一対一照合を既定にしない。今回未同梱・未API化 |

Nationの公式[説明書](https://www.wgtn.ac.nz/__data/assets/pdf_file/0004/1689349/Information-on-the-BNC_COCA-word-family-lists-20180705.pdf)
を全4ページの抽出本文で確認。Bauer–NationのLevel 6と頻度帯1–25を区別し、各行の接辞段階を
捏造しない。Level 3 partialは屈折＋4種の制限付き派生接辞を使う別表であり、頻度帯のfilterで
再構成しない。別表の取得・同一出現での比較はこの経路の次の定義感度課題に位置付ける。
`use`／`uses`と`colour`／`color`は実表で同族だが、`reusability`は今回版に未収録。
作成例のUSE族への所属をNationの事実に変更せず、未照合と完全値NAを実データ例で保持した。

日本語では、UniDicの語彙素・読み・品詞による活用／表記の整理、J-UniMorphの文法特徴、
派生・複合語の形成関係を区別する。同じ漢字や読みだけでは語族にしない。UniDicの語彙素IDは
派生語族IDではなく、辞書版ごとの利用条件を確認する。今回の[論文](https://aclanthology.org/2024.sigmorphon-1.2/)
確認は抄録・対象と構築方法の該当箇所であり、全文精読や正解精度評価ではない。
J-UniMorphは初級動詞を対象とし、生成と検索hitによる選別を含む。網羅的な日本語語彙表、
語源辞典、コーパス頻度規準、学習者知識の測定値へ拡張解釈しない。

日本語の派生・複合についてはUniDicの構造情報やSudachiDictが次の入力候補だが、
`読み手`・`読み直す`等を英語Level 6と等価なfamilyにする規則は未確立。
Asaoの語構成データベースは公開論文を確認した段階で、利用可能な配布表を取得済みとはしない。
同梱可否だけで採否を決めず、単位・候補・coverageと利用者の研究上の問いの一致で決める。

取得したNation ZIPのSHA256は`ac81c7a60e5c76cd2bbf0c59b0501808f0d4fa026b2936919dd54329a9bb6a69`。
J-UniMorph `jpn`は`6ba4589cd43846c8afab5bdf5f4c498e03e32849f95c3e5c9840be2975d4b888`。
Nation利用条件は[公式資源ページ](https://www.wgtn.ac.nz/lals/resources/paul-nations-resources)、
MorphyNetとJ-UniMorphは各公式GitHubのREADME／licenseで確認。
後続資源の追加条件は、各列を保持する読込、全行変換照合、原文単位との整合、複数候補／未収録、
保存再読込、license・出典の配布物内保持。ダウンロードできたことだけで実装完了としない。

#### MorphyNet形成関係の読込とKWIC接続（2026-10-06）

M1/M2の既存目的に沿い、「元の形成関係を保持し、どの関係を原文のどの出現に採用したか」
を確認する一経路を実装した。一般的な語根・接辞自動解析や教育的語族生成には拡張しない。

- `morphynet_read_derivations(path, language, resource_version, max_rows)`はローカルTSVを読む。
  全6列、順序、重複、literal NA、複語の空白、POSのN/V/J/R/U等を保持し、行番号・relation ID・
  full SHA256を追加。言語・版は利用者の申告であり自動推定や真正性認定ではない。
  空ファイル、不正UTF-8/NUL、列数・接辞位置の不正、行上限超過は拒否。屈折表は別形式。
- `inst/examples/morphynet-relations.R`は既存`lexdiv_ambiguity_review()`を再利用する。
  exact target_word→surfaceで全関係を候補化し、原文の各出現に選択／保留を保存する。
  quantedaはKWIC再生成時の任意依存で、表読込・保存表参照には不要。新しいreviewer APIを増やさない。
- `reusability`にはreuse+ability、reusable+ity、usability+reの3辺がある。
  複数辺は同時に成立し得るため、「3候補＝接辞3個」や「1選択＝他の辺は誤り」としない。
  exampleは同じ表層の2出現の一方を宣言付きで選択し、一方を保留する。言語学的正解標本ではない。
- 元のteach→teacherはN/Nであり、予想からV/Nへ修正しない。未知・疑問のあるPOSや
  形成分析は元表を保持して別判断とする。teachersに候補がないことも接辞0の意味ではない。
- 全英語v1の225,131行をRと独立Pythonで全列照合した。接頭105,639／接尾119,492の関係行数であり、
  コーパス中の接辞使用回数ではない。既存語族、parts、レビューの計算式は変更しない。

配布構成は実測で判断した。完全R表をRDS化すると2,349,940 bytes、元TSVのxzは1,628,932 bytes。
既存extdata 4,520,501 bytesに加えると、[CRAN方針](https://cran.r-project.org/web/packages/policies.html)
の原則的なデータ5 MB目安を超える。これはNC/SAによる同梱禁止でも、CRANへの照会・拒否でもない。
今回の本体は9行の実例・原行対応・CC BY-SA 3.0本文とnoticeを収録し、完全表は明示的なローカル入力。
9行から一般的coverageを推定しない。全体同梱／別データ配布は、その利便性と保守負担を公開構成で
判断する後続課題であり、新しい配布基盤や自動downloadを必須化しない。

残る境界：語基・形成結果のPOS符号の検証済み対応、完全な多段形成構造、lemmaや複語への位置対応、
対象集団でのcoverageと誤分析の評価。現在のreviewは空白なしsingle-token surfaceに限定される。
J-UniMorphの日本語活用形は短単位の複数tokenにまたがり得るため、その原文spanとの整合を
次の日本語経路の前提とする。今回の英語読込を日本語対応済みと報告しない。

### 検証設計：問いと証拠を対応させる

次の全文書評価は、既存ICNALEの原文・metadata・保存出力を再利用し、対象・文書単位と
追加する語族・形態条件を固定して進める。原文／校閲版だけでPOS・語族・接辞の正解参照が
得られるとはしない。N/V、TTRを用いた算術説明と、対応条件で計算済みのMATTR・HD-D・NJ8照合を
出発点にし、新しい単位での指標計算は適用可能性を確かめる。無関係な指標を網羅しない。

| 問い | 調べ方と理由 | 報告・採否判断 |
|---|---|---|
| 注釈は目的の特徴を正しく拾うか | 明示した手引き・独立参照に対し、出現位置を含む一致と欠落を確認。非候補も対象にしrecallを調べる | 特徴別件数・TP/FP/FNと全対象の処理率。集計件数の一致だけでは正確さとしない |
| 文書の結果が変わるか | 同じ全文書の条件を対応付け、分母・coverage、値・順位・計算不能を比較する | どの原文箇所が変化を生んだか説明。差の表は残すが差分図は使わない。推奨を変える許容差は研究上の意味から定める |
| 長さ・課題・資料が変わっても成立するか | 原文長、切出し位置、指標パラメータを分ける。L1/L2・書き言葉/話し言葉・日本語は参照がある条件から段階的に評価 | 全組合せを埋めるための合成文書を全文書評価と呼ばない。資料間差をL1や熟達度の因果効果としない |
| 研究者の作業に役立つか | 同一課題を既存Rツールの組合せとldfreqで実施し、同じ分析定義・出力要件で比較する | まず出力の欠落・誤結合・再読込を点検。操作時間・完了率を主張する段階で独立利用者の実測を行う |

参照作成、モデル選択、最終評価を区別し、判断の独立性はmetadataのラベルだけで保証しない。
標本数は推定したい量・稀な特徴の件数・必要な精度から決め、文献の数だけをコピーしない。
不確実性は文書・参加者・項目の反復構造に合わせ、tokenを独立としたCIを既定にしない。
同等性を問うなら許容差と精度が必要であり、非有意・高相関・高い条件付き一致で代替しない。

Kyle & Eguchi (2024)の[精読記録](KYLE-EGUCHI-2024-READING.md)と保存済み出力照合を再利用する。
同論文から採用するのは特徴別評価と下流指標の接続であり、英語依存解析の結果を日本語や
語義判別の精度へ移さない。ESLSpokの保存済み232文は回帰確認に再利用できるが、設定修正に
使用済みであるため新しい独立最終評価としない。未検証用途は未検証のまま限定して報告する。

### 資源の選択と配布

コード、原資料、加工した参照表、モデルは個別の条件を持つ。無償閲覧、利用可能、再配布可能を
分ける。全コーパスの同梱や別データパッケージ化は機能実装の前提ではない。
以下は既存の出典・ライセンス確認記録に基づく方針であり、新しい版の再配布時にはその版を確認する。

| 資源 | 方針・既存証拠 | 残る具体的判断 |
|---|---|---|
| New JACET 8000 | JACETの許可と出典明記方針を採用済み。同梱表を維持、コードのMITと区別 | 許可を取り直すことを作業条件にせず、帰属と同梱列を配布物で保持 |
| TUBELEX | 英語集計表の固定版をBSD-3-Clause表示付きで同梱。日本語は既存ローカル読込例 | 英語tokenizerとの整合経路を選ぶ。単語表からn-gram/依存MIを復元しない。出現頻度と動画・channelの範囲を分ける |
| 語族・接辞 | Nation BNC/COCA Level 6（CC BY-SA 4.0）とMorphoLex-en（CC BY-NC-SA 4.0）は同梱。MorphyNet英語派生表（CC BY-SA 3.0）はローカル読込API・KWIC接続例あり。本体には出典付き9行のみ | NationのLevel 3 partialとの定義比較、MorphyNetのPOS・対立分析・段階構造を点検。語族表と形成関係、教育的語族と形態的family sizeを区別 |
| MASC/OANC | 入力・参照構築の候補。本文を本体同梱せず、明示取得と処理例を基本にする | 拒否層・文／発話境界を少数例で照合してから拡張。再注釈や別層への変更を同一条件のfallbackにしない |
| ICNALE GRA | 許されたローカル分析に使用。本文・個別評定を公開fixtureへ移さない | ENS等の群・課題・評定の意味をmetadataで確認。校閲後の値を本人の能力向上と呼ばない |
| 公開論文等 | 利用条件を確認した学術英語の処理例を再利用 | 無料アクセスだけで再配布を決めず、著者L1不明なら母語話者コーパスとしない。少数論文を一般的頻度規準にしない |
| 日本語規準 | WLSP親密度・多義性、AoA、BOI、TUBELEXを項目IDで結ぶ例を再利用。NTTデータは同梱しない | AWD-Jの尺度説明、BOIの件数・訂正、JALEX実表・除外の未確認を個別に解く。未解決を推測で換算しない |

日本語の同表記・同音・同語義は別の関係である。表記、読み、品詞、語彙素、資源内record IDを
保ち、読みを追加しても一意にならない場合を扱う。WLSPの候補数、主観的多義性、語義別頻度を
交換可能としない。AoAのカテゴリ平均を年齢へ無断変換せず、母語成人規準をL2個人の既知率にしない。
NC/SAのある規準をMIT表示で再許諾せず、資源の説明・条件も保存結果に引き継ぐ。

### 既存ツールの再利用と条件付き拡張

| 接続先・拡張 | ldfreqが担う部分 | 着手条件・負担 |
|---|---|---|
| quanteda/textstats、tidytext、koRpus等 | 既存token・分割・位置・設定を保って集計と診断を接続 | 同名指標の定義・既定値・欠測を照合。再実装や既定値の差による優越比較を避ける |
| gibasa/UniDic、UDPipe、外部Python | 保存された完全注釈の照合、抽出、再集計 | 辞書・モデル版、文字座標、対応構造を明記。モデル推論を毎回やり直さない |
| LexOPS・既存統計パッケージ | 頻度・規準・条件・item IDを持つ表、採否と元集合への対応 | 一意性・条件別欠測・刺激選定後の分布を検証。独自最適化器や汎用混合モデルwrapperを増やさない |
| igraph | 明示した関係のedge/node表と出典、閾値・除外・孤立点の記録 | 共起・依存・連想・意味類似を区別。強度と距離の重み変換を決めてから中心性へ。図の類似で心理的語彙構造を認定しない |
| BERT等／Rのtext | 出現ID・文脈・候補・人手判断・外部スコアを結ぶ既存経路 | 独立参照と単純基準モデルで増分を評価。推論エンジンの自作・必須依存化をしない |
| AntConc/KH Coder | 文書IDによる並行分析と実際のexportの任意読込を検討 | 直接connectorは未検証。GUI・内部DB依存のwrapperを先行しない。KH Coderの現行Mac配布は有料で、購入を利用条件にしない |

### 利用者の入口と報告

新しい別名関数やガイドを増やす前に、既存21ガイドを次の研究作業へ案内する。
どの入口も「入力→条件選択→計算→診断→解釈→保存」を追えるようにする。

| 利用者の作業 | 使う足場 | 次に補うもの |
|---|---|---|
| 自分の文章を比較する | getting-started、from-text-to-report、auditing-vocabulary-profiles、英語前処理例、preprocessing-and-frequencyの語族・レビュー例 | 原文／修正版・表記選択・語単位の違いを一つの研究の問いに沿って提示。語族の実資源を使う場合は入力表の意味とcoverageを点検 |
| 心理実験の刺激を準備する | corpus-reference-profiles、japanese-norms、japanese-stimuli | 操作変数と統制変数、規準の集団、採否理由、LexOPSへの任意接続 |
| 連語や構文を調べる | ngram-profiles、annotated-corpora、dependency-pairs、phrase-list例 | 連続句・依存関係・共起窓の区別、適切な参照と境界の選択 |
| 意味・同音・多義を確認する | ambiguity-review、japanese-polysemy、contextual-models、contextual-study | 候補範囲と独立判断、未解決の偏り、研究用途に合う評価設計 |

記述統計は文書／参加者／項目の集計単位を明示し、n、欠測、平均・SD、中央値・四分位、
coverageを既存R機能で出す。指標によって利用可能な集合が違う場合は共通集合も併記する。
混合モデル等への接続は具体的な反復構造の例で示し、関数を呼べたことを適切な推論としない。

可視化はAPA、カラー既定、`monochrome = TRUE`、図内タイトル・副タイトルなしを維持する。
差分を軸に取る図は作らず、元の値・分布を同じ尺度で重ねる。密度は共通帯域幅と境界を点検し、
少数例・離散件数では点や度数を使う。図の追加はこの計画の主たる進捗尺度にしない。

### 公開工程と検証資源

既存0.2.0の候補には既に実装された機能・例・説明修正をまとめ、実資源による語族検証・接辞以降を
公開必須条件にしない。今回の語族APIは0.2.0開発候補に収録したが、公開版の範囲・番号は公開時に確定する。

| 工程 | 必要な確認 | 証拠の再利用と完了判断 |
|---|---|---|
| 候補の整合 | source、NAMESPACE/help、NEWS、README、例、ガイド索引、帰属、内部文言・ローカルパスの除外。二つの資源一覧とvalidatorを追加3資源に対応 | 既存noticeと変換証拠を再利用し、宣言された全ファイルと実内容を照合。`.Rbuildignore`のdevelopment除外を維持し、archiveの実内容でも確認 |
| 利用操作 | 新規install→実行→完全なRDS保存→別セッションで再読込。欠測・空文書・ID・UTF-8を含む | 既存ログとsource/資源/環境/設定の同一性で再利用範囲を定める。変更した経路と未完了工程だけを再実行 |
| 対応環境・CI | R-CMD-checkのUbuntu release/devel/4.1、macOS/Windows releaseを確認。Release candidate側は候補状態とexact archiveを確認 | 両workflowはPR／main push／手動で起動する。採用revision・run・完了job・archiveを一度対応付け、重複手動起動を避ける。skipを成功と数えず、表示を緑にする目的で取消・再実行しない |
| 公開経路 | リポジトリ、配布物、help・記事、issue窓口へ匿名で到達し、同じ版の導入手順が動くか | push成功と公開確認は別。公開設定・merge・サイト配備・CRAN提出は、それぞれ実際の対象と操作範囲を確認して扱う |
| CRAN提出 | 提出するtarballの`--as-cran`、対応環境、依存関係、license表示、容量、例・検査の実行負担 | 限定checkや開発版CIで代替しない。提出対象と同一の有効な証拠を使い、残るNOTEは内容と理由を説明。提出・受領・受理・配布確認を区別 |

2026-10-06に[CRAN公式方針](https://cran.r-project.org/web/packages/policies.html)を再確認した。
構成要素の権利表示、継続的な配布権、移植性、短い例・検査、提出tarballの`--as-cran`が関係する。
データと文書はそれぞれ原則5 MB以下、source tarballは可能なら10 MB以下という別の目安である。
現在のtarball 5,552,330 bytesとextdata 4,521,543 bytesだけから、文書・全データの容量や
CRAN受理を断定しない。最終成果物で各範囲を点検する。非商用条件を一律の禁止理由にせず、
採用済みの構成要素別licenseとDESCRIPTIONの整合を保つ。

MacのUTF-8経路は既に動作確認されている。plain C localeでの制限をmacOS非対応としない。
optional依存やモデルがない利用者にも基礎分析が動くことを確認し、ネット接続・自動取得を
パッケージ読込や基本例の前提にしない。実資源の任意検証とオフラインの基本検証を区別する。
配布コードに広範な影響があれば全体検証を行うが、文書・計画だけの変更で数値計算やモデル推論を
繰り返さない。失敗は実装・入力・環境・文書構築・実行制御に分け、完了工程を保持して再開する。

### 統合改訂で確定したことと、その後の実装

- 中心目的とKyle & Eguchi由来の注釈→文書評価を維持し、機能数の拡大を目標にしない。
- word family／接辞を次の具体的な追加候補として採用し、flemma・頻度帯・能力得点との混同を防ぐ。
- 公開、ソフトウェア検証、実資料適用、独立した研究上の妥当化を別々の状態として報告する。
- 日本語・母語話者資料・心理規準・連語・意味・ネットワークを共通の原文／項目ID経路へ整理し、
  それぞれの未解決な入力・構成概念・ライセンスを着手条件へ反映する。
- MorphyNet実装後の再点検で、配布一覧の不整合を次の開発課題に置いた。既存ICNALE全文書分析は
  未着手に戻さず、語族・形態条件を追加する。日本語は候補と複数tokenの出現範囲から進める。
- 過去の調査・実装記録は削除せず、以下を履歴として区別する。新しい計画ファイル・管理基盤は増やさない。

統合改訂自体はロードマップと参照先の整備だった。その後、ユーザーの継続指示により語族APIの
初期経路・help・例・既存ガイドへの統合、続いて既存レビューAPIによる出現別判断の適用を実施した。
後者は「人の判断を原文と再集計に結ぶ」という目的への不足補充であり、実資源の妥当化完了とはしない。
続く接頭辞／接尾辞・屈折／派生の質問への回答では、上記「接辞分析の実装条件」に記した一次資料を
webで確認し、既存の接辞計画を具体化した。コード・配布物を変更する作業ではなく、数値テストは再実行していない。
以前の文献確認は各履歴と精読記録を引き継ぐ。Zotero変更・実コーパスのモデル推論・公開操作は行っていない。

## 実装・調査の履歴（各時点の記録）

以下の記述は統合改訂前の根拠・経緯を保存する。着手順序と現在地には冒頭の統合計画を使う。
本節内の過去の優先順位は、冒頭を上書きしない。

描画に関する追加指定を反映：既存11種類の `plot()` に `monochrome = FALSE`
（カラー既定）を揃え、`TRUE` では白黒に切り替える。自動タイトルを付けず、
図番号・題名・注記は原稿側で配置する。両色モードで下限未満の点を記号でも区別し、
フォント・目盛り・枠線を統一する。NJ8の比例目盛りと小幅時のラベルを整備した。
既存の注釈感度例では元の値を重ね、報告ガイドに文献根拠と掲載サイズでの保存例を置く。
追加の明示指定により、差分を軸に取る図は使用しない。連続指標は共通帯域幅と
境界条件で各条件の密度を重ね、少数例・離散件数は元の値や度数を示す。
差分表・出現照合は監査用に保持するが、差分図の推奨は撤回した。
指標・分母・返却表は変更しない。これは既存の表示設定の整備であり、下記の研究目的・
段階4の優先順位を変更したり、試作ネットワーク図を公開APIへ追加したりするものではない。

直近の実装：段階4の最初の特徴として `lexdiv_amod_pairs()` と英日作成例・ガイドを追加した。
完全な外部注釈importから基本UDの木を検査し、ADJ–amod–NOUNの両端位置、方向、KWIC、
文書別の出現数・異なり数を返す。文単位の注釈欠測、原形欠測、真正のゼロを区別する。
同数でも異なる組合せを抽出する反例と保存後の再集計を確認する。段階3の分割対応と
既存の同一分割評価は保持し、必須依存・モデル・外部コーパスは追加しない。
これは独立標本での精度や心理言語学的妥当性の実証ではない。段階4のMIは対応する
参照資料・分母がないため保留し、今後の実資料適用と段階5の独立参照評価を区別して進める。
今回の検証は `PUBLICATION-20261004.md` の該当節、リモートheadのCIはPR #21を参照。
公開設定・mainへのマージ・サイト配備・CRAN提出は別の操作である。

続く実装では、任意の `udpipe` とローカルモデルによるR実行例を追加した。
保存済みの完全な出力と原文の文リストから、位置照合・amod抽出・出現比較・
元の件数分布の重ね描き・モデルを再実行しない再読込までを接続した。
1 segment = 1原文文を条件とし、未対応の分割やUD構造は停止して確認を求める。
作成例4文書の実モデル実行では同数でも異なる出現があることを確認したが、
段階5の独立精度評価ではない。公開関数・必須依存・同梱モデルは増やさない。

**英語を中心に母語話者・追加言語話者のテキストを扱い、日本語にはM6の実験的入力経路を設ける。当面の重点は、語の数え方と参照資源の照合を点検し、コーパス・レジスターをまたいで比較条件を保持する手順を整えることである。** NJ8診断に加えて同じ原文・分割の注釈差分を調べる `lexdiv_compare_annotations()` を追加した。辞書の指定・内容ハッシュ・照合ロケールの記録と、ICNALEでの文脈別注釈変更の感度確認まで追加した。Kremmel & Schmitt (2016)を踏まえ、TUBELEXの語形特徴と学習者の認識・意味想起・文脈遂行を分ける実行例と診断APIも追加した。学習者×項目の二値回答をキー・欠測・分母を保持して比較する `lexdiv_compare_responses()` とCSV／反復測定の例まで実装した。母語話者の作文・自然会話等を含むレジスター別の記述、長さ・位置・パラメータの感度確認、複数の参照コーパスによる頻度プロファイルの比較を研究対象とする。次の実装順序は、以下の注釈評価と指標への影響確認を起点に定める。個人のemployabilityを問う対応回答データの設計・妥当化は別の研究軸であり、一般的なコーパス分析の前提にはしない。複語表現は、明示的な境界・元の位置を受けるbigram/trigram抽出とローカル参照頻度まで実装した。関連度・自動文分割・語義を考慮した分析は後続の研究開発とする。

本書は現在の優先順位の正本。workspaceの `r-package/ROADMAP.md` と `r-package/INTERNAL-ROADMAP.md` にある7–8月の実装状態・予定順序を更新する。過去の測定定義や個別機能の設計記録は保存し、今回の順序変更で削除しない。Webアプリ側の実装済み機能を、R版の実装済み機能として数えない。公開・CRAN提出の日付を約束する文書ではない。

### 改訂前の優先順位：Kyle & Eguchi (2024) の全文精読を反映

**2026-10-06の再優先付け。** 可視化の追加はいったん区切る。段階1–4のAPIと
UDPipe実行例が揃った現在は、作成例を越えた適用範囲の確認が不足している。
次の順序で進め、関連する新機能をすべて必須化しない。

1. **実参照で処理率と特徴抽出を確かめる。** 既出候補UD English ESLSpokの
   固定版test split全体と既存English EWT UD 2.5モデルで、ADJ–amod–NOUNの
   出現照合・集計への影響を調べる。学習資料、注釈由来、入力単位を確認する。
   失敗を残した全対象の処理率と、処理可能な集合のprecision/recallを分ける。
2. **その結果が示す入力・解釈上の障害を解く。** 文境界、原文照合、欠測等の
   具体的な失敗を優先し、機能を増やすだけで使いやすさが改善したとはしない。
   L2作文の誤字・文法誤りについては、ユーザーの追加指定に基づき、原文を保持した
   修正方針別の感度分析をここに位置付ける。語の誤り、注釈誤り、辞書未収録を分け、
   自動校正エンジンの新設や包括的GECベンチマークへ目的を広げない。
3. **既存の頻度・規準表から研究作業へつなぐ。** TUBELEXの頻度と出現範囲、
   LexOPS接続は次の候補。上記の中核経路を見失うほど同時に拡張しない。
4. **可視化は必要な結果の説明として整える。** APA・カラー／白黒・元の分布の
   重ね描きを維持し、図の種類を増やすこと自体を開発の進捗にしない。

初回の実資料確認は、公開test splitの配布された文テキストに対する限定評価である。
ESLSpokは文の抽出標本であり、元の面接全文や独立参加者の完全なデータではない。
文書全体の多様性・順位の妥当性、L1／書き言葉／日本語への一般化は扱わない。
評価前にモデル・特徴定義・全件使用を固定し、このtestでモデル選択は行わない。
結果により既定の推奨範囲と入力改善の順序を見直すが、段階5全体の完了や
この評価の完了を限定API配布の新たな必須条件とはしない。

**この順序で実施した結果。** 固定版testの232文・2,266 tokenを全件対象とした。
元の設定は229文を処理し、3文が文の再分割で停止した。利用者が決めた1文を
保持する既存UDPipeの `tokenizer=presegmented` にガイドを修正すると232文を処理した。
参照60出現に対し一致55・誤抽出6・取りこぼし5で、両設定の出現照合結果は同じ。
元の失敗3文は参照出現0件だったため、処理率の改善をprecision/recallの改善としない。
件数一致223文のうち1文には相殺されたFP/FNがあり、出現照合を維持する必要がある。
同じtestを用いた設定修正後の結果は開発時確認であり、未使用の最終評価ではない。
Rの結果表を独立したPythonの原文位置・集合照合でも確認した。
再現scriptは `experiments/evaluate-eslspok-amod.R` と `experiments/check-eslspok-counts.py`。
コーパス・モデル・保存解析結果はパッケージに同梱しない。

この実施により、段階5の外部参照による限定的確認へ進んだ。次の中核残件は、
元の文書を保持した標本での下流指標への影響と、対象レジスター・言語ごとの検証である。
今回の文の抽出標本を全文書に合成して、その代用にしない。未実施の大規模比較を
公開の一律条件にせず、現在確認できた範囲を示して既存機能を配布できる状態を保つ。

**L2作文の修正方針を扱う追加実装。** Nagata et al. (2018) の綴り修正と指標の
感度、Berzak et al. (2016) の原文／修正版の注釈設計を確認した。同一原文を要求する
既存の注釈比較・分割対応APIを、文字列が変わる修正へ流用しない。
`inst/examples/reviewed-text.R` とdemoは、原文座標・修正前後の文字列・カテゴリ・
採否・reviewer・理由を持つ台帳から、承認済み修正だけを方針別に適用する。
原文、metadata、未解決／却下、KWIC、hashを残し、既存batch関数で各版の
N/V/TTR/MATTR・NJ8照合率・計算不能を再集計する。綴りだけの修正と文法／語境界を
含む修正を分け、原文を主分析にするかは研究の推定対象に従って決める。
原文保持は必須だが、全研究の主分析を原文に固定する方針ではない。
作成例は処理・保存・再読込の検証であり、校正の正確さや学習者能力の妥当化ではない。
実際の同一作文の原文／独立に確認した修正版で下流の影響を調べることは段階5の候補とし、
未解決の意味・語境界変更・修正方針を明示する。誤字未検出を誤りなしとみなさず、
未照合語を一括置換／除外しない。外部校正器の提案取込は現段階では実装しない。
公開export・依存・コーパス・図の種類は増やさず、既存語彙監査ガイドに導線を置く。

**表記変種・固有名詞・数詞・記号に関する追加指定。** 誤り修正と数え方を混同せず、
原文、分析用の同値キー、参照照合キーを分離する。`inst/examples/lexical-counting-policy.R`
は既存の完全注釈import・指標・NJ8・n-gram APIを再利用し、作成8文書で方針を比較する。
英米表記を誤りとせず、例示した3組の名詞aliasの適用と異なり語の統合を別に選ぶ。
PROPN除外をcontent指定で代用せず、数値パターンとNUM品詞も区別する。品詞欠測は
条件付き値と報告可能な値を分けて残す。完全注釈の位置を保持し、記号等の除外箇所を
またぐ偽の隣接n-gramを作らない。原文tokenizerが既に落とした境界は復元できない。
これは優先順位2の解釈・入力経路の整備であり、自動NER、包括的英米変換辞書、
数値意味解析、記号誤用判定の実装へ目的を広げない。TUBELEX等の頻度を変種間で
統合する場合は元のcount・分母・文書重複を扱う別の参照定義が必要であり、照合aliasを
その代替としない。表層の心理言語学的規準も無条件に合算しない。原文を使った
実資料検証は段階5に維持し、作成例を性能の根拠にはしない。

**Word family・英語接辞の追加検討（2026-10-06）。** ユーザーの明示した候補を、
優先順位2の「語の数え方」と3の「参照資源との接続」に位置付ける。現状の
`lexdiv_flemmatize()` は利用者提供AntBNCによるflemmaであり、派生語族・接辞の
専用APIではない。MASCのaffix属性の保持も派生分析の実装とは区別する。
今回は設計と利用境界の文書化までとし、以下のAPI・資源importは未実装である。
汎用形態解析器の新設や新たな学習者能力尺度の妥当化を公開の必須条件に追加しない。

研究上の問いは、同一テキストをsurface／lemma／flemma／指定したword familyで
数えると、異なり数・多様性・参照照合がどう変わり、どの派生語の区別が失われるか、
である。[Bauer & Nation (1993)](https://openaccess.wgtn.ac.nz/articles/journal_contribution/Word_families/12560408)
は頻度・規則性・生産性・予測可能性を用いた段階を提案している。
段階を個人の実測知識や一律の習得順序に置き換えない。
[Schmitt et al. (2021)](https://onlinelibrary.wiley.com/doi/full/10.1002/tesj.622)
が扱う語族内派生語の知識の問題を踏まえ、読解教材の被覆と作文での産出を区別する。
族単位の値のみで学習者の語彙力・employabilityを推定しない。

useとreusabilityを同じUSE族と定義した例では、延べ2 token・表層2 type・1 family
となる。既存のインストール済み0.2.0で作成キー `c("USE", "USE")` を
`lexdiv_metrics(..., metrics = "ttr")` に渡し、N=2、V=1、TTR=.5を確認した。
これは集計単位の動作例であり、実際のBNC/COCA表への収録・語族判定の検証ではない。
原文2出現を1出現に圧縮しない。reusabilityはuse→reuse→reusable→reusabilityという
分析候補を説明できるが、綴りの変化を含み、文字列の単純な接辞除去では再現しない。
語族表、版、形態的な包含段階、品詞・意味の扱いを明示し、BNC/COCAの頻度帯と
Bauer–Nationの接辞段階は別の列にする。

次の小規模実装は次の順で検討する。関数名は公開APIの命名確認後に確定する。

1. **利用者提供の語族対応表を照合する。** form、必要ならPOS、family_id、
   資源内record_idと、資源名・版・出典・利用条件・包含基準を受ける。
   全tokenの文書ID・原文位置・表層を保持した別のfamily層を作り、既存lemmaや
   flemmaへ上書きしない。未収録・文脈依存・複数候補は別状態で返し、先頭候補に
   決めない。KWICで判断と理由を記録する。原文の重複出現、空文書も残す。
2. **文書別に集計する。** 全対象数、照合数、未解決数、照合率、観測family数、
   各族の観測語形・lemma数を返す。未解決がある全体のfamily指標は未確定とし、
   照合部分の条件付き値と分母を別表示する。表層へのfallbackを許す場合は混合単位と
   明示し、純粋なfamily値としない。語順を保つキー列で既存指標を再利用するが、
   未照合箇所を詰めた窓のMATTRを元テキストの値と扱わない。TUBELEX等の表層頻度を
   familyへ照合するだけでfamily頻度とは呼ばず、集約用のcount・分母・定義を要する。
3. **接辞出現を別表で扱う。** 1 tokenに複数の派生／屈折接辞を許し、接辞ID、
   標準形・表層異形、prefix/suffix、機能、base/derived formとPOS、分析候補を保持する。
   綴り上の位置がない標準形に架空の文字座標を与えない。接辞を含む語数と接辞総数、
   接辞の種類数を区別する。teachersの-erと-s、reusabilityの複数接辞を落とさず、
   uncleのun-やbrotherの-erのような文字列一致を接辞認定の根拠にしない。
   未収録を「接辞なし」の0とせず、対象語全体と解析可能部分の分母を返す。

接辞付き語の比率・接辞別token/type頻度を最初の記述量とする。語根頻度・形態的
family sizeは心理言語学的な刺激統制の候補だが、教育的word familyとは定義を分ける。
短い作文での接辞の種類数を「形態的生産性」や習得の証拠と呼ばない。生産性推定を
加える場合は別途、hapaxの定義、該当接辞のtoken分母、標本量・誤字の影響を設計する。
[Cobb (2022)](https://nflrc.hawaii.edu/rfl/item/549)の複数接辞の数え落としの論点は
受入検証へ反映する。これは下記のSánchez-GutiérrezらのMorphoLexデータベースとは
別の、LextutorのMorpholexプログラムに関する論文である。

資源候補と採用境界：

- [NationのRange配布](https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs)：
  BNC/COCAのfamily-member表の候補。見出し語だけの表ではmember照合はできない。
  実ファイルの形式、重複、版とその配布物に適用される条件を確認してからadapterを作る。
  族リストだけから全memberの接辞分析や段階別対応を推定しない。
- [MorphyNet](https://github.com/kbatsuren/MorphyNet)：派生元・派生先・品詞・接辞を持つ
  公開資源で、READMEはCC BY-SA 3.0を指定。Wiktionary由来の関係を取り込む候補とする。
  連結成分を無制限にまとめてBauer–Nationの語族とみなさない。まずローカル入力で版と
  出典を保持し、対象テキストでの未収録・曖昧性を評価する。
- [MorphoLex-en](https://github.com/hugomailhot/MorphoLex-en)：
  [原著](https://link.springer.com/article/10.3758/s13428-017-0981-8)は68,624語の
  語根・接辞変数を説明する。[LICENSE](https://github.com/hugomailhot/MorphoLex-en/blob/master/LICENSE.md)
  はCC BY-NC-SA 4.0。汎用パッケージへの無条件同梱は採用せず、利用条件に沿った
  ローカル参照表と既存norm-profileへの接続を候補にする。単に無料閲覧可能であることを
  再配布自由と解釈しない。具体的import・収録語の確認は未実施。

作成例での完了条件は、token数不変、同族の反復保持、資源変更での判定差、複数候補・
欠測・空文書、複数接辞と紛らわしい非接辞、保存再読込後の集計一致を確かめること。
その後、明示した資源・包含基準について独立に確認した原文付き標本で割当を評価し、
文書指標への影響を段階5へ接続する。今回の作成キーの確認をその実証の代用にしない。
READMEには現行機能の境界だけを追記し、モデル・依存・公開関数は追加していない。

**KH Coderとの関係の検討（2026-10-06）。** ユーザーの質問に対応して公式の
[機能・2段階の分析](https://khcoder.net/diagram.html)、
[R Source出力](https://khcoder.net/scr_r.html)、
[FAQの文書×抽出語表・外部変数・自動化](https://khcoder.net/FAQ.html)、
[現行5の案内](https://khcoder.net/index.html)を確認した。Rの利用、日本語対応、
KWIC、共起図、明示的なコーディングはKH Coderにもあり、それだけをldfreqの
新規性にはしない。内容・テーマの分析と、語彙指標・参照資源・前処理による
測定条件の比較を、文書IDで併用する位置付けをREADMEへ追加した。これは比較上の
整理であり、KH Coderが語彙研究に使えないという排他的な区分ではない。

**配布条件の補足（2026-10-06）。** [公式配布案内](https://khcoder.net/dl3.html)は、
Windowsの制限付き無料版と有料の正式版を区別している。
[Mac向け現行配布](https://khcoder.net/mac_com.html)も有料（確認時12,800円）で、
Apple Silicon・macOS 11以降・空き容量5 GB以上が必要となる。旧公開ソースの存在を
現行アプリの無償提供と混同しない。手元のMacはarm64・macOS 27.0.1でCPU/OS要件を
満たすが、アプリの起動や連携は未検証である。公式案内は初回の起動許可と、
使用ツールの版に由来するWindowsとの分析結果の差も説明している。KH Coderは
既存利用者向けの任意連携候補とし、購入・インストールをldfreqの利用条件にしない。

連携は次の候補として記録し、主課題の順序や公開の必須条件には追加しない。
まず同じ原文・文書IDを使う並行分析と、文書別指標／内容コードの表の結合を検討する。
実際のexportを得てから、全度数か二値・フィルタ済みか、文／段落／作文の単位、
除外品詞・辞書・強制抽出・表記統合・空文書・IDを確認する。度数表は語順を
保持しないため、元のMATTR/MTLD・隣接n-gram・出現KWICを復元したと扱わない。
完全な原文付きtoken出力でのみ、既存importへの対応と原文座標を検証する。
KH Coderの内容コードはlexical typeや語義の正解ではなく、共起ネットワークは
隣接句・依存関係・連想規準と異なる。共通の語の多さや図の類似を互換性としない。

KH CoderのGUI・内部DBに依存するwrapperは現時点では採用しない。現行5の公式案内と
[GitHubの旧3 betaソース](https://github.com/ko-ichi-h/khcoder)を区別する。
CRAN/GitHub/公式サイトを対象とした検索では採用できる公式R wrapperを確認できなかったが、
不存在を証明したとはしない。実ファイル・現行アプリでの連携検証、API・依存追加、
GUI操作は行っていない。今回はREADMEと本書の比較・候補記録だけを更新し、
成功済みの数値テストや配布アーカイブを作り直す必要はない。直前の配布物の
数値・実装検証は有効だが、今回のREADME説明は次回の配布物に取り込む変更となる。

**最優先は、注釈の変更・誤りが研究で使う文書指標をどれだけ動かすかを、
原文の出現箇所まで戻って説明できる評価手順である。** Kyle & Eguchi (2024)を
全19ページ、図表・脚注も含めて精読し、RQ4の公開コード・保存済み出力と照合した。
[ページ別精読記録](KYLE-EGUCHI-2024-READING.md)に、論文の結果、記載の不一致、
ldfreqへの設計上の推論を分けて残す。以下が後段の各実装時点の「次の作業」に優先する。

論文から採用するのは、**特徴ごとの注釈評価と、文書指標への影響を両方確かめる設計**である。
依存関係amod–名詞の結果を連続句検索や意味判別に流用しない。
RQ4は元の文章全体ではなく文を集めた合成文書を使う。方法欄は各30文書だが、
補足の生成指定と8集計表は各28文書で、依存解析は4資料を対象にする。
またTable 10のL2作文欄は発話欄と一致する一方、補足出力は別の結果を持つ。
この表をそのまま性能基準にせず、下流評価の数値には精読記録の留保を付ける。

#### 実装済みの足場

文脈モデル評価は、`lexdiv_compare_ambiguity()`、`lexdiv_score_contextual()`、
`lexdiv_evaluate_contextual()`と研究用3 scriptで、判断・裁定・分割・設定・再集計を
作成例として実装した。独立した人手判断に対する性能は未検証である。
句リストの英日例は`lexdiv_as_quanteda()`とquantedaを使い、4語以上・重なり・
区間境界を保持して出現と被覆を分ける。lemma変異・不連続句・語義の自動判定は含まない。
これらの実装完了項目を、今後の開発の最初の作業として再掲しない。

#### 段階別の成果物と依存関係

| 順序 | 利用者の問い・成果物 | 入力と実装範囲 | 完了条件 |
|---|---|---|---|
| 1 | **注釈を変えると何が変わるか。実行例を実装済み。** 同一分割での差分から文書指標へ進む | 既存のtokenizationとlemma/UPOS/flemma、明示した語単位・内容語選択を使う。`lexdiv_compare_annotations()`と既存profile/batchを再利用し、文書・token位置で結果を結ぶ | 変更箇所、変更前後の分母・coverage・指標、計算不能理由、設定を保存。RDS再読込後に再集計が一致。lemmaだけの変更がsurfaceによる句検索を変えない反例も確認。差を誤り・改善とは呼ばない |
| 2 | **自動注釈の何を修正すべきか。評価API・英日例を実装。** 参照との照合から文書指標へ進む | `lexdiv_evaluate_annotations()` が完全な外部注釈importを再検証し、同じ原文・分割の単一ラベルを比較。参照の作成手順・label scheme・モデル閲覧・評価用途を必須宣言とする | ラベル別TP/FP/FN・support・precision/recall/F1、全出現の原文KWIC、文書coverageを保持。未知参照は採点せず、既知参照の予測欠落はFNに算入。同数でも誤選択とTTR差がある例、部分参照の得点を欠測に保つ例を用意。実標本の独立判断・裁定・標本計画は研究段階として未完了 |
| 3 | **分割の違う日本語・英語を比較できるか。API・英日例を実装。** 原文位置に基づく境界対応 | 同一原文と座標規約を前提に、1対1・1対多・多対1・対応不能を分ける。日本語の形態素分割、英語の縮約・ハイフン、Unicodeを含む | 境界自体の評価と、対応できた単位に条件付けたPOS等の評価を区別。対応率・除外理由を出す。区間の切り方が違う入力は文書座標への対応が確立するまで拒否。token行番号だけで接続しない |
| 4 | **構文的な連語はどこに現れるか。出現表・作成例を実装、MIは保留。** | `lexdiv_amod_pairs()`で基本UDのADJ–amod–NOUNを抽出。元の文・分割・位置に一致する完全な外部注釈を受ける。MIは対応する参照資料を別に用意できた場合のみ追加 | head・関係・品詞・方向・両端位置と欠測を保持。作成参照との照合は実装、独立人手標本の評価は段階5。MIの共同出現数・周辺度数・機会数・語単位・対数底・平滑化・未掲載の意味と再配布条件の確定は未完了 |
| 5 | **実際の対象資料でどこまで使えるか。** 独立標本による注釈と下流指標の評価報告 | 英語のL1/L2・書き言葉/話し言葉を、実際に存在する注釈層と標本に応じて層化。日本語は別の標本・単位・注釈手引きで検証。元の文書を保つ評価を主とする | 対象集団、課題、モデル版、訓練利用、処理率、特徴別の件数と不確実性を報告。平均差だけでなく文書別の差・順位変化を確認。合成文書と実文書、作成例と実証結果を分け、確認した範囲に公開上の主張を限定 |

1は`inst/examples/annotation-sensitivity.R`とdemo、既存vignetteへの説明として実装した。
6文書の作成例でlemma・UPOS・欠測・未照合・空文書を扱い、TTR/MATTRとNJ8の分母を保持する。
原文と処理後の文字列が同一であることを検査し、変換後の位置を原文位置として表示しない。
flemmaによる指標の比較はこの例の対象外。2は `R/annotation-evaluation.R`、
`inst/examples/annotation-evaluation.R` と `vignettes/annotation-evaluation.Rmd` に
実装した。参照は渡されたラベルを採点するための基準であり、独立性をAPIが保証するものではない。
同音異義・同一品詞内の多義性、依存headの正しさはこの機能で評価したとは扱わない。
実際の研究標本の注釈手引き・抽出設計、独立判断と裁定は引き続き必要であり、
作成例の動作確認とは分ける。これらの実証完了を、この限定された評価APIの配布条件に追加しない。
3は `R/annotation-alignment.R`、`inst/examples/annotation-alignment.R` と
`vignettes/annotation-alignment.Rmd` に実装した。文字区間の重なりの連結成分を使い、
1対多等を強引に1対1へ変換しない。区間内境界は左token末尾・右token先頭の組で定義し、
強制的な区間端は分母に入れない。品詞等は同一spanだけで評価し、非対応tokenは
条件付きラベルFNとは分ける。全token対応率とラベル評価を併記し、指標計算には
対応部分だけでなく各文書の全入力を使う。分割変更がTTRを変える例と変えない例を含む。
英日API共通化は言語間の測定等価性や解析器の性能を示すものではない。
4は `R/amod-pairs.R`、`inst/examples/amod-pairs.R`、`vignettes/dependency-pairs.Rmd` に実装。
範囲は基本UDのADJ–amod–NOUN（amodの下位関係を含む）に限定し、PROPN/PRONは含めない。
Kyle & EguchiのPenn条件と同一の再実装とは称さない。文ごとのhead/root/循環を検査し、
欠測がある文の全体を除外、文書の完全な出現数はNAとする。基本木へ明示的に射影していない
enhanced edges、原文に個別対応しない語、multiword/empty-node行は対象外。
7文書の作成例で、同数でも両端位置が異なるFP/FN、日本語、真正ゼロ、欠測文、空文書を区別する。
単語形／原形の選択は異なり数の定義であり、未知原形を語形に置換しない。
対応する参照資料がないためMIは保留し、出現表までを提供する。
5の標本計画は2から始める。全条件が揃わないことを理由に、未評価の条件を評価済みに埋めない。

#### 評価の入力と出力を先に定める

現在の`lexdiv_compare_annotations()`が受けるのは`lexdiv_tokenization`またはその名前付きlistである。
原文・処理後の文字列・tokenizer ID/版・前処理・token行の同一性を検査し、lemma/UPOS/flemmaの
差を返す。`lexdiv_import_annotations()`の外部注釈listは直接の入力ではなく、
同じ分割だけを条件に任意の解析器を比較できる関数ではない。
新しい `lexdiv_evaluate_annotations()` は外部注釈importを受け、明示した完全なラベル集合で
UPOS・Penn XPOS等の1列を評価できる。意味の異なるtagsetの対応付けは利用者側で明示する。
この同一分割評価は依存head・境界変更を含まない。異なるtoken分割には
`lexdiv_align_annotations()` を使い、原文位置の対応率と対応した部分に条件付けた
ラベル評価を別々に報告する。依存headの入力形式・採点は段階4で別に仕様化する。

新しい評価例は、独立したmetadataにcorpus/version、document/segment、participant、
language/register/task、元資料と注釈・モデルのハッシュ、splitと選定理由を保持する。
出現には原文位置、feature、予測、参照、判断状態を付ける。計画した全件から、
取込・対応付け・採点・指標計算の各段階の件数と除外理由を出す。
未知の参照、予測の欠落、対象外ラベル、予測失敗は同じ欠測へ丸めない。
参照が既知の予測失敗を条件付き精度の分母から黙って落とさず、成功例での精度と
全対象の処理率・達成率を区別する。

基本UDを受ける段階では、文単位のID、headの存在、root、自己参照・循環、文境界を検査する。
CoNLL-Uのmultiword token・empty node・enhanced dependencyの扱いを明示し、
基本木に未対応の要素を黙って平坦化しない。外部解析器の推論・学習は別工程にし、
R側は保存済み出力の検証・抽出・再集計を担う。

#### 人手判断と統計から何を言うか

KWICによる候補確認はprecisionの改善に役立つが、検出されなかった正例を見付ける
設計がなければrecallを評価できない。非候補を含む無作為な文・区間の参照注釈と、
稀な特徴の追加標本を区別する。追加標本を含む場合は抽出確率・重み・報告対象を残す。
個別判断、不一致、未解決、裁定後の参照を別に保存し、評定者間一致を人間の正答率と呼ばない。
最終評価の参照はモデル・閾値を選ぶ材料にしない。

下流の比較は同じ文書・同じ指標設定で対応を付ける。符号付き差は系統的な増減、
絶対差は誤りの相殺を含む変動の大きさとして分ける。出現数と出現IDの一致も分け、
群平均が同じ場合にも個々の文書の差を確認する。参照値のある項目だけの平均では、
各条件固有の集合と共通集合の結果・coverageを併記する。未知・全件未照合を0で埋めない。

不確実性は元の文書・参加者のまとまりを考慮し、tokenを独立観測とみなした再標本化を
既定にしない。未知文書への一般化と未知参加者への一般化を分け、後者では参加者を
訓練・開発・最終評価の間で分ける。既定モデルの学習資料が不明なら訓練重複を「なし」にしない。
モデルを比較・選択する試行と最終評価を分け、RQ4の公開コードにあるdev＋testの利用を
そのまま独立な最終評価の設計としてコピーしない。

混合モデル等は既存Rパッケージに接続する例で扱い、分散・残差・収束・反復構造を確認する。
比較集合、基準条件、差の方向、効果量の標準化、p値調整を明示する。
非有意を同等と解釈せず、同等性を問う研究では意味のある許容差を事前に定める。
相関の高さだけでも絶対的一致は保証できない。機能例の完成と研究上の妥当化の完成を分ける。

#### 意味研究・source利用・公開との関係

意味・曖昧性研究は、既存テンプレートを用いた独立人手評価を継続する。POSの区別は
同一品詞内の多義性や日本語同音異義語の解決ではなく、本論文を意味判別の精度保証に使わない。
BERT等による外部埋め込みは任意とし、単純な頻度基準に対する増分と候補coverageを検証する。
英日で同じAPIが動くことは、言語間の測定等価性の証拠ではない。

sourceと要約・再話の比較例は後続とする。source ID、participant、課題、時点を保持し、
Jaccard・方向付き被覆・頻度cosineを区別する。TF-IDFならIDFを推定する文書集合を固定する。
語列重複を言い換え理解や意味の同一性と呼ばず、独立した研究上の問いを定めて着手する。

既存のR処理・quanteda・外部解析器を使う利点は、保守対象を絞り、確立した機能を再利用できること。
代わりに、入力形式、tagset、位置座標、モデル・依存の版差を検証する責任が残る。
追加価値は、これらの接続と失敗例・人手判断・指標への影響をRで追えることに置く。
現段階で精度向上・操作時間短縮・既存パッケージへの優越は主張しない。

公開用の説明は、作成例で動作確認した機能と、独立標本で検証した用途を別々に表示する。
現在の限定された機能の配布と、後続の研究完了を一括の条件にしない。
コーパスやMI表は、再配布条件を確認できない場合は利用者が取得する経路と小さい作成例を使う。
TUBELEXの単語頻度や現在の隣接n-gram表だけから、依存関係のMIを算出したとは説明しない。
全文精読時の文書改訂だけでは数値計算・モデル推論・CIを再実行しなかった。
続く注釈感度例の追加では、変更した例・ガイド・配布物を検証し、同一性を確認した
既存の数値実装・データ・17本のガイドの証拠を再利用する。検証詳細は
`PUBLICATION-20261004.md`のAnnotation sensitivity exampleを参照する。

#### 確認した成果物と、取り入れる範囲

| 成果物・確認版 | 確認できた内容 | ldfreqへの示唆と境界 |
|---|---|---|
| [Multi-Word Units Profiler](https://github.com/egumasa/Multi-Word-Units-Profiler/tree/ba1f3dacad76986611afdbcfb7f0edfb0eb1404f) | 既存の句リストを入力文中で照合・強調表示するPython／Flask／spaCyのツール。READMEはPHRASE、AFL、Biber et al.のリストを挙げる | 指標一覧に加えて「該当箇所を読む」入口を作る。句リストとの一致、n-gram頻度、関連度、文脈中の慣用的意味を別の処理とする。現在のldfreqの2・3語参照プロファイルは汎用MWE検出器ではない |
| [LDA II授業環境](https://github.com/egumasa/linguistic-data-analysis-II-2026/tree/6a3637adf46048b7324a245d2666ecdcb28a359f)・[研究用テンプレート](https://github.com/egumasa/lda2-proj-template/tree/b4a3bd3438fe92319b504039ca71ddd60ccd3c96) | Quarto、Jupyter／Colab、ローカル用のuv設定を公開。テンプレートは標本作成、人手注釈、開発、最終評価、報告をファイルで引き継ぐ | 関数名別の説明に加え、研究者の作業順で入口をまとめる。中間結果を保存し、モデルを再実行せず評価を再現できるようにする。Google Drive／Sheets・Gemini APIは授業の選択であり、ldfreqの必要条件にしない |
| [cx-overlaps](https://github.com/egumasa/cx-overlaps/tree/c180b2d85b399bc076e3f65e0196243e9ba8d16d) | Philip Tillmanのfluencysimilarityを拡張したもの。sourceとの比較、spaCyでの語列抽出、設定ファイルによるproject単位の実行を提供 | 課題反復・source利用という研究目的を明示した入口が参考になる。unigram／trigramの語列重複を、依存構造の一致、言い換え理解、語義の意味類似度とは扱わない。原開発者とEguchi氏の拡張を区別して引用する |
| [Theme Analyzer](https://egumasa.github.io/tools/tool/theme-analyzer/)・[demoソース](https://github.com/egumasa/Theme-Analyzer-demo/tree/0b1d3b52fc52622587dc1fcc839885bbfde6f734) | 依存構造と規則でTheme／Rhemeを分類し、原文表示と結果表を提供するStreamlitアプリ | 文脈と分類根拠を一緒に見せる設計を参考にする。談話機能と語義判別は別の構成概念。公式ページの小規模評価を、ldfreqや他レジスターでの精度の根拠にはしない |
| [item-context-extractor](https://github.com/egumasa/item-context-extractor/tree/607a1d8d6cb23474a532aed958ec446495ee4c96) | modal verbs等を文脈・文法情報とともに構造化するspaCyコード | 将来の構文条件付き検索の参考。ただし現在の注釈importは汎用依存グラフの契約ではなく、既存の単語KWICへ列を追加するだけでは対応済みにならない |

[LexicalOverlapのソース](https://github.com/egumasa/LexicalOverlap/blob/b45c86f3c85f8a1a7b9b9d520f22487258c13dd9/scripts/LexicalOverlapAnalysis_20210906.py)も確認した。sourceとsummaryの語列重複を分析し、
KyleのCRATに基づくpipelineへの謝辞がある。これらの既存成果から、
**句の検索、語彙重複、cosineそのものをldfreqの新規性として訴求しない**。
追加価値は、資源の版・語単位・原文位置・未照合／処理失敗・人の判断を結び付け、
研究者が条件を変えた差をRで追えることに置く。将来の有用性評価では、既存ツールを
組み合わせる手順を比較対象とし、誤結合、見落とし、確認時間を実際に測る。
操作時間の短縮や精度の優越はまだ実証していない。

#### 実装と環境の選択

[quantedaの句検索](https://quanteda.io/reference/kwic.html)は複語の開始・終了token位置を返す。
[phrase／as.phrase](https://quanteda.io/reference/phrase.html)で成分語の順序を明示できる。
これを任意依存として使い、ldfreq側はsegmentと元の位置の対応、資源ID、集計の分母を
保持する部分を担う。検索器を再実装しない利点がある一方、quantedaの位置はそのtokens
オブジェクト内の位置なので、原文のUnicode位置と同一視しない。padding・重なり・
区間分割・版差は接続例で確認する。最初は連続した表層形の一致に限定し、lemmaの
変異形、不連続句、語義の判定は別の仕様・検証を要する。

spaCy等を使うと品詞・依存構造・学習済みモデルを再利用できるが、Python／モデルの
準備と原文への位置対応が必要になる。Rの基本分析は現状のまま利用でき、外部解析は
必要な研究だけが明示実行する構成を維持する。R側は既存のvignette／pkgdownを使い、
研究用projectの環境固定はrenv等、外部Python例は独立した仮想環境とモデル版の記録を
検討する。今回、環境・依存・クラウド接続は追加していない。

授業リポジトリは`pyproject.toml`、`.python-version`、`uv.lock`を持つが、
テンプレートごとに依存の配置は異なる。授業サイトのCIは事前生成したHTMLを配備する
設定であり、全notebookの再実行検証とは区別する。ldfreqでも保存済み出力の再集計と
モデル推論の再実行を別工程にする。APIのseedやtemperatureの指定だけで再現性を
保証したとせず、実際の出力、モデルの識別情報、入力と設定を保存する。

#### 研究根拠・再利用条件・確認の限界

[Kyle & Eguchi (2024)](https://doi.org/10.1016/j.rmal.2024.100120)は、追加されたZotero添付の
刊行版全19ページと公開補足の該当部分を確認した。L1/L2・書き言葉／話し言葉の
tagger／parserを、特徴抽出と文書指標の両段階で評価する設計を参考にする。
具体的な標本・結果の照合と不一致は[精読記録](KYLE-EGUCHI-2024-READING.md)を参照する。
この確認は保存済み数値の読み取りと限定的な集計であり、モデルからの追試ではない。
[Eguchi & Kyle (2024)](https://doi.org/10.1016/j.rmal.2024.100153)の
[機関公開要旨](https://waseda.elsevierpure.com/ja/publications/building-custom-nlp-tools-to-annotate-discourse-functional-featur/)は、
Engagement Analyzerを題材に注釈・学習・評価・配布を結ぶspaCy tutorialを説明している。
後者のEguchi & Kyle論文は引き続き要旨の確認であり、今回の全文精読の対象ではない。

[UD English ESLSpok](https://github.com/UniversalDependencies/UD_English-ESLSpok)は
L2発話のPOS／依存関係を検証する候補になる。公式READMEはCC BY-SA 4.0、
XPOS・依存関係の人手注釈、UPOSの変換後の確認、lemma非提供を記す。
lemma精度のgoldには使えず、このL2発話標本だけでL1や書き言葉の性能は判断しない。
対象モデルの訓練利用と評価splitを確認することを前提とし、今回コーパスは取得・同梱しない。

README／LICENSEで確認した条件は、MWU ProfilerがCC BY-NC-SA 4.0、
Theme Analyzer demoがCC BY-NC 4.0、LDA IIの二つのprojectテンプレートが
**コードのみMIT**、cx-overlapsがREADME上Apache-2.0である。
GitHubのlicense欄が空またはNOASSERTIONでも、本文には条件が記されている例がある。
語彙リスト・コーパス・モデルの条件をソフトウェアの条件で代用しない。
今回ldfreqへ第三者のコード・句リスト・モデルを転載せず、設計と書誌を参照した。

比較対象の出力も無条件に正解とはしない。確認版cx-overlapsの`ngrammer()`を
モデルなしで切り出した検査では、句読点なしの3語入力のtrigramが0件となり、
末尾の窓を落とす条件を確認した。末尾句読点付きの例では表面化しないため、
一致検証には短文・末尾・空入力等の独立した期待値を含める。この限定検査は
同リポジトリの他版や関連論文の結果を評価したものではない。

#### 多角的なニーズ点検（2026-10-06）

今回の依頼はZoteroとWebによるニーズの検討である。上記の目的と段階1–5を維持し、
関連する全課題を新規API・公開条件へ追加しない。文献で確認した方法上の問題、
既存機能で対応できる作業、未検証の使いやすさを区別する。以下の優先順位は、
研究上の重要性に加え、既存実装との距離と保守負担を考慮した設計上の判断である。

| 利用者・具体的な問い | 文献・公式資料から得られる根拠 | 現在の足場と残るニーズ |
|---|---|---|
| SLAの産出研究：群差・縦断変化は文章長や課題を変えても残るか | Kyle et al. (2024)は長さ、課題間安定性、熟達度との関連を別に評価。Bestgen (2025)はMATTRの位置依存を問題にする [N1] | plan/grid、局所窓・exposure、比較ガイドは実装済み。対象課題の妥当性は未確定。文書・参加者・時点・課題を保持して、主分析と感度分析を同じ例で追えるようにする。普遍的な推奨窓幅や最低語数を追加しない |
| コーパス研究：頻出語は広く使われる語でもあるか | TUBELEXは出現回数に加え動画数・チャンネル数を提供。Nohejl & Watanabe (2025)は出現範囲と分割粒度を検討するが非査読preprint [N2] | 英語profileは生の3種のcountと派生値、日本語刺激例は頻度と動画・チャンネル割合を既に返す。新しいdispersion関数より、同じ項目集合・参照単位・分母で比較する例を先に整える。英語の平滑化log割合と日本語例の未平滑化割合を同一尺度として結合しない |
| 心理言語学：操作したい特性と統制したい特性を区別して刺激語を選べるか | AoAは頻度・長さだけでは尽くせない説明情報を持つ。LexOPSは利用者の特徴表による刺激選定に対応 [N3] | generic norms、項目ID、WLSP候補判断、日本語の頻度・親密度・AoA・BOIと条件別記述は実装済み。未実装なのは検証済みLexOPS接続例。採用・除外・未解決項目を保存し、選定後の分布と照合率を確認する。独自の最適化器や自動的な「均衡保証」は追加しない |
| 日本語・多言語研究：誰にとって難しい語なのか | 日本語LCPの再注釈では中国語母語話者の評価が異なり、個人への予測も容易でない [N4] | 読み・表記・語義候補と原文位置の保持はある。今後は対象者のL1、習熟度、規準の評定集団と課題を明示する実例・評価が必要。母語話者規準、L2難易度、個人の知識を交換可能としない。英日で同じAPIが動くことを測定等価性と呼ばない |
| 語彙テスト・教材研究：知っている語を文脈で使えるか、読めるか | Kremmel & Schmitt (2016)は形式–意味得点からemployabilityへの推論を検討。Kremmel et al. (2023)ではHu & Nationの結果を完全には再現できなかった [N5] | 対応回答比較と反復測定例は実装済み。頻度、資源との照合率、本人の既知率、文脈遂行を別の変数で扱う研究が必要。資源coverageを理解率に変換したり、98%を一般的な読解合否判定にしたりしない。これは一般コーパス分析の必須工程ではない |
| 連語・構文研究：どの組合せがどこで使われ、注釈で集計がどう変わるか | Eguchi & Kyle (2023)は構文的な組合せのMI帯別プロファイルを検討。quantedaの隣接句lambdaと依存関係MIは異なる [N6] | n-gram参照比較とADJ–amod–NOUNの原文付き出現表は実装済み。続く実装で、保存済みUDPipe出力から原文照合・比較・再読込までの任意経路を検証した。分布・未照合・同数でも異なる出現を残す。自動文分割と独立精度評価は未完了。MIは必要な共同・周辺度数と機会数が揃うまで保留 |
| 意味・ネットワーク研究：何の関係を表す辺なのか | Lu & Huは語義別頻度の増分を検討。SWOWは人の連想反応を収集した資源であり、コーパス共起とは観測が異なる [N7] | 語義候補・人手判断・外部スコアの評価経路は実装済み、独立性能は未検証。ネットワークは試作段階。共起・依存・連想・埋め込み類似度を区別してigraphへ渡す例を条件付き候補とし、中心性計算器は再実装しない |
| 統計・可視化：何を単位とする差と不確実性を示すか | Gries (2022)はtokenを独立とする不確実性評価の問題と文書単位の再標本化を例示。Brysbaert (2026)はlong形式の課題信頼性を扱う [N8] | 文書別の元の値・条件別分布の重ね描き、保存・図のexport、条件別記述例はある。差分図は使用しない。モデル接続には参加者・項目・課題の反復構造を保持する具体例が必要。平均・SD・中央値・四分位・欠測数などは既存R機能を使い、信頼性・CIをすべての出力へ自動付与しない |
| 初学者・再利用者：自分の資料から報告まで到達できるか | 公式ツールの入力契約は接続候補を示すが、ldfreqの操作時間や利用者需要は実測していない | 「文書比較」「刺激項目」「連語と用例」「人手判断」の入口から既存ガイドへ案内する。独立したR利用者の完了可否、誤結合・欠測解釈、操作時間を既存ツールの組合せと比較する。新規の大規模UIや初心者向け別名APIは前提にしない |

**直近の具体的な成果物：実装・局所検証済み。** 段階4の任意入力例として、
`inst/examples/udpipe-amod.R` と依存関係ガイドに、保存済み出力→原文との対応→
amod出現→文書比較→図・再読込を実装した。
[udpipeの公式文書](https://bnosac.github.io/udpipe/docs/doc2.html)と実出力を照合し、
モデルと版、文境界、原文座標、multiword token等を保持・検査する。
対象は利用者が与える1文ごとの入力であり、未対応の構造を黙って変換しない。
31件の新規期待値と17件の既存API／smoke期待値が成功。実モデルでは空文書を含む
4文書の原文・出現・件数を保存し、別Rプロセスで再読込が一致した。
この実行例の成功と段階5の独立した精度評価は別々に報告する。

既存TUBELEX・normsの表からの頻度と出現範囲の比較、およびLexOPSへの
接続例は、冒頭の実参照確認と入力障害への対処に続く候補とする。
日本語の同じ表記に複数のitem ID・読み・判断がある場合、
LexOPS側の一意性条件を検証してから接続する。刺激選定のための除外をコーパスの
語彙coverageへ混入させず、実行後の採用集合から元の全項目表へ戻れることを確認する。
既にある日本語規準の読込・条件別記述を未実装と数え直さない。

**再利用の利点と負担。** quanteda/LexOPS/igraph等に計算を任せれば保守対象と
依存アルゴリズムの重複を減らせる。一方、版差、語単位、ID、欠測、尺度、モデル・
規準の利用条件を接続側で検証する必要がある。最初は任意依存の実行例に限定し、
繰り返し必要になる入力検証が確認できてから公開API化を判断する。
例えば[igraphのbetweenness](https://r.igraph.org/reference/betweenness.html)は
重みを距離として解釈するため、共起強度をそのまま渡してよいとはしない。
辺の定義、方向、孤立点、閾値・標本構成への感度を明示できる研究を先に定める。

**可視化と説明の残件。** APAの既定・カラー／白黒・タイトルなしは維持する。
推測の図では推定対象と反復構造に即した区間を既存統計ツールから受け、図にCIを
足しただけで妥当性を示したとはしない。今回のファイル照合では、
`vignettes/japanese-stimuli.Rmd` の全欠測時だけ `title(main = ...)` を使う分岐が
残っていた。これは11個の公開plotメソッドとは別のガイド例であり、後続の修正で
欠測理由を表・図外に出す方針へ揃えた。ニーズ調査時点ではコードを変更していなかった。

**貢献の表現と検証。** 公開時の中心的な説明は「語彙指標・参照資源・注釈の条件を
保持し、結果の差を原文の出現と欠測まで追って比較できるRの研究手順」とする。
KWIC・coverage・ネットワーク・Rでの計算の存在だけを独自性にしない。既存ツールの
組合せを対照に、同じ研究作業の誤り・完了率・再現に必要な操作を測ることが、
追加価値の実証になる。使いやすさ・速度・精度の優越は現時点では未実証である。

今回の根拠と確認範囲（2026-10-06）：

- **N1**：Zotero `CH6G3QIN` [Kyle et al. (2024)](https://doi.org/10.1017/S0272263123000402)、`5L5MEMLR` [Bestgen (2025)](https://doi.org/10.1016/j.rmal.2024.100168) の書誌・要旨を確認。`KC7MFSFS` [Kyle & Crossley (2016)](https://doi.org/10.1016/j.jslw.2016.10.003) は独立作文とsource-based課題で関連が異なることを報告。単一課題での関連を普遍的な指標選択規準にしない。
- **N2**：[TUBELEX刊行論文](https://aclanthology.org/2025.coling-main.641/)の要旨と[公式README](https://github.com/naist-nlp/tubelex)の頻度表仕様を確認。[Nohejl & Watanabe (2025)](https://arxiv.org/abs/2501.06536)は非査読と明記されたpreprint。HTML本文の導入・指標定義を確認し、同資料内でのlog-rangeの予測結果を将来の比較候補とした。あらゆる言語・課題での優越やldfreqの派生尺度との数値同一性は未確認。
- **N3**：Zotero `QZMVH8AT` [Kuperman et al. (2012)](https://doi.org/10.3758/s13428-012-0210-4) の書誌・要旨、[LexOPS公式の利用者データ例](https://jackedtaylor.github.io/LexOPSdocs/vignettes/custom-data.html)を確認。接続の動作や日本語の重複表記の扱いは今回未実行。
- **N4**：[Nohejl et al. (2024), Difficult for Whom?](https://aclanthology.org/2024.tsar-1.8/) の公式要旨を確認。規準の集団適合を検討する根拠とし、全日本語学習者での効果量・一般的なL1差は断定しない。
- **N5**：Zotero `3YK6ZI4B` [Kremmel & Schmitt (2016)](https://doi.org/10.1080/15434303.2016.1237516)、`TFETPS3R` [Kremmel et al. (2023)](https://doi.org/10.1111/lang.12622)、`8TY3UDJX` [Tanaka-Ishii & Terada (2011)](https://doi.org/10.1111/j.1467-9582.2010.01176.x) の書誌・要旨。頻度・親密度・形式–意味知識・文脈遂行の区別を維持する。
- **N6**：Zotero `4FUBMPUM` [Eguchi & Kyle (2023)](https://doi.org/10.1016/j.jslw.2023.100975) の書誌・要旨。[quanteda公式説明](https://quanteda.io/reference/textstat_collocations.html)と[現行別パッケージのソース](https://github.com/quanteda/quanteda.textstats/blob/master/R/textstat_collocations.R)を参照。MI帯の閾値や優越を他の資料へそのまま移さない。Kyle & Eguchi (2024)は既存の全19ページ精読記録を再利用し、今回再精読したとは扱わない。
- **N7**：Zotero `6E3F6B7T` [Lu & Hu](https://doi.org/10.3758/s13428-021-01675-6)（2021オンライン公開、2022巻号）、`XF6KEJNF` [De Deyne et al. (2019), SWOW](https://doi.org/10.3758/s13428-018-1115-7) の書誌・要旨。語義別指標・連想規準を文脈モデルや共起ネットワークの妥当性保証には使わない。
- **N8**：[Gries (2022)著者公開校正稿](https://stgries.info/research/2022_STG_UncertEstimates4CorpStats_RMAL.pdf)の要旨・第1節と結論付近の該当記述、Zotero `SYWZZWQC` [Brysbaert (2026)](https://doi.org/10.5334/joc.516) の書誌・要旨を確認。後者の出版社ページは取得できず本文・コード未確認。ICCの方式を採用したり、すべての研究に文書bootstrapを既定としたりする根拠とはしない。

これは焦点を絞ったニーズ調査であり、系統的レビュー・利用者調査・新しい実証分析ではない。
Zotero検索は意味検索と短い著者名検索を使い、11件の書誌・要旨を照合した。
検索のfallbackで出た無関係な項目は根拠から除いた。Zoteroへの追加・修正、
モデルや外部規準の取得、新規API、統計計算、CIの再実行は行っていない。

以下は、これまでの設計・実装を各追加時点の状態とともに残した記録である。

**2026-10-05の優先順位修正**：心理言語学・EFL/SLA研究者の具体的な作業に照らすと、連続n-gramと実在規準表を使う刺激語・項目の分析が不足している。下記M4の境界を保持したbigram/trigram抽出・頻度集計とローカル参照表への照合を実装した。次は実在資料からこの入力を作る境界検証と参照資源の選定、M2を利用した心理言語学的規準の実用例を優先する。M番号は既存項目の識別子として維持するが、番号順にすべて完了してからM4へ進む計画とはしない。公開手続と新機能の開発優先順位を分け、機能不足を公開用ガイドの充実で解決済みとは扱わない。語義・依存構造・不連続MWEはこの初期範囲の後に評価する。

**同日の実装更新**：`lexdiv_read_masc()` と `lexdiv_as_quanteda()` に続き、`lexdiv_ngram_compare()` を追加した。同じ対象の隣接bigram/trigramを複数参照で評価し、各参照のcoverage・分母と、全参照で値の定まる共通項目での平均・基準との差を返す。Mini-MASCの1文書を対象として取り置き、残りの話し言葉4文書／書き言葉3文書で処理を確認した。quanteda連携で4語以上とKWICも利用できるが、ldfreq自身の参照プロファイル・比較APIは2・3語に限定する。続いて公式MASC 3.0.0とOANC GrAFを取得・照合し、MASCの厳密な読込は392文書中122文書に限られることを確認した。全体対応を宣言せず、境界・注釈の不一致を解決する方針と資料構成の影響を次に検討する。文書単位の分割集計 `lexdiv_ngram_reference_build()` を追加し、受入れた122文書で算術とメモリを検証した。

**日本語への拡張（同日更新）**：M6の最初の入力経路を実装した。`lexdiv_import_annotations()` は完全な注釈表と原文の一致を検証し、元の位置・語形情報・欠測・辞書宣言を保持する。gibasa 1.1.3とunidic-lite 1.0.8によるRだけの実解析から、既存の指標・n-gram・quanteda・RDS保存まで検証した。必須依存は増やさず、解析器・辞書・コーパスは同梱しない。当時はTUBELEX日本語の適合検証、分割が変わる比較、日本語研究での妥当化が未完了だった。分割比較は現在の段階3でAPI・作成例を実装済み。TUBELEX等の後続作業は下記の各検証記録を参照し、研究上の妥当化とは区別する。

#### 心理言語学・EFL/SLAの研究作業との対応

| 研究者の作業 | 現状 | 次の成果物と成立条件 |
|---|---|---|
| 作文・発話に現れる語の連なりを調べる | 明示的な区間・位置からbigram/trigramを抽出。Mini-MASC Penn読込とquanteda連携を追加し、4語以上とKWICも利用可能 | 対応する資料・層を拡張し、参照を変える比較を検証する。機械的なn-gramをすべて慣用表現とは呼ばない |
| 連語の頻度・結び付きと発達・熟達度を調べる | `lexdiv_ngram_reference()` と `lexdiv_ngram_profile()` で頻度・coverageを追加。MI/t-score/方向別関連度は未実装 | 適切な参照資料、同じ分割規則の共起数・位置別周辺度数・機会数、未照合とゼロ頻度の区別。trigramの関連度は定義を別途確定する |
| 語彙判断・読解実験の刺激語を選ぶ／統制する | caller-supplied normsのlookup・batch・欠測は実装済み。実在規準表の導入手順は不足 | 項目IDを保つ語頻度・文字長・AoA・具体性・親密度等の表、規準ごとの母集団・版・尺度・欠測。項目別出力を主にし、文書平均だけにまとめない |
| 産出語彙の心理言語学的特性を記述する | 複数規準の平均・coverageは実装済み | 実在資源を1件ずつ検証した読み込み例と照合診断。母語話者AoAをEFL学習者の習得順序や難易度へ読み替えない |
| 項目特性を反応時間・正答率・反復測定と結ぶ | 二値回答比較は実装済み。RT専用処理や推論モデルはない | participant/item/task/occasionを保持したlong形式への結合例。RTを二値回答APIへ投入せず、欠測・誤答・除外と混合モデル等の分析を既存Rツールにつなぐ |

研究上の根拠：Kim, Crossley, & Kyle (2018), [doi:10.1111/modl.12447](https://onlinelibrary.wiley.com/doi/10.1111/modl.12447) の出版社要旨は、L2作文・語彙熟達度・縦断変化に関して、単語特性とbigram/trigramの頻度・関連度を複数の次元として報告している。Siyanova-Chanturia, Conklin, & van Heuven (2011), [doi:10.1037/a0022531](https://pubmed.ncbi.nlm.nih.gov/21355667/) の研究要旨は、L1・熟達したL2話者の視線計測で句頻度を検討している。これらは複語単位を開発の中心課題にする根拠であり、特定得点の普遍的優位性や現在のldfreqの妥当性を承認する証拠ではない。今回は書誌・要旨の確認で、全文に基づく再現設計は未実施。

規準表の候補として、[Brysbaert, Warriner, & Kuperman (2014)](https://biblio.ugent.be/publication/5774089) の具体性と、[Brysbaert & Biemiller (2017)](https://biblio.ugent.be/publication/8535511) の語義別AoAを著者機関の説明で確認した。構成概念・測定法・単語／複語／語義のキーが異なるため、同じ列名への機械的変換はしない。データ本体・ライセンス・欠測コード・版の確認と、研究目的に合う資源の選定は次の作業であり、取得・同梱済みとは記載しない。

### 1. 利用者の問題とパッケージの貢献

主な利用者は、英語母語話者・追加言語話者の作文、自然会話、学術・報道等の文章、教材をRで分析する研究者・教師である。母語話者の使用を単独で記述する研究も中心的な用途に含める。同じ「語彙多様性」や「語彙レベル」という名前でも、語の単位、分割、窓幅、参照資源、未照合語の扱いによって結果が変わる。利用者が論文の方法を再現し、異なる結果の原因を調べられることを目標とする。

訴求文の軸：

> ldfreqは、英語テキストの語彙多様性と参照語彙プロファイルをRで計算し、前処理、語の単位、指標の定義、パラメータ、照合率、除外項目を結果と一緒に保持する。分析条件によって何が変わるかを点検し、再現可能な方法記述につなげられる。

新しい数式を発明した、指標が多いほどよい、他ソフトより妥当性が高い、未照合語は難語である、という主張は採用しない。独自性は、明示的な比較条件、NJ8/TUBELEX等の資源、診断・再現手順を一つのRワークフローに組み合わせる点に置く。その有用性は具体的な失敗例と比較例で示す。

#### コーパスの範囲と、次に確かめる問い

母語話者コーパスをL2作文の「正解」だけとして使わず、それ自体の語彙使用の変異を研究対象にする。分析対象のコーパス、語の頻度を与える参照資源、特定の問いへの比較群は別の役割である。TUBELEXはYouTube字幕由来の参照資源であり、各話者の母語を認定する資料ではない。L1/L2を区別する場合は資料の参加者情報に基づき、不明をL1へ埋めない。

| 優先する問い | 設計と候補 | 得られる答えと限界 |
|---|---|---|
| 母語話者の使用の中で、レジスターや長さによる変動はどの程度か | 作文・自然会話等を別々に層化し、同一文書内で単位・窓幅・切出し位置を比較 | 各標本・条件における指標の挙動。高得点を母語話者の普遍的目標値にしない |
| 参照資料を変えると頻度プロファイルの解釈は変わるか | TUBELEXと、目的に合う書き言葉／話し言葉の資源を比較。語単位・分割・分母・版を記録 | 参照領域への依存性。異なるZipfの分母・平滑化・語彙表を同一尺度とみなさず、共通に照合できた語と資源固有のcoverageを分ける |
| L1/L2の使用は、比較可能な課題・条件でどう異なるか | 年齢・教育・課題・話題・媒体・時間制限・校閲を可能な範囲で揃え、著者／話者の反復を扱う | 条件付きの群比較。編集済み専門文と時間制限付き学習者作文の差をL1/L2だけに帰属させない |
| 個人が特定語義を理解・使用できるか | L1/L2いずれも対象にできるが、目的技能に対応する課題・採点・必要なら反応時間を独立に収集 | 特定の課題・語義での遂行。自然コーパスの未出現を誤答扱いしない |

候補は、英国・米国の英語母語話者学生の作文を収める [LOCNESS](https://corpora.uclouvain.be/catalog/en/corpus/locness)、友人・家族間の自然会話を収める [Spoken BNC2014](https://www.lancaster.ac.uk/news/articles/2017/researchers-release-largest-ever-public-collection-of-british-conversations/)、複数のレジスターを比較できる [COCA](https://www.english-corpora.org/coca/help/tour.asp)。開発者の公式説明を確認した候補であり、この変更では取得・分析・同梱を行っていない。各資料の取得条件、必要メタデータ、利用・再配布範囲を確認して分析用snapshotを固定する。一般英語コーパスという名称だけで全寄稿者が確認済みL1話者とはみなさない。

Granger (2015), [Contrastive interlanguage analysis: A reappraisal](https://research.dial.uclouvain.be/entities/publication/1e2169fc-3327-4f29-8f6a-58ec6eb6c81e) の著者所属機関が公開する要旨も、比較における変異の役割を明示している。ここでは書誌・要旨を確認した範囲で参照し、本文の具体的方法を追試済みとは扱わない。

実装の入口は既存batch/profile APIを使う。独立したmetadata表に corpus/version、document、author/speaker、言語背景の根拠、register、task/topic、時期を残し、document IDで結合する。会話全体・話者turn・一定範囲のturn列のどれを分析するか、転記タグ・フィラー・言い直しの扱いを先に決める。話者ごとの発話だけを連結すると会話上の隣接関係が変わる。全コーパスを一つの文書にして無関係な境界をMATTR窓がまたぐ処理は避ける。XML・転記形式への対応はtokenizerと別の入力処理として評価する。

この範囲拡張に新しい「母語話者モード」は不要。語の単位と資料の条件を保持する既存の設計を生かし、利用例と外的検証の対象を広げる。一般コーパスの記述には認識・意味想起テストを要求しない。

#### 公開できる実例と、L1の研究設計を分ける（2026-10-05）

ユーザーの指摘を反映し、公開用実例を既成のコーパスや母語話者資料に限定しない。ICNALE GRAの原文は再配布しない。LOCNESSも公式配布ページに非商用・申請・第三者再配布の制約があるため、公開fixtureの代替とはしない。無料閲覧と再配布許可を区別し、論文ごとの明示的な利用条件を確認する。

新しい `open-access-papers` vignette と `inst/examples/open-access-papers.R` は、CC BY 4.0が明示されたJOSSのtidytext・tokenizers・quanteda論文を使う。公式JATSのコミットとSHA-256、DOI・全著者・ライセンス、抽出した段落と除外範囲を保存する。本文は明示実行時だけ取得し、パッケージへ同梱しない。R内でtokenize→指標→NJ8→診断→metadata結合→保存・再読込まで進められる。XML解析用の `xml2` は任意依存。TUBELEXは既存の別tokenization手順につなぐ。

この例は著者のL1を未確認のまま保持する**学術英語の実例**であり、母語話者コーパスとして扱わない。3論文は目的抽出で著者の重複もある。レジスター効果・個人能力・ソフト間の優劣を推定するデータではない。実際のR利用者による操作観察や、L1情報を確認した多レジスター研究は引き続き別の検証課題である。

公開までの直近順序は、(1)この実例と利用文書を確定、(2)同一ソースの証拠を再利用して変更範囲を確認、(3)既存PRへまとめて反映し必要なCIを1回採用、(4)リポジトリ・配布物・サイトの匿名アクセスと版を揃える、の順とする。認証付き確認でリポジトリはPRIVATE、Pagesは公開・mainのルートを参照していた。最新の成功CIは `13d580fa` に対するもので、その後のローカル追加機能を含まない。公開状態の変更・サイト配備・CRAN提出はまだ行っていない。

### 2. 現在地：実装と証拠を分ける

| 項目 | 現在の状態 | 次に必要なこと |
|---|---|---|
| 語彙多様性12指標、定義違い、plan/grid、batch | 実装済み | 既存の定義と境界を維持する。新しい名前の同等指標を重複実装しない |
| R内の英語tokenizer、生テキストbatch | 実装済み。Unicode既定値を維持 | 対象表現の例と限界を示す。TUBELEX Treebank互換と称さない |
| lemma/flemma・UPOSを伴う内容語選択 | 明示的な注釈入力を実装済み。textstemは任意 | 注釈資源の同一性と変換履歴をさらに明確にする。POS推定済みと誤認させない |
| NJ8、TUBELEX、単文書generic norm | 実装済み | 頻度、照合率、認知的規準を別の概念として報告する |
| `nj8_diagnostics()` | **今回実装**。未照合語と語形対応の頻度・文書数、文字列変換のフラグを返す | ローカル検証・文書反映は完了。公開対象commitのCIと公開URLを確認する |
| `lexdiv_compare_annotations()` | **追加実装**。原文・分割を照合し、lemma/UPOS/flemmaの変更と前後のprovenanceを返す | 辞書の内容同一性記録を追加済み。POS/形態モデルの評価は別途必要 |
| `tubelex_diagnostics()` | **追加実装**。頻度の比較表、coverage、未照合語・正規化履歴、空・失敗文書を保持 | 資源特徴と学習者の遂行を別に扱う。employabilityの妥当化は未実施 |
| `lexdiv_compare_responses()` | **追加実装**。二値回答の複合キー検査、方向別比較、欠測、層別と分母 | 採点済み回答の記述。独立な採点・妥当化や未記録の受検予定を自動確認するものではない |
| `lexdiv_mattr_profile()` | 実装済み。局所窓と位置別exposureを保持 | 位置依存を説明する比較例に再利用する |
| `lexdiv_norm_profile_batch()` | **追加実装**。既存B0/B1を再利用し、共有資源の1回検査・全体行数上限・文書別欠測を保持 | 単文書との一致、独立算術、metadataとの結合・保存を確認。公開対象でのCIは別途必要 |
| `lexdiv_ngrams()` / `lexdiv_ngram_reference()` / `lexdiv_ngram_profile()` | **追加実装**。隣接語列・ローカル参照頻度・coverage、完全表の標本ゼロと不完全表の未掲載の区別 | 入力の境界と資源選定の妥当性は別途検証。自動文分割・関連度・標準大規模資源は未実装 |
| `lexdiv_read_masc()` / `lexdiv_as_quanteda()` | Mini-MASC Pennの注釈・原文位置を保ちquantedaへ接続。reader 0.2.0でMASC 3.0.0のmodern headerも受ける | MASC 3.0.0は392文書中122文書を受入れ、270文書を厳密条件で拒否。全体対応・OANC対応は未達。非ASCIIのquanteda取込はUTF-8 localeが必要 |
| `lexdiv_ngram_reference_build()` | **追加実装**。全文書の出現表を保持せず、文書単位のchunkから頻度・文書頻度・分母・入力記録を蓄積 | 異なる語列と文書IDはメモリに残る。小さいchunkでは遅くなる。122文書の部分集合で検証済み、OANC規模は未検証 |
| `lexdiv_ngram_compare()` | **追加実装**。同じ対象・各参照のcoverage・共通項目での平均と基準との差を保持。Mini-MASCの文書IDを分けた例で独立算術と一致 | 共通に計算可能な項目には完全参照の標本ゼロも含む。参照の代表性・十分な標本数・優劣は認定しない |
| ICNALE GRA予備検証 | ローカル分析済み。原文140、校閲140、学習者の相関分析136 | 評定者・課題・語単位の影響と独立標本での再現を別々に検証する |
| 公開 | 開発版。今回の新機能はローカル差分 | 必要なCI、配布物、公開URLと文書を確認して公開判断する |

NJ8はユーザーが確認したJACETの利用許可と出典明記の方針を採用済みであり、許可の取り直しを開発の前提にしない。ICNALE本文・個別評定はローカルの研究資料であり、パッケージの公開fixtureには含めない。

### 3. 文献から何を採用し、何をまだ言えないか

Zoteroで `lexical diversity`、`lexical sophistication`、`lemmatization` を検索し、以下の8論文の書誌・要旨を確認した。同じKyle et al. (2024)の重複登録は一つとして扱った。初回は書誌・要旨のみを確認した。その後、追加登録されたCaltabellotta et al. (2026)、Bestgen (2024, 2025)の添付本文で方法・結果・限界を確認した。Webでは出版社、著者・開発元、公式パッケージ文書を確認した。これは機能の優先順位を決めるための対象を絞った調査であり、系統的レビューや全文に基づく追試設計の完了ではない。

| 根拠 | 本ロードマップへの具体的な反映 | 過剰に一般化しない点 |
|---|---|---|
| Caltabellotta et al. (2026), [doi](https://doi.org/10.1016/j.asw.2026.101039), Zotero `JJLFZD7S` | lemmaの作り方と全語／内容語の選択を明示する。本文のcustom schemeは動詞の時制・法等の細分であり、辞書修正とは区別する | 同研究での既定lemma・全語の関連の強さを、全課題・全集団の最適条件へ拡張しない |
| Bestgen (2024), [doi](https://doi.org/10.1111/lang.12630), `WW4JRLXK` | 文章長と計算窓・標本サイズの感度を区別し、plan/gridを再利用する | 短い標本で長さとの相関が小さいだけでは、長さへの不変性を証明できない |
| Bestgen (2025), [doi](https://doi.org/10.1016/j.rmal.2024.100168), `5ZW9GUW2` | 既存の局所MATTR・exposureを利用者の説明へ結び付ける | MATTRだけを無条件の推奨指標としない |
| Kyle, Sung, Eguchi, & Zenker (2024), [doi](https://doi.org/10.1017/S0272263123000402), `RRSQ5JDL` | 長さ、課題間安定性、熟達度との関連を別の検証項目にする | 口頭課題の知見を今回の作文へ直接移さない |
| Kyle, Crossley, & Jarvis (2021), [doi](https://doi.org/10.1080/15434303.2020.1844205), `A93563CV` | 語彙多様性そのものへの人間の判断と、総合作文評定を区別する | ICNALEのHolistic/Complexityを語彙多様性の直接評定と呼ばない |
| Eguchi & Kyle (2020), [doi](https://doi.org/10.1111/modl.12637), `7ZSXAIFN` | 頻度・具体性・複語表現などを別軸として扱い、generic normのbatch化を準備する | 多数の指標を足した総合scoreや、普遍的な因子構造を固定しない |
| Eguchi (2022), [doi](https://doi.org/10.7820/vli.v11.2.Eguchi), `EY5Y5WRG` | 内容語・機能語・複語表現の役割を検討する後続段階を設ける | 口頭面接での結果や予測精度をRパッケージ自身の性能として使用しない |
| Hu, Lu, & Hu (2025), [doi](https://doi.org/10.3758/s13428-025-02741-z), `QWM2IMSN` | 将来は語義に対応する注釈を受け取れる構成を検討する | 語形だけのNJ8レベルを語義別CEFRとみなさない。重いモデルを既定依存にしない |

BestgenとKyleらでは、HD-D等の長さへの感度に関する記述・評価が一致しない部分がある。要旨だけから一方を採用して「指標Xが常に最良」と結論付けず、全文・補足の方法、長さ操作、パラメータ、資料特性を照合してから追試条件を固定する。

#### 2026-10-04の追加登録を確認した結果

最新の関連登録3件は以下の同一DOIの論文だった。先行研究の件数を3本増やして数えず、既存の根拠との対応を保持する。Zotero上の統合・削除は行わない。

| 論文 | 今回確認したitem key | 前回参照したitem key | 次の具体化 |
|---|---|---|---|
| Caltabellotta et al. (2026) | `8MU4UT3N` | `JJLFZD7S` | default/custom lemmaと全語/内容語の要因を区別。surface/lemma比較を同研究の追試と呼ばない |
| Bestgen (2024) | `WU3ZJ43M` | `WW4JRLXK` | 原文の長さ、切出し位置、MATTR窓幅、HD-D標本サイズを別の設定として保存 |
| Bestgen (2025) | `5L5MEMLR` | `5ZW9GUW2` | 語数・頻度を固定した位置変更の反例を、局所MATTRの使い方へ追加 |

追加登録の確認時点では書誌・要旨を参照した。その後の本文確認と実装への反映は [本文確認と注釈比較の記録](ANNOTATION-COMPARISON-20261004.md) に記録した。補足の取得は403となり、補足コードや追試は未確認である。Bestgen (2024)の[出版社ページ](https://onlinelibrary.wiley.com/doi/10.1111/lang.12630)には、補足S1（位置の重み）、S3（sampling）、S7（HD-Dの長さ感度に関する議論）が示されている。追試仕様を固定する際には、この補足とKyleらの方法・対象資料を照合する。[著者サイトのBestgen (2025)原稿](https://perso.uclouvain.be/yves.bestgen/images/RMAL24.pdf)はpreprintで、最終版と実証分析の範囲が異なるとの表示があるため、最終版の代理として扱わない。

今回の追加確認によってM1を最優先とする順序は維持する。実装の第一単位として、既存APIによる「同一文書×語単位×窓幅」の実行例と、位置のみを変えた手計算可能な反例をvignetteに追加した。その後、同じ原文・分割の注釈を比較する `lexdiv_compare_annotations()` を実装した。その後、辞書指定・内容ハッシュ・照合ロケールの記録も実装した。汎用の条件比較APIとPOS推定は未実装である。

複語表現を後続候補に置く根拠には、二つの学習者作文資料でformulaic measuresの寄与を調べた [Bestgen (2017)](https://doi.org/10.1016/j.system.2017.08.004) もある。一方、TUBELEXの評価対象は語彙判断時間・親密度・語の複雑さ等であり、その頻度を作文能力の直接尺度に置き換えない。[TUBELEXの公式説明](https://github.com/naist-nlp/tubelex) を参照する。

### 4. ICNALEの結果が優先順位を変えた理由

今回の原作文140件では、平均NJ8照合率が表層形83.3%、辞書lemma96.3%だった。`is`、`students`、`jobs`等の基本的な語形も表層形では未照合となった。辞書では `second→2` 等も57 tokensに生じた。したがって、単に照合率を返すだけでなく、照合単位と変換過程を見せる必要がある。

学習者136名で表層形MATTR50とHolisticの順位相関は .451、文章長と地域を調整した偏順位相関は .281だった。評定者を固定した条件付き区間であり、一般的な妥当性の確立や、未見課題での予測性能ではない。

個別評定から再計算した平均とSummaryが3作文で異なり、欠測や範囲外評定もあった。検証例には入力の照合を含める。Sophisticationは内容・発想、Complexityは語彙・文法を含むため、構成概念に対応する問いと評定を選ぶ。校閲版は介入後の学習者能力を表すデータとは扱わない。

ローカル成果物：workspaceの `analysis/icnale-gra/report.html`、`analyze.R`、`lemma-sensitivity.R`。本文と評定を含む派生データは公開パッケージへ移さない。

### 5. 段階別の実装計画と完了条件

順序は依存関係によるものであり、独立した研究をすべて終えるまで0.2.0を公開できない、という意味ではない。既存機能の明確な説明とソフトウェア検証で公開可能な範囲を確定し、妥当性の主張は実際の証拠に限定する。

#### M0：今回の追加を公開可能な単位へまとめる

**利用者の操作**：`profile <- nj8_profile_batch(prepared, unit = "surface")` の後に `audit <- nj8_diagnostics(profile)` を実行する。

**追加済み**：`$unmatched_terms` は照合キーごとの延べ出現数・文書数、`$unit_mappings` は元の語形・選択単位・照合キー・照合状態の対応を返す。数字・空白を含む単位が新たに生じた場合のフラグを返す。文書別coverage、注釈欠測による除外、出典・前処理情報を残す。元profileのlookupを再利用し、資源の再読込や計算式変更を行わない。

**完了条件**：手計算例、同語の文書内反復と文書間出現の区別、空文書・全件未照合・全件除外、正規化、保存再読込、入力非破壊、既存APIとの統合を検証する。help、NEWS、README、vignette、pkgdownに反映し、配布sourceのcheckを通す。新機能のCIと公開URLの確認は、実際の公開対象ができた時点で行う。

2026-10-04のローカル検証は完了：配布sourceの `R CMD check --no-manual` はStatus OK、testthat 4,673件はFAIL/WARN/SKIPすべて0、7 vignettesを構築・再構築した。API監査は33 exports・30 S3 methods・16 help topicsを確認した。ICNALEの保存済み結果と照合し、未照合語の延べ頻度・文書数が表層形931種類／lemma272種類で一致、数字化57件も検出した。pkgdownは環境上の失敗箇所から再開し、全工程と最終検査を完了。86 HTMLページのローカル参照先に欠落なし。ブラウザでの全ページ目視、今回の差分の新しいcross-platform CI、公開・CRAN提出は未実施。

#### M1：条件比較と注釈の再現性

**利用者の問い**：「窓幅や語単位を変えても、同じ作文の差・順位は保たれるか」。

**実装方針**：既存 `lexdiv_metrics_text_batch()`、`lexdiv_plan()`、`lexdiv_profile_batch()` を組み合わせる比較手順を先に固定する。繰り返しが実際に残る部分だけを、候補名 `lexdiv_compare_conditions()` の単一入口へまとめる。この候補名はまだ公開APIではない。

入力は、同じdocument ID集合を持つ明示的な条件とprepared documents。出力は `condition_id × document_id × request` のlong結果、条件定義、前処理・分母、欠測理由、比較可能な文書数。条件間で文書が黙って落ちることを許さない。原文／校閲文の違いは同じ元本文での前処理差と区別する。差や順位相関を示す場合も対象指標・条件・有効ペア数を明示し、異なる尺度を平均した総合scoreや最適条件の自動選択をしない。

注釈については、現在のtextstem本体のversion記録に加え、使用辞書のversion・内容同一性、利用者が修正した対応、変更前後を保存する方法を定める。既存 `method="supplied"` の流れを再利用する。人手で調べる対象は無作為部分と、数字化・空白化・未照合頻出語等の問題が疑われる部分を区別し、後者から一般的な誤り率を推定しない。

**完了条件**：明示的loopとの一致、条件順・document ID・欠測の保存、比較不能理由、annotation coverage、辞書を変えた再現例、RDS round trip、論文の方法に転記できる設定表。内容語分析はUPOSがあるときだけ使い、textstemのみで品詞が得られたと装わない。

M1は「比較手順」「注釈・辞書の記録」「任意POS経路の評価」に分けて実装する。内容語分析をRで完結させる候補には [udpipe](https://bnosac.github.io/udpipe/en/index.html) がある。採用前にモデルの版・入手手順・対象レジスター・話者群での注釈精度を確認し、既存tokenと一対一対応しない注釈を位置だけで結合しない。基礎分析の必須依存や暗黙のモデルdownloadにはしない。

追加文献を踏まえたM1の実装単位と受入条件：

1. **同じ文書での比較手順（実行例を追加済み）**：surface/lemmaと窓幅を明示的に組み合わせ、文書ごとの計算不能理由を残す。表示表に加え、完全な結果と注釈をRDSへ保存する。例の小さな窓幅を推奨値にしない。
2. **注釈条件の比較（差分監査・辞書記録を実装済み）**：同一原文にdefault/customの注釈を別々に作り、全語/内容語と交差させる。UPOSの由来、辞書版、修正対応、注釈欠測、選択後の語数を記録する。内容語列の窓幅は選択後の語数であり、原文の同じ幅ではないことを示す。
3. **長さ・窓幅・位置の比較（実証手順を確定後）**：`source_document_id`、元のtoken位置、切出し長、指標のパラメータを別々に保存する。連続部分の切出しと無作為抽出は別の操作として扱い、同じ作文からの部分標本を独立な作文として検定しない。順位相関が高いことと得点の一致も区別する。
4. **専用入口の必要性を評価**：上の手順で残る反復・誤結合を確認してから `lexdiv_compare_conditions()` の仕様を決める。専用APIを追加する場合は、任意の条件組合せで文書ID・欠測・仕様の同一性を保持し、手動loopとの一致を必須にする。

本文確認を踏まえ、default/custom schemeは基底lemmaと形態情報で細分した語単位の比較として明示する。現行 `unit = "lemma"` は供給された文字列を数え、POS・時制・法を自動付与しない。UPOSで内容語を選ぶこととPOS別typeを数えることは別の操作である。語彙表への照合はその参照単位に合わせ、形態情報を付けたキーをNJ8へ直接照合しない。新しいガイドでは2注釈×2語選択の著者作成例を追加した。

位置診断では、標準MATTRと位置別の窓への包含回数を併記する。包含回数で得点を補正した新指標や、全体得点から位置の「因果的寄与」を算出する機能は追加しない。固定頻度の反例は数式の性質を示すソフトウェア検証であり、HD-Dの外的妥当性や全条件での最適性の根拠にはしない。

注釈比較API追加後のローカル検証：新しい配布sourceの `R CMD check --no-manual` はStatus OK、testthat 4,750件はFAIL/WARN/SKIPすべて0。7 vignettesと34 exportsの文書・API整合を確認した。証拠は `reviews/ldfreq-annotation-20261004/evidence/` に保存している。前の4,673件の記録とはソースが異なる。

辞書記録と文脈別点検の実装を追加した。`lexdiv_lemmatize(method = "textstem")` に辞書を指定でき、同じ版ラベルでも内容差を検出する。ICNALEでは原文140件の旧注釈を再現後、文脈を点検した序数・列挙55箇所を別schemeへ変更した。平均NJ8照合率は96.29181%から96.46498%へ変化し、MATTR50とHD-D42は全作文で不変だった。無作為点検30箇所とは別に保存し、注釈精度向上や能力差とは解釈しない。詳細は [辞書記録・文脈点検・再実行の記録](DICTIONARY-REVIEW-20261004.md) を参照する。

辞書対応後の検証は4,817 PASS、全体check Status OK。helpの契約番号の後続訂正は限定checkで再確認し、数値テストの同一ソースの証拠を再利用した。7 vignettesと34 exportsの整合を確認。詳細は上記記録、証拠は `reviews/ldfreq-dictionary-20261004/evidence/` に保存した。

**次に取り組む範囲**：M1の長さ・位置・パラメータの比較を、原作文IDと切出し位置を保持する明示的なRスクリプトとして具体化する。既存plan/gridと局所MATTRを再利用し、論文の補足と方法の未確認部分を解消してから一般化した結論を出す。文脈判断を自動正解扱いせず、独立した人間の注釈点検は別の検証課題として残す。M2以降の機能追加を今回の辞書機能の完成条件へ追加しない。

#### M2：複数の語彙規準をコーパス全体で扱う

**利用者の問い**：「複数のコーパス・文書に同じ参照表を適用し、頻度・親密度・習得年齢などを、それぞれの意味と照合率を保って比較したい」。

既存single-document `lexdiv_norm_profile()` の計算を再利用し、`lexdiv_norm_profile_batch()` を追加実装した。既存のworkspace `r-package/NORM-PROFILE-BATCH-CONTRACT.md` とB1試作を出発点とし、同じ設計を新規に作り直さない。caller-supplied tableから始め、特定規準表の同梱をbatch APIの条件にしない。

**完了条件**：共通資源を一度だけ検証、全体の行数上限をlookup前に確認、singleの明示loopと順序・数値・欠測・metadataが一致。token/type weighting、resource coverage、value coverage、matched-but-missingを保持する。単語の具体性と語彙頻度等を一つの「洗練度」に合成しない。

実装はbatch契約0.1.0と単文書契約0.1.0を区別し、37番目のexportとbounded printを追加した。追加依存・新規データ同梱はない。 ローカル配布sourceのcheckはStatus OK、5,006 PASS（FAIL/WARN/SKIP 0）。9 vignettes、37 exports・31 S3 methods・20 help topics、PDFマニュアル構築を確認した。新規89件はCロケールでも成功。公開対象revisionのcross-platform CIは未実施。`corpus-reference-profiles.Rmd` は著者作成の文章と規準表から、語単位の指定、文書metadataのID結合、3種類のcoverage、空文書、RDS再実行まで示す。異なる規準の単位を揃えずに合成する機能や、文書を自動的にプールする機能は加えていない。


#### M3：R内で参照コーパスと整合する頻度分析

**利用者の問い**：「Pythonの準備なしで、参照コーパスと整合した英語頻度分析を行いたい」。

現在の英語tokenizerと同梱TUBELEX Treebank版は同一の分割規則ではない。coverageが高いことを互換性の根拠にしない。まずRで実装するTreebank準拠経路と、上流の別tokenization variantを明示的な別資源として使う経路を比較する。上流の固定版・規則・負担を確認して一つを選び、既存資源を黙って差し替えない。

**完了条件**：短縮形、所有格、略語、引用符、ハイフン、数字、Unicode、文境界について上流の固定規則との比較fixtureを通す。資源版と分割器を対にして記録する。新資源を採用する場合はその出典・配布範囲・変換の確認を行う。整合性を示せない経路は感度分析として明示し、compatibleとは表記しない。

#### M3に関連する研究軸：lexical employability

ユーザー指定のKremmel & Schmitt (2016)（Zotero `3YK6ZI4B`、[DOI](https://doi.org/10.1080/15434303.2016.1237516)）は、語を実際のコミュニケーションで使用できることを問題とし、読解に必要な意味想起を間接的に調べている。操作のしやすさや就業可能性の意味ではない。TUBELEXは語形の頻度・分布を記述する参照資源であり、学習者の意味認識、想起速度、適切な使用を直接示さない。

**追加済み**：`tubelex_diagnostics()`、`lexdiv_compare_responses()` と `vocabulary-knowledge-and-use.Rmd`。同一語形の異なる語義に別item IDを保持し、learner×itemの認識・意味想起とTUBELEX値を接続する著者作成例を実行した。方向別の不一致、異なる分母、片側／両側の欠測、未照合を保ち、資源を能力得点へ読み替えない。回答比較APIは複合キーの重複と二値採点を検査し、形式・時点・採点版による層別集計とCSV入力を支援する。検査できるのは入力の整合性であり、採点規準の適切さや未記録の受検予定は研究側で確認する。

回答比較API追加時点のローカル検証は4,917 PASS、FAIL/WARN/SKIP 0、配布sourceのcheckはStatus OK。8 vignettesと36 exportsの整合を確認し、資源bytesは前回から変更していない。CSV入力・反復時点の層別・欠測・分母・RDS保存再読込を著者作成例で確認した。実在学習者における妥当性検証とは区別する。

**個人のemployabilityを問う場合の実証の入口**：同じ参加者・同じ語義における認識と意味想起の対応を先に確かめ、頻度のみの基準モデルにchannel prevalenceが追加情報を持つかを調べる。その後、目的技能に合った文脈遂行を独立に評価する。学習者・項目の反復、提示順、採点規準、汎化先を設計に含める。ICNALEの一般作文評定だけでは語ごとのemployabilityは検証できない。

研究軸の詳細、論文で確認した方法と限界、実装・検証の範囲は [TUBELEXとemployabilityの記録](TUBELEX-EMPLOYABILITY-20261004.md)。R内でのTreebank準拠や別資源variantの採用というM3の技術課題は残る。頻度の新指標や自動employability判定器を追加することを目標にしない。

#### M4：複語表現・連語プロファイル（抽出・参照頻度を実装、境界適応と関連度は継続）

**利用者の問い**：「個々の単語に加えて、語の組合せの慣用性はどう異なるか」。

初期APIは明示的な句の成分キーとcaller-supplied reference countsを受ける限定的な設計とした。生テキストからの抽出には文境界と除外位置を必要とする。句読点や除外語を取り除いた単語列を単純に連結して、架空の隣接関係を作らない。`quanteda.textstats`にもcollocation機能があるため、抽出・連携の再利用を比較し、同等機能の再実装を目的にしない。

**完了条件**：bigram/trigramの定義、重複、文書・文の境界、OOV、参照コーパス、機会数と周辺度数を固定する。MI/t-score等の分母・平滑化・低頻度境界を手計算で確認する。unigram頻度やlanguage-model確率から、観測共起数を復元できると仮定しない。外的関連はジャンル・課題をまたいで検証する。

最初の実装単位は次の順にする。

1. **隣接語列の抽出と頻度**：bigram/trigramを対象に、document ID、明示的なsegment/sentence ID、元のtoken位置を保持する。文・文書・削除箇所を越えない。たとえば `make a decision` から `a` を除いた後に `make decision` を連続bigramとして作らない。空文書・短い区間・重複出現・句読点・改行・Unicodeを手計算例で検証する。文境界の既存実装やquantedaとの連携を評価し、句点分割だけを万能な文分割としない。
2. **参照頻度と診断**：利用者が取得した参照コーパス／集計表から始め、同じ分割・除外条件でn-gram出現機会数と文書数を記録する。文書別頻度・文書分布・参照表coverageと出現箇所を返す。同梱TUBELEXの単語集計表は、連続語の共起情報を保持しないためn-gram資源の代用にしない。公開論文3件は処理例に使えても、一般英語の安定した連語頻度規準にはしない。
3. **関連度**：bigramの観測共起数、各位置の周辺度数、同じ標本空間の機会数を保持し、MI/t-score/方向別指標を仕様・手計算に照合する。低頻度で値が大きい場合も元の頻度を併記し、ゼロ・未照合・未定義を区別する。異なる定義の指標をひとつの「慣用性得点」へ合成しない。

JOSS実例の抽出テキストは、参考文献参照・コード・図等を除いて段落を結合している。現在の単語分析用の列をそのままn-gram用に流用せず、除去した要素の境界と文の区切りを保持する入力経路を別途確認する。段落だけを保持しても、段落内の除去箇所を跨ぐ架空の連続性は防げない。

##### n-gram参照資源を同梱しない実装方針

コーパスを使う機能とコーパスの再配布は別の作業である。初期のn-gram機能は、分析コード・入力仕様・独自作成の小例だけを配布し、利用者が利用条件内で用意した文書／集計表をローカルで処理する。参照データをRパッケージ形式にする必要はなく、data.frame、CSV/TSV、RDSで渡せる。データの版・ハッシュ・出典・分割設定は結果へ残し、参照本文を外部送信しない。

三つの処理を契約0.1.0として実装した。使い方は `vignettes/ngram-profiles.Rmd`、入力と結果の固定仕様は `inst/spec/adjacent-ngram-contract.json` に記録した。追加データ・依存・自動取得はない。

1. **抽出 `lexdiv_ngrams()`**：入力をdocument ID、segment ID、元のtoken位置、語形の表で受け、区間内で元の位置が連続する2語／3語だけを出現表へ展開する。削除後に位置を詰め直した入力からは元の隣接性を復元できないため、入力条件を明示する。外部参照なしでも対象コーパスのn-gram数・頻度・文書分布を計算できる。
2. **参照集計の構築／読込 `lexdiv_ngram_reference()`**：抽出結果または外部集計表から、成分語・n・出現頻度・文書頻度、n別機会数と総文書数、完全性の申告、設定と出典を持つ参照オブジェクトを作る。外部表は機会数・文書数を必須とし、上位項目だけの頻度合計を総機会数の代用にしない。完全表は頻度和と機会数の一致を検査する。位置別周辺度数の出力・関連度は今回の実装に含めず、後続仕様で同じ対象範囲から算出する。
3. **対象との照合 `lexdiv_ngram_profile()`**：対象文書の出現表を参照表に照合し、文書・項目・位置を保持して頻度とcoverageを返す。分母はn別の参照機会数で、word-token数ではない。token/type別の利用可能値の平均と、照合率・利用可能値率を保持する。関連度は計算しない。参照データを一度RDSに保存すれば、次回以降は原文の再処理を不要にできる。内部的な語列キーは単純な区切り文字結合による衝突を避け、成分語とnを保持する。

頻度表の収録範囲も入力仕様に含める。全観測項目を含む表での未出現、最低頻度で打ち切った表の欠落、照合キーの不一致、取得失敗を同じ0へ変換しない。完全表のゼロも、定義した参照標本中のゼロであり「英語では存在しない」を意味しない。初期APIは総機会数・文書頻度・総文書数のある表を対象とする。必要項目のない生頻度表は入力を受け付けず、不明値を推定して埋めない。定義した標本のゼロも、機会数がゼロなら正規化頻度は未定義として返す。

配布方式は、(a)利用者の手元の資源、(b)条件を確認した公式配布先からの明示的な取得、(c)再配布可能な小規模集計表の任意同梱、の順に検討する。別のデータパッケージに分けることはサイズ・更新管理の選択肢であり、再配布許可の代わりにはならない。頻度表に加工したという理由だけで自由に配布できると判断しない。原文・集計表・コードの各条件を確認する。

[textdataの開発元説明](https://emilhvitfeldt.github.io/textdata/) は、大きさやライセンスの理由でデータを同梱せず、取得・解析・ローカル保存を行う設計の先例となる。一方、[CRAN方針](https://cran.r-project.org/web/packages/policies.html) は実行時に取得する構成要素も権利確認の対象に含めている。ダウンロード方式を権利制約の回避策として説明しない。初期APIの動作確認は独自作成の小例でオフライン実行できるようにする。

**残る資源面の課題**：機能を実装できることと、利用者がすぐ使える大規模で適切な標準参照資源があることは別である。標準資源はまだ選定していない。話し言葉／書き言葉、時期、地域、語単位、集計の打切り、必要な周辺度数、利用・再配布条件を確認して選ぶ。分析対象の学習者データをそのまま外部の規準と呼ばず、目的に応じて対象・参照の役割と重複を明示する。公開論文3件の処理例を大規模な頻度規準の代替にしない。

**2026-10-05の実装検証**：修正後の配布物でn-gramテスト812件がPASS、FAIL/WARN/SKIPは0。初回全体検査で成功した既存5,006件はソース同一性を確認して再利用し、合計5,818件をカバーした（修正後に全体を再実行したという意味ではない）。最終 `R CMD check --no-tests --no-manual` はStatus OK、11 vignettes・実行例・40 exports／34 S3／21 help topicsの整合を確認。CSV・RDS再利用、Cロケール、独立した抽出手順との一致、完全表と省略表の差も検証した。pkgdownの101 HTMLページにローカル参照切れなし。証拠は `reviews/ldfreq-ngrams-20261005/evidence/`、初回の列順不整合・名前空間NOTEとその修正を含む経緯は `PUBLICATION-20261004.md` の追記に残した。初期の頻度機能の検証であり、文分割・標準参照資源・関連度や心理言語学的妥当性の検証完了ではない。

##### MASC・OANCの採用と参照資料の使い分け（2026-10-05）

**採用判断**：まずMASCの小例で入力と注釈の扱いを確認し、次にMASC全体のレジスター別参照、さらにOANCの大きい参照へ進める。利用・再配布の条件から候補にできる資料であり、「コーパスなので同梱できない」と一括して扱わない。ただし、全文と全注釈をRパッケージ本体に含めることを標準にはしない。

| 資料 | 公式説明・配布条件 | ldfreqでの役割と限界 |
|---|---|---|
| [MASC](https://anc.org/data/masc/) | 約50万語の書き言葉・話し言葉。[CC BY 3.0 US](https://creativecommons.org/licenses/by/3.0/us/)で共有・改変・商用利用が可能。帰属・ライセンス・派生物の変更表示を保持する | 文・token・POS等の注釈を使う読込例、前処理の比較、レジスター別の小規模参照。低頻度・長いn-gramの不安定さを示し、全英語の標準値と呼ばない |
| [OANC](https://anc.org/data/oanc/) | 約1,500万語。配布元は利用・再配布に制限がないこと、商用利用も含むことを明記 | より大きい参照頻度とレジスター比較。大きさだけで代表性や注釈精度が保証されるわけではない |

[MASCの構造説明](https://anc.org/data/masc/corpus/masc-structure/) は本文・注釈を別ファイルで結び、複数のtoken/POS層を区別している。総論の「manually validated」だけから全層・全版を正解データとみなさない。同ページはPenn層のタグが完全には手修正されていないことも記している。採用する配布物、層、版、参照関係と文字位置を確認する。MASC Sentence Corpusは特定の多義語の用例を選んだ別資料であり、一般頻度の分母を作るためにMASC本文へ足さない。

[OANCの構成表](https://anc.org/data/oanc/contents/) では話し言葉約322万語、書き言葉約1,141万語で、雑誌・生医学等の寄与も大きい。全体の延べ語数による頻度と、ジャンルを等しく重み付けした頻度は別の参照量として定義する。ファイルは会話全体・章・記事等の異なる単位であり、document prevalenceを人や会話相手の普及率に読み替えない。米国資料であることから全著者のL1が確認済みとは扱わない。

MASCはOANC由来の資料を含むため、両者を無条件に独立な検証集合と呼ばず、結合・対象／参照比較時には原資料ID、同一本文、部分的な抜粋の重なりを点検する。本文ハッシュだけでは抜粋や正規化違いの重複は見つからない。レジスター別の参照で結果が変わることは研究上の問いであり、目的の評定と最大相関になる参照を自動的に選ぶ機能にはしない。TUBELEXとの比較はまずunigramで行い、同梱TUBELEXのunigram表からn-gram共起数を作らない。

**配布形態**：再配布条件を明示した小さい実例は同梱候補にする。全体データは明示的に取得した公式アーカイブからRで読み、集計した参照をローカル保存する。便利な標準参照表を別途配布する場合は、版・出典・注釈層・処理規則・分母・完全表／打切り表の区別を一緒に固定する。コードのMITとデータの条件を混同しない。別データパッケージの新設は実測サイズと更新頻度を見て判断する。[CRAN方針](https://cran.r-project.org/web/packages/policies.html) もパッケージを必要最小限のサイズにすることを求めており、大量データの別扱いを認めている。チェック時に全コーパスを取得・再集計する構成にはしない。

**実行した小規模試行**：公式ページからMini-MASCのZIPを取得し、READMEの `Mini-MASC-1.0 / 2010-09-19` とSHA-256 `b2ad414a4c175970c1ca01b2cbcac4980eec186fd9a7cfeaac29e41adbb9e5a6` を固定した。配布URLのrelease日をコーパスの内容版と混同しない。`experiments/mini-masc-quanteda.R` は既存のxml2で8文書の579区間を読み、quanteda 4.5.0のword4で再分割した。句読点・記号を除いた位置に空きを残し、小文字化した6,483 tokensについて以下を確認した。

| n | 出現機会数 | 異なり数 | 検証 |
|---|---:|---:|---|
| 2 | 5,630 | 4,314 | quantedaと既存ldfreqの頻度・文書頻度・文書別機会数が一致 |
| 3 | 4,919 | 4,726 | 同上 |
| 4 | 4,283 | 4,249 | quantedaで実行。ldfreqの公開APIは2・3語のまま |

KWICも実行できた。試行では元のs/u区間を使い、文書頻度は区間の行列を原文書へ集約してから求めた。`make a decision` から `a` を除く小例では、quantedaの `padding = TRUE` で架空のbigramを防げることも確認した。境界を保持すること自体をldfreq独自の発明とは説明しない。

試行は**配布token/POS/lemmaの読込・検証ではなく、指定区間内の再tokenize経路**である。GrAFの複数regionを参照するtoken、注釈層の選択、一般的なUnicode offset対応、MASC 3.0.0全体とOANCの処理は未検証。元本文や注釈は成果物へコピーせず、集計と設定のみを `reviews/ldfreq-roadmap-20261004/evidence/mini-masc-quanteda-{counts.csv,probe.log}` に保存した。初回試行の疎行列に対するbaseの行列集計エラーはMatrixの公開集計関数に修正し、同じ試行を完走した。パッケージ本体・依存宣言を変更していないので全体checkは再実行していない。

なお、workspaceに既存の `OANC-GrAF` ディレクトリはあるが、今回確認したヘッダと本文3件は0 bytesだった。ローカルOANCを正常取得済み・分析済みとは数えず、原因も未確認として扱う。既存の空ファイルは変更していない。

**注釈を保持する公開APIへの実装（同日追記）**：上の再分割試行に続き、`lexdiv_read_masc()` はGrAF 1.0の `seg`・`s`・`penn` を読み、7,263個の配布token、579区間、8文書を保持する。annotation ID・lemma・POS・その他のfeature・原文・文字位置・ファイルのSHA-256を返す。Unicode codepointとUTF-16 code unitを明示指定でき、不連続token・重なり・区間外のtokenはエラーにする。PTB層には別の分割や重なりも見られたため、複数層を一括して対応済みとはしない。Python標準XML処理との独立照合で、全tokenの表層・lemma/POS・位置・区間が一致した。851 tokenに元々lemmaがなく、その欠測も保持した。

`lexdiv_as_quanteda()` はMASC以外の明示的なtoken/segment表も受け、各区間をquanteda文書とし、除外位置と末尾の空きをpaddingで保持する。再分割せず、戻したtoken列が入力と同一であることを確認する。`as.tokens()` が入力の空文字を落とす点、`dfm()` が既定で小文字化する点を検証し、接続処理とガイドで条件を明示した。非ASCII tokenはUTF-8 localeでのみ取り込む。ユーザーのlocaleを自動変更しない。KWICの位置対応は元のtoken objectに対するもので、結合・再分割後にはそのまま適用しない。

文字または数字を含む6,718 tokenを保持し、大文字・小文字を維持した注釈経路では、bigramが5,873出現／4,373種、trigramが5,166出現／4,877種、4-gramが4,528出現／4,461種となった。2・3語の頻度・原文書頻度は既存ldfreqとquantedaで一致し、279 KWIC hitsを原文位置へ対応付け、注釈・変換結果のRDS保存再読込も確認した。前掲の再分割・小文字化試行とは条件が異なるため、数値の大小を精度差として解釈しない。

追加したvignette `annotated-corpora` は独自作成・MITライセンスの小例でオフライン実行できる。コーパス本体は同梱せず、xml2とquantedaを任意依存として使う。実装・検査の記録は `reviews/ldfreq-masc-20261005/evidence/` と `PUBLICATION-20261004.md`。この段階で検証できたのは注釈の読込と既存集計への接続であり、一般的なMASC/OANC参照規準、心理言語学的妥当性、処理性能の優位性ではない。

##### 複数参照を同じ対象で比較する実装（2026-10-05追記）

`lexdiv_ngram_compare()` は既存の `lexdiv_ngram_profile()` を再利用する。各参照の平均・lookup coverage・value coverageを残したまま、全参照で頻度の値が定まる対象項目の共通集合、共通coverage、共通平均、明示した基準参照との差を返す。token/typeの重みを分け、文書を混ぜず、語句の成分キーと出現位置を保持する。完全表の未観測は分母が正なら標本ゼロとして共通集合に入る。不完全表の未掲載と分母ゼロは入らない。共通集合が空なら平均・差はNAとなる。参照を追加すると集合が変わり得るので、2資料だけを比べたいときはその2資料を渡す。

ガイドでは、同じ参照の打切りによって `choice_item` のbigram平均が166,666.67から333,333.33へ上がる例を使用した。共通項目 `make a` の頻度は同じなので差は0、共通coverageは1/2となる。これにより、項目の欠落による平均の変化と、同じ項目の頻度の変化を分けて説明できる。別の手計算テストでは、利用可能な値の平均では上昇して見えるものが、共通項目で比べると低下する例も確認した。既存のプロフィールの計算式は変更していない。

**実資料での処理確認**：Mini-MASCの `lw1` を対象として取り置き、headerの `catRef` がSPの4文書と、lw1以外のWRの3文書を参照とした。語形の大小文字を保持し、文字・数字を含むPenn tokenを選び、除外位置を保持した。対象と参照のdocument IDを分けた確認であり、資料間の全文・抜粋重複や母語情報まで独立性を検証した設計ではない。

| 参照 | n | 参照内の出現機会数 | 対象内で参照に観測された割合 | 対象token重み付き平均／100万機会 |
|---|---:|---:|---:|---:|
| SP 4文書 | 2 | 3,396 | 10.84% | 97.55 |
| WR 3文書 | 2 | 1,831 | 8.98% | 167.40 |
| SP 4文書 | 3 | 2,993 | 0.18% | 0.60 |
| WR 3文書 | 3 | 1,614 | 0.72% | 4.43 |

対象の出現機会数はbigram 646、trigram 559。両参照は抽出範囲の完全表で、分母も正なので、標本ゼロを含めれば共通coverageは1となる。これは観測率が100%であることを意味しない。特にtrigramの観測が極めて少なく、この小例を標準頻度・レジスターの優劣・熟達度差の実証としない。8通りのtoken/type別平均を別の表結合・重み付き算術と照合し、保存した対象・参照・結果から再実行して一致した。

追加比較テスト93件と最終配布候補の `R CMD check --no-tests --no-manual` は成功。既存runtime・テスト・資源は前候補と同一で、成功済みの検証を再利用した。証拠は `reviews/ldfreq-reference-comparison-20261005/evidence/`。現在のMacのRは `C.UTF-8`／UTF-8判定TRUEで、非ASCII tokenのquantedaへの受渡しも成功した。plain `C` の試験での制限をMacの非対応と誤解しないようガイドを更新した。

##### MASC全体の点検と分割集計（2026-10-05追記）

**実装**：`lexdiv_ngram_reference_build()` は利用者のcallbackから既存の `lexdiv_ngrams()` 結果を順に受け、頻度・文書頻度・n別分母を加算する。出現表はchunkごとに解放する。文書IDがchunkをまたいで再登場したら停止し、空文書も母数へ保持する。全入力で前処理IDとnの集合が一致することを要求する。返す `$reference` は既存のprofile/compareへそのまま接続でき、`$sources` と `$documents` に入力のハッシュ・順序・文書を残す。型数上限を超えた場合は停止し、稀な語列を勝手に剪定しない。新しい依存は追加しない。

**MASCの結果**：公式MASC 3.0.0 ZIPは36,358,521 bytes、SHA-256 `0b300d96016233c7c79b43559b477a6bb0ed16bb416d5c517eccb108a6228493` で配布元digestと一致した。READMEの内容版は2012-12-15。modern `documentHeader`／`.hdr` をreader 0.2.0へ追加したが、従来の境界条件は緩和していない。392文書中122文書が通過し、270文書を拒否した。最初の失敗は、文／発話へのtoken包含130件、文／発話の重複126件、anchorの不適合9件、tokenの重複4件、未対応feature構造1件。今回は既定のcodepoint座標で検査した。anchorの9件を追加点検すると、いずれもseg層に長さ0以下のregionがあり、codepointとUTF-16の本文長は同じだった。この9件はUTF-8 localeへ変更して解決する問題ではない。これはreaderの診断であり、全注釈の誤り認定ではない。黙って除外した部分集合を「MASC全体」や標準規準としない。

**独立照合と測定**：受入れた122文書の79,059 tokensについて、別のPython実装で原文anchorから切り出した語形・区間・元位置が一致した。bigram機会67,220、trigram機会57,909、計94,674 typesの頻度・文書頻度・分母も独立集計と一致した。この部分集合で、同じR 4.6.1/Macの別プロセスを各1回測定した結果は以下。XML読込は事前に完了し、同じ準備済みRDSを入力した。時間はR内の読込・抽出・参照構築、メモリはプロセス全体のmaximum resident set size。性能の一般的優位性を推定する反復ベンチマークではない。

| 集計方法 | 処理時間 | ピークメモリ（10進MB） |
|---|---:|---:|
| 122文書を一括 | 1.420秒 | 378.4 |
| 1文書ずつ、122 chunks | 9.678秒 | 297.1 |
| 最大10文書ずつ、13 chunks | 2.415秒 | 292.8 |

分割は全出現表の保持を避けるが、全typeと文書一覧は依然としてメモリ内にある。現在は累積type表をchunkごとに結合するため、細分化には時間の費用がある。定数メモリ・OANC規模対応・任意の大型単一文書への対応・途中再開は主張しない。

**OANCの結果**：公式GrAF ZIPは655,230,430 bytes、SHA-256 `5a26559a1becba41a527cb674fff4fb9c4fb70b276f60422c4f07a0ef23fd867` で配布元digestと一致。全展開サイズは約7.4GBのため、ZIP内のheaderを直接点検した。`.txt`は8,824件、`.anc`は9,074件あり、9,073件をXMLとして解析できた。大多数は `hepple` 層を使い、token regionを別のsegファイルに置くMASC経路と異なる。層構成の例外もあり、ファイル数をそのまま有効文書数としない。OANC reader・全本文処理・資料重複確認は未実装／未完了。既存の0-byteディレクトリには触れていない。

**次の判断**：まず拒否原因を少数の原文・注釈で照合し、保持すべき文／発話境界と層を明示する。誤りの修正、別層の選択、自動再注釈は測定条件が異なるため、ひとつの自動fallbackにまとめない。OANCはHeppleの読込と原文位置の独立検証を別に行う。その後、資料構成・全文／抜粋重複と除外の影響を確かめて参照を構築する。M2の実在規準を使う項目分析は並行する研究課題として残す。関連度追加には共起母数と統計定義の検証が必要であり、頻度比較を関連度・employabilityと呼ばない。

入力監査・独立算術・測定・配布確認の証拠は `reviews/ldfreq-corpus-scaling-20261005/evidence/`。コーパス本文はパッケージへ同梱しない。

#### M5：語義・構文を考慮した拡張

語義に基づくCEFR、dependency collocations、構文指標は研究候補とする。初期は外部で作成した注釈を受ける設計を比較し、Python・大規模モデル・クラウドサービスを基礎分析の必須依存にしない。語義注釈の不確実性、品詞・sense ID、資源版を保持できること、対象レジスター・話者群での注釈評価、追加構成概念の妥当性が着手・公開の条件となる。現行パッケージをcomplete CAF analyzerや自動CEFR判定器とは呼ばない。

#### M6：日本語の語単位・表記・参照資源を保持する分析

**実装状態（2026-10-05）**：第一段階の注釈入力と実解析例を追加済み。
`lexdiv_import_annotations()` は解析器を限定しないplain token表を受け、
原文の非空白文字に抜けがないことを照合し、segment内のUnicode codepoint
位置を付ける。辞書版・語単位・正規化は呼出側の宣言として保持し、実際の
形態素解析精度や原文に対する文／発話区切りの妥当性まで保証しない。
`gibasa` は任意依存、unidic-lite 1.0.8は作業領域だけに展開して検証した。
実出力にはsurface・orthBase・lemma・lForm・階層的POS・生featureを残した。
gibasaが返さない未知語nodeフラグは欠けたlemmaから推測しない。

公開用の使い方は `vignettes/japanese-annotations.Rmd`。
実解析・手計算との照合・座標・欠測・境界・保存再読込の証拠は
`reviews/ldfreq-japanese-import-20261005/evidence/` にある。
日本語規準については下記の実在AoA・BOIの読込と、WLSPの候補確認・選択記録を
公開ガイドと同梱コード例へ追加した。
次の優先順位は、(1)WLSPの反復レコード等の未確定の規準情報を検討し、
用途別の刺激選定例へ進めること、(2)固定した日本語TUBELEXのキー・正規化・
辞書版との適合、(3)同じ原文の分割変更を扱うsource-span比較、
(4)用途別に人手注釈した資料による誤り分析と、測定妥当性の検討。
短単位の受入れ実装だけで日本語SLA・心理言語学への妥当性を満たしたとはしない。

##### 無料で取得できる心理言語学的規準（2026-10-05確認）

**問い**：有料のNTT規準表を持たない利用者が、親密度・AoA・抽象度・
身体との相互作用・語彙判断成績をRで照合できるか。また、一般公開する
パッケージへどのデータを含められるか。この二つを分けて判断する。

[NTT印刷の利用規約](https://www.nttprint.com/Portals/0/PDF/nttPrintVocabulary/riyokiyaku.pdf)
第3条(3)は、データの一部でも第三者が再利用できる形式での公開を認めていない。
出典明記だけで再配布可能とはしない。一方、以下には無償取得可能な資料がある。
論文とデータのライセンスが同じとは限らないため、配布元のデータ条件を確認した。

| 資源 | 測定内容と確認した範囲 | データ条件・採用方針 |
|---|---|---|
| [WLSP-familiarity v4.0](https://github.com/masayu-a/WLSP-familiarity) | 「知っている・書く・読む・話す・聞く」等のベイズ推定値。固定commit `38af7500b9177cf7dc086bd0eabae1b7b3a66c8d` のCSVを確認 | CC BY-NC-SA 3.0。親密度の有力候補。非商用等の条件を保持した利用者側の読込から始める |
| [AWD-J core](https://sociocom.naist.jp/awd-j/) | 15,220語の人間による抽象度評定。core実ファイルを確認。EXは機械による推定であり、人間の評定と区別する | CC BY 4.0。同梱候補だが尺度・列の説明に不一致があるため自動変換は未実装 |
| [日本語AoA](https://osf.io/fawmq/)（Mochizuki & Ota, 2025） | `data_AoA.csv`：5,736語の回顧的な獲得時期評定、人数・平均・SD・最小・最大 | **データはCC BY-NC 4.0**（OSF APIで確認）。論文のCC BY 4.0と区別。ローカル読込例を追加 |
| [JALEX](https://osf.io/qr2sg/)（Ota & Mochizuki, 2025） | 5,736語を対象とする語彙判断RT・正答率。今回は配布一覧とライセンスを確認し、CSV本体・除外処理は未点検 | `license.txt` はCC BY-NC 4.0。APIの単なる「Other」や論文ライセンスで判断しない。現行 `JALEX_v2.csv` を次の点検対象とする |
| [日本語BOI](https://osf.io/gkjmc/)（Mochizuki & Ota, 2026） | 身体と対象物の相互作用の評定。`data_boi.csv` と著者の分析コードを確認 | OSF projectはCC BY 4.0。同梱候補。固定ファイルの読込例を追加したが、下記の出版物との対応確認を残す |

CC BYでは出典・ライセンス・変更の表示等を守った再配布が可能である。
NC/SAも条件付きの再配布を一律に禁じるものではないが、商用を含む一般利用を
想定するMITコードと無条件に一体化しない。現段階ではデータを同梱せず、
利用条件の確認と取得を利用者側に置く。コードのMIT表示で読み込んだ規準値や
出力表を再許諾することはできない。参照：[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja)、
[CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.ja)。

**実データの点検で分かった問題**：

- WLSPのCSVは101,067レコード、`見出し本体` は81,272種類で、一意キーではない。
  同じ見出しでも値が異なる行がある。任意の先頭行採用・一律平均・無検証の多対多結合を避け、
  読み・見出し・レコード種別と対応方針を検討する。公開値はNTTの生の7段階評定と同じ尺度ではない。
- AWD-J公式ページは説明では1=具体的・5=抽象的、引用された教示では逆を示す。
  また `Deviation` の「分散」という説明と例示値の関係も未解決。
  方向反転・標準誤差への換算・EXとの統合を、列名だけから実装しない。
- AoAは1=0–1歳から7=12歳以上までのカテゴリで、分からない場合にも7を選ぶ教示。
  `meanAoA` は年齢の平均ではない。集計値だけから未知回答を除去することもできない。
  [原論文](https://www.frontiersin.org/journals/language-sciences/articles/10.3389/flang.2025.1605224/full)に基づき、そのまま評定カテゴリの平均として保持する。
- BOIの[出版物](https://doi.org/10.3758/s13428-025-02939-1)とOSF projectの表題は5,637語、
  取得した `data_boi.csv` と著者の分析コードは5,736語である。
  [訂正記事](https://doi.org/10.3758/s13428-026-03000-5)の存在は確認したが、訂正内容は未確認。
  現在の例を論文の最終分析対象の再現とは呼ばず、配布CSVの処理確認として限定する。
  NTT等の第三者規準を含むmerged tableへOSF projectのライセンスを一括適用しない。

**初回に実装した最小の利用例**：`experiments/japanese-norms.R` は利用者が取得した
AoA・BOIの集計CSVを受け、検証したSHA-256と照合して既存
`lexdiv_norm_profile()` へ渡す。新規export・依存・自動ダウンロードは追加しない。
語の表記による完全一致を使い、項目ID・元のID・品詞・評定人数・SD・欠測を
項目別表へ残す。資源と尺度を分けてtoken/typeの平均・照合率を計算し、
CSVとRDSに保存する。取得元・ライセンス・入力ハッシュ・R環境も保存する。
例の入力は重複を含む4出現と意図的な未照合1件であり、標本の代表性を示す分析ではない。

**検証範囲**：両CSVは5,736個の一意な `Word` キーを持ち、例をこのMacで実行した。
token照合率4/5、type照合率3/4で、未照合値はNAのまま残る。
直接の表結合による平均との一致、元の評定人数・SD・項目IDの保持、保存再読込を確認した。
証拠は `reviews/ldfreq-japanese-norms-20261005/evidence/`。
初回の変更は配布対象外の実験スクリプトと開発ロードマップだけで、既存の配布archive・
公開ガイド・runtimeを更新したとは扱わず、全体checkの再実行は行っていない。

**続く公開ガイドの実装（同日）**：`vignettes/japanese-norms.Rmd` と
`inst/examples/japanese-norms.R` を追加した。Rから明示的にsourceする例であり、
新しいexportは設けない。`profile_japanese_norm_items(items, path, resource)` は
AoAまたはBOIを単独で受け、利用者自身の `item_id`・`term` と任意の条件列を
保ったまま、規準の値・人数・SD・元のID・欠測理由を付与する。source時に
ダウンロードやファイル書込はしない。実験スクリプトはこの実装を再利用する。

ガイドは架空の評定値を使ってオフライン実行できる。条件Aは2/2項目、Bは
1/3項目で値が得られる反例により、条件別の照合率と比較対象の偏りを説明する。
実データの取得・ライセンス確認、CSVの先頭ゼロ付きID、項目IDによる資源間結合、
保存再読込、尺度・母集団・研究解釈の限界まで示した。公開サイトのREADME・
記事索引・help・NEWSから案内する。データ本体は引き続き同梱しない。

追加点検ではWLSPの `人気` に `にんき` と `ひとけ` があり、`上手` の
`じょうず` でも異なる値を持つ複数行がある。読みを足すだけで全体を一意化
できるとは扱わず、元レコードIDを保持した明示的な対応方針を必要とする。
AWD-Jの尺度説明とBOI訂正内容は今回も未解決である。

両実ファイルで、行順・条件・先頭ゼロ付きID、重複語、未照合・空入力、平均の
独立算術、元の人数・SD、RDS/CSV往復を確認した。重複ID・欠損term・出力列衝突・
誤った資源ファイルは拒否する。配布候補の `R CMD check --no-tests --no-manual
--no-vignettes` は **Status: OK**。最終インストール確認で古い13件のvignette索引が
残ることを発見し、既存の14本のsource/outputから索引を再生成した。最終archiveの
差は索引とDESCRIPTIONのbuild metadataだけで、再インストール後に14件の発見と
`vignette("japanese-norms")` のHTML参照・同梱例の照合を確認した。
変更した2ガイドは別途renderで実行済み。
新ガイドを含む14 vignettesを同梱し、ローカルサイト109 HTMLの相対ファイルリンクに
欠落はない。以前のarchiveからR本体・既存テスト・仕様・既存データ・NAMESPACEが
同一であることを確認し、その検証証拠を再利用した。全体数値テストの新規一括成功とは
報告しない。記録・配布候補は `reviews/ldfreq-japanese-norm-guide-20261005/evidence/`。
リモートサイトの公開、push、CRAN提出は行っていない。

**WLSPの候補確認・選択記録（同日追加）**：`inst/examples/wlsp-items.R` の
`review_wlsp_items(items, path, decisions = NULL)` を明示的にsourceする例を
追加した。固定v4.0のCSVをSHA-256で確認し、表記が完全一致する候補を全件返す。
元レコードID・見出し・読み・分類番号／項目・レコード種別と5種類の推定値を残し、
一件しかない場合も自動選択しない。利用者が `item_id`・`record_id`・`reason`
を指定した項目だけに値を付与し、元の項目数・条件・行順を保持する。
未照合、候補はあるが未確認、明示的に選択済みを分ける。選択済みでも元の値が
欠測ならNAのままで、選択の妥当性や語義別規準の成立をソフトウェアが認定しない。

ガイドの著者作成例は5項目・12候補。`人気` の二つの読みと `学校` を確認して
選び、`上手` を未確認、作成語を未照合として残す。候補表をそのまま分析単位に
すると同じ項目が多重に数えられるため、項目表と候補表を別に扱う。選択表のCSVは
レコードIDの先頭ゼロを保持し、結果・判断・データ版はRDSにまとめる。

検証は実際の固定CSVで、5推定値と元行の一致、条件・順序、同じ表記の別項目、
空入力、未照合、選択済み欠測、Unicode正規化を行わない挙動、百万候補を超える
展開の事前拒否を確認した。不明／別表記のレコードID、重複選択、空の理由、数値化
されたID、列衝突、別ファイルは拒否する。配布候補をインストールし、ガイド中の
WLSP用3コードブロックを変更せず実データで実行し、判断の再適用と保存復元も確認した。

`R CMD check --no-tests --no-manual --no-vignettes --no-examples` は **Status: OK**。
変更したガイドは別途render済み。14 vignettesの発見、同梱例とcheckoutの同一性、
ローカル109 HTMLの相対リンクを確認した。R本体・既存テスト・仕様・既存データ・
exportsは前候補と同一で、成功済みの検証を再利用する。新規の全体テスト成功とはしない。
証拠・最終候補は `reviews/ldfreq-wlsp-review-20261005/evidence/`。
WLSPデータ自体や実行結果は同梱せず、新規export・依存も追加していない。
リモート公開・CRAN提出は未実施。AWD-JとBOIの資料側の未解決事項は残る。

**研究上の限界と公開する価値**：親密度、使用頻度、獲得時期、抽象度、BOI、RTは別の構成概念である。
無料の別尺度でNTTの全規準を置換したり、これらを根拠なく一つの「語彙難易度」に合成したりしない。
母語成人の規準は日本語学習者本人の習得順序・既知語・employabilityではない。
本パッケージが加える価値は、各資源の条件を保った項目表と、未照合・曖昧な対応を確認できる手順である。
今後の用途別の例では、語形・読み・品詞の対応と刺激選定／除外の判断を点検し、
条件群の同等性や混合モデル等の推論は研究設計に即して既存Rツールへ接続する。

##### 問いと独自性

利用者は、日本語母語話者・日本語学習者の作文／発話、教材、実験刺激を分析する研究者である。「何を一語とするか」「どの表記を同じ語とするか」「どの資料の頻度を参照するか」によって、分母、異なり語数、n-gram、照合率が変わる。この変更が結果をどれだけ左右し、どの原文箇所に由来するかを利用者が点検できることを目標にする。日本語の追加だけを学術的新規性の証明とせず、既存Rツールを直接組み合わせた手順との比較で実証する。

[UniDicの説明](https://clrd.ninjal.ac.jp/unidic/glossary.html)は分割基準と階層的見出しの区別を明示し、[BCCWJの形態論情報](https://clrd.ninjal.ac.jp/bccwj/morphology.html)は短単位・長単位を別の言語単位として設計している。したがって、辞書・語単位は単なる環境設定ではなく測定条件として保持する。短単位を英語の空白区切り語と同じものにせず、SudachiのA/B/CをBCCWJの短単位／長単位へ自動対応させない。

具体的な価値は次の三つ。

1. **分割・表記の感度を原文へ戻って説明する**：同じ資料から、表層形／書字形基本形／語彙素、細かい／粗い分割、全語／指定品詞の条件を作り、指標だけでなくN・V、除外とn-gram機会数、変更箇所を並べる。語彙素文字列だけでは区別が不十分な場合に、読み・品詞・資源側IDの構造を保持する。読みだけへの統合で同音異義語を混ぜない。
2. **参照に合わせて照合する**：TUBELEX日本語・BCCWJ等の分割・見出し・正規化・版に適合するキーを作り、未照合、複数候補、欠測を可視化する。「カバー率が上がった」だけで正しい語に対応したとは判断しない。
3. **心理言語学の項目表へ接続する**：原表記、語頻度、書字形別の頻度、親密度、文字長、読みとその出典をitem IDで結び、L1・熟達度・提示形式などの設計情報を別表に残す。文字数とモーラ数は別列にする。未知の読みからモーラを推測せず、漢字率をそのまま難易度得点にしない。

日本語と英語の同じ名前の指標を共通尺度とみなさない。同じMATTR窓幅50でも、短単位50と英語50語では言語的な量が異なる。まず各言語内の条件差を評価し、言語間比較には対象・課題・語単位と測定の同等性を別に検討する。頻度や表記の特徴から個人のemployabilityを推定しない。

##### 第一段階実装前の評価と既存APIの境界

| 現在の入口 | 日本語での位置付け |
|---|---|
| `lexdiv_metrics()`、明示的token表のn-gram群、generic norm群 | 文字列を受ける計算基盤として再利用できる。日本語の分割・注釈を自動的に妥当化するものではない |
| `lexdiv_tokenize(tokenizer = "unicode")` | Unicode文字列抽出であり、日本語の形態素解析ではない。連続した日本語を長い一片として返す |
| `lexdiv_compare_annotations()` | 原文・前処理・token行が同じ場合の注釈差分専用。1対多／多対1の分割変更は扱えない |
| `lexdiv_ngram_compare()` | 同じ前処理・同じ対象語列で参照を変える比較。異なる分割のn-gramを同じ対象として押し込まない |
| `tubelex_profile()` / NJ8 | 現在の同梱資源は英語。日本語頻度／日本語学習者の語彙レベルの入口にはしない |

このMacのC.UTF-8環境で、最終インストール済み0.2.0を用いた独自作成文「国際連合で国際協力を学ぶ。」の小例を実行した。現行Unicode抽出は句点を除いて1 token。手で設定した細分条件は7 tokens・6 typesでTTR=6/7、複合語をまとめた条件は5 tokens・5 typesでTTR=1となった。bigram機会数は6対4、trigramは5対3である。原文上の位置と手計算に一致した。**細分／結合は説明用の独自条件であり、UniDicやSudachiの実出力・正解データではない。** 短い文での算術確認であって、指標の妥当性や解析精度を検証したものではない。

事前評価の証拠：`reviews/ldfreq-japanese-20261005/evidence/probe.R`、`probe.log`、`granularity-probe.csv` とRDS。この時点では自動形態素解析は未実行で、gibasa等は未導入だった。その後の実装検証で、作業領域の専用Rライブラリへgibasaを導入し、UniDic辞書を別途展開した。システム設定やホームのMeCab設定は変更していない。現在の実解析の証拠は本節冒頭の別ディレクトリを参照する。

##### 既存処理系を使う選択

| 候補 | 利点 | 負担・検証条件 | 方針 |
|---|---|---|---|
| MeCab + UniDicをRから利用（gibasa等） | 日本語の短単位・見出し情報を保持しやすく、TUBELEX日本語との整合検証につながる | 辞書とネイティブ環境、辞書に依存するfeature列、R bindingごとの位置情報を確認する。MeCabを使っただけで同じ結果とは限らない | 最初の参照資源整合の候補。任意依存として1経路を検証 |
| `udpipe` | Rから分割・lemma・UPOSへ進められ、Python/Java実行環境は不要 | 日本語モデルが別途必要。モデル版とライセンス、学習資料・分割規則を固定。UniDicとの互換性は未検証 | Rで操作する簡便な別経路として比較。既にR本体は導入済みだが日本語モデルは未取得 |
| Sudachi系R binding | 分割モードの違いを具体的に比較できる | bindingによりPython等の実行環境が必要。辞書・モード・正規化を保持。公開・保守状況も採用時に確定 | 第2段階の分割比較候補。最初から複数backendを必須化しない |
| quanteda / stringi | 集計・KWIC・Unicode処理を引き続き再利用できる | 単に語境界が得られることと、指定した日本語の語彙単位・lemmaを得ることは別 | 既存の位置付きtoken表との接続に使う |

根拠：[gibasa公式文書](https://paithiov909.github.io/gibasa/)（UTF-8辞書とMeCab環境）、[UDPipe R公式文書](https://bnosac.github.io/udpipe/docs/doc1.html)（Python/Javaを要求しない設計）、[sudachir公式文書](https://uribo.github.io/sudachir/)（reticulate/SudachiPy、モード例）。Rで操作が完結することと、Rの標準機能のみ・辞書不要で実装することを混同しない。独自の日本語形態素解析器は新設しない。

##### 最初に使う参照資料と配布

- **TUBELEX日本語**を最初の候補とする。[公式README](https://github.com/naist-nlp/tubelex)には日本語の表層形・base・lemma、およびUniDic 3.1.0の別版がある。[上流実装](https://github.com/naist-nlp/tubelex/blob/main/lang_utils.py)ではbaseとlemmaに異なるUniDicフィールドを使う。英語Treebank版へlanguage引数だけを足す設計にはしない。採用する日本語ファイルのcommit・ハッシュ・辞書・処理・列・総数・権利表示を固定し、既存の英語資源登録手順を再利用する。上流にはBSD-3-ClauseのLICENSEがあるが、今回、日本語データを取得・採用・同梱したわけではない。unigram表から観測n-gramを復元しない。
- **BCCWJ1の短単位／長単位語彙表**を参照感度の候補とする。[現行の中納言版公開ページ](https://clrd.ninjal.ac.jp/bccwj/bcc-chu.html)はVersion 1.1を掲載し、旧Version 1.0ページをobsoleteと区別している。本文、注釈、集計表は別資源として扱う。旧[1.0解説](https://clrd.ninjal.ac.jp/bccwj/data-files/frequency-list/BCCWJ_frequencylist_manual_ver1_0b.pdf)では研究教育利用と再配布禁止が明記されている。1.1解説のリンク先は今回取得できていないので、旧版の条件だけで新版の配布可否を確定しない。初期経路は利用者が保有するローカル表を読み込むものとし、採用版の条件を確認する。公開頻度表だけでは新しいn-gramや原文位置を得られない。
- **会話・学習者資料**は後段。学習者と母語話者、話し言葉と書き言葉で辞書誤り・未知語率・表記の揺れが異なるかを調べる。本文の取得・再配布許可は各資料で確認する。公開小例は当面独自作成文を使い、学習者資料の再配布を前提にしない。
- **ソフト・辞書・学習モデル・頻度表のライセンスを分ける**。例えば既存udpipeの既定取得候補である[UD 2.5モデル配布元](https://github.com/jwijffels/udpipe.models.ud.2.5)はCC BY-NC-SA 4.0を示しており、Rパッケージ本体の条件とは同じでない。任意のローカルモデル指定を基本とし、大型モデルや辞書を自動取得・同梱しない。

##### 実装順序と完了条件

1. **注釈表の受入れと単位の定義**：原文・document/sentence/turn ID・元のtoken位置と文字範囲・surface・書字形基本形・語彙素・読み・元の品詞・未知語フラグを保持する。辞書にない列は推測せずNA。解析器・辞書・ユーザー辞書の版と内容ハッシュ、正規化・除外規則、座標系を記録する。日本語の階層的品詞を無断でUPOSへ置換しない。現行 `lexdiv_tokenization` の内部構造へ外部注釈を強制挿入せず、既存のplain token表への接続を先に検証する。
2. **一つの解析経路と頻度表を接続**：まずMeCab/UniDic系の1経路で原文範囲を手作業の小fixtureと照合し、TUBELEX日本語の1版へ適合を確認する。語形・base・lemmaは別条件、キー衝突・未照合・欠測は別診断にする。汎用normの一意文字列キーだけで資源を表現できない場合は、読み・品詞等の複合キーを保持する別の対応表が必要。恣意的な最初の一件の採用や、他の語形頻度による穴埋めはしない。
3. **原文範囲による分割比較**：同じ元文書に対し一致・分割・結合・境界の交差・不整合を記録する。1対1対応の既存注釈比較とは別の仕様にする。NFC/NFKC等で文字数が変わるときは原文への対応を保存し、正規化後offsetを原文offsetと称さない。n-gramは各条件内で抽出し、除外や文／発話境界をまたいだ隣接を作らない。
4. **研究上の有用性を評価**：書き言葉・会話・学習者文を層別し、独立に確認した境界・見出しとの一致、未知語・多義的照合・coverage、指標と順位の感度、時間・メモリ・利用者操作を測る。既存ツールを直接つないだ手順と同じ条件で算術と作業負担を比べる。解析誤りの群差が見かけの能力差を作らないか検討する。熟達度との相関だけで分割法を選ばない。

Rパッケージ公開の条件には、解析器未導入でも既存英語機能が動くこと、日本語依存がある／ない環境、保存・再読込、UTF-8、結合文字・半角カナ・数字・絵文字・空文書・助詞除外の境界、helpと例を含める。日本語機能の追加を現行英語版0.2.0の公開の前提にはしない。最初の小さな日本語機能が検証できた時点で別の実装単位として公開範囲を決める。

##### 文献確認の範囲

[TUBELEX論文（Nohejl et al., 2025）](https://aclanthology.org/2025.coling-main.641/)の書誌・要旨と公式資源説明を確認した。日本語を含む頻度資源と心理言語学的変数の評価は候補選定の根拠になるが、今回のパッケージや日本語SLAにおける測定妥当性を承認する結果ではない。

ZoteroのJapanese検索から、Chikamatsu (1996), [doi:10.1017/S0272263100015369](https://doi.org/10.1017/S0272263100015369), item `VC7THDRM` の要旨を確認した。異なるL1文字体系を持つ日本語学習者の語認識を扱っており、表記・提示形式・参加者のL1を単純な語彙素へ吸収しない設計の根拠になる。この研究を現代の全学習者・全課題へ一般化しない。Amano, Kasahara, & Kondo (2007), [doi:10.3758/BF03192997](https://doi.org/10.3758/BF03192997), `UQLQJCI9` は親密度の年・場所に関する関連書誌として確認したが、Zotero応答に要旨はなく結果の数値・本文は未確認。親密度データ自体も取得していない。今回の検索は系統的レビューではなく、全文に基づく再現設計でもない。書誌検索と採用したmetadataを今回のevidenceに保存した。Zoteroライブラリは変更していない。

### 6. 実証研究は別の進捗軸で管理する

| 問い | 設計と比較対象 | 判定に必要な証拠／現在の限界 |
|---|---|---|
| 実装した数値は正しいか | 手計算、別実装、同一トークン・同一パラメータ、境界例 | ソフトウェアの正しさ。構成概念妥当性とは別。既存の有効な証拠を再利用する |
| 前処理で何が変わるか | 同一原文・document IDでsurface/lemma/flemma、全語/内容語、tokenizerを比較 | 変更された語・分母・除外率を伴う結果。条件選択を同じ評定への最大相関だけで決めない |
| 文章長・位置で何が変わるか | 同じ作文の複数長・複数位置の連続部分を比較し、原作文IDを保持 | 先頭だけの切出しや独立文書扱いを避ける。ICNALE全原文で共通に取れる最大長は179 tokensで、範囲は限定的 |
| 評定との関連は何を表すか | ICNALEのHolistic/Complexityを区別。作文・評定者の交差構造、地域・文章長を扱う | 平均評定の相関は予備結果。評定者を含む不確実性、モデル仮定・外れ値・尺度の検討が残る |
| 語彙多様性そのものを捉えるか | 直接的な多様性評定、または適切な語彙知識尺度との関係 | 現行GRAの総合評定だけでは直接答えられない。データ／評定手続を別途確定する |
| 未見の作文・課題へ一般化するか | writerをまとめた分割、可能なら課題・コーパスをまたぐholdout | 前処理・feature selection・調整を訓練側で完結。ICNALEの同一課題140件だけで課題間安定性を認定しない |
| 新指標群に追加価値があるか | 明示的なbaselineと追加後を同じ分割で比較 | 相関だけでなく予測誤差・区間・実質差を事前に定める。採点・CEFR推定は別に検証する |

本文に基づく具体化：Bestgen (2024)は長さ操作で絶対一致、パラメータ操作で一致性を評価している。順位相関だけで得点一致としない。ICCを採用する際は一致の定義と対象を明示する。同論文のICNALE Edited Essays 188作文と現在のGRA 140原文は異なる設計であり、独立な外部検証と称する前に作文・書き手IDの重複を確認する。Caltabellottaらは生産語彙知識を外的基準としており、総合作文評定を直接扱っていない。また操作化で目的変数が変わるGAMのAICを、そのまま最適条件の自動選択に使わない。

今後のコーパス研究では、母語話者の資料を含むレジスター別の前処理・パラメータ比較を先に進め、既存ICNALEの結果をその一事例に位置付ける。ICNALEの入力問題を記録した上での作文・評定者の関連分析は、別の限定的な問いとして継続できる。研究モデルの選定前に、連続近似と順序尺度の扱い、作文数136と特徴数のバランスを検討する。MWEや語義モデルを多数追加してから一括で選ぶ設計にはしない。

### 7. 利用者が迷わない導線

| やりたいこと | 現在の入口 | 説明する判断 |
|---|---|---|
| CSVの作文をまとめて分析 | `lexdiv_tokenize_batch()` → `lexdiv_metrics_text_batch()` | ID・欠測本文・空文書、英語tokenizer、小文字化、語単位 |
| NJ8で語彙構成を調べる | `nj8_profile_batch()` → **`nj8_diagnostics()`** | surfaceとlemma、未照合と注釈欠測、延べ頻度と文書数 |
| 見出し語化の結果を確認 | `lexdiv_lemmatize()` → `$tokens`／`lexdiv_compare_annotations()` | 辞書ID・版・ハッシュ・ロケール、実体の保存、文脈別の変更理由、品詞情報の有無 |
| TUBELEXと学習者の回答を関連付ける | `tubelex_profile()` のlookup＋一意なitem ID → `lexdiv_compare_responses()` | 語形の資源特徴と語義別の遂行、同じlearner×item、欠測・分母・採点規準 |
| 窓幅を変えて比較 | `lexdiv_plan()`／`lexdiv_grid()` → `lexdiv_profile_batch()` | 共通窓幅、短文の計算不能、異なる条件を混ぜない |
| 局所的な反復を調べる | `lexdiv_mattr_profile()` | 局所窓と文章全体の解釈、位置別exposure |
| 論文用の結果を保存 | 完全なRDS＋表のCSV＋設定・session情報 | 得点だけでなく出典、照合率、除外、設定を保存 |

短い導入は「入力→計算→診断→解釈→保存」の順とし、初回からすべての指標を並べない。研究者向けの詳しい説明はvignetteに置く。今回の新しいガイドは `vignettes/auditing-vocabulary-profiles.Rmd`。モデルを追加導入せずに動く著者作成例と、任意のtextstem利用方法を区別した。

M1以降の利用性確認は、同じ課題を実際のR利用者に実施してもらい、完了できたか、どの入力・用語で止まるか、出力をどう解釈するかを観察する。未実施の利用者テストを「使いやすさを実証した」と表記しない。

### 8. 既存Rパッケージとの位置付け

| ツール | 既存の強み | ldfreqで重点を置く点 |
|---|---|---|
| [quanteda.textstats](https://quanteda.r-universe.dev/quanteda.textstats/doc/manual.html) | lexical diversity、頻度、keyness、collocations等。quantedaのデータ構造と連携 | 同じtoken列を取り込み、方法・条件・計算不能理由・NJ8等の資源照合を明示する。collocation抽出の再利用を検討する |
| [koRpus](https://reaktanz.de/R/pckg/koRpus/index.html) | 多様性、可読性、POS・lemma関連処理と詳細診断 | 定義・尺度を合わせて比較する。MTLD、HD-D、局所診断の存在自体を新規性にしない |
| [textstem](https://search.r-project.org/CRAN/refmans/textstem/html/lemmatize_words.html) | Rで利用できる辞書による見出し語化 | 既存backendとして使い、資源・変換・coverageを記録する。独自の万能lemmatizerを急造しない |
| tidytext／zipfR | それぞれtidyなテキスト処理／語彙頻度分布・語彙成長モデル | 既存adapterや明示的なtoken入力で連携する。分布モデルや統計推論を重複して抱え込まない |

比較実験では既定値の違いを成績差にしない。同一入力の数値一致と、各ソフトの通常ワークフローによる違いを分ける。Rで動くこと、MATTRがあること、辞書を扱うことだけでは差別化にならない。

心理言語学・SLA研究者の比較対象には、Rパッケージ以外の [TAALES](https://www.linguisticanalysistools.org/taales.html) も含める。開発元は単語・bigram・trigramの指標と、文書・項目別coverageを既に提供していると説明している。coverageの存在自体をldfreqだけの新規性にしない。[quantedaのn-gram生成](https://quanteda.io/reference/tokens_ngrams.html) と [collocation分析](https://quanteda.io/reference/textstat_collocations.html) も既存機能である。ldfreqが目指す追加価値は、R内で単語・複語・心理規準の条件、資源、欠測、原文への対応、研究用の項目IDを一貫して保持し、分析へ渡せること。複語部分は明示的な境界を受ける抽出・頻度・coverageまで実装済みで、関連度・自動文分割・大規模標準参照は残る。実装範囲を越えた差別化や優位性として宣伝しない。

#### AntConcとの機能比較・連携とR配布の方針（2026-10-05）

**判断**：AntConcの主要な分析をRの研究手順につなぐ価値はある。ldfreqの基礎分析はAntConcなしで実行できる構成を維持し、既存R機能の再利用と、AntConcが保存したデータの任意の取り込みを進める。GUI全体の再制作や画面操作の自動化を公開の前提にしない。

**接続について確認できたこと**：公式資料とCRAN/GitHubの公開検索では、AntConcの分析をRから直接実行する、維持された専用wrapperや公開された解析APIは確認できなかった。網羅的な不存在の証明ではない。一方、手元のAntConc 4.4.2のヘルプには、結果のtext/TSV等への保存、対応ツールの結果テーブルのZIP出力、設定のINI出力、SQLite readerでのコーパスDB参照が記載されている。[公式配布ページ](https://www.laurenceanthony.net/software/antconc/) と [4.4.2ヘルプ](https://www.laurenceanthony.net/software/antconc/releases/AntConc442/docs/help.pdf) を参照。起動中のアプリを操作する接続と、保存ファイルの読込は別の機能として説明する。

付属デモ `Alice_Adventures.db` をPython標準のsqlite3で**読み取り専用**に開き、`corpus`、`docs`、`docs_fulltext`、`doc_token_offsets`、`lexicon`、`kwic_info` 等の11テーブルと列定義を確認した。`corpus_info.db_version` は `2.0`。本文・データベースのコピーや再配布、アプリの変更は行っていない。R側の汎用接続には [DBI/RSQLite](https://rsqlite.r-dbi.org/reference/SQLite.html) を使えるが、この環境にはRSQLiteがなく、R接続とldfreqへの変換は未実装・未検証である。読み込み時は `flags = RSQLite::SQLITE_RO` を使い、対応するDB版・必須列・位置の定義を検査する。単にSQLで読めることを、解析結果の互換性の証拠にしない。

| AntConcで行う作業 | 既存Rの入口 | ldfreqで追加・接続する価値 |
|---|---|---|
| KWIC・検索語周辺の原文確認 | [quanteda::kwic()](https://quanteda.io/reference/kwic.html)、[mclm::conc()](https://search.r-project.org/CRAN/refmans/mclm/html/conc.html) | NJ8未照合語、lemma差分、n-gramを文書ID・位置から用例へ戻す。mclmはAntConcに似たconcordance機能を明記しているが、AntConcを制御するwrapperではない |
| Word List・Keyword List | quanteda.textstatsの頻度集計と [textstat_keyness()](https://tutorials.quanteda.io/statistical-analysis/keyness/) | 頻度・文書分布・対象／参照の母数を保持し、NJ8・TUBELEX・規準表を結合する。keynessをそのまま個人能力の群間検定と解釈しない |
| Cluster・N-Gram | [quanteda::tokens_ngrams()](https://quanteda.io/reference/tokens_ngrams.html) と検索箇所による選択 | 現行ldfreqは2・3語のみ。4語以上のlexical bundleを扱う拡張、検索語を含む語列、頻度・文書分布の絞り込みを検討する |
| Collocate：検索語の左右に現れる語 | [quanteda::fcm()](https://quanteda.io/reference/fcm.html) は窓内共起の基盤となる | 左右幅、距離、句読点・文境界、重なった窓の数え方を明示した共起表と、定義を検証したMI/t-score等。単純な関数の置換でAntConc互換としない |
| Plot・File View | [quanteda.textplotsの分布図](https://quanteda.io/articles/pkgdown/examples/plotting.html)、KWIC・原文位置からの抽出 | 出現の集中・分散と前処理の誤りを確認する。GUIの複製を必要条件にしない |
| Wordcloud・ChatAI | 可視化は既存Rツール、AIは別途評価 | 当面は頻度表・用例・分布図を優先する。研究上の解釈や語義判定を自動生成の説明だけに委ねない |

**分析単位の区別**：隣接n-gram、検索語を含むcluster、左右の窓内共起は異なる観測単位である。[quanteda.textstats::textstat_collocations()](https://quanteda.io/reference/textstat_collocations.html) のlambda/zもAntConcのMI/t-scoreと同じ指標ではない。比較には同じtoken列、境界、重複、周辺度数、標本空間、補正、低頻度閾値を揃える必要がある。AntConcへの数値一致だけでなく、手計算と独立した定義照合を用いる。集約したkeynessは、著者・話者・項目の反復を扱う研究モデルの代わりにしない。

**取り込みの段階**：最初は実際に保存したWord List・KWIC等の形式を1種類ずつ確認して読込例を作る。上位項目だけのTSVや表示されたスコアから、総機会数・未出現・検索条件を復元しない。n-gram参照として必要な情報が不足する場合は、表の閲覧用取込と分析用参照の構築を区別する。その後、必要性が確認できたDB形式だけにread-only adapterを加え、未知の形式は明示的に拒否する。RからAntConcへの受け渡しは、まず標準テキスト等の公式な入力形式を利用し、DBへの書込は対象にしない。実際の往復読込やスコアの一致は今後の検証である。

**Rパッケージの配布**：分析コード、著者作成の小さい例、オフラインで動くテストとガイドを配布する。quanteda連携やDB読込を追加する場合は必要なパッケージを任意依存として扱い、AntConcのインストール・起動、Python、ネットワークを基礎分析の条件にしない。大きいコーパスは利用者が明示的に取得したローカルファイルから参照を構築し、パッケージ読込・テスト時に自動取得しない。小さい参照集計表の同梱は、原資料と集計物の再配布条件、版、出典、サイズを確認してから判断する。データパッケージへの分離だけでは許諾の問題は解消しない。

AntConc 4.4.2付属の [ライセンス](https://www.laurenceanthony.net/software/antconc/releases/AntConc442/docs/license.pdf) は非商用の無料利用と商用利用を分け、ソフトウェアの再配布を制限している。AntConc本体や同梱コーパスをldfreqに取り込めると解釈しない。公開された分析方法をRで実装すること、利用者の保存ファイルを読むこと、ソフトやコーパスの再配布は分けて扱い、取得する資料ごとの条件を確認する。

**次の実装順序**：M4の実用的な入力経路として、(1)文・除去箇所・元の位置を保つtoken入力とKWICによる確認、(2)4語以上の連続n-gram・文書分布、(3)左右窓の共起数と関連度、(4)実ファイルに基づく任意のAntConc取込、の順を提案する。頻度・keyness・図は既存R機能の再利用を先に試す。M2の実在する心理言語学的規準の読込例も別の必要機能として維持する。全文書の出現表を保持しない分割集計を追加し、MASCの受入れた部分集合で測定した。OANC規模の集計とtype表のメモリ負担は引き続き未検証。

**新規性と今回の範囲**：KWIC・n-gram・keynessやR内でのコーパス分析そのものを新規性にしない。[polmineR](https://polmine.github.io/polmineR/) もCWB/CQPを基盤とするKWIC・共起・分散等を提供している。ldfreqでは語彙多様性、NJ8/TUBELEX・心理規準、複語、原文位置、比較条件、欠測・coverageをつなぐ研究手順に貢献を置き、既存ツールを組み合わせた手順との作業・出力比較で実証する。今回行ったのは公式資料の照合とローカルDB構造の読取、計画の更新である。新しい解析API・接続関数の実装、GUI操作、AntConcとの数値照合、CRANチェックの再実行は行っていない。

#### 既存Rパッケージの利用とldfreqの追加価値（2026-10-05）

**設計判断**：汎用の検索・n-gram・行列集計はquantedaを中心に再利用し、ldfreqでは参照資料の選択、照合、条件間比較、診断と研究用出力を整える。機能ごとに別の計算エンジンを多数選べる仕組みは作らない。既存の英語tokenizerと指標を即座に置換せず、定義と結果が一致する範囲を確認してから重複実装を減らす。

| 選択 | 利点 | 費用・弱点 | 当面の判断 |
|---|---|---|---|
| 検索・分割・集計をすべて独自実装 | 仕様と依存を直接管理できる | 高速化、Unicode、各OS、既存機能の修正を抱える。指標数だけでは追加価値を説明しにくい | 特有の定義や必要な診断を除き採らない |
| quantedaを全体の必須基盤にする | 入力・実装を揃えやすく、利用者の準備手順も一つになる | 基礎指標だけの利用者にも依存とインストール負担が生じる。上流変更の影響が広い | 新しい主要機能の大半が依存する段階で再評価 |
| 既存の基礎機能＋quantedaを使う追加機能 | 既存APIを保ちつつ実用的なコーパス処理を再利用できる | 任意依存の有無、対応版、変換時の情報保持を検証する必要がある | **初期の推奨構成** |
| 多数のbackendを自動で切り替える | 選択肢は多い | 分割・既定値・統計量の違いが隠れ、比較と保守が増える | 採らない |

最初の連携対象はquanteda、必要な統計量にはquanteda.textstats、図にはquanteda.textplotsとする。MASC/OANCのGrAFは既存のxml2で必要な層だけを読む。一般文書の読込は [readtext](https://readtext.quanteda.io/) 等を案内できるが、汎用読込が注釈間の対応まで解決すると仮定しない。AntConcのSQLite読込は別の任意機能とし、DBI/RSQLiteを使う。

採用する任意機能では `Suggests` と条件付きの名前空間利用を用い、未導入時の必要操作を明示する。自動インストールや、別の計算への黙った切替はしない。独自の名前に包むだけの一対一wrapperも増やさず、既存関数をそのまま使える箇所はガイドで接続する。利用者がほぼ必ず必要とする依存になった場合は `Imports` の方が単純になるため、依存数の少なさ自体を目的にしない。CRANの現行版に対応し、研究結果には実際の版・設定を記録する。試行の固定版と、公開パッケージの永久的な版固定は区別する。

**境界で保持する情報**：token ID、文書と区間のID、元の位置、語形・lemma・POSの由来、除外位置、参照版と集計母数を保持する。quantedaは [既存のtoken列を受け取れる](https://quanteda.io/reference/as.tokens.html) ため、検証済みのMASC注釈を利用する場合は無条件に再分割しない。[padding](https://quanteda.io/reference/tokens_select.html) は既存機能として使う。現行 `lexdiv_as_documents()` のnamed-list変換だけでは、注釈層、区間、文字位置の情報は渡せない。文書全体を句読点削除後に連結した語列も、n-gramの安全な入口とはみなさない。疎行列を巨大な通常の表や全出現表へ変換せず、原文への対応は必要な用例で取得する。速度・メモリの優位性はOANC規模で計測するまで主張しない。

**追加価値は具体的な研究作業で示す**：

1. **参照の選択で結論がどの程度変わるか**：同じ対象文書をMASC/OANCの会話・学術文等の参照で比較し、語・句ごとの変化、共通に評価できた項目、資料ごとのcoverage、低頻度・未収録を返す。比較条件が異なるものをひとつの順位に混ぜない。
2. **得点の変化を用例から説明する**：語形／lemmaや除外方針の差が、どの項目と出現機会数を変えたかをKWIC・原文位置と結ぶ。quantedaにも元からある用例検索・paddingを独自性として数えない。
3. **実験の項目・文書の分析表を作る**：語・句の参照頻度、各成分語の頻度、AoA・具体性等をitem IDで結合し、尺度・資料の違いと欠測を残す。句頻度と構成語頻度、コーパス特徴と個人のemployabilityは別の列・別の解釈で扱う。

新規性は個々の計算式よりも、この手順の統合と比較可能な出力に置く。その有用性は、quanteda等を直接組み合わせるbaselineと同じ入力・条件で比べ、数値一致、設定を変えたときの追跡、誤った結合や境界を検出できるか、利用者の作業量、時間・メモリで評価する。研究成果としての妥当性・ユーザビリティ・性能改善は今回の小規模試行では実証していない。

**更新後の着手順序**：MASC PennのID・位置保持、quanteda接続、4語以上とKWICの手順、隣接bigram/trigramの参照比較は実装した。分割集計とMASC全文書の受入れ点検まで追加した。次は拒否された注釈の境界方針、OANC Hepple層の独立読込、資料構成と重複を確認する。比較では資料規模・欠測・共通項目と実際の観測率を併記する。M2の実在規準を使う項目別分析は同じ出力へ接続する。既存パッケージの単なるwrapperを増やさず、比較条件と結果の解釈に必要な接続を優先する。

#### 汎用パッケージとしての公開前点検

公開前の重点は、対象を広げる説明と、利用者が自分のコーパス・参照表で一貫して実行できる入口である。既存B0/B1を生かしてnorm batchを追加し、文書IDを保つmetadata結合、3種類のcoverage、空文書、実体を含む保存と再実行をガイド化した。計算、Rの英語前処理、特定言語の参照資源、個人能力の解釈を分けることで、多用途と過剰な一般化を区別する。

公開面では、認証なしのHTTP確認でリポジトリとissue trackerは404、説明サイトのホームは200だった。新しいbatch関数の公開help URLは404で、ホームにも直近追加の機能名は載っていない。ローカルの完成度と一般利用者が入手できる状態を区別する。リポジトリの公開設定は変更していない。

`DESCRIPTION`に既存の第三者著作権一覧への参照を追加した。JACETの利用許可・出典明記の方針と資源のbytesは維持し、追加データや依存を増やしていない。最終候補の複数OSでのCI、匿名インストール、公開された例・helpとの一致が公開前の残件である。観点ごとの判定と限界は既存の `PUBLICATION-20261004.md` の追記に記録した。

### 9. 公開までの検証資源の使い方

新しいsource差分に対し、関連テスト、統合check、例・vignette・API・サイトの整合を確認する。本文・設定資料だけの変更では数値計算を繰り返さない。注釈比較の新APIを加えた差分では、新しい配布sourceの統合checkを行う。資源bytesやsource builderが変わらなければ、その再生成証拠は再利用する。新しいruntime APIの対応環境は、公開対象commitのCIで確認する。

公開時にはコードが通ることに加え、インストール、実行例、保存再読込、help、README、NEWS、Web参照先、配布tarballの内容を確認する。開発CIの成功、匿名到達可能な公開状態、CRAN受理を別の状態として記録する。研究の妥当性検証の未完了は明記し、その未完了を無関係なソフトウェア機能の完成と混同しない。

### 10. 文献・検索記録

Zotero item keyはライブラリ内の識別子であり、BibTeX citation keyではない。書誌情報は次のとおり。

- Kremmel, B., & Schmitt, N. (2016). Interpreting vocabulary test scores: What do various item formats tell us about learners’ ability to employ words? *Language Assessment Quarterly, 13*(4), 377–392. `3YK6ZI4B`. 書誌・索引全文を確認。
- Caltabellotta, E., Van Steendam, E., Noreillie, A.-S., & Peters, E. (2026). Measuring vocabulary use in L2 English and L2 French writing: How methodological decisions shape the results. *Assessing Writing, 69*, 101039. `JJLFZD7S`.
- Bestgen, Y. (2024). Measuring lexical diversity in texts: The twofold length problem. *Language Learning, 74*(3), 638–671. `WW4JRLXK`.
- Bestgen, Y. (2025). Estimating lexical diversity using the moving average type-token ratio (MATTR): Pros and cons. *Research Methods in Applied Linguistics, 4*(1), 100168. `5ZW9GUW2`.
- Kyle, K., Sung, H., Eguchi, M., & Zenker, F. (2024). Evaluating evidence for the reliability and validity of lexical diversity indices in L2 oral task responses. *Studies in Second Language Acquisition, 46*(1), 278–299. `RRSQ5JDL`.
- Kyle, K., Crossley, S. A., & Jarvis, S. (2021). Assessing the validity of lexical diversity indices using direct judgements. *Language Assessment Quarterly, 18*(2), 154–170. `A93563CV`.
- Eguchi, M., & Kyle, K. (2020). Continuing to explore the multidimensional nature of lexical sophistication: The case of oral proficiency interviews. *The Modern Language Journal, 104*(2), 381–400. `7ZSXAIFN`.
- Eguchi, M. (2022). Modeling lexical and phraseological sophistication in oral proficiency interviews: A conceptual replication. *Vocabulary Learning and Instruction, 11*(2), 1–16. `EY5Y5WRG`.
- Hu, N., Lu, X., & Hu, R. (2025). Developing fine-grained sense-aware lexical sophistication indices based on the CEFR levels of word senses. *Behavior Research Methods, 57*, 226. `QWM2IMSN`.

検索と書誌の記録はworkspaceの `reviews/ldfreq-roadmap-20261004/evidence/zotero-search.json` に保存。Zoteroライブラリへの追加・削除・変更は行っていない。

今回の追加登録の対応は同じdirectoryの `zotero-added-records.json` に保存。前回の検索記録を上書きせず、今回確認したitem key・DOI・確認範囲を記録する。

### KWICと曖昧性レビューの接続（2026-10-05）

`lexdiv_ambiguity_review()` を追加した。`lexdiv_import_annotations()` の完全な
入力、指定表層形、利用者が用意した候補表・資源宣言を受け、quantedaのKWICと
原文・Unicode位置・出現ID・判断を結ぶ。候補が1件でも自動確定しない。
未確認・選択済み・明示的な保留・候補なしを保持し、判断者と理由を記録する。
原文・注釈・対象語集合・候補表・資源版の変更は旧判断の使用を拒否する。
表示幅や行順の変更は許容する。Unicodeの合成済み／結合文字表記をquantedaが
同一視して検索するケースは、元の表記と検索語の厳密照合で区別する。

追加73件の検証はFAIL/WARN/SKIP 0。既存の注釈入力とMASC/quanteda連携の
検証も成功した。保存済みの実際のgibasa/UniDic入力は、最終アーカイブから
インストールした関数で3出現を照合し、入力・位置の保持を確認した。
英語・日本語の実行可能ガイド、RDS/CSV再読込、help・API一覧・NEWSを整合させた。
最終配布アーカイブの限定checkはStatus OK（テスト・vignette再実行・manualを
除外し、例は実行）。新規・変更ガイドは別途実行構築し、PDF manualも構築済み。
112 HTMLのローカル参照先欠落は0。詳細は `PUBLICATION-20261004.md` の末尾と
`reviews/ldfreq-ambiguity-review-20261005/evidence/` を参照。

未実装：自動語義判別・同音語抽出、辞書からの候補自動取得、意味類似度、語義別
参照頻度、多トークンの語義判断、複数評定者の自動調停。次の資源連携では、読み・
音素・アクセント・語彙素・語義・概念IDを混同せず、候補範囲と版を固定する。
研究での注釈精度・評定者間一致・対象集団での妥当化はソフトウェア検証と別に行う。
この差分のWindows/Linux CI、PR反映、公開環境への配備は未実施。

### 判断の比較と実在資源の候補表（2026-10-05追補）

`lexdiv_compare_ambiguity()` は、完全なレビュー二つを出現IDで対応付け、
用例別・語別・全体の比較表と再確認用のKWICを返す。表示幅と判断行順の違いは
許容し、原文・注釈・対象語・候補表・資源版の違いは拒否する。全内容のハッシュで
保存後の変更も検出する。旧レビューは保持された入力から作り直して比較する。

一致率の分母は双方が候補を選んだ用例に限定し、その用例数／全対象出現数も返す。
未確認・明示的保留・候補なしを意味的一致には数えない。選択範囲だけの高い一致率を
全用例の信頼性と解釈しない。κ・α・信頼区間・自動調停は含まない。
[Artstein & Poesio (2008)](https://aclanthology.org/J08-4004/) を踏まえ、
評定者の独立性、カテゴリの定義、標本構成、偶然一致を考慮する係数の選択は
研究設計として扱う。一致そのものを語義判断の正確さの証拠にはしない。

明示的にsourceする `wlsp_ambiguity_candidates()` は、別途入手した
WLSP親密度v4の固定CSVを既存readerで照合し、候補ID・見出し・読み・分類を返す。
実ファイルで「人気」2件、「上手」7件、「学校」1件、未収録の例語0件を確認した。
同じ読みの別レコードもあるため、レコード数を心理学的な語義数には読み替えない。
データの取得・同梱は増やさず、資源の版・ハッシュ・帰属・利用条件を保持する。

新規比較53件＋既存レビュー73件＝126件が成功。実資源の独立した列照合、
KWICとの接続、比較、RDS再読込も成功した。新しい配布アーカイブの限定checkは
Status OK、変更ガイド二つは別途実行構築した。74ページのmanualと113 HTMLを
構築し、ローカル参照先の欠落は0。既存数値コードの全テストはローカルで繰り返さず、
今回のPR差分のOS別CIを別途確認する。公開用データ12ファイルは前アーカイブと同一。

次に検討する問いは、(1)独立した評定者が同じ候補範囲とガイドラインで判断できるか、
(2)読み・語義候補の取りこぼしや分割の違いが判断とcoverageを変えるか、
(3)語形への心理規準と文脈中の語義をどのキーで結べるか、である。
その資源候補として、公式 [WLSP-norms](https://github.com/masayu-a/WLSP-norms/)
v1.0（2025-11-10）の多義性評定を確認した。本文データ、評定尺度、ID対応、欠測と
利用条件の検証はまだ行っておらず、今回の実装対象ではない。多義性の評定値、辞書の
レコード数、同音語数、文脈での選択結果は別々の変数として設計する。


### WLSPの主観的多義性と文脈判断の接続（2026-10-05追補）

前節で候補としたWLSP-norms v1.0の多義性ファイルを取得・検証した。
`read_wlsp_polysemy()` と `review_wlsp_polysemy_items()` はインストールされる
明示実行のexample scriptであり、exportを追加しない。既存のnorm profileと
KWICレビューを再利用し、必須依存、数式、既存APIは変更しない。

固定ファイルは100,827行でWIDは一意だが、表示語WORDは84,152種類で重複する。
WORDには見出しと読みが含まれ、LABELにも別のID・分類情報がある。親密度の
record_idや表層形をそのままキーにしない。利用者が表記・読み・分類を確認して
norm_wordと理由を指定し、別の判断表でWIDを選ぶ。候補が一つでも自動確定しない。
「人気」のにんき／ひとけは同形異音の照合例であり、関連語義の多義性操作を実証する
刺激対ではない。候補数、主観的多義性、同音語数、文脈での選択を別の変数とする。

[Asahara (2025)のプレプリント](https://doi.org/10.51094/jxiv.2164) と
[公式README](https://github.com/masayu-a/WLSP-norms/tree/72125c8dc538aeb70b07cb1c76c183e338f0cde9)
を確認した。公開VALUEは負値を含み、READMEは正規化推定値と記すが、照合した
説明から正確な正規化式は確定できない。原値を保持し、0–5への切詰め、z得点との
断定、語義数への読み替えをしない。推定値の尺度の詳細、語義特異性、測定誤差と
対象研究での妥当性は別途検証が必要。データ条件はCC BY-NC-SA 3.0であり、原表・
評定値は同梱しない。論文のライセンスとデータのライセンスも混同しない。

項目出力には未確定キー、未照合、候補未選択、選択済みを残す。集計profileは
選択済みWIDのみを対象とし、全項目のcoverageを別に返す。掲載例の3/6という
選択率と選択後の100%照合を区別する。KWICとの接続は出現IDを保持し、異なる
資源で作ったcandidate_idの流用はしない。値を見て都合のよい候補を選ばない。

実ファイルの全列照合、独立した平均計算、空・未選択・重複キー・誤ID・型・
ファイル改変の拒否、KWIC、RDS再読込が成功した。実際のガイド4コード塊も
取得済みファイルを使って実行した。C文字ロケールで新規readerと項目照合も成功。
KWICのUTF-8条件は維持する。新規helperの実データ検証をrelease-Rの3 OSに追加し、
CI結果はPRの対象コミットで別途確認する。既存数値処理のローカル再実行は省いた。

次の優先事項は資源を無制限に増やすことではなく、(1)研究で使う候補表・判定基準と
独立評定の設計、(2)未確定例の条件別偏り、(3)反応時間・正答率等の独立した結果と
関連語義／無関連意味の区別を結ぶ妥当化である。学習者個人のemployabilityは別の
課題・反応データで検証し、母語話者規準や用例中の一度の選択から推定しない。

### 文脈モデルとRの研究ワークフロー（2026-10-05追補）

`lexdiv_import_contextual()` を追加した。完全なKWICレビューと、外部計算前に
書き出した出現ID・review ID・原文・表層形・Unicode位置を照合してから、対象語の
埋め込み行列や候補スコアを結合する。モデル候補と人の判断は別列で保持し、保留・
エラー・結果未返却を全出現数の分母に残す。スコアの確率化・自動確定は行わない。
モデルとtokenizerの版、ソフトウェア、層・集約方法等を保存する。宣言の真実性や
計算そのものをハッシュで保証することはできない。

明示的に実行する `inst/examples/contextual-embeddings.py` は、取得済みの
commit固定Hugging FaceモデルをCPUで使う。元のsegment全体を入力し、対象語を
過不足なく覆うsubwordの最終層を平均する。未知語、境界をまたぐ分割、位置の隙間・
重複、長過ぎる文脈は理由付きで除外する。1出現ずつ処理する実証用scriptであり、
大規模コーパス用の高速化、cropped context、sentence-transformersの全pipeline、
語義判別器は含まない。Rの必須依存は増やさず、Python・重み・外部データを同梱しない。

既存Rパッケージtextの埋め込み計算を再実装する意義はない。今回の追加価値は原文・
研究上の語単位・候補資源・人の判断・欠測を結び付ける部分に置く。textを使う場合も、
単語型や文の集約済みベクトルに出現IDを後付けせず、位置対応を別途検証する。
日本語では非ASCII文字除去等の既定前処理も確認する。

取得済み英語BERTでは英語2用例を処理し、日本語2用例は対応条件を満たさず除外。
取得済み多言語MiniLMのbase modelでは英日4用例を処理した。別のchar-to-token
照合と加算によるベクトル再計算とも一致した。反復語、補助平面文字、複数subword、
語境界不一致、長文の検証も実施した。これは連携検証であり意味判別の正答率ではない。
対象語の選択、層、集約方法が心理言語学的構成概念を測るという証拠にもならない。

次の研究課題は、独立評定した語義を単純な候補頻度基準より識別できるか、また既存
ツールの組合せより誤結合・見落とし・確認時間を減らせるかである。候補表と判定基準を
先に固定し、モデル選択用と最終評価用の例を分ける。未知語への一般化なら語単位、
未知文書への一般化なら文書単位で分割する。候補coverage、全例に対する処理率、
独立評定済み例に限定した精度、未確定例、言語・読み・頻度・ジャンル別の誤りを併記。
モデル提示前の人手判断と提示後の判断を区別し、後者を独立評定と呼ばない。
実験参加者の反応、独立したgold labels、時間計測を伴う妥当化は未実施。

### モデル候補と明示的な参照判断の評価（2026-10-05追補）

`lexdiv_evaluate_contextual()` を追加した。取込済み出力と参照レビューの完全性・
同じ原文／候補集合を確認し、スコアの向きと同点許容幅を明示して比較する。
全候補が採点され、一つが最良の場合だけ予測IDを作る。候補欠落・同点・無得点・
候補なしでは予測を保留し、元のモデルエラーや未返却理由を保持する。人の判断を
変更せず、語別の混同行列と不一致／比較不能のKWICを返す。

一致数／比較可能数に加え、予測数／全例、参照選択数／全例、比較可能数／全例、
一致数／参照選択済み例数を返す。未選択の参照ラベルを誤答にも一致にも数えない。
単一候補の自明な予測を別計数し、候補IDを別の表層形と一括して混同しない。
候補完全性は利用者が指定した表に対するものに限り、未知の語義を網羅した証拠ではない。

参照ID・判定手順・モデル提示の有無・評価用途は宣言として保存する。not_shownや
held_outの指定だけで独立性・情報漏洩の不存在・正解ラベルの妥当性を保証しない。
指標名は記述的一致に留め、benchmark F1、κ、信頼区間、閾値最適化は実装しない。
埋め込みのみの出力から語義予測を生成しない。語義判別器の実装・研究評価とは別段階。

ガイドには、作成例で条件付き一致1/1に対し予測coverage1/4、参照選択例への一致1/3
となる例を追加した。高い条件付き一致だけではほとんどの用例が評価されていない事実を
見落とす。頻度基準との比較は別の訓練データで基準を作り、同じ参照・候補集合・評価規則を
使う。手法ごとのcoverageと共通に評価可能な出現集合を併記する。モデル提示前の独立評定、
語／文書単位のholdout、対象集団・ジャンルごとの誤り分析は引き続き研究として必要。

### 文脈ベクトルから比較可能な候補スコアへ（2026-10-05追補）

`lexdiv_score_contextual()` が、訓練側の選択済み参照ラベルと埋め込みから語義別の
平均ベクトルを作り、評価対象とのcosineを返す。訓練ラベル頻度も同時に返し、
同じ候補表・参照判断で比較できる。用例ごとの正規化はせず、平均後にL2正規化。
基礎となる平均語義表現は[Loureiro & Jorge (2019)](https://aclanthology.org/P19-1569/)を
参照するが、LMMS全体、WordNet伝播、gloss統合を再実装したものではない。

文書ID重複と対象語を含むsegmentの完全一致を拒否する。モデル宣言、次元・列順の名前、
候補表・資源も一致が必要。queryのラベルと既存スコアは学習に使わない。近似重複、
参加者共有、事前学習データへの混入、モデル選択段階での情報漏洩は自動保証できない。
訓練例数、利用可能ベクトル数、未知候補、ゼロ・欠測・相殺ベクトルを監査表へ保持する。
頻度基準は埋め込みのない選択済み訓練例も利用するため、両手法の訓練母数を区別する。

ガイドでは作成例による連携と、実際の意味精度の研究を区別する。次の実証的な問いは
対象語と語義表を固定した文書外評価で、頻度基準を上回るか、その差が言語・ジャンル・
頻度帯で維持されるかである。代表ベクトルのない未知語への一般化はこの手法の対象外。
モデル・層・閾値を比較するときは開発用データと最終評価を分け、訓練量・候補coverage・
共通に評価可能な出現集合を明記する。作成例の高い一致を実証結果として扱わない。

### 文脈評価を研究用フォルダへまとめる（2026-10-05追補）

`inst/examples/contextual-study/`に準備・評価・再集計の3本のR scriptを追加した。
Eguchi氏の研究用テンプレートからファイル単位の引継ぎを参考にし、既存APIを使って
独自に作成した。新しいexport・依存・解析器・モデル・外部コーパスは追加しない。
原文・ラベル・ベクトル・group IDはすべて作成例であり、独立した人手評定ではない。

14文書を訓練6・開発4・最終評価の例4へ分け、元の判断二つと裁定後の参照を保存する。
文書とmetadataの対応、group IDの集合、partition間の対象文脈の完全一致を検査し、
開発側の評価後に設定・訓練入力・R環境を固定する。評価側は候補スコアを保存してから
参照判断を読む。これらはアクセス制御や真の独立性を保証する仕組みではない。
CSVは可読なsnapshotであり、編集時はreview APIを通してRDSを明示的に再生成する。

作成例ではcosine法の条件付き一致は2/2、頻度基準は2/3だが、参照選択済み全例への
一致は両方2/3である。両手法が評価可能な共通2例では2/2対1/2となる。
共通集合は全4例の半分に限られ、未解決の参照1例は誤答にも一致にも入れない。
この違いを分母・KWIC・言語・groupとともに保存し、語別結果も保持する。
同じ集団の同じ推定対象を測った三つの精度だとは説明しない。

新規33件とAPI／installed smoke17件の計50件が配布アーカイブのインストール後に成功。
group共有、原文IDの不一致、空／重複metadata、IDを変えた開発文脈のコピー、
上書きの拒否、共通評価例0件、保存済み結果の不変性を確認した。
3本を別々のRセッションで実行し、入力フォルダを移動した後も再集計が成功した。
変更ガイドは実行構築し、残る17本と変更のない数値計算・モデル実行の証拠を再利用した。
詳細な配布物・検証記録は`PUBLICATION-20261004.md`を参照する。
