CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.procedure_Aging_analysis_tempdataags02(executemonth IN varchar2) AS
 

    V_LAST_MONTH_END DATE; -- 传入处理月份的月末；使用DATE避免日期与字符隐式转换。
    insert_counter NUMBER := 0;
    vt_sql VARCHAR2(32767);  -- 定义sql
    v_fristsql VARCHAR2(32767);
    CURSOR c_aging_ids IS           -- 定义游标获取ID
        SELECT  LAST_DAY(ADD_MONTHS(TO_DATE('201801', 'YYYYMM'), LEVEL - 1)) AS lastday
              FROM DUAL  CONNECT BY LEVEL <= MONTHS_BETWEEN(SYSDATE, TO_DATE('201801', 'YYYYMM')) + 1;

BEGIN
	
	SELECT LAST_DAY(TO_DATE(executemonth, 'YYYY-MM')) INTO V_LAST_MONTH_END FROM DUAL;
   
    -- 开始执行
    INSERT INTO course_method_log (id, EXECUTE_MONTH, METHOD_NAME, METHOD_STATUS, DESCRIPTION)
    VALUES (sequence_course_method_log.nextval, executemonth, 'procedure_Aging_analysis_tempdataags02', 'START', '【佣金账龄临时数据生成】方法正在执行');
    
    -- 因为此部分数据每月会进行反冲，所以每次提取都需要提取全量，防止和之前的数据造成冲突，所以每月清除（影响：后续无法查看之前的明细数据，此科目每月均为最新的数据）
    DELETE FROM temp_FINANCE_Aging_analysis c WHERE c.JE_SOURCE='AGS' AND C.SUBJECT_ID='2202010206';
   
-- 佣金
INSERT INTO temp_FINANCE_Aging_analysis (
    id,
    ledger_id,
    short_name,
    product_no,
    insurance_code,
    period_name,
    subject_id,
    subject_name,
    amount,
    default_effective_date,
    aging_month,
    handle_status,
    execute_method,
    district_id,
    je_source,
    BRANCH_CODE,
    START_DT,
    ACKNWLDG_RCPT_DT,
    BACK_VISITING_DATE,
    STATUS,
    AGENT_NAME,
    AGENT_STATUS,
    LINE_DESCIPTION,
    DSTRBTR_HEAD_CODE,
    DSTRBTR_HEAD_NAME,
    POLICY_NO,
    DSTRBTR_SOURCE,
    DSTRBTR_OID,
    DSTRBTR_CODE,
    BUSINESS_NO,
    FINANCE_DSTRBTR_SOURCE,
    PRODUCT_CODE_NEW,
    PRODUCT_CODE_NEWNAME,
    AGING_MARKER,
    ZERO_CLOSING_MARKER
)
SELECT 
    sequence_temp_FINANCE_Aging_analysis.nextval AS id,
    tm1.LEDGER_ID,
    tm1.SHORT_NAME,
    tm1.PRODUCT_NO,
    tm1.SEGMENT6 AS insurance_code,
    tm1.PERIOD_NAME,
    tm1.SEGMENT3 AS subject_id,
    tm1.SEGMENT3name AS subject_name,
    tm1.amount AS amount, 
    tm1.default_effective_date,
    1 AS aging_month,
    0 AS handle_status,
    'procedure_Aging_analysis_tempdata02' AS execute_method,
    tm1.SEGMENT1 AS district_id,
    tm1.JE_SOURCE,
    tm1.BRANCH_CODE,
    tm1.START_DT,
    tm1.ACKNWLDG_RCPT_DT,
    tm1.BACK_VISITING_DATE,
    tm1.STATUS,
    tm1.AGENT_NAME,
    tm1.AGENT_STATUS,
    tm1.LINE_DESCIPTION,
    tm1.DSTRBTR_HEAD_CODE,
    tm1.DSTRBTR_HEAD_NAME,
    tm1.POLICY_NO,
    tm1.DSTRBTR_SOURCE,
    TM1.DSTRBTR_OID,
    tm1.DSTRBTR_CODE,
    tm1.BUSINESS_NO,
    tm1.FINANCE_DSTRBTR_SOURCE ,
    tm1.PRODUCT_CODE_NEW,
    tm1.PRODUCT_CODE_NEWNAME,
    executemonth as AGING_MARKER,
    '0' AS ZERO_CLOSING_MARKER
