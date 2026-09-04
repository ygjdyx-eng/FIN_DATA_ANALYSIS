# TMP抽数与结零年月标记 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不新增数据库表和字段的前提下，让 PLIS、GLIS 接收并按现有科目配置分流 `TMP` 增量，同时在长期历史表中记录本次结零年月，并提供受人工确认保护的重跑清理脚本。

**Architecture:** 阶段一只扩展来源过滤条件，进入系统后仍将来源归一为 `PLIS` 或 `GLIS`；阶段二只在长期历史表的有效结零更新中同步写入 `SHORT_NAME=YYYYMM`。人工重跑由独立运维脚本先预览影响行数，再以“系统-月份”确认口令执行恢复和删除，脚本不自动调用账龄过程。

**Tech Stack:** Oracle PL/SQL、Oracle Native Dynamic SQL、SQL*Plus/SQLcl 脚本、Shell 静态检查、Git

**Spec:** `/Users/yuegaojie/Desktop/存储过程/FIN_DATA_ANALYSIS/5.代码分析/10_结零年月标记与手工重跑设计.md`

## Global Constraints

- 不新增数据库表、字段、序列、包或存储过程。
- 只修改 PLIS、GLIS；AGS 的抽数、结零、恢复逻辑全部保持现状。
- PLIS 的 `TMP` 数据按 `SUBJECTENUMERATIONAGING.JE_SOURCE='PLIS'` 的科目分流，落表后统一为 `JE_SOURCE='PLIS'`。
- GLIS 的 `TMP` 数据只进入配置科目主分支，落表后统一为 `JE_SOURCE='GLIS'`；FCS 两个固定科目的特殊分支不接收 `TMP`。
- 上线前科目交集查询必须返回0行，否则停止部署，由业务先明确科目唯一归属。
- 结零年月格式固定为 `YYYYMM`，只写入长期历史表的 `SHORT_NAME`。
- PLIS 标记 `2` 和标记 `1` 的长期历史回写均记录结零年月；GLIS 只修改当前有效的两段标记 `2` 更新，注释状态的标记 `1` 代码不得启用。
- 未结零记录保持 `ZERO_CLOSING_MARKER='0' AND SHORT_NAME IS NULL`；历史旧结零记录的 `SHORT_NAME IS NULL` 保持不变。
- 人工重跑按“系统来源 + 处理年月”恢复；不自动恢复、不自动删除、不自动重试、不自动调用重跑过程。
- 不修改阶段三、`BALANCE_OFF`、月度编排包和定时任务。
- `HANDLE_STATUS`、`AGING_MARKER`、`AGING_PERIOD` 的现有业务含义保持不变。
- 公开月度入口仍接收 `YYYY-MM`；阶段一使用 `YYYY-MM`，阶段二和 `SHORT_NAME` 使用 `YYYYMM`，最终表期间使用 `YYYY0MM`。
- 每次 Git 提交只暂存本任务明确列出的文件，不包含 `.DS_Store` 或其他既有未跟踪文件。

## File Structure

- `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS01.sql` 至 `13.sql`：PLIS 十三个业务分支的当月增量抽取。
- `1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql`：GLIS 配置科目主分支和 FCS 固定科目特殊分支的当月增量抽取。
- `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0102.sql` 至 `1302.sql`：PLIS 十三个长期历史表的累计结零和跨档结零处理。
- `2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql`：GLIS 共享长期历史表的两段有效累计结零处理。
- `7.运维脚本/01_TMP科目归属检查.sql`：上线前只读门禁，检查 PLIS、GLIS 科目交集。
- `7.运维脚本/02_PLIS_GLIS手工重跑清理.sql`：指定系统和月份的影响预览、结零恢复、历史增量删除和最终结果删除。
- `7.运维脚本/03_测试库部署与编译检查.sql`：按依赖顺序在测试库重新编译本次修改的过程并查询编译错误。
- `5.代码分析/10_结零年月标记与手工重跑设计.md`：实施完成后记录验证结论并将状态更新为已实施。

---

### Task 1: PLIS十三个阶段一过程增加TMP来源

**Files:**

- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS01.sql:51`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS02.sql:47`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS03.sql:46`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04.sql:52`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS05.sql:53`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS06.sql:53`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS07.sql:52`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS08.sql:52`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS09.sql:53`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS10.sql:52`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS11.sql:54`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS12.sql:47`
- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS13.sql:53`

**Interfaces:**

- Consumes: `executemonth VARCHAR2`，格式 `YYYY-MM`；源表 `MRT.FRS_ODS_DW_SLA_LINES` 中 `JE_SOURCE='TMP'` 且科目属于 PLIS 配置的数据。
- Produces: 十三张 PLIS 当月临时表；新增数据继续使用现有常量列 `JE_SOURCE='PLIS'`。

- [ ] **Step 1: 运行修改前静态测试并确认失败**

```bash
plis_tmp_file_count=$(rg -l "f\.JE_SOURCE IN \([^)]*'TMP'" '1.增量抽数'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
test "$plis_tmp_file_count" = "13"
```

Expected: FAIL；当前13个文件均未包含 `TMP` 来源。

- [ ] **Step 2: 按现有来源顺序追加TMP**

01、02、03 使用：

```sql
AND f.JE_SOURCE IN ('PLIS','PLI','EFT','FCS','TMP')
```

04、05 使用：

```sql
AND f.JE_SOURCE IN ('PLIS','EFT','PLI','FCS','TMP')
```

06、07、08、09、10、11、12、13 使用：

```sql
AND f.JE_SOURCE IN ('PLIS','EFT','FCS','PLI','TMP')
```

不得修改紧随其后的 PLIS 科目过滤，也不得把 SELECT 列中的 `'PLIS' JE_SOURCE` 改成源字段。

- [ ] **Step 3: 运行静态测试确认十三个文件各出现一次TMP**

```bash
plis_tmp_file_count=$(rg -l "f\.JE_SOURCE IN \([^)]*'TMP'" '1.增量抽数'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
plis_tmp_occurrence_count=$(rg -o "'TMP'" '1.增量抽数'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
plis_normalized_source_count=$(rg -l "'PLIS'[[:space:]]+JE_SOURCE" '1.增量抽数'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
test "$plis_tmp_file_count" = "13"
test "$plis_tmp_occurrence_count" = "13"
test "$plis_normalized_source_count" = "13"
```

Expected: PASS；三个计数均为13。

- [ ] **Step 4: 审查差异，确认没有改变科目、账簿、月份和SHORT_NAME过滤**

```bash
git diff --check -- '1.增量抽数'
git diff -- '1.增量抽数'
```

Expected: 只有13处来源列表各增加一个 `'TMP'`。

- [ ] **Step 5: 提交PLIS抽数修改**

```bash
git add -- '1.增量抽数'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql
git commit -m "feat: PLIS抽数增加TMP来源"
```

---

### Task 2: GLIS主抽取分支增加TMP来源

**Files:**

- Modify: `1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql:56`
- Protect unchanged: `1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql:109`

**Interfaces:**

- Consumes: `executemonth VARCHAR2`，格式 `YYYY-MM`；源表中 `JE_SOURCE='TMP'` 且科目属于 GLIS 配置的数据。
- Produces: `TEMP_MONTH_GROUP_INSURANCE`；新增数据继续使用现有常量列 `JE_SOURCE='GLIS'`。

- [ ] **Step 1: 运行修改前静态测试并确认失败**

```bash
glis_tmp_occurrence_count=$(rg -o "'TMP'" '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql' | wc -l | tr -d ' ')
test "$glis_tmp_occurrence_count" = "1"
```

Expected: FAIL；当前文件没有 `TMP`。

- [ ] **Step 2: 只修改配置科目主分支**

```sql
AND f.JE_SOURCE IN ('GLI','GLIS','TMP')
AND SEGMENT3 IN (
  SELECT a.SUBJECT
    FROM SUBJECTENUMERATIONAGING a
   WHERE a.JE_SOURCE='GLIS'
)
```

FCS 特殊分支必须继续保持：

```sql
AND f.JE_SOURCE IN ('FCS')
AND SEGMENT3 IN ('2203010202','1221030601')
```

- [ ] **Step 3: 验证TMP只出现一次且来源仍归一为GLIS**

```bash
glis_tmp_occurrence_count=$(rg -o "'TMP'" '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql' | wc -l | tr -d ' ')
test "$glis_tmp_occurrence_count" = "1"
rg -n "f\.JE_SOURCE IN|SEGMENT3 IN|'GLIS'[[:space:]]+JE_SOURCE" '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql'
```

Expected: `TMP` 只在 `('GLI','GLIS','TMP')` 中出现；FCS 分支不变；两个 SELECT 分支写入的来源仍是 `GLIS`。

- [ ] **Step 4: 审查并提交GLIS抽数修改**

```bash
git diff --check -- '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql'
git diff -- '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql'
git add -- '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql'
git commit -m "feat: GLIS抽数增加TMP来源"
```

---

### Task 3: PLIS十三个阶段二过程记录结零年月

**Files:**

| 文件 | 标记2更新/执行行 | 标记1历史回写/执行行 | 长期历史表 |
|---|---:|---:|---|
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0102.sql` | 159/170 | 318/339 | `TEMP_FINANCE_AGING_ANALYSISPLIS01` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0202.sql` | 157/168 | 313/334 | `TEMP_FINANCE_AGING_ANALYSISPLIS02` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0302.sql` | 161/172 | 316/337 | `TEMP_FINANCE_AGING_ANALYSISPLIS03` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0402.sql` | 159/170 | 316/337 | `TEMP_FINANCE_AGING_ANALYSISPLIS04` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0502.sql` | 158/169 | 312/333 | `TEMP_FINANCE_AGING_ANALYSISPLIS05` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0602.sql` | 157/168 | 310/331 | `TEMP_FINANCE_AGING_ANALYSISPLIS06` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0702.sql` | 160/171 | 316/337 | `TEMP_FINANCE_AGING_ANALYSISPLIS07` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0802.sql` | 159/170 | 313/334 | `TEMP_FINANCE_AGING_ANALYSISPLIS08` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0902.sql` | 159/170 | 314/335 | `TEMP_FINANCE_AGING_ANALYSISPLIS09` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002.sql` | 159/170 | 317/338 | `TEMP_FINANCE_AGING_ANALYSISPLIS10` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1102.sql` | 158/169 | 314/335 | `TEMP_FINANCE_AGING_ANALYSISPLIS11` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1202.sql` | 155/166 | 309/330 | `TEMP_FINANCE_AGING_ANALYSISPLIS12` |
| `2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1302.sql` | 158/168 | 313/334 | `TEMP_FINANCE_AGING_ANALYSISPLIS13` |

**Interfaces:**

- Consumes: `executemonth VARCHAR2`，格式 `YYYYMM`；现有结零资格子查询和现有动态 SQL 绑定值。
- Produces: 长期历史表中新转为标记 `2` 或 `1` 的行同步写入 `SHORT_NAME=executemonth`。

- [ ] **Step 1: 运行修改前静态测试并确认失败**

```bash
plis_close_month_count=$(rg -o "SHORT_NAME=:close_month" '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
test "$plis_close_month_count" = "26"
```

Expected: FAIL；当前不存在结零年月绑定。

- [ ] **Step 2: 给每个标记2动态更新增加结零年月绑定**

每个文件只改变对应长期历史表的动态 UPDATE。将现有开头：

```plsql
vt_sql:='update TEMP_FINANCE_AGING_ANALYSISPLIS01 set ZERO_CLOSING_MARKER=''2'' where id in (
```

替换为：

```plsql
vt_sql:='update TEMP_FINANCE_AGING_ANALYSISPLIS01 set ZERO_CLOSING_MARKER=''2'', SHORT_NAME=:close_month where id in (
```

并将现有执行语句：

```plsql
EXECUTE IMMEDIATE vt_sql USING recday.lastday, recday.lastday;
```

替换为：

```plsql
EXECUTE IMMEDIATE vt_sql USING executemonth, recday.lastday, recday.lastday;
```

将示例表名按上表精确替换为 `01` 至 `13`。原 SQL 中两个 `:enddate` 的绑定顺序保持不变，仅在最前面新增 `executemonth`。

- [ ] **Step 3: 给每个标记1长期历史回写增加结零年月绑定**

不得修改 `v_fristsql` 对 `TEMP_FINALLY_FINANCE_AGING_ANALYSISnn` 的更新。只把 `v_sql` 中现有语句：

```plsql
UPDATE TEMP_FINANCE_AGING_ANALYSISPLIS01 a SET ZERO_CLOSING_MARKER=''1'' WHERE a.ID IN (
```

替换为：

```plsql
UPDATE TEMP_FINANCE_AGING_ANALYSISPLIS01 a SET ZERO_CLOSING_MARKER=''1'', SHORT_NAME=:close_month WHERE a.ID IN (
```

再将现有执行语句：

```plsql
EXECUTE IMMEDIATE v_sql USING rec.id, V_LAST_MONTH_END, V_LAST_MONTH_END, V_LAST_MONTH_END, V_LAST_MONTH_END, rec.id;
```

替换为：

```plsql
EXECUTE IMMEDIATE v_sql USING executemonth, rec.id, V_LAST_MONTH_END, V_LAST_MONTH_END, V_LAST_MONTH_END, V_LAST_MONTH_END, rec.id;
```

将示例表名按上表精确替换为 `01` 至 `13`。新增绑定位于 SQL 文本和 `USING` 列表的第一位；原六个绑定值的顺序不得改变。

- [ ] **Step 4: 在两类长期历史更新前增加用途注释**

```plsql
-- SHORT_NAME 专用于记录本行被本次 YYYYMM 处理结零，供人工重跑按月恢复。
-- 不写当月临时表和 TEMP_FINALLY 表；旧结零行的 SHORT_NAME 空值保持不变。
```

- [ ] **Step 5: 验证绑定数量和修改边界**

```bash
plis_close_month_count=$(rg -o "SHORT_NAME=:close_month" '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
plis_marker2_bind_count=$(rg -l "EXECUTE IMMEDIATE vt_sql USING executemonth" '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
plis_marker1_bind_count=$(rg -l "EXECUTE IMMEDIATE v_sql USING executemonth" '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql | wc -l | tr -d ' ')
test "$plis_close_month_count" = "26"
test "$plis_marker2_bind_count" = "13"
test "$plis_marker1_bind_count" = "13"
rg -n "temp_finally.*SHORT_NAME=:close_month" '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql
```

Expected: 前三个检查通过；最后一个命令无输出，证明结零年月没有写入 `TEMP_FINALLY`。

- [ ] **Step 6: 审查并提交PLIS结零年月修改**

```bash
git diff --check -- '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql
git diff -- '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql
git add -- '2.账龄结零'/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS*.sql
git commit -m "feat: 记录PLIS结零处理年月"
```

---

### Task 4: GLIS两段有效累计结零记录结零年月

**Files:**

- Modify: `2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql:111-123`
- Modify: `2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql:127-139`
- Protect unchanged: `2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql:266-319`

**Interfaces:**

- Consumes: `executemonth VARCHAR2`，格式 `YYYYMM`；两段现有 GLIS 标记 `2` 资格子查询。
- Produces: 共享长期表 `TEMP_FINANCE_AGING_ANALYSIS` 中新结零的 GLIS 行写入 `SHORT_NAME=executemonth`。

- [ ] **Step 1: 运行修改前静态测试并确认失败**

```bash
glis_close_month_count=$(rg -o "SHORT_NAME=:close_month" '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql' | wc -l | tr -d ' ')
test "$glis_close_month_count" = "2"
```

Expected: FAIL；当前两段更新只写标记和更新时间。

- [ ] **Step 2: 修改第一段按保单和科目累计结零**

将第111行动态 SQL 的开头替换为：

```plsql
-- SHORT_NAME 记录本行被本次 YYYYMM 处理结零，供人工重跑按月恢复。
vt_sql:='update temp_FINANCE_Aging_analysis set ZERO_CLOSING_MARKER=''2'',UPDATE_DATE=SYSDATE,SHORT_NAME=:close_month where id in (
```

将第123行替换为：

```plsql
EXECUTE IMMEDIATE vt_sql USING executemonth;
```

- [ ] **Step 3: 修改第二段按业务号、保单和科目累计结零**

将第127行动态 SQL 的开头替换为：

```plsql
-- SHORT_NAME 记录本行被本次 YYYYMM 处理结零，供人工重跑按月恢复。
vt_sql:='update temp_FINANCE_Aging_analysis set ZERO_CLOSING_MARKER=''2'',UPDATE_DATE=SYSDATE,SHORT_NAME=:close_month where id in (
```

将第139行替换为：

```plsql
EXECUTE IMMEDIATE vt_sql USING executemonth;
```

两段原有资格子查询都继续限定 `a.JE_SOURCE='GLIS'`。不得取消注释或改动标记 `1` 的整段注释代码。

- [ ] **Step 4: 验证两处绑定和GLIS隔离条件**

```bash
glis_close_month_count=$(rg -o "SHORT_NAME=:close_month" '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql' | wc -l | tr -d ' ')
glis_execute_bind_count=$(rg -o "EXECUTE IMMEDIATE vt_sql USING executemonth" '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql' | wc -l | tr -d ' ')
glis_source_guard_count=$(rg -o "a\.JE_SOURCE =''GLIS''" '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql' | wc -l | tr -d ' ')
test "$glis_close_month_count" = "2"
test "$glis_execute_bind_count" = "2"
test "$glis_source_guard_count" -ge "2"
```

Expected: PASS；结零年月和执行绑定各2处，两段资格子查询均保留 GLIS 条件。

- [ ] **Step 5: 审查并提交GLIS结零年月修改**

```bash
git diff --check -- '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql'
git diff -- '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql'
git add -- '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql'
git commit -m "feat: 记录GLIS结零处理年月"
```

---

### Task 5: 增加上线门禁和人工重跑清理脚本

**Files:**

- Create: `7.运维脚本/01_TMP科目归属检查.sql`
- Create: `7.运维脚本/02_PLIS_GLIS手工重跑清理.sql`

**Interfaces:**

- Consumes: 科目配置表；人工设置的 `P_SYSTEM`、`P_MONTH`、`P_CONFIRM`。
- Produces: 只读门禁结果；经精确口令确认后恢复目标结零标记、删除目标月份历史增量和最终结果。

- [ ] **Step 1: 创建TMP科目唯一归属门禁脚本**

```sql
SET PAGESIZE 500
SET LINESIZE 200

PROMPT === TMP科目归属交集明细：预期0行 ===
SELECT SUBJECT,
       LISTAGG(JE_SOURCE, ',') WITHIN GROUP (ORDER BY JE_SOURCE) AS SOURCE_LIST
  FROM (
        SELECT DISTINCT SUBJECT, JE_SOURCE
          FROM SUBJECTENUMERATIONAGING
         WHERE JE_SOURCE IN ('PLIS', 'GLIS')
       )
 GROUP BY SUBJECT
HAVING COUNT(*) > 1
 ORDER BY SUBJECT;

PROMPT === TMP科目归属交集数量：必须为0 ===
SELECT COUNT(*) AS TMP_SUBJECT_OVERLAP_COUNT
  FROM (
        SELECT SUBJECT
          FROM SUBJECTENUMERATIONAGING
         WHERE JE_SOURCE IN ('PLIS', 'GLIS')
         GROUP BY SUBJECT
        HAVING COUNT(DISTINCT JE_SOURCE) > 1
       );

DECLARE
  v_overlap_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO v_overlap_count
    FROM (
          SELECT SUBJECT
            FROM SUBJECTENUMERATIONAGING
           WHERE JE_SOURCE IN ('PLIS', 'GLIS')
           GROUP BY SUBJECT
          HAVING COUNT(DISTINCT JE_SOURCE) > 1
         );

  IF v_overlap_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20021,
      'TMP科目归属门禁失败，PLIS与GLIS存在交集科目：' || v_overlap_count
    );
  END IF;
END;
/
```

- [ ] **Step 2: 创建默认只预览的人工清理脚本**

```sql
SET SERVEROUTPUT ON
SET VERIFY OFF

-- 运行人员只修改以下三项。
DEFINE P_SYSTEM = PLIS
DEFINE P_MONTH = 202607
DEFINE P_CONFIRM = NO

DECLARE
  TYPE t_table_names IS TABLE OF VARCHAR2(128);
  v_plis_tables t_table_names := t_table_names(
    'TEMP_FINANCE_AGING_ANALYSISPLIS01',
    'TEMP_FINANCE_AGING_ANALYSISPLIS02',
    'TEMP_FINANCE_AGING_ANALYSISPLIS03',
    'TEMP_FINANCE_AGING_ANALYSISPLIS04',
    'TEMP_FINANCE_AGING_ANALYSISPLIS05',
    'TEMP_FINANCE_AGING_ANALYSISPLIS06',
    'TEMP_FINANCE_AGING_ANALYSISPLIS07',
    'TEMP_FINANCE_AGING_ANALYSISPLIS08',
    'TEMP_FINANCE_AGING_ANALYSISPLIS09',
    'TEMP_FINANCE_AGING_ANALYSISPLIS10',
    'TEMP_FINANCE_AGING_ANALYSISPLIS11',
    'TEMP_FINANCE_AGING_ANALYSISPLIS12',
    'TEMP_FINANCE_AGING_ANALYSISPLIS13'
  );
  v_system          VARCHAR2(4) := UPPER(TRIM('&&P_SYSTEM'));
  v_month           VARCHAR2(6) := TRIM('&&P_MONTH');
  v_confirm         VARCHAR2(20) := UPPER(TRIM('&&P_CONFIRM'));
  v_aging_period    VARCHAR2(7);
  v_month_date      DATE;
  v_restore_rows    PLS_INTEGER;
  v_history_rows    PLS_INTEGER;
  v_result_rows     PLS_INTEGER;
  v_total_restored  PLS_INTEGER := 0;
  v_total_history   PLS_INTEGER := 0;
BEGIN
  IF v_system NOT IN ('PLIS', 'GLIS') THEN
    RAISE_APPLICATION_ERROR(-20011, 'P_SYSTEM只能是PLIS或GLIS');
  END IF;

  IF NOT REGEXP_LIKE(v_month, '^[0-9]{6}$') THEN
    RAISE_APPLICATION_ERROR(-20012, 'P_MONTH必须使用YYYYMM，例如202607');
  END IF;

  BEGIN
    v_month_date := TO_DATE(v_month, 'FXYYYYMM');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20012, 'P_MONTH不是有效月份：' || v_month);
  END;

  IF TO_CHAR(v_month_date, 'YYYYMM') <> v_month THEN
    RAISE_APPLICATION_ERROR(-20012, 'P_MONTH不是有效月份：' || v_month);
  END IF;

  v_aging_period := SUBSTR(v_month, 1, 4) || '0' || SUBSTR(v_month, 5, 2);

  DBMS_OUTPUT.PUT_LINE('系统=' || v_system || '，处理月=' || v_month
    || '，最终期间=' || v_aging_period);

  IF v_system = 'PLIS' THEN
    FOR i IN 1 .. v_plis_tables.COUNT LOOP
      EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM ' || v_plis_tables(i)
        || ' WHERE ZERO_CLOSING_MARKER<>''0'' AND SHORT_NAME=:1'
        INTO v_restore_rows USING v_month;
      EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM ' || v_plis_tables(i)
        || ' WHERE AGING_MARKER=:1'
        INTO v_history_rows USING v_month;
      DBMS_OUTPUT.PUT_LINE(v_plis_tables(i)
        || '：待恢复=' || v_restore_rows
        || '，待删除增量=' || v_history_rows);
    END LOOP;
  ELSE
    SELECT COUNT(*)
      INTO v_restore_rows
      FROM TEMP_FINANCE_AGING_ANALYSIS
     WHERE JE_SOURCE='GLIS'
       AND ZERO_CLOSING_MARKER<>'0'
       AND SHORT_NAME=v_month;
    SELECT COUNT(*)
      INTO v_history_rows
      FROM TEMP_FINANCE_AGING_ANALYSIS
     WHERE JE_SOURCE='GLIS'
       AND AGING_MARKER=v_month;
    DBMS_OUTPUT.PUT_LINE('TEMP_FINANCE_AGING_ANALYSIS：待恢复='
      || v_restore_rows || '，待删除增量=' || v_history_rows);
  END IF;

  SELECT COUNT(*)
    INTO v_result_rows
    FROM FINANCE_AGING_ANALYSIS
   WHERE JE_SOURCE=v_system
     AND AGING_PERIOD=v_aging_period;
  DBMS_OUTPUT.PUT_LINE('FINANCE_AGING_ANALYSIS：待删除结果=' || v_result_rows);

  IF v_confirm <> v_system || '-' || v_month THEN
    DBMS_OUTPUT.PUT_LINE('当前仅预览，没有修改数据。');
    DBMS_OUTPUT.PUT_LINE('确认执行时将P_CONFIRM改为'
      || v_system || '-' || v_month || '后重新运行。');
    RETURN;
  END IF;

  IF v_system = 'PLIS' THEN
    FOR i IN 1 .. v_plis_tables.COUNT LOOP
      EXECUTE IMMEDIATE
        'UPDATE ' || v_plis_tables(i)
        || ' SET ZERO_CLOSING_MARKER=''0'', SHORT_NAME=NULL'
        || ' WHERE ZERO_CLOSING_MARKER<>''0'' AND SHORT_NAME=:1'
        USING v_month;
      v_total_restored := v_total_restored + SQL%ROWCOUNT;

      EXECUTE IMMEDIATE
        'DELETE FROM ' || v_plis_tables(i)
        || ' WHERE AGING_MARKER=:1'
        USING v_month;
      v_total_history := v_total_history + SQL%ROWCOUNT;
    END LOOP;
  ELSE
    UPDATE TEMP_FINANCE_AGING_ANALYSIS
       SET ZERO_CLOSING_MARKER='0',
           SHORT_NAME=NULL
     WHERE JE_SOURCE='GLIS'
       AND ZERO_CLOSING_MARKER<>'0'
       AND SHORT_NAME=v_month;
    v_total_restored := SQL%ROWCOUNT;

    DELETE FROM TEMP_FINANCE_AGING_ANALYSIS
     WHERE JE_SOURCE='GLIS'
       AND AGING_MARKER=v_month;
    v_total_history := SQL%ROWCOUNT;
  END IF;

  DELETE FROM FINANCE_AGING_ANALYSIS
   WHERE JE_SOURCE=v_system
     AND AGING_PERIOD=v_aging_period;
  v_result_rows := SQL%ROWCOUNT;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('已提交：恢复结零=' || v_total_restored
    || '，删除历史增量=' || v_total_history
    || '，删除最终结果=' || v_result_rows);
  DBMS_OUTPUT.PUT_LINE('清理脚本不会自动重跑；请人工调用对应单系统入口。');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/

-- 清理成功后，由运行人员另行选择并执行一个单系统入口：
-- BEGIN FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_PLIS('2026-07'); END;
-- /
-- BEGIN FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_GLIS('2026-07'); END;
-- /

UNDEFINE P_SYSTEM
UNDEFINE P_MONTH
UNDEFINE P_CONFIRM
```

- [ ] **Step 3: 在测试库验证默认预览不会改数据**

使用 `P_SYSTEM=PLIS`、`P_MONTH=202607`、`P_CONFIRM=NO` 执行脚本两次，分别在前后运行：

```sql
SELECT SUM(CASE WHEN SHORT_NAME='202607' AND ZERO_CLOSING_MARKER<>'0' THEN 1 ELSE 0 END) AS CLOSE_ROWS,
       SUM(CASE WHEN AGING_MARKER='202607' THEN 1 ELSE 0 END) AS HISTORY_ROWS
  FROM TEMP_FINANCE_AGING_ANALYSISPLIS01;

SELECT COUNT(*) AS RESULT_ROWS
  FROM FINANCE_AGING_ANALYSIS
 WHERE JE_SOURCE='PLIS'
   AND AGING_PERIOD='2026007';
```

Expected: 前后计数完全一致，输出包含“当前仅预览，没有修改数据”。

- [ ] **Step 4: 在测试库验证确认口令和范围隔离**

依次验证：

```text
P_SYSTEM=PLIS, P_MONTH=202607, P_CONFIRM=GLIS-202607  -> 只预览
P_SYSTEM=PLIS, P_MONTH=202607, P_CONFIRM=PLIS-202607  -> 只清理PLIS 202607
P_SYSTEM=GLIS, P_MONTH=202607, P_CONFIRM=GLIS-202607  -> 只清理GLIS 202607
P_SYSTEM=AGS,  P_MONTH=202607, P_CONFIRM=AGS-202607   -> ORA-20011
P_SYSTEM=PLIS, P_MONTH=202613, P_CONFIRM=PLIS-202613  -> ORA-20012
```

执行后验证：

```sql
SELECT JE_SOURCE, AGING_MARKER, ZERO_CLOSING_MARKER, SHORT_NAME, COUNT(*) AS ROWS_COUNT
  FROM TEMP_FINANCE_AGING_ANALYSIS
 WHERE JE_SOURCE IN ('GLIS','AGS')
 GROUP BY JE_SOURCE, AGING_MARKER, ZERO_CLOSING_MARKER, SHORT_NAME
 ORDER BY JE_SOURCE, AGING_MARKER, ZERO_CLOSING_MARKER, SHORT_NAME;
```

Expected: 目标 GLIS 月份被清理；AGS、其他月份、`SHORT_NAME IS NULL` 的旧结零行不变。

- [ ] **Step 5: 审查并提交运维脚本**

```bash
git diff --check -- '7.运维脚本'
git diff -- '7.运维脚本'
git add -- '7.运维脚本/01_TMP科目归属检查.sql' '7.运维脚本/02_PLIS_GLIS手工重跑清理.sql'
git commit -m "ops: 增加TMP门禁与手工重跑清理脚本"
```

---

### Task 6: 生成测试库部署脚本并完成全链路验证

**Files:**

- Create: `7.运维脚本/03_测试库部署与编译检查.sql`
- Modify: `5.代码分析/10_结零年月标记与手工重跑设计.md:4`

**Interfaces:**

- Consumes: Tasks 1-5 的全部 SQL 文件；测试库中的 PLIS、GLIS 配置和受控测试月份数据。
- Produces: 28个修改过程的有效编译状态、TMP分流证据、结零年月证据、恢复隔离证据和最终实施记录。

- [ ] **Step 1: 创建按依赖顺序执行的测试库部署脚本**

脚本先运行科目门禁；只有人工确认交集数量为0后，才继续执行下列文件：

```sql
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

@@01_TMP科目归属检查.sql

@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS01.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS02.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS03.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS05.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS06.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS07.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS08.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS09.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS10.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS11.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS12.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS13.sql
@@../1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdata.sql

@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0102.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0202.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0302.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0402.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0502.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0602.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0702.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0802.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0902.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1102.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1202.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1302.sql
@@../2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_glistempdataglis02.sql

PROMPT === 编译错误：预期0行 ===
SELECT NAME, TYPE, LINE, POSITION, TEXT
  FROM USER_ERRORS
 WHERE TYPE='PROCEDURE'
   AND (
        NAME LIKE 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS%'
        OR NAME IN (
          'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATA',
          'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATAGLIS02'
        )
       )
 ORDER BY NAME, SEQUENCE;

PROMPT === 对象状态：预期28行且全部VALID ===
SELECT OBJECT_NAME, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_TYPE='PROCEDURE'
   AND (
        OBJECT_NAME LIKE 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS%'
        OR OBJECT_NAME IN (
          'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATA',
          'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATAGLIS02'
        )
       )
 ORDER BY OBJECT_NAME;

DECLARE
  v_error_count   PLS_INTEGER;
  v_valid_count   PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
   WHERE TYPE='PROCEDURE'
     AND (
          NAME LIKE 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS%'
          OR NAME IN (
            'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATA',
            'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATAGLIS02'
          )
         );

  SELECT COUNT(*)
    INTO v_valid_count
    FROM USER_OBJECTS
   WHERE OBJECT_TYPE='PROCEDURE'
     AND STATUS='VALID'
     AND (
          OBJECT_NAME LIKE 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS%'
          OR OBJECT_NAME IN (
            'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATA',
            'PROCEDURE_AGING_ANALYSIS_GLISTEMPDATAGLIS02'
          )
         );

  IF v_error_count <> 0 OR v_valid_count <> 28 THEN
    RAISE_APPLICATION_ERROR(
      -20022,
      '编译门禁失败：错误数=' || v_error_count
      || '，VALID对象数=' || v_valid_count
    );
  END IF;
END;
/
```

部署脚本只用于测试库。生产执行仍需人工先查看 `TMP_SUBJECT_OVERLAP_COUNT=0`，再按照变更审批窗口单独启动。

- [ ] **Step 2: 在测试库验证TMP科目分流和去重**

选择同时含 PLIS、GLIS 配置科目的受控测试月。测试用 `BUSINESS_NO` 必须在该月唯一，数据同时满足现有账簿、机构和 `SHORT_NAME` 过滤。运行单系统入口后，按测试业务号查询源到目标的数量和金额：

```sql
BEGIN
  FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_PLIS('2026-07');
END;
/

BEGIN
  FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_GLIS('2026-07');
END;
/
```

两个单系统入口均不调用 `BALANCE_OFF`，便于在最终物理删除前完成抽数和结零核对。

```sql
SELECT c.JE_SOURCE AS TARGET_SYSTEM,
       COUNT(*) AS SOURCE_ROWS,
       SUM(NVL(f.ENTERED_DR, -f.ENTERED_CR)) AS SOURCE_AMOUNT
  FROM MRT.FRS_ODS_DW_SLA_LINES f
  JOIN (
        SELECT DISTINCT SUBJECT, JE_SOURCE
          FROM SUBJECTENUMERATIONAGING
         WHERE JE_SOURCE IN ('PLIS','GLIS')
       ) c
    ON c.SUBJECT=f.SEGMENT3
 WHERE f.PERIOD_NAME='2026-07'
   AND f.JE_SOURCE='TMP'
 GROUP BY c.JE_SOURCE
 ORDER BY c.JE_SOURCE;
```

```sql
WITH TMP_KEYS AS (
  SELECT DISTINCT c.JE_SOURCE AS TARGET_SYSTEM,
         NVL(f.BUSINESS_NO, f.POLICY_NO) AS BUSINESS_NO
    FROM MRT.FRS_ODS_DW_SLA_LINES f
    JOIN (
          SELECT DISTINCT SUBJECT, JE_SOURCE
            FROM SUBJECTENUMERATIONAGING
           WHERE JE_SOURCE IN ('PLIS','GLIS')
         ) c
      ON c.SUBJECT=f.SEGMENT3
   WHERE f.PERIOD_NAME='2026-07'
     AND f.JE_SOURCE='TMP'
)
SELECT t.JE_SOURCE, COUNT(*) AS TARGET_ROWS, SUM(t.AMOUNT) AS TARGET_AMOUNT
  FROM (
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE01
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE02
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE03
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE04
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE05
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE06
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE07
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE08
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE09
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE10
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE11
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE12
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_PERSONAL_INSURANCE13
        UNION ALL
        SELECT JE_SOURCE, AMOUNT, BUSINESS_NO FROM TEMP_MONTH_GROUP_INSURANCE
       ) t
  JOIN TMP_KEYS k
    ON k.TARGET_SYSTEM=t.JE_SOURCE
   AND k.BUSINESS_NO=t.BUSINESS_NO
 GROUP BY t.JE_SOURCE
 ORDER BY t.JE_SOURCE;
```

Expected: TMP 源数据按配置只进入一个系统；目标来源只有 `PLIS`、`GLIS`，没有 `TMP` 和 `AGS`；按过程原有过滤条件解释后的数量和金额一致。

- [ ] **Step 3: 在测试库验证结零年月**

受控数据至少覆盖一个 PLIS 标记 `2`、一个 PLIS 标记 `1` 和一个 GLIS 标记 `2`。运行后检查全部13张 PLIS 长期历史表：

```sql
SET SERVEROUTPUT ON

DECLARE
  TYPE t_table_names IS TABLE OF VARCHAR2(128);
  v_plis_tables t_table_names := t_table_names(
    'TEMP_FINANCE_AGING_ANALYSISPLIS01',
    'TEMP_FINANCE_AGING_ANALYSISPLIS02',
    'TEMP_FINANCE_AGING_ANALYSISPLIS03',
    'TEMP_FINANCE_AGING_ANALYSISPLIS04',
    'TEMP_FINANCE_AGING_ANALYSISPLIS05',
    'TEMP_FINANCE_AGING_ANALYSISPLIS06',
    'TEMP_FINANCE_AGING_ANALYSISPLIS07',
    'TEMP_FINANCE_AGING_ANALYSISPLIS08',
    'TEMP_FINANCE_AGING_ANALYSISPLIS09',
    'TEMP_FINANCE_AGING_ANALYSISPLIS10',
    'TEMP_FINANCE_AGING_ANALYSISPLIS11',
    'TEMP_FINANCE_AGING_ANALYSISPLIS12',
    'TEMP_FINANCE_AGING_ANALYSISPLIS13'
  );
  v_month_close_rows PLS_INTEGER;
  v_bad_open_rows     PLS_INTEGER;
BEGIN
  FOR i IN 1 .. v_plis_tables.COUNT LOOP
    EXECUTE IMMEDIATE
      'SELECT COUNT(CASE WHEN ZERO_CLOSING_MARKER IN (''1'',''2'')'
      || ' AND SHORT_NAME=''202607'' THEN 1 END),'
      || ' COUNT(CASE WHEN ZERO_CLOSING_MARKER=''0'''
      || ' AND SHORT_NAME IS NOT NULL THEN 1 END)'
      || ' FROM ' || v_plis_tables(i)
      INTO v_month_close_rows, v_bad_open_rows;
    DBMS_OUTPUT.PUT_LINE(v_plis_tables(i)
      || '：本月结零=' || v_month_close_rows
      || '，未结零但SHORT_NAME非空=' || v_bad_open_rows);
  END LOOP;
END;
/

SELECT ZERO_CLOSING_MARKER, SHORT_NAME, COUNT(*) AS ROWS_COUNT
  FROM TEMP_FINANCE_AGING_ANALYSIS
 WHERE JE_SOURCE='GLIS'
   AND ZERO_CLOSING_MARKER='2'
 GROUP BY ZERO_CLOSING_MARKER, SHORT_NAME
 ORDER BY SHORT_NAME;
```

Expected: 受控的新结零行 `SHORT_NAME='202607'`，所有 PLIS 表的“未结零但SHORT_NAME非空”均为0；本次执行前记录的基线查询与执行后对比证明旧结零行没有被补写。

- [ ] **Step 4: 执行静态边界检查**

```bash
tmp_outside_scope_count=$(rg -o "'TMP'" '1.增量抽数/FIN_DATA_ANALYSIS.procedure_Aging_analysis_tempdataAGS.sql' '2.账龄结零/FIN_DATA_ANALYSIS.procedure_Aging_analysis_tempdataAGS02.sql' | wc -l | tr -d ' ')
test "$tmp_outside_scope_count" = "0"

forbidden_change_count=$(git diff HEAD~5..HEAD --name-only | rg '阶段3|BALANCE_OFF|PKG_FINANCE_AGING_MONTHLY|JOB_FINANCE_AGING_MONTHLY' | wc -l | tr -d ' ')
test "$forbidden_change_count" = "0"
git diff --check HEAD~5..HEAD
```

Expected: AGS 的 TMP 计数为0；阶段三、`BALANCE_OFF`、编排包、定时任务均未出现在修改清单；差异格式检查通过。

- [ ] **Step 5: 更新设计文档实施状态和验证记录**

全部测试库验证通过后，将状态改为：

```text
状态：已实施，测试库验证通过，待生产部署
```

在设计文档末尾粘贴本计划中实际执行的 Git 日志和测试库查询输出，包括28个过程的编译结果、科目交集数量、TMP数量/金额勾稽结果、结零标记分布和人工清理隔离验证结果。不得用推断结论代替实际输出。

- [ ] **Step 6: 提交部署脚本和实施记录**

```bash
git add -- '7.运维脚本/03_测试库部署与编译检查.sql' '5.代码分析/10_结零年月标记与手工重跑设计.md'
git commit -m "docs: 补充测试库部署与验证记录"
```

- [ ] **Step 7: 最终核对提交范围**

```bash
git status --short
git log --oneline -6
git diff HEAD~6..HEAD --stat
```

Expected: 本功能共6个聚焦提交；既有 `.DS_Store` 和无关未跟踪文件仍未暂存、未提交。
