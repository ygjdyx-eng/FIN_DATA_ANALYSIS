CREATE OR REPLACE PROCEDURE FIN_DATA_ANALYSIS.BALANCE_OFF(executemonth IN varchar2) AS  
BEGIN 
    --先清除数据防止误删除
	delete from FI_AGING where 1=1; 
    delete from FI_AGING01 where 1=1; 
    delete from FI_AGINGAGS where 1=1; 
	delete from FI_AGING_GLIS where 1=1; 
   
	-- 处理最终的账龄(排除结0的账目) 以整体保单为维度,仅以个险为维度
	INSERT INTO FI_AGING (id, POLICY_NO,SUBJECT_ID)
	SELECT 
    sequence_FI_AGING.nextval AS id,
    a.POLICY_NO,
    a.SUBJECT_ID
    FROM (
      SELECT
        a.POLICY_NO ,a.SUBJECT_ID  
      FROM FINANCE_Aging_analysis a 
      WHERE a.AGING_PERIOD=executemonth and a.JE_SOURCE='PLIS' 
      GROUP BY a.POLICY_NO ,a.SUBJECT_ID,a.JE_SOURCE  HAVING sum(a.AMOUNT)= 0 
    ) a;
   
   INSERT INTO FI_AGING01 (id, POLICY_NO,BRANCH_CODE,SUBJECT_ID)
	SELECT 
    sequence_FI_AGING.nextval AS id,
    a.POLICY_NO,
    a.BRANCH_CODE,a.SUBJECT_ID
    FROM (
      SELECT
        a.POLICY_NO ,a.BRANCH_CODE ,SUBJECT_ID
      FROM FINANCE_Aging_analysis a 
      WHERE a.AGING_PERIOD=executemonth and a.JE_SOURCE='PLIS' 
      GROUP BY a.POLICY_NO ,a.BRANCH_CODE,a.JE_SOURCE,SUBJECT_ID  HAVING sum(a.AMOUNT)= 0 
    ) a;
    
    --进行结零处理
    DELETE FROM FINANCE_Aging_analysis c WHERE c.aging_period=executemonth  AND C.JE_SOURCE='PLIS' 
    AND EXISTS (SELECT 1 FROM FI_AGING B WHERE B.POLICY_NO = c.POLICY_NO  AND B.SUBJECT_ID = c.SUBJECT_ID);
    
    DELETE FROM FINANCE_Aging_analysis c WHERE c.aging_period=executemonth  AND C.JE_SOURCE='PLIS' 
    AND EXISTS (SELECT 1 FROM FI_AGING01 B WHERE B.POLICY_NO = c.POLICY_NO  AND B.BRANCH_CODE  = c.BRANCH_CODE AND B.SUBJECT_ID = c.SUBJECT_ID);
   
    -- AGS 第一轮：非空保单号按原七个维度计算合计，直接通过 ROWID 定位结零记录。
    -- 不再生成或关联第一轮 FI_AGINGAGS 名单；空保单号仍由下方独立分支处理。
    -- 原关联使用 SUBJECT_ID 等值匹配，不匹配空科目；此处保留该语义。
    DELETE FROM FINANCE_Aging_analysis c
    WHERE c.AGING_PERIOD = executemonth
      AND c.JE_SOURCE = 'AGS'
      AND c.POLICY_NO IS NOT NULL
      AND c.SUBJECT_ID IS NOT NULL
      AND c.ROWID IN (
          SELECT q.RID
          FROM (
              SELECT a.ROWID AS RID,
                     SUM(a.AMOUNT) OVER (
                         PARTITION BY a.PERIOD_NAME,
                                      a.SUBJECT_ID,
                                      a.JE_SOURCE,
                                      a.AGENT_NAME,
                                      a.POLICY_NO,
                                      a.AGING_PERIOD,
                                      a.BUSINESS_SCENE_NO
                     ) AS GROUP_AMOUNT
              FROM FINANCE_Aging_analysis a
              WHERE a.AGING_PERIOD = executemonth
                AND a.JE_SOURCE = 'AGS'
                AND a.POLICY_NO IS NOT NULL
                AND a.SUBJECT_ID IS NOT NULL
          ) q
          WHERE q.GROUP_AMOUNT = 0
      );
	
	-- 第一轮补充：空保单号不写辅助表，也不替换成虚拟保单号。
	-- 保留原分组维度及 SUM(amount)=0 口径，只清理本账期 AGS 的空保单号结零分组。
    DELETE FROM FINANCE_Aging_analysis c
    WHERE c.AGING_PERIOD = executemonth
      AND c.JE_SOURCE = 'AGS'
      AND c.POLICY_NO IS NULL
      AND EXISTS (
          SELECT 1
          FROM (
              SELECT PERIOD_NAME, SUBJECT_ID, JE_SOURCE, AGENT_NAME,
                     POLICY_NO, AGING_PERIOD, BUSINESS_SCENE_NO
              FROM FINANCE_Aging_analysis a
              WHERE a.JE_SOURCE = 'AGS'
                AND a.AGING_PERIOD = executemonth
                AND a.POLICY_NO IS NULL
              GROUP BY PERIOD_NAME, SUBJECT_ID, JE_SOURCE, AGENT_NAME,
                       POLICY_NO, AGING_PERIOD, BUSINESS_SCENE_NO
              HAVING SUM(amount) = 0
          ) b
          WHERE (b.PERIOD_NAME = c.PERIOD_NAME OR (b.PERIOD_NAME IS NULL AND c.PERIOD_NAME IS NULL))
            AND b.SUBJECT_ID = c.SUBJECT_ID
            AND b.JE_SOURCE = c.JE_SOURCE
            AND (b.AGENT_NAME = c.AGENT_NAME OR (b.AGENT_NAME IS NULL AND c.AGENT_NAME IS NULL))
            AND b.AGING_PERIOD = c.AGING_PERIOD
            AND (b.BUSINESS_SCENE_NO = c.BUSINESS_SCENE_NO OR (b.BUSINESS_SCENE_NO IS NULL AND c.BUSINESS_SCENE_NO IS NULL))
      );

	-- 第二轮开始前清空工作名单，辅助表仅用于本轮代理人整体结零的结果。
	-- 此处只清空结零辅助表，不清理历史明细，也不是重跑自动清理。
	DELETE FROM FI_AGINGAGS;

	-- 第二轮：仅2202010207、2241010217按代理人跨保单结零，保留原业务范围。
	INSERT INTO FI_AGINGAGS  (id, PERIOD_NAME,SUBJECT_ID,JE_SOURCE,AGENT_NAME,POLICY_NO,AGING_PERIOD,BUSINESS_SCENE_NO)
    SELECT sequence_FI_AGINGAGS.nextval AS id,
         PERIOD_NAME,SUBJECT_ID,JE_SOURCE,AGENT_NAME,POLICY_NO,AGING_PERIOD,BUSINESS_SCENE_NO  
         FROM(
			SELECT null as PERIOD_NAME,SUBJECT_ID,JE_SOURCE,AGENT_NAME,'1' as POLICY_NO ,AGING_PERIOD, null as BUSINESS_SCENE_NO
				FROM FINANCE_Aging_analysis a WHERE 1=1 AND a.JE_SOURCE='AGS' AND a.AGING_PERIOD=executemonth and SUBJECT_ID in ('2202010207','2241010217')
				GROUP BY SUBJECT_ID,JE_SOURCE,AGENT_NAME,AGING_PERIOD  HAVING SUM(amount) = 0 );
		
	DELETE FROM FINANCE_Aging_analysis c WHERE c.aging_period=executemonth  AND C.JE_SOURCE='AGS' 
    AND EXISTS (SELECT 1 FROM FI_AGINGAGS B WHERE B.SUBJECT_ID in ('2202010207','2241010217')
    AND B.SUBJECT_ID = c.SUBJECT_ID
    AND B.JE_SOURCE = c.JE_SOURCE
    AND (B.AGENT_NAME = c.AGENT_NAME OR (B.AGENT_NAME IS NULL AND c.AGENT_NAME IS NULL))
    AND B.AGING_PERIOD = c.AGING_PERIOD);
	
	
	
	-- 团险进行结0处理，排除 2243010106 独立帐户负债-公司转独立帐户(万能)科目
	INSERT INTO FI_AGING_GLIS  (id, POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO)
    SELECT sequence_FI_AGINGAGS.nextval AS id,POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO  
    FROM(
	    SELECT POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO
		FROM FINANCE_Aging_analysis a WHERE 1=1 AND a.JE_SOURCE='GLIS' AND a.AGING_PERIOD=executemonth 
		and SUBJECT_ID not in ('2243010106')
		GROUP BY SUBJECT_ID,JE_SOURCE,POLICY_NO,BUSINESS_SCENE_NO,AGING_PERIOD HAVING SUM(amount) = 0 );
		
    -- 单独处理 2243010106 独立帐户负债-公司转独立帐户(万能)科目，包含1301，1302，整体是结0的，处理单边。
	INSERT INTO FI_AGING_GLIS  (id, POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO)
    SELECT sequence_FI_AGINGAGS.nextval AS id,POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO  
    FROM(
	    SELECT POLICY_NO,SUBJECT_ID,JE_SOURCE,AGING_PERIOD,BUSINESS_SCENE_NO
		FROM FINANCE_Aging_analysis a WHERE 1=1 AND a.JE_SOURCE='GLIS' AND a.AGING_PERIOD=executemonth 
		and SUBJECT_ID in ('2243010106') AND ACCOUNT_SEGMENT = '1301'
		GROUP BY SUBJECT_ID,JE_SOURCE,POLICY_NO,BUSINESS_SCENE_NO,AGING_PERIOD HAVING SUM(amount) = 0 );
	
		
	DELETE FROM FINANCE_Aging_analysis c WHERE c.aging_period=executemonth  AND C.JE_SOURCE='GLIS' 
    AND EXISTS (SELECT 1 FROM FI_AGING_GLIS B WHERE B.SUBJECT_ID = c.SUBJECT_ID
    AND B.JE_SOURCE = c.JE_SOURCE
	AND B.POLICY_NO = c.POLICY_NO
    AND NVL(B.BUSINESS_SCENE_NO,'null')  = NVL(c.BUSINESS_SCENE_NO,'null'));
	
	COMMIT;
END ;
