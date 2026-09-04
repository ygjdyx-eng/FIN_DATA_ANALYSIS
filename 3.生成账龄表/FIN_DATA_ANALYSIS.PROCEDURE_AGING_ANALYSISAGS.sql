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
 		SELECT count(id) INTO finallycount FROM temp_finally_FINANCE_Aging_analysis;
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
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,
    subquery_result.SHORT_NAME,
    subquery_result.PRODUCT_NO,
    --subquery_result.PRODUCT_CODE,
    subquery_result.PERIOD_NAME,
    subquery_result.subject_id,
    subquery_result.subject_name,
    subquery_result.sum_amount AS amount,
    subquery_result.DEFAULT_EFFECTIVE_DATE,
    subquery_result.aging_month,
    subquery_result.handle_status,
    subquery_result.execute_method,
    subquery_result.district_id,
    --(CASE  WHEN subquery_result.SUBJECT_ID ='2202020203'
    --    THEN (SELECT a.BRANCH_LV2_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a.BRANCH_LV2_CODE =subquery_result.district_id) 
    --    else
    (SELECT a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) 
    -- end)
    AS DISTRICT_NAME, --地址名称
    subquery_result.JE_SOURCE,
    subquery_result.BRANCH_CODE,
    subquery_result.START_DT,
    subquery_result.ACKNWLDG_RCPT_DT,
    subquery_result.BACK_VISITING_DATE,
    subquery_result.STATUS,
    subquery_result.AGENT_NAME,
    subquery_result.AGENT_STATUS,
    subquery_result.LINE_DESCIPTION,
    subquery_result.DSTRBTR_HEAD_CODE,
    subquery_result.DSTRBTR_HEAD_NAME,
    subquery_result.partner_id,
    subquery_result.POLICY_NO,
    subquery_result.DSTRBTR_OID,
    subquery_result.DSTRBTR_CODE,
    subquery_result.DSTRBTR_SOURCE,
    subquery_result.BUSINESS_SCENE_NO,
    subquery_result.PRODUCT_CODE_NEW,
    subquery_result.PRODUCT_CODE_NEWNAME,
    subquery_result.FINANCE_DSTRBTR_SOURCE,
    executemonth  AS AGING_PERIOD
FROM (
    SELECT 
        SHORT_NAME,
        PRODUCT_NO,
        PRODUCT_CODE,
        PERIOD_NAME,
        a.subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        DEFAULT_EFFECTIVE_DATE,
        aging_month,
        handle_status,
        execute_method,
        a.district_id,
        a.JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
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
        a.POLICY_NO,
        DSTRBTR_OID,
        DSTRBTR_CODE,
        a.DSTRBTR_SOURCE,
        BUSINESS_SCENE_NO,
        PRODUCT_CODE_NEW,
        PRODUCT_CODE_NEWNAME,
        FINANCE_DSTRBTR_SOURCE
    FROM 
        temp_finally_FINANCE_Aging_analysis a  
        JOIN (
        --按照 机构，保单号，科目，渠道进行分组，合计金额是不为0进行核销排除
        SELECT  subject_id,
                b.POLICY_NO,
                DISTRICT_ID,
                JE_SOURCE,
                DSTRBTR_SOURCE 
         FROM temp_finally_FINANCE_Aging_analysis  b 
         WHERE 1=1 
         GROUP BY  
             subject_id,
             b.POLICY_NO,
             DISTRICT_ID,
             JE_SOURCE,
             DSTRBTR_SOURCE
        HAVING SUM(amount) <> 0
    ) tm2   
    ON  NVL(a.subject_id,'null')  =NVL( tm2.subject_id ,'null')
    and  NVL(a.POLICY_NO,'null')  =NVL( tm2.POLICY_NO ,'null')
    and  NVL(a.DISTRICT_ID,'null')  =NVL( tm2.DISTRICT_ID ,'null')
    and  NVL(a.JE_SOURCE,'null')  =NVL( tm2.JE_SOURCE ,'null')
    and  NVL(a.DSTRBTR_SOURCE,'null')  =NVL( tm2.DSTRBTR_SOURCE ,'null')
    WHERE 
       a.JE_SOURCE = 'AGS'
    GROUP BY 
        LEDGER_ID,
        SHORT_NAME,
        PRODUCT_NO,
        PRODUCT_CODE,
        PERIOD_NAME,
        a.subject_id,
        subject_name,
        DEFAULT_EFFECTIVE_DATE,
        aging_month,
        handle_status,
        execute_method,
        a.district_id,
        a.JE_SOURCE,
        SUBSTR(a.BRANCH_CODE, 1, 9),
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
        a.POLICY_NO,
        DSTRBTR_OID,
        DSTRBTR_CODE,
        a.DSTRBTR_SOURCE,
        BUSINESS_SCENE_NO,
        PRODUCT_CODE_NEW,
        PRODUCT_CODE_NEWNAME,
        FINANCE_DSTRBTR_SOURCE
) subquery_result WHERE sum_amount<>'0';

 		-- 执行结束记录日志  
 		INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','END','【账龄数据生成】方法执行结束');
 		ELSE 
 		INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','ERROR','【账龄数据生成】未生成最终临时账龄表数据');
 
 		END IF;
 
 		COMMIT;
 
END;