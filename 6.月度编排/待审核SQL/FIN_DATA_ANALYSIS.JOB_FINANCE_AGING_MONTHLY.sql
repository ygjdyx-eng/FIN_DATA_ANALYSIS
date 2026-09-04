
-- 用途：创建每月 10 日 02:00（Asia/Shanghai）执行的财务账龄任务。
-- 调用：FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_SCHEDULED。
-- 效果：本月调用时处理上一个自然月。
-- 安全：任务创建后保持禁用，本脚本不启用、不立即运行、不删除同名任务。

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK ON

-- =====================================================================
-- 1. 上线前检查：Package Spec 和 Body 必须都是 VALID
-- =====================================================================
SELECT owner,
       object_name,
       object_type,
       status
  FROM all_objects
 WHERE owner = 'FIN_DATA_ANALYSIS'
   AND object_name = 'PKG_FINANCE_AGING_MONTHLY'
   AND object_type IN ('PACKAGE', 'PACKAGE BODY')
 ORDER BY object_type;

-- RUN_SCHEDULED 使用数据库服务器 SYSDATE 计算上月，必须核对服务器日期。
SELECT SYSDATE         AS database_server_date,
       SYSTIMESTAMP    AS database_timestamp,
       DBTIMEZONE      AS database_time_zone,
       SESSIONTIMEZONE AS session_time_zone
  FROM dual;

-- 若返回同名任务，请停止执行并先由 DBA 核对；本脚本不自动覆盖。
SELECT owner,
       job_name,
       enabled,
       state,
       start_date,
       repeat_interval,
       next_run_date
  FROM all_scheduler_jobs
 WHERE owner = 'FIN_DATA_ANALYSIS'
   AND job_name = 'JOB_FINANCE_AGING_MONTHLY';

-- =====================================================================
-- 2. 创建定时任务（默认禁用）
-- =====================================================================
-- 首次计划时间：2026-10-10 02:00:00 Asia/Shanghai。
-- 后续计划时间：每月 10 日 02:00:00 Asia/Shanghai。
-- 如果上线时已超过首次计划时间，必须先由 DBA 重新确认 start_date。
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name            => 'FIN_DATA_ANALYSIS.JOB_FINANCE_AGING_MONTHLY',
    job_type            => 'STORED_PROCEDURE',
    job_action          => 'FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY.RUN_SCHEDULED',
    number_of_arguments => 0,
    start_date          => TO_TIMESTAMP_TZ(
                             '2026-10-10 02:00:00 Asia/Shanghai',
                             'YYYY-MM-DD HH24:MI:SS TZR'
                           ),
    repeat_interval     => 'FREQ=MONTHLY;BYMONTHDAY=10;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
    end_date            => NULL,
    enabled             => FALSE,
    auto_drop           => FALSE,
    comments            => '每月 10 日 02:00 处理上一个自然月财务账龄'
  );
END;
/

-- =====================================================================
-- 3. 创建后检查：ENABLED 应为 FALSE，STATE 应为 DISABLED
-- =====================================================================
SELECT owner,
       job_name,
       enabled,
       state,
       job_type,
       job_action,
       start_date,
       repeat_interval,
       next_run_date,
       auto_drop
  FROM all_scheduler_jobs
 WHERE owner = 'FIN_DATA_ANALYSIS'
   AND job_name = 'JOB_FINANCE_AGING_MONTHLY';

-- =====================================================================
-- 4. 执行历史查询：未启用且未运行时应无记录
-- =====================================================================
SELECT log_date,
       status,
       error#,
       req_start_date,
       actual_start_date,
       run_duration,
       additional_info
  FROM all_scheduler_job_run_details
 WHERE owner = 'FIN_DATA_ANALYSIS'
   AND job_name = 'JOB_FINANCE_AGING_MONTHLY'
 ORDER BY log_date DESC;

-- =====================================================================
-- 5. 人工启用/停用（只作为操作参考，默认注释）
-- =====================================================================
-- 完成 Package 编译、业务审阅、测试库验证和 BALANCE_OFF 风险门禁后，
-- 才可由 DBA 单独执行以下启用语句：
-- BEGIN
--   DBMS_SCHEDULER.ENABLE(
--     name => 'FIN_DATA_ANALYSIS.JOB_FINANCE_AGING_MONTHLY'
--   );
-- END;
-- /

-- 需要暂停后续调度时，由 DBA 单独执行：
-- BEGIN
--   DBMS_SCHEDULER.DISABLE(
--     name => 'FIN_DATA_ANALYSIS.JOB_FINANCE_AGING_MONTHLY'
--   );
-- END;
-- /
