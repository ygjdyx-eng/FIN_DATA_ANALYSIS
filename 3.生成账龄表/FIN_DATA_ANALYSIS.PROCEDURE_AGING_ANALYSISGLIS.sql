CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.procedure_Aging_analysisglis(executemonth IN varchar2)
AS finallycount NUMBER;

BEGIN 
 
 	-- 开始执行
 	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','START','【团险账龄数据生成】方法正在执行');
	SELECT count(id) INTO finallycount FROM temp_finally_FINANCE_Aging_analysis;
	
	IF finallycount>0 THEN
 

	-- 生成新的账龄数据 ,个险，团险，佣金分开处理
	INSERT INTO FINANCE_Aging_analysis (
		id,                 --ID 
		subject_id,         --科目
		subject_name,       --科目名称
		amount,             --金额
		DEFAULT_EFFECTIVE_DATE,  --凭证日期
		aging_month,        --账龄
		handle_status,      --处理状态 暂时没作用   
		district_id,        --地区
		DISTRICT_NAME,      --地区名称
		JE_SOURCE,          --来源
		BRANCH_CODE,        --机构
		POLICY_NO,          --保单号
		BUSINESS_SCENE_NO,  --业务号
		AGING_PERIOD ,      --账龄开始时间
		account_segment
	)
	SELECT 
		sequence_FINANCE_Aging_analysis.nextval AS id,   --id
		subquery_result.subject_id,                      --科目
		(CASE WHEN subquery_result.subject_id='207101*' THEN '保户投资款-公共'
			  WHEN subquery_result.subject_id='207102*' THEN '保户投资款-个人'
			  ELSE 'NULL' END)  AS  subject_name,             --科目名称
		subquery_result.sum_amount AS amount,            --金额
		subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
		subquery_result.aging_month,                     --账龄
		subquery_result.handle_status,                   --处理状态
		subquery_result.district_id,                     --地址
		(SELECT a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
		subquery_result.JE_SOURCE,    --来源       
		subquery_result.BRANCH_CODE,  --机构
		subquery_result.POLICY_NO,                     --保单号
		subquery_result.BUSINESS_SCENE_NO,             --业务号
		executemonth  AS AGING_PERIOD   ,--账龄开始时间,
		account_segment  --账户段
	FROM (
		SELECT 
			subject_id,
			SUM(amount) AS sum_amount,
			max(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE,
			min(aging_month) AS aging_month,
			handle_status,
			district_id,
			JE_SOURCE,
			BRANCH_CODE,
			POLICY_NO,
			max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
			account_segment
		FROM 
			temp_finally_FINANCE_Aging_analysis a  
		WHERE 
		   a.JE_SOURCE ='GLIS'
		   AND a.subject_id  IN ('207102*','207101*')
		   AND a.ZERO_CLOSING_MARKER = '0'
		GROUP BY 
			subject_id,
			handle_status,
			district_id,
			JE_SOURCE,
			BRANCH_CODE,
			account_segment,
			POLICY_NO
	) subquery_result WHERE subquery_result.sum_amount<>'0';

	COMMIT;

	-- 生成新的账龄数据 ,个险，团险，佣金分开处理
	INSERT INTO FINANCE_Aging_analysis (
		id,                 		--ID 
		subject_id,         		--科目
		subject_name,       		--科目名称
		amount,             		--金额
		DEFAULT_EFFECTIVE_DATE,     --凭证日期
		aging_month,        		--账龄
		handle_status,      		--处理状态 暂时没作用   
		district_id,        		--地址
		DISTRICT_NAME,      		--地址名称
		JE_SOURCE,          		--来源
		BRANCH_CODE,        		--机构
		POLICY_NO,          		--保单号
		BUSINESS_SCENE_NO,
		AGING_PERIOD  ,             --账龄开始时间
		account_segment
	)
	SELECT 
		sequence_FINANCE_Aging_analysis.nextval AS id,   --id
		subquery_result.subject_id,                      --科目
		subquery_result.subject_name,                    --科目名称
		subquery_result.sum_amount AS amount,            --金额
		subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
		subquery_result.aging_month,                     --账龄
		subquery_result.handle_status,                   --处理状态
		subquery_result.district_id,                     --地址
		(SELECT a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
		subquery_result.JE_SOURCE,                       --来源       
		subquery_result.BRANCH_CODE,                     --机构
		subquery_result.POLICY_NO,                       --保单号
		subquery_result.BUSINESS_SCENE_NO,               --业务号
		executemonth  AS AGING_PERIOD,                   --账龄开始时间,
		account_segment                                  --账户段
	FROM (
		SELECT 
			subject_id,
			subject_name,
			SUM(amount) AS sum_amount,
			min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
			aging_month AS aging_month ,
			handle_status,
			district_id,
			JE_SOURCE,
			BRANCH_CODE,
			POLICY_NO,
			BUSINESS_SCENE_NO AS BUSINESS_SCENE_NO,
			account_segment
		FROM 
			temp_finally_FINANCE_Aging_analysis a  
		WHERE 
		   a.JE_SOURCE ='GLIS'AND a.subject_id NOT IN ('2203030101','207102*', '207101*')
		   AND a.ZERO_CLOSING_MARKER ='0'
		GROUP BY 
			subject_id,
			subject_name,
			handle_status,
			district_id,
			JE_SOURCE,
			BUSINESS_SCENE_NO,
			BRANCH_CODE,
			account_segment,
			POLICY_NO,
			aging_month
	) subquery_result WHERE sum_amount<>'0';


	INSERT INTO FINANCE_Aging_analysis (
		id,                 --ID 
		subject_id,         --科目
		subject_name,       --科目名称
		amount,             --金额
		DEFAULT_EFFECTIVE_DATE,  --凭证日期
		aging_month,        --账龄
		handle_status,      --处理状态 暂时没作用   
		district_id,        --地址
		DISTRICT_NAME,      --地址名称
		JE_SOURCE,          --来源
		BRANCH_CODE,        --机构
		POLICY_NO,          --保单号
		BUSINESS_SCENE_NO,
		AGING_PERIOD  ,     --账龄开始时间
		account_segment
	)
	SELECT 
		sequence_FINANCE_Aging_analysis.nextval AS id,   --id
		subquery_result.subject_id,                      --科目
		subquery_result.subject_name,                    --科目名称
		subquery_result.sum_amount AS amount,            --金额
		subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
		subquery_result.aging_month,                     --账龄
		subquery_result.handle_status,                   --处理状态
		subquery_result.district_id,                     --地址
		(SELECT a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
		subquery_result.JE_SOURCE,    --来源       
		subquery_result.BRANCH_CODE,  --机构
		'null' AS POLICY_NO,                    --保单号
		subquery_result.BUSINESS_SCENE_NO,             --业务号
		executemonth  AS AGING_PERIOD   ,--账龄开始时间,
		account_segment  --账户段
	FROM (
		SELECT 
			subject_id,
			subject_name,
			SUM(amount) AS sum_amount,
			min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
			aging_month AS aging_month ,
			handle_status,
			district_id,
			JE_SOURCE,
			BRANCH_CODE,
			BUSINESS_SCENE_NO AS BUSINESS_SCENE_NO,
			account_segment
		FROM 
			temp_finally_FINANCE_Aging_analysis a  
		WHERE 
		   a.JE_SOURCE ='GLIS'AND a.subject_id  IN ('2203030101')
		   AND a.ZERO_CLOSING_MARKER ='0'
		GROUP BY 
			subject_id,
			subject_name,
			handle_status,
			district_id,
			JE_SOURCE,
			BUSINESS_SCENE_NO,
			BRANCH_CODE,
			account_segment,
			aging_month
	) subquery_result WHERE sum_amount<>'0';


 
	-- 执行结束记录日志  
	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','END','【团险账龄数据生成】方法执行结束');
	ELSE 
	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','ERROR','【团险账龄数据生成】未生成最终临时账龄表数据');
	END IF;

	COMMIT;
 
END;