CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002(executemonth IN varchar2) AS
 
    --V_LAST_MONTH_DATE VARCHAR(20); -- 格式：2019002
    --V_LAST_MONTH_DAY VARCHAR(20); -- 格式：2019-01
    --V_CURRENT_TIME VARCHAR(20); -- 格式：17:20:00 当前时间
    --V_CURRENT_MONTH VARCHAR(20); -- 2019003 当前月份
    V_LAST_MONTH_END VARCHAR(20); --  上月的月末 20190228
    insert_counter NUMBER := 0;
    v_sql VARCHAR2(32767);  -- 定义sql
    v_fristsql VARCHAR2(32767);
    CURSOR c_aging_ids IS           -- 定义游标获取ID
        SELECT DISTINCT  id FROM TEMP_AGING_COMBIN ORDER BY id;
    vt_sql  VARCHAR2(32767);   --预处理sql
    CURSOR c_aging_idsday IS        -- 定义游标获取时间
        SELECT cutoff_date AS lastday
        FROM (
            SELECT TRUNC(ADD_MONTHS(TO_DATE('201810', 'YYYYMM'), LEVEL - 1), 'MM') AS cutoff_date
            FROM DUAL
            CONNECT BY LEVEL <= MONTHS_BETWEEN(SYSDATE, TO_DATE('201810', 'YYYYMM')) + 1
            UNION ALL
            SELECT LAST_DAY(ADD_MONTHS(TO_DATE('201810', 'YYYYMM'), LEVEL - 1)) AS cutoff_date
            FROM DUAL
            CONNECT BY LEVEL <= MONTHS_BETWEEN(SYSDATE, TO_DATE('201810', 'YYYYMM')) + 1
        )
        ORDER BY cutoff_date;

   
BEGIN
	--用于账龄计算
    --select REPLACE(TO_CHAR(SYSDATE - INTERVAL '1' MONTH, '%Y-%m'), '-', '0') into V_LAST_MONTH_DATE from dual;
    --SELECT TO_CHAR(SYSDATE - INTERVAL '1' MONTH, '%Y-%m') INTO V_LAST_MONTH_DAY FROM DUAL;
    --SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') INTO V_CURRENT_TIME FROM DUAL;
    --select REPLACE(TO_CHAR(SYSDATE, '%Y-%m'), '-', '0') into V_CURRENT_MONTH from dual;
	--SELECT LAST_DAY(ADD_MONTHS(SYSDATE, -2)) INTO V_LAST_MONTH_END FROM DUAL;
    SELECT LAST_DAY(TO_DATE(executemonth, 'YYYYMM')) INTO V_LAST_MONTH_END FROM DUAL;
    -- 开始执行
    INSERT INTO course_method_log (id, EXECUTE_MONTH, METHOD_NAME, METHOD_STATUS, DESCRIPTION)
    VALUES (sequence_course_method_log.nextval, executemonth, 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002', 'START', '【账龄临时数据生成】方法正在执行');

   
    -- 把当月金额<>0的数据放入临时账龄表中
    -- 个险数据插入
   -- 个险
INSERT INTO TEMP_FINANCE_AGING_ANALYSISPLIS10 (
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
    PRODUCT_CODE_NEW,
    PRODUCT_CODE_NEWNAME,
    ACCOUNT_SEGMENT,
    ZERO_CLOSING_MARKER,
    AGING_MARKER
)
SELECT 
    sequence_temp_FINANCE_Aging_analysisplis10.nextval AS id,
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
    tm1.DSTRBTR_OID,
    tm1.DSTRBTR_CODE,
    tm1.BUSINESS_NO,
    tm1.PRODUCT_CODE_NEW,
    tm1.PRODUCT_CODE_NEWNAME,
    tm1.SEGMENT4 AS ACCOUNT_SEGMENT,
    '0' AS ZERO_CLOSING_MARKER,
     executemonth  AS AGING_MARKER
FROM temp_month_personal_insurance10 tm1
JOIN (
    SELECT 
        SHORT_NAME, 
        PERIOD_NAME, 
        SEGMENT3, 
        SEGMENT4,
        PRODUCT_NO, 
        POLICY_NO,
        SEGMENT1, 
        SEGMENT6, 
        JE_SOURCE,
        PRODUCT_CODE_NEW,
        DEFAULT_EFFECTIVE_DATE
    FROM temp_month_personal_insurance10
    GROUP BY 
        SHORT_NAME, 
        PERIOD_NAME, 
        SEGMENT3, 
        SEGMENT4,
        PRODUCT_NO, 
        POLICY_NO,
        SEGMENT1, 
        SEGMENT6, 
        DEFAULT_EFFECTIVE_DATE,
        JE_SOURCE,
        PRODUCT_CODE_NEW
    HAVING SUM(amount) <> 0
) tm2 
    ON  NVL(tm1.SHORT_NAME,'null') = NVL(tm2.SHORT_NAME,'null')
    AND NVL(tm1.PERIOD_NAME,'null') = NVL(tm2.PERIOD_NAME,'null')
    AND NVL(tm1.SEGMENT3,'null') = NVL(tm2.SEGMENT3,'null')
    AND NVL(tm1.SEGMENT4,'null') = NVL(tm2.SEGMENT4,'null')
    AND NVL(tm1.POLICY_NO,'null')=NVL(tm2.POLICY_NO,'null')
    AND NVL(tm1.PRODUCT_NO,'null') = NVL(tm2.PRODUCT_NO,'null')
    AND NVL(tm1.SEGMENT1,'null') = NVL(tm2.SEGMENT1,'null')
    AND NVL(tm1.SEGMENT6,'null') = NVL(tm2.SEGMENT6,'null')
    AND NVL(tm1.PRODUCT_CODE_NEW,'null')=NVL(tm2.PRODUCT_CODE_NEW,'null')
    AND tm1.DEFAULT_EFFECTIVE_DATE=tm2.DEFAULT_EFFECTIVE_DATE
    AND NVL(tm1.JE_SOURCE,'null') = NVL(tm2.JE_SOURCE,'null');
   --WHERE tm1.PERIOD_NAME =executemonth;
FOR recday  IN  c_aging_idsday  LOOP   
    -- SHORT_NAME记录本行被本次YYYYMM处理结零，供人工重跑按月恢复。
    vt_sql:='update TEMP_FINANCE_AGING_ANALYSISPLIS10 set ZERO_CLOSING_MARKER=''2'', SHORT_NAME=:close_month where ZERO_CLOSING_MARKER=''0'' and id in (
SELECT ID FROM (
select POLICY_NO,SUBJECT_ID from TEMP_FINANCE_AGING_ANALYSISPLIS10 a 
WHERE DEFAULT_EFFECTIVE_DATE>=DATE ''2018-10-10'' AND DEFAULT_EFFECTIVE_DATE<= :enddate
and a.ZERO_CLOSING_MARKER=''0''
GROUP BY SUBJECT_ID ,A.POLICY_NO HAVING  SUM(A.AMOUNT)=0) A LEFT JOIN 
(SELECT SUBJECT_ID,POLICY_NO,B.ID  FROM TEMP_FINANCE_AGING_ANALYSISPLIS10 B 
WHERE B.DEFAULT_EFFECTIVE_DATE>=DATE ''2018-10-10'' AND DEFAULT_EFFECTIVE_DATE<= :enddate ) c
ON A.POLICY_NO= c.POLICY_NO
AND A.SUBJECT_ID=C.SUBJECT_ID )';

    EXECUTE IMMEDIATE vt_sql USING executemonth,recday.lastday,recday.lastday;
    COMMIT;
    END LOOP; 
   
   
   
   
   
