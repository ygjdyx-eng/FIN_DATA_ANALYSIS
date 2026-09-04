CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.procedure_Aging_analysisplis(executemonth IN varchar2 )
AS
BEGIN 

 	-- 开始执行
 	INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysisplis','START','【账龄数据生成】方法正在执行');
    
 
-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis01 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis02 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis03 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;


-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis04 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis05 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis06 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis07 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis08 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis09 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis10 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis11 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis12 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;

-- 生成新的账龄数据 ,个险，团险，佣金分开处理
-- 个险无需业务号等信息  个险所需
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
    AGING_PERIOD,       --账龄开始时间
    POLICY_NO,          --保单号
    BUSINESS_SCENE_NO,  --业务号
    account_segment     --账户段
)
SELECT 
    sequence_FINANCE_Aging_analysis.nextval AS id,   --id
    subquery_result.subject_id,                      --科目
    subquery_result.subject_name,                    --科目名称
    subquery_result.sum_amount AS amount,            --金额
    subquery_result.DEFAULT_EFFECTIVE_DATE,          --凭证日期
    subquery_result.aging_month,                     --账龄
    subquery_result.handle_status,                   --处理状态
    subquery_result.district_id as  district_id ,
    (SELECT distinct a.BRANCH_NAME FROM mrt.FRS_DIM_COA_CO a WHERE a. BRANCH_CODE =subquery_result.district_id) AS DISTRICT_NAME, --地址名称,
    subquery_result.JE_SOURCE,    --来源       
    subquery_result.BRANCH_CODE,
    executemonth  AS AGING_PERIOD,   --账龄开始时间
    subquery_result.POLICY_NO,                    --保单号
    subquery_result.BUSINESS_SCENE_NO,            --业务号
    account_segment                               --账户段
FROM (
    SELECT 
        subject_id,
        subject_name,
        SUM(amount) AS sum_amount,
        min(DEFAULT_EFFECTIVE_DATE) AS DEFAULT_EFFECTIVE_DATE ,
        aging_month,
        handle_status,
        nvl(district_id, (SELECT MIN(c.BRANCH_CODE) FROM mrt.FRS_DIM_COA_CO c WHERE c.CO_ADMIN_CODE LIKE  CONCAT(SUBSTR(a.BRANCH_CODE, 1, 9), '%'))) AS district_id ,                     --地址
        
        
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9) AS BRANCH_CODE,
        POLICY_NO,
        max(BUSINESS_SCENE_NO) AS BUSINESS_SCENE_NO,
        account_segment
    FROM 
        temp_finally_FINANCE_Aging_analysis13 a  
    WHERE 
       a.JE_SOURCE ='PLIS'  AND a.ZERO_CLOSING_MARKER ='0'
    GROUP BY 
        subject_id,
        subject_name,
        aging_month,
        handle_status,
        district_id,
        JE_SOURCE,
        SUBSTR(BRANCH_CODE, 1, 9),    
        account_segment,
        POLICY_NO
     having sum(a.amount) <> 0
) subquery_result;
    
    INSERT INTO course_method_log (id,EXECUTE_MONTH,METHOD_NAME,METHOD_STATUS,DESCRIPTION) VALUES (sequence_course_method_log.nextval,executemonth,'procedure_Aging_analysis','END','【账龄数据生成】方法执行结束');
 		
    COMMIT;
END;