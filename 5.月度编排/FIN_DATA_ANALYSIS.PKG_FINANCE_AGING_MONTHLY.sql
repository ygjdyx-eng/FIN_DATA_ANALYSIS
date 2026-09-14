-- REVIEW DRAFT ONLY: do not execute before the documented deployment gates pass.
-- 审阅草案：未通过文档中的上线前门禁时，不得执行本脚本。
CREATE OR REPLACE PACKAGE FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY AS
  -- 指定月份总入口：依次尝试 PLIS、GLIS、AGS，任一系统成功后执行 BALANCE_OFF。
  PROCEDURE RUN_MONTHLY(p_execute_month IN VARCHAR2);

  -- 定时调度入口：根据数据库服务器当前月份，自动处理上一个自然月。
  PROCEDURE RUN_SCHEDULED;

  -- 单系统入口：只执行指定系统，不自动执行 BALANCE_OFF。
  PROCEDURE RUN_PLIS(p_execute_month IN VARCHAR2);
  PROCEDURE RUN_GLIS(p_execute_month IN VARCHAR2);
  PROCEDURE RUN_AGS(p_execute_month IN VARCHAR2);
END PKG_FINANCE_AGING_MONTHLY;
/

CREATE OR REPLACE PACKAGE BODY FIN_DATA_ANALYSIS.PKG_FINANCE_AGING_MONTHLY AS
  -- =====================================================================
  -- 1. 常量与内部类型
  -- =====================================================================
  -- 非法月份参数的自定义 Oracle 错误码。
  c_invalid_month_code      CONSTANT PLS_INTEGER := -20001;
  -- 月度编排出现一个或多个失败组件时的统一错误码。
  c_monthly_failed_code     CONSTANT PLS_INTEGER := -20002;
  -- RAISE_APPLICATION_ERROR 对外返回的汇总信息最大长度。
  c_raise_message_chars     CONSTANT PLS_INTEGER := 300;
  -- 写入 COURSE_METHOD_LOG.DESCRIPTION 的描述最大长度。
  c_log_description_chars  CONSTANT PLS_INTEGER := 500;

  -- 同一个账龄月份需要按子过程接口转换为三种格式。
  TYPE t_month_params IS RECORD (
    month_dash    VARCHAR2(7), -- YYYY-MM，例如 2025-04
    month_compact VARCHAR2(6), -- YYYYMM， 例如 202504
    aging_period  VARCHAR2(7)  -- YYYY0MM，例如 2025004
  );

  -- =====================================================================
  -- 2. 日志处理
  -- =====================================================================
  -- 日志使用自治事务，不受主业务 COMMIT/ROLLBACK 影响。
  -- 日志写入失败时仅输出 DBMS_OUTPUT，不覆盖原业务异常。
  PROCEDURE write_log(
    p_execute_month IN VARCHAR2,
    p_method_name   IN VARCHAR2,
    p_method_status IN VARCHAR2,
    p_description   IN VARCHAR2
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO FIN_DATA_ANALYSIS.COURSE_METHOD_LOG (
      id,
      execute_month,
      method_name,
      method_status,
      description
    ) VALUES (
      FIN_DATA_ANALYSIS.SEQUENCE_COURSE_METHOD_LOG.NEXTVAL,
      p_execute_month,
      p_method_name,
      p_method_status,
      SUBSTR(p_description, 1, c_log_description_chars)
    );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      BEGIN
        DBMS_OUTPUT.PUT_LINE(
          SUBSTR('AGING orchestration log failed: ' || SQLERRM, 1, 255)
        );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
  END write_log;

  -- =====================================================================
  -- 3. 月份参数校验与转换
  -- =====================================================================
  -- 公开入口只接收 YYYY-MM，然后统一派生子过程需要的格式。
  PROCEDURE derive_months(
    p_execute_month IN  VARCHAR2,
    p_months        OUT t_month_params
  ) IS
    v_month_date DATE;
  BEGIN
    IF p_execute_month IS NULL
       OR NOT REGEXP_LIKE(
         p_execute_month,
         '^[0-9]{4}-(0[1-9]|1[0-2])$'
       ) THEN
      RAISE_APPLICATION_ERROR(
        c_invalid_month_code,
        'p_execute_month must use YYYY-MM, for example 2025-04'
      );
    END IF;

    BEGIN
      v_month_date := TO_DATE(p_execute_month, 'FXYYYY-MM');
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
          c_invalid_month_code,
          'p_execute_month is not a valid calendar month: ' || p_execute_month
        );
    END;

    IF TO_CHAR(v_month_date, 'YYYY-MM') <> p_execute_month THEN
      RAISE_APPLICATION_ERROR(
        c_invalid_month_code,
        'p_execute_month is not a valid calendar month: ' || p_execute_month
      );
    END IF;

    -- 例：2025-04 -> 2025-04 / 202504 / 2025004。
    p_months.month_dash := p_execute_month;
    p_months.month_compact := REPLACE(p_execute_month, '-', '');
    p_months.aging_period :=
      SUBSTR(p_execute_month, 1, 4)
      || LPAD(SUBSTR(p_execute_month, 6, 2), 3, '0');
  END derive_months;

  -- =====================================================================
  -- 4. 错误信息格式化与汇总
  -- =====================================================================
  -- 保留原 SQLCODE 与 SQLERRM，便于追溯子过程失败原因。
  FUNCTION format_error(
    p_code    IN PLS_INTEGER,
    p_message IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SQLCODE=' || TO_CHAR(p_code)
      || ', SQLERRM=' || SUBSTR(p_message, 1, 500);
  END format_error;

  -- 累加各失败组件的详细错误。
  FUNCTION append_error(
    p_summary IN VARCHAR2,
    p_name    IN VARCHAR2,
    p_detail  IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    IF p_summary IS NULL THEN
      RETURN p_name || ': ' || p_detail;
    END IF;
    RETURN p_summary || '; ' || p_name || ': ' || p_detail;
  END append_error;

  -- 累加组件名称和 SQLCODE，保证多个失败时不丢失组件信息。
  FUNCTION append_failure_code(
    p_summary IN VARCHAR2,
    p_name    IN VARCHAR2,
    p_code    IN PLS_INTEGER
  ) RETURN VARCHAR2 IS
  BEGIN
    IF p_summary IS NULL THEN
      RETURN p_name || '=' || TO_CHAR(p_code);
    END IF;
    RETURN p_summary || ', ' || p_name || '=' || TO_CHAR(p_code);
  END append_failure_code;

  -- =====================================================================
  -- 5. PLIS 账龄执行链
  -- =====================================================================
  -- 判定成功的依据是子过程未向外抛出异常。
  PROCEDURE run_plis_core(p_months IN t_month_params) IS
    v_error_code    PLS_INTEGER;
    v_error_message VARCHAR2(4000);
  BEGIN
    write_log(p_months.month_dash, 'AGING_PLIS', 'START', 'PLIS started');

    -- 阶段1：按 YYYY-MM 运行 13 个 PLIS 基础临时数据过程。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS01(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS02(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS03(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS04(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS05(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS06(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS07(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS08(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS09(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS10(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS11(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS12(p_months.month_dash);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS13(p_months.month_dash);

    -- 阶段2：按 YYYYMM 运行 13 个 PLIS 二次处理过程。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0102(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0202(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0302(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0402(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0502(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0602(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0702(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0802(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS0902(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1002(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1102(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1202(p_months.month_compact);
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAPLIS1302(p_months.month_compact);

    -- 阶段3：按 YYYY0MM 生成 PLIS 最终账龄结果。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSISPLIS(p_months.aging_period);

    write_log(p_months.month_dash, 'AGING_PLIS', 'END', 'PLIS completed');
  EXCEPTION
    WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      write_log(
        p_months.month_dash,
        'AGING_PLIS',
        'ERROR',
        'PLIS failed: ' || format_error(v_error_code, v_error_message)
      );
      RAISE;
  END run_plis_core;

  -- =====================================================================
  -- 6. GLIS 账龄执行链
  -- =====================================================================
  -- 注意：现有 GLIS 阶段3在某些无数据情形下可能只记 ERROR 日志但不抛异常，
  -- 此时本 Package 仍会按“成功返回”处理，需要运维同时核对子过程日志。
  PROCEDURE run_glis_core(p_months IN t_month_params) IS
    v_error_code    PLS_INTEGER;
    v_error_message VARCHAR2(4000);
  BEGIN
    write_log(p_months.month_dash, 'AGING_GLIS', 'START', 'GLIS started');

    -- 阶段1：YYYY-MM 基础临时数据。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_GLISTEMPDATA(p_months.month_dash);
    -- 阶段2：YYYYMM 二次处理。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_GLISTEMPDATAGLIS02(p_months.month_compact);
    -- 阶段3：YYYY0MM 最终账龄结果。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSISGLIS(p_months.aging_period);

    write_log(p_months.month_dash, 'AGING_GLIS', 'END', 'GLIS completed');
  EXCEPTION
    WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      write_log(
        p_months.month_dash,
        'AGING_GLIS',
        'ERROR',
        'GLIS failed: ' || format_error(v_error_code, v_error_message)
      );
      RAISE;
  END run_glis_core;

  -- =====================================================================
  -- 7. AGS 账龄执行链
  -- =====================================================================
  -- 注意：现有 AGS 阶段3也可能只记 ERROR 日志而不抛异常，
  -- 因此调度结果与子过程日志都需要核对。
  PROCEDURE run_ags_core(p_months IN t_month_params) IS
    v_error_code    PLS_INTEGER;
    v_error_message VARCHAR2(4000);
  BEGIN
    write_log(p_months.month_dash, 'AGING_AGS', 'START', 'AGS started');

    -- 阶段1：YYYY-MM 基础临时数据。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAAGS(p_months.month_dash);
    -- 阶段2：现有接口仍使用 YYYY-MM。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSIS_TEMPDATAAGS02(p_months.month_dash);
    -- 阶段3：YYYY0MM 最终账龄结果。
    FIN_DATA_ANALYSIS.PROCEDURE_AGING_ANALYSISAGS(p_months.aging_period);

    write_log(p_months.month_dash, 'AGING_AGS', 'END', 'AGS completed');
  EXCEPTION
    WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      write_log(
        p_months.month_dash,
        'AGING_AGS',
        'ERROR',
        'AGS failed: ' || format_error(v_error_code, v_error_message)
      );
      RAISE;
  END run_ags_core;

  -- =====================================================================
  -- 8. 单系统公开入口
  -- =====================================================================
  -- 以下入口用于人工单系统执行或补跑，均不调用 BALANCE_OFF。
  -- 现有子过程包含内部 COMMIT，异常时的 ROLLBACK 只能清理尚未提交的尾部操作。
  PROCEDURE RUN_PLIS(p_execute_month IN VARCHAR2) IS
    v_months t_month_params;
  BEGIN
    derive_months(p_execute_month, v_months);
    BEGIN
      run_plis_core(v_months);
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
  END RUN_PLIS;

  PROCEDURE RUN_GLIS(p_execute_month IN VARCHAR2) IS
    v_months t_month_params;
  BEGIN
    derive_months(p_execute_month, v_months);
    BEGIN
      run_glis_core(v_months);
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
  END RUN_GLIS;

  PROCEDURE RUN_AGS(p_execute_month IN VARCHAR2) IS
    v_months t_month_params;
  BEGIN
    derive_months(p_execute_month, v_months);
    BEGIN
      run_ags_core(v_months);
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
  END RUN_AGS;

  -- =====================================================================
  -- 9. 月度总编排入口
  -- =====================================================================
  -- 执行顺序：参数校验 -> PLIS -> GLIS -> AGS -> BALANCE_OFF -> 错误汇总。
  -- 三个系统分别捕获异常，任一系统失败不阻断其他系统；本 Package 不自动重试。
  PROCEDURE RUN_MONTHLY(p_execute_month IN VARCHAR2) IS
    -- 各系统及 BALANCE_OFF 的执行状态。
    v_months           t_month_params;
    v_plis_ok           BOOLEAN := FALSE;
    v_glis_ok           BOOLEAN := FALSE;
    v_ags_ok            BOOLEAN := FALSE;
    v_balance_attempted BOOLEAN := FALSE;
    v_balance_ok        BOOLEAN := FALSE;
    -- 保留各失败组件的原始 SQLCODE。
    v_plis_error_code   PLS_INTEGER;
    v_glis_error_code   PLS_INTEGER;
    v_ags_error_code    PLS_INTEGER;
    v_balance_error_code PLS_INTEGER;
    -- 记录详细错误，在所有可继续步骤结束后统一汇总。
    v_plis_error        VARCHAR2(1000);
    v_glis_error        VARCHAR2(1000);
    v_ags_error         VARCHAR2(1000);
    v_balance_error     VARCHAR2(1000);
    v_failed_components VARCHAR2(1000);
    v_error_detail      VARCHAR2(32767);
    v_error_summary     VARCHAR2(32767);
  BEGIN
    -- 9.1 先校验并派生三种月份格式。
    derive_months(p_execute_month, v_months);
    write_log(v_months.month_dash, 'AGING_MONTHLY', 'START', 'Monthly aging started');

    -- 9.2 PLIS 独立执行块：失败后保留错误，继续执行 GLIS。
    BEGIN
      run_plis_core(v_months);
      v_plis_ok := TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        v_plis_error_code := SQLCODE;
        v_plis_error := format_error(v_plis_error_code, SQLERRM);
        ROLLBACK;
    END;

    -- 9.3 GLIS 独立执行块：失败后保留错误，继续执行 AGS。
    BEGIN
      run_glis_core(v_months);
      v_glis_ok := TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        v_glis_error_code := SQLCODE;
        v_glis_error := format_error(v_glis_error_code, SQLERRM);
        ROLLBACK;
    END;

    -- 9.4 AGS 独立执行块：失败不会抹掉前两个系统的状态。
    BEGIN
      run_ags_core(v_months);
      v_ags_ok := TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        v_ags_error_code := SQLCODE;
        v_ags_error := format_error(v_ags_error_code, SQLERRM);
        ROLLBACK;
    END;

    -- 9.5 只要 PLIS/GLIS/AGS 任一成功，即尝试执行一次 BALANCE_OFF。
    -- BALANCE_OFF 按期间处理已存在数据，可能波及当期多个系统的记录，
    -- 因此上线前必须完成已记录的 BALANCE_OFF 范围门禁核对。
    IF v_plis_ok OR v_glis_ok OR v_ags_ok THEN
      v_balance_attempted := TRUE;
      BEGIN
        write_log(
          v_months.month_dash,
          'AGING_BALANCE',
          'START',
          'BALANCE_OFF started'
        );
        FIN_DATA_ANALYSIS.BALANCE_OFF(v_months.aging_period);
        v_balance_ok := TRUE;
        write_log(
          v_months.month_dash,
          'AGING_BALANCE',
          'END',
          'BALANCE_OFF completed'
        );
      EXCEPTION
        WHEN OTHERS THEN
          v_balance_error_code := SQLCODE;
          v_balance_error := format_error(v_balance_error_code, SQLERRM);
          ROLLBACK;
          write_log(
            v_months.month_dash,
            'AGING_BALANCE',
            'ERROR',
            'BALANCE_OFF failed: ' || v_balance_error
          );
      END;
    ELSE
      write_log(
        v_months.month_dash,
        'AGING_BALANCE',
        'END',
        'BALANCE_OFF skipped: all systems failed'
      );
    END IF;

    -- 9.6 汇总所有失败组件，不以最后一个异常覆盖之前的错误。
    IF NOT v_plis_ok THEN
      v_failed_components := append_failure_code(
        v_failed_components,
        'PLIS',
        v_plis_error_code
      );
      v_error_detail := append_error(v_error_detail, 'PLIS', v_plis_error);
    END IF;
    IF NOT v_glis_ok THEN
      v_failed_components := append_failure_code(
        v_failed_components,
        'GLIS',
        v_glis_error_code
      );
      v_error_detail := append_error(v_error_detail, 'GLIS', v_glis_error);
    END IF;
    IF NOT v_ags_ok THEN
      v_failed_components := append_failure_code(
        v_failed_components,
        'AGS',
        v_ags_error_code
      );
      v_error_detail := append_error(v_error_detail, 'AGS', v_ags_error);
    END IF;
    IF v_balance_attempted AND NOT v_balance_ok THEN
      v_failed_components := append_failure_code(
        v_failed_components,
        'BALANCE_OFF',
        v_balance_error_code
      );
      v_error_detail := append_error(
        v_error_detail,
        'BALANCE_OFF',
        v_balance_error
      );
    END IF;

    -- 9.7 存在任一失败时，先写汇总日志，再用统一错误码通知调度平台。
    IF v_failed_components IS NOT NULL THEN
      v_error_summary := 'FAILED[' || v_failed_components || ']';
      IF v_error_detail IS NOT NULL THEN
        v_error_summary := v_error_summary
          || '; DETAILS[' || v_error_detail || ']';
      END IF;
      write_log(
        v_months.month_dash,
        'AGING_MONTHLY',
        'ERROR',
        v_error_summary
      );
      RAISE_APPLICATION_ERROR(
        c_monthly_failed_code,
        SUBSTR(v_error_summary, 1, c_raise_message_chars)
      );
    END IF;

    -- 只有所有已尝试组件都成功时，才记录月度编排成功。
    write_log(v_months.month_dash, 'AGING_MONTHLY', 'END', 'Monthly aging completed');
  END RUN_MONTHLY;

  -- =====================================================================
  -- 10. 定时调度入口
  -- =====================================================================
  -- 调度平台在本月调用时，按数据库服务器 SYSDATE 计算并处理上一个自然月。
  -- ADD_MONTHS 会自动处理跨年，例如 2026 年 1 月调用时处理 2025-12。
  -- 不在此处捕获异常，让 RUN_MONTHLY 的最终结果原样返回调度平台。
  PROCEDURE RUN_SCHEDULED IS
  BEGIN
    RUN_MONTHLY(
      TO_CHAR(
        ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1),
        'YYYY-MM'
      )
    );
  END RUN_SCHEDULED;
END PKG_FINANCE_AGING_MONTHLY;
/
