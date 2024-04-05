-- local fewshot = {
--     messages = {
--         {
--             role = "system",
--             content = [[
-- You must identify any readability issues in the code snippet.
-- Some readability issues to consider:
-- - Unclear naming
-- - Unclear purpose
-- - Redundant or obvious comments
-- - Lack of comments
-- - Long or complex one liners
-- - Too much nesting
-- - Long variable names
-- - Inconsistent naming and code style.
-- - Code repetition
-- You may identify additional problems. The user submits a small section of code from a larger file.
-- Only list lines with readability issues, in the format line=<num>: <issue and proposed solution>
-- Your commentary must fit on a single line]]
--         },
--         {
--             role = "user",
--             content = [[
-- 04 public class Logic {
-- 05     public static void main(String[] args) {
-- 06         Scanner sc = new Scanner(System.in);
-- 07         int n = sc.nextInt();
-- 08         int[] arr = new int[n];
-- 09         for (int i = 0; i < n; i++) {
-- 10             arr[i] = sc.nextInt();
-- 11         }
-- 12         int[] dp = new int[n];
-- 13         dp[0] = arr[0];
-- 14         dp[1] = Math.max(arr[0], arr[1]);
-- 15         for (int i = 2; i < n; i++) {
-- 16             dp[i] = Math.max(dp[i - 1], dp[i - 2] + arr[i]);
-- 17         }
-- 18         System.out.println(dp[n - 1]);
-- 19     }
-- 20 }]]
--         },
--         {
--             role = "assistant",
--             content = [[
-- line=4: The class name 'Logic' is too generic. A more meaningful name could be 'DynamicProgramming'
-- line=6: The variable name 'sc' is unclear. A more meaningful name could be 'scanner'.
-- line=7: The variable name 'n' is unclear. A more meaningful name could be 'arraySize' or 'numElements'.
-- line=8: The variable name 'arr' unclear. A more descriptive name could be 'inputArray' or 'elementValues'.
-- line=12: The variable name 'dp' is unclear. A more informative name could be 'maxSum' or 'optimalSolution'.
-- line=13: There are no comments explaining the meaning of the 'dp' array values and how they relate to the problem statement.
-- line=15: There are no comments explaining the logic and purpose of the for loop]]
--         },
--         {
--             role = "user",
--             content = [[
-- 673    for (let i: number = 0; i < l; i++) {
-- 674       let notAddr: boolean = false;
-- 675       // non standard input
-- 676       if (items[i].scriptSig && !items[i].addr) {
-- 677         items[i].addr = 'Unparsed address [' + u++ + ']';
-- 678         items[i].notAddr = true;
-- 679         notAddr = true;
-- 680       }
-- 681
-- 682       // non standard output
-- 683       if (items[i].scriptPubKey && !items[i].scriptPubKey.addresses) {
-- 684         items[i].scriptPubKey.addresses = ['Unparsed address [' + u++ + ']'];]]
--         },
--         {
--             role = "assistant",
--             content = [[
-- line=673: The variable name 'i' and 'l' are unclear and easily confused with other characters like '1'. More meaningful names could be 'index' and 'length' respectively.
-- line=674: The variable name 'notAddr' is unclear and a double negative. An alternative could be 'hasUnparsedAddress'.
-- line=676: The comment "non standard input" is not very informative. It could be more descriptive, e.g., "Check for non standard input address"
-- line=682: The comment "non standard output" is not very informative. It could be more descriptive, e.g., "Check for non standard output address"
-- line=683: The variable name 'items' might be more informative if changed to 'transactions' or 'txItems'.
-- line=684: The array element 'Unparsed address [' + u++ + ']' could use a more descriptive comment, e.g., "Assign a unique identifier to non standard output addresses"
-- line=684: The variable name 'u' is unclear. A more meaningful name could be 'unparsedAddressCount' or 'unparsedAddressId'.]]
--         }
--     }
-- }
--
-- return fewshot

-- local fewshot = {
--     messages = {
--         {
--             role = "system",
--             content = [[
-- コードスニペットの可読性の問題を特定する必要があります。
-- 考慮すべき可読性の問題：
-- - 不明瞭な命名
-- - 不明瞭な目的
-- - 冗長または明らかなコメント
-- - コメントがない
-- - 長いまたは複雑な1行
-- - ネストが深すぎる
-- - 長い変数名
-- - 一貫性のない命名とコードスタイル。
-- - コードの繰り返し
-- 追加の問題を特定することができます。ユーザーは大きなファイルから小さなコードセクションを提出します。
-- 可読性の問題を特定するには、問題と提案された解決策を含む行のみをリストアップしてください。
-- あなたのコメントは1行に収まる必要があります]]
--         },
--         {
--             role = "user",
--             content = [[
-- 04 public class Logic {
-- 05     public static void main(String[] args) {
-- 06         Scanner sc = new Scanner(System.in);
-- 07         int n = sc.nextInt();
-- 08         int[] arr = new int[n];
-- 09         for (int i = 0; i < n; i++) {
-- 10             arr[i] = sc.nextInt();
-- 11         }
-- 12         int[] dp = new int[n];
-- 13         dp[0] = arr[0];
-- 14         dp[1] = Math.max(arr[0], arr[1]);
-- 15         for (int i = 2; i < n; i++) {
-- 16             dp[i] = Math.max(dp[i - 1], dp[i - 2] + arr[i]);
-- 17         }
-- 18         System.out.println(dp[n - 1]);
-- 19     }
-- 20 }]]
--         },
--         {
--             role = "assistant",
--             content = [[
-- line=4: クラス名 'Logic' はあまりにも一般的です。より意味のある名前に変更することができます 'DynamicProgramming'
-- line=6: 変数名 'sc' は不明瞭です。より意味のある名前に変更することができます 'scanner'。
-- line=7: 変数名 'n' は不明瞭です。より意味のある名前に変更することができます 'arraySize' または 'numElements'。
-- line=8: 変数名 'arr' は不明瞭です。より説明的な名前に変更することができます 'inputArray' または 'elementValues'。
-- line=12: 変数名 'dp' は不明瞭です。より情報提供的な名前に変更することができます 'maxSum' または 'optimalSolution'。
-- line=13: 'dp' 配列の値の意味と問題文との関係を説明するコメントがありません。
-- line=15: for ループのロジックと目的を説明するコメントがありません。]]
--         },
--         {
--             role = "user",
--             content = [[
-- 673    for (let i: number = 0; i < l; i++) {
-- 674       let notAddr: boolean = false;
-- 675       // non standard input
-- 676       if (items[i].scriptSig && !items[i].addr) {
-- 677         items[i].addr = 'Unparsed address [' + u++ + ']';
-- 678         items[i].notAddr = true;
-- 679         notAddr = true;
-- 680       }
-- 681
-- 682       // non standard output
-- 683       if (items[i].scriptPubKey && !items[i].scriptPubKey.addresses) {
-- 684         items[i].scriptPubKey.addresses = ['Unparsed address [' + u++ + ']'];]]
--         },
--         {
--             role = "assistant",
--             content = [[
-- line=673: 変数名 'i' と 'l' は不明瞭で、'1' などの他の文字と簡単に混同されます。より意味のある名前に変更することができます 'index' および 'length' それぞれ。
-- line=674: 変数名 'notAddr' は不明瞭で、二重否定です。代替として 'hasUnparsedAddress' があります。
-- line=676: コメント "non standard input" はあまり情報提供的ではありません。より記述的にすることができます、例えば "非標準入力アドレスをチェック"。
-- line=682: コメント "non standard output" はあまり情報提供的ではありません。より記述的にすることができます、例えば "非標準出力アドレスをチェック"。
-- line=683: 変数名 'items' は 'transactions' または 'txItems' に変更するとより情報提供的かもしれません。
-- line=684: 配列要素 'Unparsed address [' + u++ + ']' には、より記述的なコメントが必要です、例えば "非標準出力アドレスに一意の識別子を割り当てる"。
-- line=684: 変数名 'u' は不明瞭です。より意味のある名前に変更することができます 'unparsedAddressCount' または 'unparsedAddressId'。]]
--         }
--     }
-- }
--
-- return fewshot


local fewshot = {
    messages = {
        {
            role = "system",
            content = [[
コードスニペットのセキュリティリスク、バグ、またはその他の問題を特定する必要があります。
考慮すべき可読性のことができます。ユーザーは大きなファイルから小さなコードセクションを提出します。
可読性の問題を特定するには、問題と提案された解決策を含む行のみをリストアップしてください。
]]
        },
-- 不具合を含んでいるコード
        {
            role = "user",
            content = [[
04 $users = User::where('status', 'active')->get();
05 foreach ($users as $user) {
06     $user->status = 'inactive';
07     $user->save();
08 }
]]
        },
-- 不具合を指摘する
        {
            role = "assistant",
            content = [[
line=4: 'status' が 'active' のユーザーを取得するクエリは、'status' が 'active' であるユーザーを取得するため、意図しないユーザーが取得される可能性があります。
line=6: ループ内でユーザーのステータスを 'inactive' に変更して保存していますが、ループ内でユーザーのステータスを変更すると、ループの次のイテレーションで変更された値が反映される可能性があります。
line=7: ユーザーのステータスを変更した後、ユーザーを保存していますが、ループ内でユーザーを保存すると、データベースへのクエリが多く発生する可能性があります。]]
        }
    }
}

return fewshot