FROM temp_month_commission tm1
JOIN (
    SELECT 
        SHORT_NAME,     
        PERIOD_NAME,
        SEGMENT3,
        PRODUCT_NO,
        POLICY_NO,
        BRANCH_CODE,
        SEGMENT1,
        SEGMENT6,
        DSTRBTR_HEAD_CODE,
        DSTRBTR_SOURCE,
        DEFAULT_EFFECTIVE_DATE,
        LINE_DESCIPTION,
        JE_SOURCE,
        AGENT_NAME
    FROM temp_month_commission
    GROUP BY 
        SHORT_NAME,
        
        PERIOD_NAME,
        SEGMENT3,
        BRANCH_CODE,
        PRODUCT_NO,
        DSTRBTR_SOURCE,
        POLICY_NO,
        SEGMENT1,
        DSTRBTR_HEAD_CODE,
        DEFAULT_EFFECTIVE_DATE,
        SEGMENT6,
        LINE_DESCIPTION,
        JE_SOURCE,
        AGENT_NAME
    HAVING SUM(amount) <> 0
) tm2 
    ON  NVL(tm1.SHORT_NAME,'null') = NVL(tm2.SHORT_NAME,'null')
    AND NVL(tm1.PERIOD_NAME,'null') = NVL(tm2.PERIOD_NAME,'null')
    AND NVL(tm1.SEGMENT3,'null') = NVL(tm2.SEGMENT3,'null')
    AND NVL(tm1.POLICY_NO,'null')=NVL(tm2.POLICY_NO,'null')
    AND NVL(tm1.PRODUCT_NO,'null') = NVL(tm2.PRODUCT_NO,'null')
    AND NVL(tm1.SEGMENT1,'null') = NVL(tm2.SEGMENT1,'null')
    AND NVL(tm1.SEGMENT6,'null') = NVL(tm2.SEGMENT6,'null')
    AND NVL(tm1.DSTRBTR_SOURCE,'null') = NVL(tm2.DSTRBTR_SOURCE,'null')
    AND NVL(tm1.BRANCH_CODE,'null') = NVL(tm2.BRANCH_CODE,'null')
    AND NVL(tm1.DSTRBTR_HEAD_CODE,'null') = NVL(tm2.DSTRBTR_HEAD_CODE,'null')
    AND NVL(tm1.LINE_DESCIPTION,'null') = NVL(tm2.LINE_DESCIPTION,'null')
    AND tm1.DEFAULT_EFFECTIVE_DATE=tm2.DEFAULT_EFFECTIVE_DATE
    AND NVL(tm1.AGENT_NAME,'null') = NVL(tm2.AGENT_NAME,'null')
    AND NVL(tm1.JE_SOURCE,'null') = NVL(tm2.JE_SOURCE,'null'); 

--预处理
--FOR rec  IN  c_aging_ids  LOOP   
--    vt_sql:='update temp_FINANCE_Aging_analysis set ZERO_CLOSING_MARKER=''2'' where id in (
--SELECT ID FROM (
--select POLICY_NO,SUBJECT_ID from temp_FINANCE_Aging_analysis a 
--WHERE a.JE_SOURCE =''AGS'' 
--AND  DEFAULT_EFFECTIVE_DATE>=DATE ''2018-10-10'' AND DEFAULT_EFFECTIVE_DATE< :enddate
--and a.ZERO_CLOSING_MARKER=''0''
--GROUP BY SUBJECT_ID ,A.POLICY_NO HAVING  SUM(A.AMOUNT)=0) A LEFT JOIN 
--(SELECT SUBJECT_ID,POLICY_NO,B.ID  FROM temp_FINANCE_Aging_analysis B 
--WHERE B.DEFAULT_EFFECTIVE_DATE>=DATE ''2018-10-10'' AND DEFAULT_EFFECTIVE_DATE< :enddate ) c
--ON A.POLICY_NO= c.POLICY_NO
--AND A.SUBJECT_ID=C.SUBJECT_ID )';
--    EXECUTE IMMEDIATE vt_sql USING rec.lastday,rec.lastday;
--    COMMIT;
--    END LOOP;  
 
   
   
--筛选临时账龄表 金额<>0的数据,进行查询，对账龄进行处理，此处为明细
INSERT INTO temp_finally_FINANCE_AGING_ANALYSIS (
    id,
    LEDGER_ID,
    SHORT_NAME,
    PRODUCT_NO,
    PRODUCT_CODE,
    PERIOD_NAME,
    subject_id,
    subject_name,
    ACCOUNT_SEGMENT ,
    amountflag,
    amount,
    DEFAULT_EFFECTIVE_DATE,
    aging_month,
    handle_status,
    execute_method,
    district_id,
    JE_SOURCE,
    partner_id,
    BRANCH_CODE,
    START_DT,
    ACKNWLDG_RCPT_DT,
    BACK_VISITING_DATE,
    STATUS,
    AGENT_NAME,
    AGENT_STATUS,
    LINE_DESCIPTION,
    DSTRBTR_HEAD_CODE,
    DSTRBTR_HEAD_NAME,
    data_flag,
    POLICY_NO,
    DSTRBTR_OID,
    DSTRBTR_CODE,
    DSTRBTR_SOURCE,
    BUSINESS_SCENE_NO,
    PRODUCT_CODE_NEW,
    PRODUCT_CODE_NEWNAME,
    FINANCE_DSTRBTR_SOURCE
)
SELECT 
    sequence_temp_finally_FINANCE_Aging_analysis.nextval AS id,
    faa.LEDGER_ID,
    faa.SHORT_NAME,
    faa.PRODUCT_NO,
    faa.Insurance_code,
    faa.PERIOD_NAME,
    faa.subject_id,
    faa.subject_name,
    faa.ACCOUNT_SEGMENT ,
    CASE WHEN faa.amount >= 0 THEN 'D' ELSE 'C' END AS amountflag,
    faa.amount,
    faa.DEFAULT_EFFECTIVE_DATE,
    --MONTHS_BETWEEN(SYSDATE,faa.DEFAULT_EFFECTIVE_DATE) AS aging_month,
    --账龄
	MONTHS_BETWEEN(V_LAST_MONTH_END, faa.DEFAULT_EFFECTIVE_DATE)  AS aging_month,
    faa.handle_status,
    faa.execute_method,
    faa.district_id,
    faa.JE_SOURCE,
    faa.partner_id,
    faa.BRANCH_CODE,
    faa.START_DT,
    faa.ACKNWLDG_RCPT_DT,
    faa.BACK_VISITING_DATE,
    faa.STATUS,
    faa.AGENT_NAME,
    faa.AGENT_STATUS,
    faa.LINE_DESCIPTION,
    faa.DSTRBTR_HEAD_CODE,
    faa.DSTRBTR_HEAD_NAME,
    faa.data_flag ,
    faa.POLICY_NO ,
    faa.DSTRBTR_OID,
    faa.DSTRBTR_CODE,
    faa.DSTRBTR_SOURCE,
    faa.BUSINESS_NO,
    faa.PRODUCT_CODE_NEW,
    faa.PRODUCT_CODE_NEWNAME,
    faa.FINANCE_DSTRBTR_SOURCE --财务渠道
