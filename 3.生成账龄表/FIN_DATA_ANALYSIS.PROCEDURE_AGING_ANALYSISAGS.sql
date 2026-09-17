CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.procedure_Aging_analysisags(executemonth IN varchar2 )
AS
finallycount NUMBER;
BEGIN 
 
 	-- 开始执行
 
 	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysisags','START','【账龄数据生成】方法正在执行');
 
 		-- 最终临时账龄表，金额<>0的数据，但是过程数据有冲销掉的数据，去除冲销的数据。
 		--DELETE FROM  temp_finally_FINANCE_Aging_analysis faa
 		--WHERE amountflag='C' AND EXISTS (
 		--SELECT 1 FROM temp_finally_FINANCE_Aging_analysis tfaa 
 		--WHERE tfaa.LEDGER_ID=faa.LEDGER_ID
 		--AND tfaa.SHORT_NAME=faa.SHORT_NAME
 		--AND tfaa.PERIOD_NAME=faa.SHORT_NAME
 		--AND tfaa.subject_id=faa.subject_id
 		--AND tfaa.PRODUCT_NO = faa.SHORT_NAME 
 		--AND tfaa.district_id=faa.district_id 
 		--AND tfaa.PRODUCT_CODE=faa.PRODUCT_CODE
 		--AND tfaa.JE_SOURCE=faa.JE_SOURCE
 		--AND tfaa.amount=faa.amount
 		--AND tfaa.amountflag='D'
 		--);
    SELECT count(id) INTO finallycount
        FROM temp_finally_FINANCE_Aging_analysis
        WHERE JE_SOURCE = 'AGS';
 		IF finallycount>0 THEN
 

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
INSERT INTO FINANCE_Aging_analysis (
    id,
    SHORT_NAME,
    PRODUCT_NO,
    --PRODUCT_CODE,
    PERIOD_NAME,
    subject_id,
    subject_name,
    amount,
    DEFAULT_EFFECTIVE_DATE,
    aging_month,
    handle_status,
    execute_method,
    district_id,
    DISTRICT_NAME,
    JE_SOURCE,
    BRANCH_CODE,             --机构
    START_DT,
    ACKNWLDG_RCPT_DT,
    BACK_VISITING_DATE,
    STATUS,
    AGENT_NAME,
    AGENT_STATUS,
    LINE_DESCIPTION,
    DSTRBTR_HEAD_CODE,
    DSTRBTR_HEAD_NAME,
    partner_id,
    POLICY_NO,
    DSTRBTR_OID,
    DSTRBTR_CODE,
    CHANNEL_CODE,
    BUSINESS_SCENE_NO,
    PRODUCT_CODE_NEW,
    PRODUCT_CODE_NEWNAME,
    FINANCE_DSTRBTR_SOURCE,
    AGING_PERIOD --账龄开始时间
)
WITH policy_totals AS (
    -- 仅取本次运行的AGS中间数据；窗口汇总代替原来的分组自关联。
    SELECT a.*,
           SUM(a.AMOUNT) OVER (
               PARTITION BY a.SUBJECT_ID,
                            a.POLICY_NO,
                            a.DISTRICT_ID,
                            a.JE_SOURCE,
                            a.DSTRBTR_SOURCE
           ) AS POLICY_AMOUNT
    FROM FIN_DATA_ANALYSIS.TEMP_FINALLY_FINANCE_AGING_ANALYSIS a
    WHERE a.JE_SOURCE = 'AGS'
),
grouped_result AS (
    -- 保留原来的完整结果分组，包括不写入结果表的LEDGER_ID、PRODUCT_CODE。
    SELECT p.LEDGER_ID,
           p.SHORT_NAME,
           p.PRODUCT_NO,
           p.PRODUCT_CODE,
           p.PERIOD_NAME,
           p.SUBJECT_ID,
           p.SUBJECT_NAME,
           SUM(p.AMOUNT) AS AMOUNT,
           p.DEFAULT_EFFECTIVE_DATE,
           p.AGING_MONTH,
           p.HANDLE_STATUS,
           p.EXECUTE_METHOD,
           p.DISTRICT_ID,
           p.JE_SOURCE,
           SUBSTR(p.BRANCH_CODE, 1, 9) AS BRANCH_CODE,
           p.START_DT,
           p.ACKNWLDG_RCPT_DT,
           p.BACK_VISITING_DATE,
           p.STATUS,
           p.AGENT_NAME,
           p.AGENT_STATUS,
           p.LINE_DESCIPTION,
           p.DSTRBTR_HEAD_CODE,
           p.DSTRBTR_HEAD_NAME,
           p.PARTNER_ID,
           p.POLICY_NO,
           p.DSTRBTR_OID,
           p.DSTRBTR_CODE,
           p.DSTRBTR_SOURCE,
           p.BUSINESS_SCENE_NO,
           p.PRODUCT_CODE_NEW,
           p.PRODUCT_CODE_NEWNAME,
           p.FINANCE_DSTRBTR_SOURCE
    FROM policy_totals p
    WHERE p.JE_SOURCE = 'AGS'
      AND p.POLICY_AMOUNT <> 0
    GROUP BY p.LEDGER_ID,
             p.SHORT_NAME,
             p.PRODUCT_NO,
             p.PRODUCT_CODE,
             p.PERIOD_NAME,
             p.SUBJECT_ID,
             p.SUBJECT_NAME,
             p.DEFAULT_EFFECTIVE_DATE,
             p.AGING_MONTH,
             p.HANDLE_STATUS,
             p.EXECUTE_METHOD,
             p.DISTRICT_ID,
             p.JE_SOURCE,
             SUBSTR(p.BRANCH_CODE, 1, 9),
             p.START_DT,
             p.ACKNWLDG_RCPT_DT,
             p.BACK_VISITING_DATE,
             p.STATUS,
             p.AGENT_NAME,
             p.AGENT_STATUS,
             p.LINE_DESCIPTION,
             p.DSTRBTR_HEAD_CODE,
             p.DSTRBTR_HEAD_NAME,
             p.PARTNER_ID,
             p.POLICY_NO,
             p.DSTRBTR_OID,
             p.DSTRBTR_CODE,
             p.DSTRBTR_SOURCE,
             p.BUSINESS_SCENE_NO,
             p.PRODUCT_CODE_NEW,
             p.PRODUCT_CODE_NEWNAME,
             p.FINANCE_DSTRBTR_SOURCE
    HAVING SUM(p.AMOUNT) <> 0
)
SELECT sequence_FINANCE_Aging_analysis.nextval AS id,
       g.SHORT_NAME,
       g.PRODUCT_NO,
       g.PERIOD_NAME,
       g.SUBJECT_ID,
       g.SUBJECT_NAME,
       g.AMOUNT,
       g.DEFAULT_EFFECTIVE_DATE,
       g.AGING_MONTH,
       g.HANDLE_STATUS,
       g.EXECUTE_METHOD,
       g.DISTRICT_ID,
       (SELECT d.BRANCH_NAME
          FROM MRT.FRS_DIM_COA_CO d
         WHERE d.BRANCH_CODE = g.DISTRICT_ID) AS DISTRICT_NAME,
       g.JE_SOURCE,
       g.BRANCH_CODE,
       g.START_DT,
       g.ACKNWLDG_RCPT_DT,
       g.BACK_VISITING_DATE,
       g.STATUS,
       g.AGENT_NAME,
       g.AGENT_STATUS,
       g.LINE_DESCIPTION,
       g.DSTRBTR_HEAD_CODE,
       g.DSTRBTR_HEAD_NAME,
       g.PARTNER_ID,
       g.POLICY_NO,
       g.DSTRBTR_OID,
       g.DSTRBTR_CODE,
       g.DSTRBTR_SOURCE AS CHANNEL_CODE,
       g.BUSINESS_SCENE_NO,
       g.PRODUCT_CODE_NEW,
       g.PRODUCT_CODE_NEWNAME,
       g.FINANCE_DSTRBTR_SOURCE,
       executemonth AS AGING_PERIOD
FROM grouped_result g
WHERE g.JE_SOURCE = 'AGS';

 		-- 执行结束记录日志  
 		INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','END','【账龄数据生成】方法执行结束');
 		ELSE 
 		INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','ERROR','【账龄数据生成】未生成最终临时账龄表数据');
 
 		END IF;
 
 		COMMIT;
 
END;
