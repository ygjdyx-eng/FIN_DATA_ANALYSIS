# PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS01

- 【代码事实】技术目的：刷新 PLIS01 月度桥接表和对应当批表，并从总账抽取机构范围 `001001%` 的明细。
- 【合理推断】业务目的：为 PLIS01 机构范围的后续账龄累计、分档和最终汇总准备当月明细。
- 【合理推断】最小示例：若源行借方100、贷方NULL、业务号NULL、保单P1，则写入金额100且业务号P1；若维表/过滤均满足，该行进入01月度表。

- 【代码事实】用途与接口：阶段 1 的 PLIS01 增量抽取，入参 `executemonth` 使用已确认正确的 `YYYY-MM`（调用为 `2025-04`）；机构范围为 `BRANCH_CODE LIKE '001001%'`。证据：过程 `:1-2,:49`，调用脚本 `:3`。
- 【代码事实】顺序与对象：写 START 日志 → TRUNCATE `temp_month_personal_insurance01`、`temp_finally_FINANCE_Aging_analysis01` → 从 `MRT.FRS_ODS_DW_SLA_LINES` 及科目/机构维表抽取 → 写完成描述日志 → COMMIT。证据：`:4-57`。
- 【代码事实】写入粒度/字段：逐总账行写保单、来源、科目、账户段、会计日期、金额、机构、行说明、业务号；`JE_SOURCE` 固定为 `PLIS`，`BUSINESS_NO=NVL(BUSINESS_NO,POLICY_NO)`。证据：`:11-48`。
- 【代码事实】金额与账户：`amount=NVL(ENTERED_DR,-ENTERED_CR)`；部分科目保留 `SEGMENT4`，`2243010102` 的 1401～1408 映射为同值，其他置空。证据：`:25-36`。
- 【代码事实】过滤：排除账簿 2222/2030、限定期间和来源、按 `SUBJECTENUMERATIONAGING` 的 PLIS 科目过滤，并排除 `SHORT_NAME LIKE 'THTF_I17%'`。证据：`:39-53`。
- 【代码事实】事务/日志：两次 TRUNCATE 带来隐式提交，末尾显式提交；完成日志的 `METHOD_STATUS` 仍写 `START`。证据：`:7-8,:55-57`。
- 【合理推断】风险：过程不是原子事务；全局中间表无批次隔离，不宜并发；完成状态错误会误导监控；维表标量子查询若多行会触发 ORA-01427。
- 【待业务确认】核实 `SEGMENT1='100001'` 未采用其他 PLIS 分支的机构特例是否符合 PLIS01 口径，并补充目标表 DDL/唯一键/触发器。