FROM temp_FINANCE_AGING_ANALYSIS faa
JOIN (
    SELECT 
        SHORT_NAME,
        PERIOD_NAME,
        subject_id,
        PRODUCT_NO,
        POLICY_NO,
        district_id,
        insurance_code,
        JE_SOURCE,
        ACCOUNT_SEGMENT,
        LINE_DESCIPTION,
        DSTRBTR_SOURCE,
        BRANCH_CODE,
        AGENT_NAME,
        DEFAULT_EFFECTIVE_DATE
    FROM TEMP_FINANCE_AGING_ANALYSIS
    -- 与外层明细使用相同状态范围，已结零/已处理记录不参与金额汇总。
    WHERE JE_SOURCE = 'AGS'
      AND HANDLE_STATUS = 0
      AND ZERO_CLOSING_MARKER = '0'
    GROUP BY
        SHORT_NAME,
        PERIOD_NAME,
        BRANCH_CODE,
        subject_id,
        PRODUCT_NO,
        POLICY_NO,
        district_id,
        Insurance_code,
        JE_SOURCE,
        ACCOUNT_SEGMENT,
        DSTRBTR_SOURCE,
        LINE_DESCIPTION,
        AGENT_NAME,
        DEFAULT_EFFECTIVE_DATE
    HAVING SUM(amount) <> 0
) tfaa 
    ON NVL(faa.SHORT_NAME,'null') = NVL(tfaa.SHORT_NAME,'null')
    AND NVL(faa.PERIOD_NAME,'null') = NVL(tfaa.PERIOD_NAME,'null')
    AND NVL(faa.DSTRBTR_SOURCE,'null') = NVL(tfaa.DSTRBTR_SOURCE,'null')
    AND NVL(faa.BRANCH_CODE,'null') = NVL(tfaa.BRANCH_CODE,'null')
    AND NVL(faa.subject_id,'null') = NVL(tfaa.subject_id,'null')
    AND NVL(faa.PRODUCT_NO,'null') = NVL(tfaa.PRODUCT_NO,'null')
    AND NVL(faa.POLICY_NO,'null') = NVL(tfaa.POLICY_NO,'null')
    AND NVL(faa.district_id,'null') = NVL(tfaa.district_id,'null')
    AND NVL(faa.INSURANCE_CODE,'null') = NVL(tfaa.INSURANCE_CODE,'null')
    AND NVL(faa.JE_SOURCE,'null') = NVL(tfaa.JE_SOURCE,'null')
    AND NVL(faa.DEFAULT_EFFECTIVE_DATE,'null') = NVL(tfaa.DEFAULT_EFFECTIVE_DATE,'null')
    AND NVL(faa.ACCOUNT_SEGMENT,'null') = NVL(tfaa.ACCOUNT_SEGMENT,'null')
    AND NVL(faa.AGENT_NAME,'null') = NVL(tfaa.AGENT_NAME,'null')
    AND NVL(faa.LINE_DESCIPTION,'null') = NVL(tfaa.LINE_DESCIPTION,'null')
WHERE faa.handle_status = 0  AND faa.JE_SOURCE IN ('AGS') AND ZERO_CLOSING_MARKER='0';






    -- 执行结束记录日志  ce
    INSERT INTO course_method_log (id, EXECUTE_MONTH, METHOD_NAME, METHOD_STATUS, DESCRIPTION)
    VALUES (sequence_course_method_log.nextval, executemonth, 'procedure_Aging_analysis_tempdataags02', 'END', '【佣金账龄临时分析】方法执行结束');

    COMMIT;
END;