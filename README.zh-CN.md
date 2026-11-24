# moonjudge

MoonBit 本地评测与对拍工具链 —— 用 MoonBit 原生重写 [testlib.h](https://github.com/MikeMirzayanov/testlib)
（MIT，Codeforces）的严格校验语义，配套种子化数据生成、带超时的子进程运行器，以及可复现的对拍 CLI。

> 2026 MoonBit 黑客松参赛作品 · 方向：开发者工具 · 十一月赛。
>
> English: [README.md](README.md)

## 为什么做

竞赛训练（CSP / ICPC / Codeforces）离不开对拍与严格输出校验。MoonBit 已有
`ac-library-mbt`、`moongraph` 等算法库，却没有配套的本地评测/验证工具——
对 mooncakes 约 100 个关键词的查重显示 `testlib`、判题类项目为零。`moonjudge`
用原生 MoonBit 填补这一缺口。

## 安装（mooncakes）

已发布到 [mooncakes.io](https://mooncakes.io)，包名 `xcc-ordinary/moonjudge`：

```bash
moon add xcc-ordinary/moonjudge
```

然后按需导入，例如 `xcc-ordinary/moonjudge/checkers`（别名 `@checkers`）
与 `xcc-ordinary/moonjudge/stress`。

## 功能

- **`checker`** —— 严格流式校验核心（`InStream`）：`read_int`（符号/前导零/负零/
  溢出/边界/token 边界规则）、`read_double`（严格小数/指数，拒绝非有限值）、`read_token`、
  `read_line`、`read_eof`、`ensure`；`CheckError` 与 `Verdict`（AC/WA/TLE/RE/CF）。
- **`checkers`** —— 现成 checker：`check_ints`、`check_int_sequence`、
  `check_unordered_ints`（多重集）、`check_permutation`（1..n）、`check_yes_no`、
  `check_token`、`check_double`/`check_doubles`/`check_double_sequence`（绝对/相对容差）、
  `check_sorted`（非递减）、`check_unordered_doubles`（容差多重集）、
  `check_tokens`（字符串序列，可选大小写不敏感）。
- **`gen`** —— 可复现 `Rng`（xorshift64*）：`next_int`、`next_array`、`permutation`。
- **`runner`** —— 异步子进程执行：stdin 喂入、stdout/stderr 捕获、超时终止、判定映射。
- **`stress`** —— 可复现对拍循环（`stress_inprocess`），四种比较模式
  （Exact / Ints / UnorderedInts / Doubles(eps)），返回首个反例及其种子以便复现。
- **`cmd/moonjudge`** —— CLI：`demo` / `judge` / `stress` / `batch`。`judge` 支持
  `--answer` 对参考答案评测；`batch` 遍历目录批量评测；反例落盘 `moonjudge-failure/`。

## 快速开始

```bash
moon test --target wasm          # 全量回归（87 测试）
moon test --target wasm-gc       # 纯逻辑包（78 测试）

# 自包含演示：抓出植入 bug 并保存反例
moon run --target wasm cmd/moonjudge -- demo

# 评测单个程序：格式校验，或对参考答案比对
moon run --target wasm cmd/moonjudge -- judge --prog "sol.exe" --answer ans.txt --checker doubles

# 对拍外部程序（生成器以轮次种子作为最后一个参数）
moon run --target wasm cmd/moonjudge -- stress --gen "gen.exe" --brute "brute.exe" --fast "fast.exe" --rounds 100 --seed 42

# 批量评测目录（每个用例 case.in + case.ans）
moon run --target wasm cmd/moonjudge -- batch --prog "sol.exe" --tests ./tests --checker ints
```

`wasm` 目标经 `moonrun` 开箱即用，可 spawn 真实操作系统进程，无需 C 编译器；
`native` 目标亦支持，但需系统 C 编译器（cc/gcc/clang）构建运行时。

## 真实对拍案例（dogfooding）

- **最大子段和**：O(n²) 暴力 vs Kadane（"best 初始化为 0" 经典 bug）。
  反例 `input=[2 -4 -2]`，brute=-2 / buggy=0；修正后 2000 轮全过。
- **lower_bound 二分**：`a[mid] <= target` 误算成 upper_bound，重复元素时出错。
  反例 `input=[8 1 0 0 1 3 3 4 4 4]` target=1，brute=2 / buggy=3；修正后全过。

## 性能（可复现基准）

`moon test --target wasm-gc checkers`：

```
check_int_sequence:    4000000 ints in ~0.15s   (~2700 万整数/秒)
check_unordered_ints:  30000 ints (reversed) in ~0.003s
```

无序校验改用内置 `Array::sort`，最坏（逆序）输入较原插入排序**提速约 34×**。
绝对数值随硬件与构建模式变化（此处 wasm-gc debug），测试已提交可复现。

## 验证

- wasm 全量 **87 测试通过**，wasm-gc 纯逻辑 **78** 通过。
- CI（GitHub Actions）在每次 push/PR 时跑 check + 全量测试。
- 故意构造的错误回归样例库覆盖每条严格整数/浮点规则。
- 跨平台集成测试按操作系统选择 `cmd.exe` / `sh`。

## 许可与来源

MIT。校验语义参照 testlib.h（MIT），未复制任何 testlib 代码，规则均以 MoonBit
原生重写。见 `LICENSE`。

## AI 使用说明

AI 辅助代码生成与 API 探索。目标、任务拆解、技术选型与最终质量由参赛者掌握并可解释；
全部开发通过公开提交记录追踪。