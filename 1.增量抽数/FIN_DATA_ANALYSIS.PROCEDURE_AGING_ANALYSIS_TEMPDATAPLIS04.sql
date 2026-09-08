CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04(executemonth IN varchar2 )
AS
BEGIN
	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04','START','【财务账龄分析临时数据生成】方法正在执行');

		-- 情空上个月的桥梁表数据，
		EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_month_personal_insurance04';
		EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_finally_FINANCE_Aging_analysis04';
	-- 设置当前月份的桥梁表数据，添加个险数据
    INSERT INTO temp_month_personal_insurance04 (
        id,
        POLICY_NO,    -- 保单号
        JE_SOURCE ,   --来源
        SEGMENT3,     --科目
        SEGMENT3name, -- 科目名称
        SEGMENT4, --账户
        DEFAULT_EFFECTIVE_DATE, --凭证日期
        --PERIOD_NAME,  --期间
        amount , --金额
        BRANCH_CODE,      --机构
        SEGMENT1,         --地区
        LINE_DESCIPTION,  --行说明
        BUSINESS_NO        
    )
    SELECT
        sequence_temp_month_personal_insurance04.nextval AS id,
        f.POLICY_NO , -- 保单号
        'PLIS' JE_SOURCE, --来源
        f.SEGMENT3,       --科目
        (SELECT a.ACCOUNT_NAME FROM MRT.FRS_DIM_COA_AC a WHERE a.ACCOUNT_CODE = f.SEGMENT3) as SEGMENT3name, --科目名称   
        (case when f.SEGMENT3 in ('2612110101','2602020101','2602020301','2243010101','2243010105') then f.SEGMENT4  
		      when f.SEGMENT3 ='2243010102' and f.SEGMENT4  in ('1401','1402','1403','1404','1405','1406','1407','1408') then '1401-1408' 
			  else null END )  as SEGMENT4, --账户
        f.DEFAULT_EFFECTIVE_DATE, --凭证日期
        NVL(f.ENTERED_DR, 0) - NVL(f.ENTERED_CR, 0) AS amount,--金额
        (case when SEGMENT1='100001' then '001' else 
		 (SELECT DISTINCT (SUBSTR(a.BRANCH_CODE,1,9))  FROM FRS_DIM_COA_COAGING A WHERE LENGTH(BRANCH_CODE) >= 9 and a.SEGMENT1=f.SEGMENT1) END)  as BRANCH_CODE,
        f.SEGMENT1,
        F.LINE_DESCIPTION,
        nvl (f.BUSINESS_NO,f.POLICY_NO) AS BUSINESS_NO 
    FROM mrt.FRS_ODS_DW_SLA_LINES f
    /*left JOIN  
		 (SELECT DISTINCT  POLICY_NO,START_DT, ACKNWLDG_RCPT_DT,BACK_VISITING_DATE, CHANNEL_NEW ,STATUS, BRANCH_CODE,DSTRBTR_OID, DSTRBTR_CODE,DSTRBTR_HEAD_CODE,DSTRBTR_HEAD_NAME,
		 ROW_NUMBER() OVER (PARTITION BY POLICY_NO ORDER BY LCD DESC) rn
		FROM  mrt.FRS_ODS_POLICY  
		) d 
		ON f.POLICY_NO=d.POLICY_NO  AND rn=1*/
    WHERE f.LEDGER_ID NOT IN (2222, 2030)
      AND f.PERIOD_NAME = executemonth
      AND f.SEGMENT1 IN (SELECT distinct SEGMENT1 FROM FRS_DIM_COA_COAGING a WHERE  BRANCH_CODE LIKE '001004%')
      AND f.JE_SOURCE IN ('PLIS','EFT','PLI','FCS','TMP')
      AND SEGMENT3 IN (SELECT a.SUBJECT FROM SUBJECTENUMERATIONAGING a WHERE a.JE_SOURCE ='PLIS')
	  and f.SHORT_NAME  not like 'THTF_I17%';
     INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04','START','【财务账龄分析临时数据生成】方法执行完成');

	  COMMIT; 
END ;