--筛选临时账龄表 金额<>0的数据,进行查询，对账龄进行处理，此处为明细
INSERT INTO temp_finally_FINANCE_AGING_ANALYSIS10 (
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
    ZERO_CLOSING_MARKER
)
SELECT 
    sequence_temp_finally_FINANCE_Aging_analysis01.nextval AS id,
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
	(CASE 
    WHEN MONTHS_BETWEEN(V_LAST_MONTH_END, faa.DEFAULT_EFFECTIVE_DATE) < 3 THEN 1
    WHEN MONTHS_BETWEEN(V_LAST_MONTH_END, faa.DEFAULT_EFFECTIVE_DATE) < 12 THEN 2
    WHEN MONTHS_BETWEEN(V_LAST_MONTH_END, faa.DEFAULT_EFFECTIVE_DATE) < 36 THEN 3
    WHEN MONTHS_BETWEEN(V_LAST_MONTH_END, faa.DEFAULT_EFFECTIVE_DATE) < 60 THEN 4
    ELSE 5 END) AS aging_month,
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
    '0' AS ZERO_CLOSING_MARKER
FROM TEMP_FINANCE_AGING_ANALYSISPLIS10 faa
-- 仅汇总未结零明细；SHORT_NAME只记录结零年月，不参与业务分组和关联。
JOIN (
    SELECT 
        PERIOD_NAME,
        subject_id,
        PRODUCT_NO,
        POLICY_NO,
        --district_id,
        insurance_code,
        JE_SOURCE,
        ACCOUNT_SEGMENT
    FROM TEMP_FINANCE_AGING_ANALYSISPLIS10
    WHERE ZERO_CLOSING_MARKER = '0'
    GROUP BY 
        PERIOD_NAME,
        subject_id,
        PRODUCT_NO,
        POLICY_NO,
        --district_id,
        Insurance_code,
        JE_SOURCE,
        ACCOUNT_SEGMENT
    HAVING SUM(amount) <> 0
) tfaa 
    ON NVL(faa.PERIOD_NAME,'null') = NVL(tfaa.PERIOD_NAME,'null')
    AND NVL(faa.subject_id,'null') = NVL(tfaa.subject_id,'null')
    AND NVL(faa.PRODUCT_NO,'null') = NVL(tfaa.PRODUCT_NO,'null')
    AND NVL(faa.POLICY_NO,'null') = NVL(tfaa.POLICY_NO,'null')
    --AND NVL(faa.district_id,'null') = NVL(tfaa.district_id,'null')
    AND NVL(faa.INSURANCE_CODE,'null') = NVL(tfaa.INSURANCE_CODE,'null')
    AND NVL(faa.JE_SOURCE,'null') = NVL(tfaa.JE_SOURCE,'null')
    AND NVL(faa.ACCOUNT_SEGMENT,'null') = NVL(tfaa.ACCOUNT_SEGMENT,'null')
