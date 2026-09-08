CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.procedure_Aging_analysis_tempdataAGS(executemonth IN varchar2 )
AS
BEGIN 
	-- 开始执行
	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis_tempdata','START','【佣金财务账龄分析临时数据生成】方法正在执行');

	
		-- 情空上个月的桥梁表数据，
		--EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_month_personal_insurance';
		--EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_month_group_insurance';
		EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_month_commission';
		EXECUTE  IMMEDIATE 'TRUNCATE TABLE temp_finally_FINANCE_Aging_analysis';
	
	 --佣金部分
	 --需要添加 机构，科目名称，挂账日期，代理人，代理人状态，合作方编码/银行网点，合作方名称/银行名称，保单状态，保单生效日期，回执日期，回访日期，佣金手续费，挂账原因
     INSERT INTO temp_month_commission (
			id ,                --id
			PERIOD_NAME,        --期间
			SEGMENT1,           --公司
			SEGMENT3,	        --科目
			SEGMENT3name,       --科目名称
			SEGMENT4,           --账户
			SEGMENT6,           --险种
			JE_SOURCE,          --来源
			DEFAULT_EFFECTIVE_DATE,   --凭证日期
			amount,             --金额
			ATTRIBUTE8,         --保单号
			execute_method,
			POLICY_NO,          --保单
			START_DT,           --生效日期
			ACKNWLDG_RCPT_DT,   --回执日期
			BACK_VISITING_DATE, --回访日期
			DSTRBTR_SOURCE,     --渠道
			FINANCE_DSTRBTR_SOURCE ,--渠道财务段
			STATUS,          --状态
			AGENT_NAME,      --代理人
			AGENT_STATUS,
			BRANCH_CODE,
			DSTRBTR_OID,
			DSTRBTR_CODE,
			LINE_DESCIPTION,
			DSTRBTR_HEAD_CODE,
			DSTRBTR_HEAD_NAME,
			PRODUCT_CODE_NEW,   --险种
			PRODUCT_CODE_NEWNAME --险种名称
		)SELECT 
		     sequence_temp_month_commission.nextval AS id, --id
		     SUBSTR(f.PERIOD_NAME, 1, 4) || LPAD(SUBSTR(f.PERIOD_NAME, 6, 2), 3, '0') AS PERIOD_NAME,  --期间
		     f.SEGMENT1,            --公司
		     f.SEGMENT3,       --科目
		     (SELECT a.ACCOUNT_NAME FROM MRT.FRS_DIM_COA_AC a WHERE a.ACCOUNT_CODE =f.SEGMENT3) as SEGMENT3name, --科目名称
		     f.SEGMENT4,            --账户
		     (CASE WHEN f.SEGMENT6='0' OR f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END) AS SEGMENT6,            --险种
		     'AGS'  AS JE_SOURCE,         --来源
		     f.DEFAULT_EFFECTIVE_DATE,--凭证日期
		     --AMT AS amount,  --金额
		     NVL(f.ENTERED_DR, 0) - NVL(f.ENTERED_CR, 0) AS amount,--金额
		     f.POLICY_NO AS ATTRIBUTE8 , --保单号
		     'procedure_Aging_analysis_tempdata' AS execute_method,
		     f.POLICY_NO ,
		     d.START_DT , --保单生效日期
		     d.ACKNWLDG_RCPT_DT , --回执日期
	         d.BACK_VISITING_DATE , --回访日期
	         (CASE WHEN f.SEGMENT7 IN ('1001','1002','1003','1004') THEN '006' --团险
	               WHEN f.SEGMENT7 IN ('1201','1202','1204') THEN '210'        --代理人
	               WHEN f.SEGMENT7 IN ('1501','1502','1504') THEN '221'        --银保
	               WHEN f.SEGMENT7 IN ('1301','1302','1304') THEN '200'        --经贷代理公司
	               WHEN f.SEGMENT7 IN ('1401','1402','1404') THEN '300'        --经纪人 
	               WHEN f.SEGMENT7 IN ('1701','1702') THEN '005'               --直销
	               WHEN f.SEGMENT7 IN ('1601','1602') THEN '004'               --互联网销
	               ELSE f.SEGMENT7 end) as DSTRBTR_SOURCE, --渠道
	         f.SEGMENT7 AS FINANCE_DSTRBTR_SOURCE,--渠道财务
	         d.STATUS ,--状态
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE11) as AGENT_NAME, --代理人
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE= d.DSTRBTR_CODE) 
	         (case WHEN f.SEGMENT3 ='2202010301' THEN  f.ATTRIBUTE7
	               WHEN f.SEGMENT3 ='2202030201' THEN NULL 
		           WHEN f.SEGMENT7 not IN('1501','1502','1504','1701','1702','1601','1602')THEN f.ATTRIBUTE7
		           
	               ELSE NULL END ) AS AGENT_NAME,--代理人
	         (SELECT (CASE when a.AGENT_STATUS='Active' THEN '有效' 
		              when a.AGENT_STATUS='Struck Off' THEN '虚拟代理人' 
					  when a.AGENT_STATUS='Suspended' THEN '暂停' 
					  when a.AGENT_STATUS='Terminated' THEN '终止' 
					  when a.AGENT_STATUS='Other' THEN '无' ELSE '其他' end) from  MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE7), --代理人状态
		     --d.BRANCH_CODE ,      --机构
		     (SELECT DISTINCT (SUBSTR(a.BRANCH_CODE,1,9))  FROM FRS_DIM_COA_COAGING A WHERE LENGTH(BRANCH_CODE) >= 9 and a.SEGMENT1=f.SEGMENT1)  AS BRANCH_CODE,--机构
		     d.DSTRBTR_OID,      --分销商oid
		     d.DSTRBTR_CODE,     --分销商编号
		     f.LINE_DESCIPTION ,   --行说明
		     
		     (case WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     nvl(d.DSTRBTR_HEAD_CODE,f.ATTRIBUTE7) ELSE  NULL end) AS DSTRBTR_HEAD_CODE, --银行网点
		      (CASE WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     COALESCE(d.DSTRBTR_HEAD_NAME,
		     (SELECT fodb.BANK_NAME  FROM MRT.FRS_ODS_D_BANK fodb WHERE fodb.BANK_CODE=f.ATTRIBUTE7),
             (SELECT AGENCY_NAME FROM MRT.FRS_ODS_D_AGENCY foda WHERE foda.AGENCY_CODE=f.ATTRIBUTE7),
             (SELECT BROKER_NAME FROM MRT.FRS_ODS_D_BROKER fodb2 WHERE fodb2.BROKER_CODE=f.ATTRIBUTE7)) ELSE NULL end ),  --银行名称
             
		     (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)  AS PRODUCT_CODE_NEW,   --险种
		     (SELECT c.PROD_NAME FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_CODE=  (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)) AS PRODUCT_CODE_NEWNAME --险种名称
		FROM mrt.FRS_ODS_DW_SLA_LINES f 
		   left JOIN  
		 (SELECT DISTINCT  POLICY_NO,START_DT, ACKNWLDG_RCPT_DT,BACK_VISITING_DATE, CHANNEL_NEW ,STATUS, BRANCH_CODE,DSTRBTR_OID, DSTRBTR_CODE,DSTRBTR_HEAD_CODE,DSTRBTR_HEAD_NAME,PRODUCT_OID,
		 ROW_NUMBER() OVER (PARTITION BY POLICY_NO ORDER BY LCD DESC) rn
		FROM  mrt.FRS_ODS_POLICY ) d 
		ON f.POLICY_NO=d.POLICY_NO  AND rn=1  WHERE f.JE_SOURCE  IN ('AG','AGS')
	 	AND f.PERIOD_NAME = executemonth
	    AND f.SEGMENT3  IN ('2202010301','2202010302','2202020202','2202020203','2202020302','2202030201','2202030213','2202030214','2211010104')
		and f.SHORT_NAME  not like 'THTF_I17%';
	    
		
     INSERT INTO temp_month_commission (
			id ,                --id
			PERIOD_NAME,        --期间
			SEGMENT1,           --公司
			SEGMENT3,	        --科目
			SEGMENT3name,       --科目名称
			SEGMENT4,           --账户
			SEGMENT6,           --险种
			JE_SOURCE,          --来源
			DEFAULT_EFFECTIVE_DATE,   --凭证日期
			amount,             --金额
			ATTRIBUTE8,         --保单号
			execute_method,
			POLICY_NO,          --保单
			START_DT,           --生效日期
			ACKNWLDG_RCPT_DT,   --回执日期
			BACK_VISITING_DATE, --回访日期
			DSTRBTR_SOURCE,     --渠道
			FINANCE_DSTRBTR_SOURCE ,--渠道财务段
			STATUS,          --状态
			AGENT_NAME,      --代理人
			AGENT_STATUS,
			BRANCH_CODE,
			DSTRBTR_OID,
			DSTRBTR_CODE,
			LINE_DESCIPTION,
			DSTRBTR_HEAD_CODE,
			DSTRBTR_HEAD_NAME,
			PRODUCT_CODE_NEW,   --险种
			PRODUCT_CODE_NEWNAME --险种名称
		)SELECT 
		     sequence_temp_month_commission.nextval AS id, --id
		     SUBSTR(f.PERIOD_NAME, 1, 4) || LPAD(SUBSTR(f.PERIOD_NAME, 6, 2), 3, '0') AS PERIOD_NAME,  --期间
		     f.SEGMENT1,            --公司
		     f.SEGMENT3,       --科目
		     (SELECT a.ACCOUNT_NAME FROM MRT.FRS_DIM_COA_AC a WHERE a.ACCOUNT_CODE =f.SEGMENT3) as SEGMENT3name, --科目名称
		     f.SEGMENT4,            --账户
		     (CASE WHEN f.SEGMENT6='0' OR f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END) AS SEGMENT6,            --险种
		     'AGS'  AS JE_SOURCE,         --来源
		     f.DEFAULT_EFFECTIVE_DATE,--凭证日期
		     --AMT AS amount,  --金额
		     NVL(f.ENTERED_DR, 0) - NVL(f.ENTERED_CR, 0) AS amount,--金额
		     f.POLICY_NO AS ATTRIBUTE8 , --保单号
		     'procedure_Aging_analysis_tempdata' AS execute_method,
		     f.POLICY_NO ,
		     d.START_DT , --保单生效日期
		     d.ACKNWLDG_RCPT_DT , --回执日期
	         d.BACK_VISITING_DATE , --回访日期
	         (CASE WHEN f.SEGMENT7 IN ('1001','1002','1003','1004') THEN '006' --团险
	               WHEN f.SEGMENT7 IN ('1201','1202','1204') THEN '210'        --代理人
	               WHEN f.SEGMENT7 IN ('1501','1502','1504') THEN '221'        --银保
	               WHEN f.SEGMENT7 IN ('1301','1302','1304') THEN '200'        --经贷代理公司
	               WHEN f.SEGMENT7 IN ('1401','1402','1404') THEN '300'        --经纪人 
	               WHEN f.SEGMENT7 IN ('1701','1702') THEN '005'               --直销
	               WHEN f.SEGMENT7 IN ('1601','1602') THEN '004'               --互联网销
	               ELSE f.SEGMENT7 end) as DSTRBTR_SOURCE, --渠道
	         f.SEGMENT7 AS FINANCE_DSTRBTR_SOURCE,--渠道财务
	         d.STATUS ,--状态
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE11) as AGENT_NAME, --代理人
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE= d.DSTRBTR_CODE) 
	         (case WHEN f.SEGMENT3 ='2202010301' THEN  f.ATTRIBUTE7
	               WHEN f.SEGMENT3 ='2202030201' THEN NULL 
		           WHEN f.SEGMENT7 not IN('1501','1502','1504','1701','1702','1601','1602')THEN f.ATTRIBUTE7
	               ELSE NULL END ) AS AGENT_NAME,--代理人
	         (SELECT (CASE when a.AGENT_STATUS='Active' THEN '有效' 
		              when a.AGENT_STATUS='Struck Off' THEN '吊销执照' 
					  when a.AGENT_STATUS='Suspended' THEN '暂停' 
					  when a.AGENT_STATUS='Terminated' THEN '终止' 
					  when a.AGENT_STATUS='Other' THEN '无' ELSE '其他' end) from  MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE7), --代理人状态
		     --d.BRANCH_CODE ,      --机构
		     (SELECT DISTINCT (SUBSTR(a.BRANCH_CODE,1,9))  FROM FRS_DIM_COA_COAGING A WHERE LENGTH(BRANCH_CODE) >= 9 and a.SEGMENT1=f.SEGMENT1)  AS BRANCH_CODE,--机构
		     d.DSTRBTR_OID,      --分销商oid
		     d.DSTRBTR_CODE,     --分销商编号
		     f.LINE_DESCIPTION ,   --行说明
		     (case WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     nvl(d.DSTRBTR_HEAD_CODE,f.ATTRIBUTE7) ELSE  NULL end) AS DSTRBTR_HEAD_CODE, --银行网点
		     (CASE WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     COALESCE(d.DSTRBTR_HEAD_NAME,
		     (SELECT fodb.BANK_NAME  FROM MRT.FRS_ODS_D_BANK fodb WHERE fodb.BANK_CODE=f.ATTRIBUTE7),
             (SELECT AGENCY_NAME FROM MRT.FRS_ODS_D_AGENCY foda WHERE foda.AGENCY_CODE=f.ATTRIBUTE7),
             (SELECT BROKER_NAME FROM MRT.FRS_ODS_D_BROKER fodb2 WHERE fodb2.BROKER_CODE=f.ATTRIBUTE7)) ELSE NULL end ),  --银行名称
             
		     (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)  AS PRODUCT_CODE_NEW,   --险种
		     (SELECT c.PROD_NAME FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_CODE=  (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)) AS PRODUCT_CODE_NEWNAME --险种名称
		FROM mrt.FRS_ODS_DW_SLA_LINES f 
		   left JOIN  
		 (SELECT DISTINCT  POLICY_NO,START_DT, ACKNWLDG_RCPT_DT,BACK_VISITING_DATE, CHANNEL_NEW ,STATUS, BRANCH_CODE,DSTRBTR_OID, DSTRBTR_CODE,DSTRBTR_HEAD_CODE,DSTRBTR_HEAD_NAME,PRODUCT_OID,
		 ROW_NUMBER() OVER (PARTITION BY POLICY_NO ORDER BY LCD DESC) rn
		FROM  mrt.FRS_ODS_POLICY ) d 
		ON f.POLICY_NO=d.POLICY_NO  AND rn=1  
	   WHERE f.JE_SOURCE  IN  ('PLI','PLIS')  
	   AND f.PERIOD_NAME = executemonth
	   AND F.SEGMENT3  IN ('2202010302','2202030201')
	   and f.SHORT_NAME  not like 'THTF_I17%';
	    
	  
	   INSERT INTO temp_month_commission (
			id ,                --id
			PERIOD_NAME,        --期间
			SEGMENT1,           --公司
			SEGMENT3,	        --科目
			SEGMENT3name,       --科目名称
			SEGMENT4,           --账户
			SEGMENT6,           --险种
			JE_SOURCE,          --来源
			DEFAULT_EFFECTIVE_DATE,   --凭证日期
			amount,             --金额
			ATTRIBUTE8,         --保单号
			execute_method,
			POLICY_NO,          --保单
			START_DT,           --生效日期
			ACKNWLDG_RCPT_DT,   --回执日期
			BACK_VISITING_DATE, --回访日期
			DSTRBTR_SOURCE,     --渠道
			FINANCE_DSTRBTR_SOURCE ,--渠道财务段
			STATUS,          --状态
			AGENT_NAME,      --代理人
			AGENT_STATUS,
			BRANCH_CODE,
			DSTRBTR_OID,
			DSTRBTR_CODE,
			LINE_DESCIPTION,
			DSTRBTR_HEAD_CODE,
			DSTRBTR_HEAD_NAME,
			PRODUCT_CODE_NEW,   --险种
			PRODUCT_CODE_NEWNAME --险种名称
		)SELECT 
		     sequence_temp_month_commission.nextval AS id, --id
		     SUBSTR(f.PERIOD_NAME, 1, 4) || LPAD(SUBSTR(f.PERIOD_NAME, 6, 2), 3, '0') AS PERIOD_NAME,  --期间 
		     f.SEGMENT1,            --公司
		     f.SEGMENT3,       --科目
		     (SELECT a.ACCOUNT_NAME FROM MRT.FRS_DIM_COA_AC a WHERE a.ACCOUNT_CODE =f.SEGMENT3) as SEGMENT3name, --科目名称
		     f.SEGMENT4,            --账户
		     (CASE WHEN f.SEGMENT6='0' OR f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END) AS SEGMENT6,            --险种
		     'AGS'  AS JE_SOURCE,         --来源
		     f.DEFAULT_EFFECTIVE_DATE,--凭证日期
		     --AMT AS amount,  --金额
		     NVL(f.ENTERED_DR, 0) - NVL(f.ENTERED_CR, 0) AS amount,--金额
		     f.POLICY_NO AS ATTRIBUTE8 , --保单号
		     'procedure_Aging_analysis_tempdata' AS execute_method,
		     f.POLICY_NO ,
		     d.START_DT , --保单生效日期
		     d.ACKNWLDG_RCPT_DT , --回执日期
	         d.BACK_VISITING_DATE , --回访日期
	         (CASE WHEN f.SEGMENT7 IN ('1001','1002','1003','1004') THEN '006' --团险
	               WHEN f.SEGMENT7 IN ('1201','1202','1204') THEN '210'        --代理人
	               WHEN f.SEGMENT7 IN ('1501','1502','1504') THEN '221'        --银保
	               WHEN f.SEGMENT7 IN ('1301','1302','1304') THEN '200'        --经贷代理公司
	               WHEN f.SEGMENT7 IN ('1401','1402','1404') THEN '300'        --经纪人 
	               WHEN f.SEGMENT7 IN ('1701','1702') THEN '005'               --直销
	               WHEN f.SEGMENT7 IN ('1601','1602') THEN '004'               --互联网销
	               ELSE f.SEGMENT7 end) as DSTRBTR_SOURCE, --渠道
	         f.SEGMENT7 AS FINANCE_DSTRBTR_SOURCE,--渠道财务
	         d.STATUS ,--状态
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE11) as AGENT_NAME, --代理人
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE= d.DSTRBTR_CODE) 
	         (case WHEN f.SEGMENT3 ='2202010301' THEN  f.ATTRIBUTE7
	               WHEN f.SEGMENT3 ='2202030201' THEN NULL 
		           WHEN f.SEGMENT7 not IN('1501','1502','1504','1701','1702','1601','1602')THEN f.ATTRIBUTE7
	               ELSE NULL END ) AS AGENT_NAME,--代理人
	         (SELECT (CASE when a.AGENT_STATUS='Active' THEN '有效' 
		              when a.AGENT_STATUS='Struck Off' THEN '虚拟代理人' 
					  when a.AGENT_STATUS='Suspended' THEN '暂停' 
					  when a.AGENT_STATUS='Terminated' THEN '终止' 
					  when a.AGENT_STATUS='Other' THEN '无' ELSE '其他' end) from  MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE7), --代理人状态
		     --d.BRANCH_CODE ,      --机构
		     (SELECT DISTINCT (SUBSTR(a.BRANCH_CODE,1,9))  FROM FRS_DIM_COA_COAGING A WHERE LENGTH(BRANCH_CODE) >= 9 and a.SEGMENT1=f.SEGMENT1)  AS BRANCH_CODE,--机构
		     d.DSTRBTR_OID,      --分销商oid
		     d.DSTRBTR_CODE,     --分销商编号
		     f.LINE_DESCIPTION ,   --行说明
		     
		     (case WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     nvl(d.DSTRBTR_HEAD_CODE,f.ATTRIBUTE7) ELSE  NULL end) AS DSTRBTR_HEAD_CODE, --银行网点
		     
		      (CASE WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     COALESCE(d.DSTRBTR_HEAD_NAME,
		     (SELECT fodb.BANK_NAME  FROM MRT.FRS_ODS_D_BANK fodb WHERE fodb.BANK_CODE=f.ATTRIBUTE7),
             (SELECT AGENCY_NAME FROM MRT.FRS_ODS_D_AGENCY foda WHERE foda.AGENCY_CODE=f.ATTRIBUTE7),
             (SELECT BROKER_NAME FROM MRT.FRS_ODS_D_BROKER fodb2 WHERE fodb2.BROKER_CODE=f.ATTRIBUTE7)) ELSE NULL end ),  --银行名称
             
		     (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)  AS PRODUCT_CODE_NEW,   --险种
		     (SELECT c.PROD_NAME FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_CODE=  (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)) AS PRODUCT_CODE_NEWNAME --险种名称
		FROM mrt.FRS_ODS_DW_SLA_LINES f 
		   left JOIN  
		 (SELECT DISTINCT  POLICY_NO,START_DT, ACKNWLDG_RCPT_DT,BACK_VISITING_DATE, CHANNEL_NEW ,STATUS, BRANCH_CODE,DSTRBTR_OID, DSTRBTR_CODE,DSTRBTR_HEAD_CODE,DSTRBTR_HEAD_NAME,PRODUCT_OID,
		 ROW_NUMBER() OVER (PARTITION BY POLICY_NO ORDER BY LCD DESC) rn
		FROM  mrt.FRS_ODS_POLICY ) d 
		ON f.POLICY_NO=d.POLICY_NO  AND rn=1 
		WHERE f.JE_SOURCE  IN ('AG','AGS')
	    AND f.SEGMENT3  IN ('2202010206') 
		AND f.PERIOD_NAME = executemonth 
	    AND f.JE_CATEGORY='FAR'
		and f.SHORT_NAME  not like 'THTF_I17%';
	 
	   
	   INSERT INTO temp_month_commission (
			id ,                --id
			PERIOD_NAME,        --期间
			SEGMENT1,           --公司
			SEGMENT3,	        --科目
			SEGMENT3name,       --科目名称
			SEGMENT4,           --账户
			SEGMENT6,           --险种
			JE_SOURCE,          --来源
			DEFAULT_EFFECTIVE_DATE,   --凭证日期
			amount,             --金额
			ATTRIBUTE8,         --保单号
			execute_method,
			POLICY_NO,          --保单
			START_DT,           --生效日期
			ACKNWLDG_RCPT_DT,   --回执日期
			BACK_VISITING_DATE, --回访日期
			DSTRBTR_SOURCE,     --渠道
			FINANCE_DSTRBTR_SOURCE ,--渠道财务段
			STATUS,          --状态
			AGENT_NAME,      --代理人
			AGENT_STATUS,
			BRANCH_CODE,
			DSTRBTR_OID,
			DSTRBTR_CODE,
			LINE_DESCIPTION,
			DSTRBTR_HEAD_CODE,
			DSTRBTR_HEAD_NAME,
			PRODUCT_CODE_NEW,   --险种
			PRODUCT_CODE_NEWNAME --险种名称
		)SELECT 
		     sequence_temp_month_commission.nextval AS id, --id
		     SUBSTR(f.PERIOD_NAME, 1, 4) || LPAD(SUBSTR(f.PERIOD_NAME, 6, 2), 3, '0') AS PERIOD_NAME,  --期间
		     f.SEGMENT1,            --公司
		     f.SEGMENT3,       --科目
		     (SELECT a.ACCOUNT_NAME FROM MRT.FRS_DIM_COA_AC a WHERE a.ACCOUNT_CODE =f.SEGMENT3) as SEGMENT3name, --科目名称
		     f.SEGMENT4,            --账户
		     (CASE WHEN f.SEGMENT6='0' OR f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END) AS SEGMENT6,            --险种
		     'AGS'  AS JE_SOURCE,         --来源
		     f.DEFAULT_EFFECTIVE_DATE,--凭证日期
		     --AMT AS amount,  --金额
		     NVL(f.ENTERED_DR, 0) - NVL(f.ENTERED_CR, 0) AS amount,--金额
		     f.POLICY_NO AS ATTRIBUTE8 , --保单号
		     'procedure_Aging_analysis_tempdata' AS execute_method,
		     f.POLICY_NO ,
		     d.START_DT , --保单生效日期
		     d.ACKNWLDG_RCPT_DT , --回执日期
	         d.BACK_VISITING_DATE , --回访日期
	         (CASE WHEN f.SEGMENT7 IN ('1001','1002','1003','1004') THEN '006' --团险
	               WHEN f.SEGMENT7 IN ('1201','1202','1204') THEN '210'        --代理人
	               WHEN f.SEGMENT7 IN ('1501','1502','1504') THEN '221'        --银保
	               WHEN f.SEGMENT7 IN ('1301','1302','1304') THEN '200'        --经贷代理公司
	               WHEN f.SEGMENT7 IN ('1401','1402','1404') THEN '300'        --经纪人 
	               WHEN f.SEGMENT7 IN ('1701','1702') THEN '005'               --直销
	               WHEN f.SEGMENT7 IN ('1601','1602') THEN '004'               --互联网销
	               ELSE f.SEGMENT7 end) as DSTRBTR_SOURCE, --渠道
	         f.SEGMENT7 AS FINANCE_DSTRBTR_SOURCE,--渠道财务
	         d.STATUS ,--状态
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE11) as AGENT_NAME, --代理人
		     --(SELECT a.AGENT_NAME FROM MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE= d.DSTRBTR_CODE) 
	         (case WHEN f.SEGMENT3 ='2202010301' THEN  f.ATTRIBUTE7
	               WHEN f.SEGMENT3 ='2202030201' THEN NULL 
		           WHEN f.SEGMENT7 not IN('1501','1502','1504','1701','1702','1601','1602')THEN f.ATTRIBUTE7
		           
	               ELSE NULL END ) AS AGENT_NAME,--代理人
	         (SELECT (CASE when a.AGENT_STATUS='Active' THEN '有效' 
		              when a.AGENT_STATUS='Struck Off' THEN '虚拟代理人' 
					  when a.AGENT_STATUS='Suspended' THEN '暂停' 
					  when a.AGENT_STATUS='Terminated' THEN '终止' 
					  when a.AGENT_STATUS='Other' THEN '无' ELSE '其他' end) from  MRT.FRS_ODS_D_AGENT a WHERE a.AGENT_CODE =f.ATTRIBUTE7), --代理人状态
		     --d.BRANCH_CODE ,      --机构
		     (SELECT DISTINCT (SUBSTR(a.BRANCH_CODE,1,9))  FROM FRS_DIM_COA_COAGING A WHERE LENGTH(BRANCH_CODE) >= 9 and a.SEGMENT1=f.SEGMENT1)  AS BRANCH_CODE,--机构
		     d.DSTRBTR_OID,      --分销商oid
		     d.DSTRBTR_CODE,     --分销商编号
		     f.LINE_DESCIPTION ,   --行说明
		     
		     (case WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     nvl(d.DSTRBTR_HEAD_CODE,f.ATTRIBUTE7) ELSE  NULL end) AS DSTRBTR_HEAD_CODE, --银行网点
		     
		      (CASE WHEN  f.SEGMENT7 not IN('1201','1202','1204') AND f.SEGMENT3 <>'2202010301' THEN 
		     COALESCE(d.DSTRBTR_HEAD_NAME,
		     (SELECT fodb.BANK_NAME  FROM MRT.FRS_ODS_D_BANK fodb WHERE fodb.BANK_CODE=f.ATTRIBUTE7),
             (SELECT AGENCY_NAME FROM MRT.FRS_ODS_D_AGENCY foda WHERE foda.AGENCY_CODE=f.ATTRIBUTE7),
             (SELECT BROKER_NAME FROM MRT.FRS_ODS_D_BROKER fodb2 WHERE fodb2.BROKER_CODE=f.ATTRIBUTE7)) ELSE NULL end ),  --银行名称
             
		     (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)  AS PRODUCT_CODE_NEW,   --险种
		     (SELECT c.PROD_NAME FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_CODE=  (CASE WHEN f.SEGMENT6='0' OR  f.SEGMENT6 is NULL THEN 
		     (SELECT c.PROD_CODE FROM mrt.FRS_DIM_COA_PD c WHERE c.PROD_SHORTNAME=d.PRODUCT_OID)
		     ELSE  f.SEGMENT6 END)) AS PRODUCT_CODE_NEWNAME --险种名称
		FROM mrt.FRS_ODS_DW_SLA_LINES f 
		   left JOIN  
		 (SELECT DISTINCT  POLICY_NO,START_DT, ACKNWLDG_RCPT_DT,BACK_VISITING_DATE, CHANNEL_NEW ,STATUS, BRANCH_CODE,DSTRBTR_OID, DSTRBTR_CODE,DSTRBTR_HEAD_CODE,DSTRBTR_HEAD_NAME,PRODUCT_OID,
		 ROW_NUMBER() OVER (PARTITION BY POLICY_NO ORDER BY LCD DESC) rn
		FROM  mrt.FRS_ODS_POLICY ) d 
		ON f.POLICY_NO=d.POLICY_NO  AND rn=1 
		WHERE f.JE_SOURCE  IN ('AG','AGS')
	    AND f.SEGMENT3  IN ('2202010207','2241010217') 
	    AND f.PERIOD_NAME = executemonth
	    AND f.JE_CATEGORY='ACC'
		and f.SHORT_NAME  not like 'THTF_I17%';

	   
	-- 执行结束
	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis_tempdata','END','【佣金财务账龄分析临时数据生成】方法执行结束');
	COMMIT;
END;