WHERE faa.handle_status = 0 AND faa.ZERO_CLOSING_MARKER='0'  ;

FOR rec  IN  c_aging_ids  LOOP
	
	v_fristsql:='UPDATE temp_finally_FINANCE_AGING_ANALYSIS10 SET ZERO_CLOSING_MARKER=''1''  
      WHERE ID IN 
    (SELECT id FROM (SELECT DISTRICT_ID,SUBJECT_ID ,a.POLICY_NO,sum(a.AMOUNT)
    FROM temp_finally_FINANCE_AGING_ANALYSIS10 a 
	WHERE a.AGING_MONTH IN (SELECT AGINGMOT FROM TEMP_AGING_COMBIN a  WHERE id =:bind_pid)
    and a.ZERO_CLOSING_MARKER =''0''
	GROUP BY DISTRICT_ID,SUBJECT_ID,a.POLICY_NO  HAVING sum(a.AMOUNT)=''0'') C LEFT JOIN 
	(SELECT B.DISTRICT_ID,B.SUBJECT_ID ,B.POLICY_NO,B.ID  FROM temp_finally_FINANCE_AGING_ANALYSIS10 B
	 	WHERE B.AGING_MONTH IN (SELECT AGINGMOT FROM TEMP_AGING_COMBIN a  WHERE id =:bind_pid))D
	 	ON C.DISTRICT_ID=D.DISTRICT_ID
	 	AND C.SUBJECT_ID=D.SUBJECT_ID
	    AND C.POLICY_NO=D.POLICY_NO)';
	
	
    --对可结零的数据下次不再展示 
	v_sql:='
    UPDATE TEMP_FINANCE_AGING_ANALYSISPLIS10 a SET ZERO_CLOSING_MARKER=''1'', SHORT_NAME=:close_month WHERE a.ZERO_CLOSING_MARKER=''0'' AND a.ID IN (
	SELECT aa.id FROM 
	(SELECT  
         DISTRICT_ID,SUBJECT_ID ,a.POLICY_NO,sum(a.AMOUNT)
    FROM temp_finally_FINANCE_AGING_ANALYSIS10 a 
	WHERE a.AGING_MONTH IN (SELECT AGINGMOT FROM TEMP_AGING_COMBIN a  WHERE id =:bind_pid)
    and a.ZERO_CLOSING_MARKER =''0''
	GROUP BY DISTRICT_ID,SUBJECT_ID,a.POLICY_NO  HAVING sum(a.AMOUNT)=''0'') B  LEFT JOIN 
	(SELECT ID,
    (CASE 
    WHEN MONTHS_BETWEEN(:bind_last_month_end, faa.DEFAULT_EFFECTIVE_DATE) < 3 THEN 1
    WHEN MONTHS_BETWEEN(:bind_last_month_end, faa.DEFAULT_EFFECTIVE_DATE) < 12 THEN 2
    WHEN MONTHS_BETWEEN(:bind_last_month_end, faa.DEFAULT_EFFECTIVE_DATE) < 36 THEN 3
    WHEN MONTHS_BETWEEN(:bind_last_month_end, faa.DEFAULT_EFFECTIVE_DATE) < 60 THEN 4
    ELSE 5 END) AS aging_month, faa.POLICY_NO,faa.SUBJECT_ID,DISTRICT_ID 
    FROM TEMP_FINANCE_AGING_ANALYSISPLIS10 faa) aa 
    ON  aa.POLICY_NO=B.POLICY_NO 
    AND aa.DISTRICT_ID=B.DISTRICT_ID 
    AND aa.SUBJECT_ID=B.SUBJECT_ID 
    AND aa.AGING_MONTH IN (SELECT AGINGMOT FROM TEMP_AGING_COMBIN a  WHERE id = :bind_pid))';
   
    EXECUTE IMMEDIATE v_sql USING executemonth,rec.id,V_LAST_MONTH_END,V_LAST_MONTH_END,V_LAST_MONTH_END,V_LAST_MONTH_END,rec.id;
    EXECUTE IMMEDIATE v_fristsql USING rec.id,rec.id;
    COMMIT;
    END LOOP;

    -- 执行结束记录日志  ce
    INSERT INTO course_method_log (id, EXECUTE_MONTH, METHOD_NAME, METHOD_STATUS, DESCRIPTION)
    VALUES (sequence_course_method_log.nextval, executemonth, 'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002', 'END', '【账龄临时分析】方法执行结束');

    COMMIT;
END;
