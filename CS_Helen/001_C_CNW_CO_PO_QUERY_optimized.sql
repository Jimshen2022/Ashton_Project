-- File Path: D:\Documents\00-Query\Project_Query\Open order C and CNW_Query_version03.xlsb
-- Query Name: ASHTON OPEN ORDER QUERY FOR TRUDY
-- Created on: Oct 16, 2024, Version: 03
-- Modification History:
--   • Aug 06, 2025 – Added 'Ship Inst' column by Nguyen, Helen requirement
--   • Optimized query performance with indexing hints and structure improvements

WITH open_orders AS (
    SELECT
        t1.HOUSE,
        t1.ORDNO,
        t4.SHINS AS "Ship Inst",
        t1.ITMSQ,
        t1.ITNBR,
        t1.ITDSC,
        t1.ITCLS,
        t1.CCUSNO,
        t1.CSHPNO,
        t3.CUSNM,
        t4.CUSPO,
        -- 优化：将日期转换移到最外层，减少重复计算
        t2.TKNDAT,
        t2.FRZDAT,
        t2.RQSDAT,
        t1.RQIDT,
        t1.MFIDT,
        t2.ORDUSR,
        t1.COQTY,
        t1.QTYSH,
        t1.QTYBO,
        t1.COQTY - t1.QTYSH AS OPEN_CO_QTY,
        -- 优化：简化 CASE 表达式
        CASE
            WHEN t1.IAFLG = 0 THEN 'N'
            WHEN t1.IAFLG = 2 THEN 'Y'
            ELSE 'Check'
        END AS ALC,
        -- 优化：简化产品分类逻辑
        CASE
            WHEN t1.ITCLS NOT LIKE 'Z%' THEN 'RP'
            WHEN t1.ITNBR LIKE '100-%' THEN 'CG'
            WHEN LEFT(t1.ITNBR, 1) IN ('A','B','D','E','H','L','M','P','Q','R','T','W','Z') THEN 'CG'
            ELSE 'UPH'
        END AS Product,
        -- 创建连接键，避免在 JOIN 时进行字符串拼接
        t1.ORDNO || t1.ITMSQ || t1.ITNBR || t1.CCUSNO AS join_key
    FROM AFILELIB.CODATAN t1
        INNER JOIN AFILELIB.EXTORD t2 ON t2.XORDNO = t1.ORDNO
        INNER JOIN AFILELIB.ACUSMASJ t3 ON t3.CUSNO = t1.CCUSNO
        INNER JOIN AFILELIB.COMAST t4 ON t4.ORDNO = t1.ORDNO
    WHERE t1.HOUSE IN ('335', 'CNW', 'C')
        AND t1.COQTY > t1.QTYSH  -- 优化：使用 > 替代 <> 0，更清晰的意图
),
trip_data AS (
    SELECT
        t1.BDTRP#,
        t1.BDISEQ,
        t1.BDITQT AS Trip_Qty,
        t1.BDITCT,
        t1.BDITWT,
        t1.BDREF#,
        t2.BHCDAT,
        t2.BHCTIM,
        t2.BHRDAT,
        t2.BHLDAT,
        t2.BHLTIM,
        -- 预计算连接键
        t1.BDORD# || t1.BDISEQ || t1.BDITM# || t1.BDCUS# AS join_key
    FROM DISTLIB.BTTRIPD t1
        INNER JOIN DISTLIB.BTTRIPH t2 ON t1.BDTRP# = t2.BHTRP#
    WHERE t2.BHWHS# IN ('335', 'CNW', 'C')
        AND t2.BHLDAT <= 29991231  -- 优化：使用范围查询替代 BETWEEN 0 AND
        AND t2.BHTRPS IN ('A', 'R', 'X')
)
SELECT
    a1.HOUSE,
    a1.ORDNO,
    a1."Ship Inst",
    a1.ITMSQ,
    a1.ITNBR,
    a1.ITDSC,
    a1.ITCLS,
    a1.CCUSNO,
    a1.CSHPNO,
    a1.CUSNM,
    a1.CUSPO,
    -- 优化：日期转换只在最终输出时执行一次
    DATE(SUBSTR(CHAR(a1.TKNDAT + 1000000), 2, 4) || '-' ||
         SUBSTR(CHAR(a1.TKNDAT + 1000000), 6, 2) || '-' ||
         SUBSTR(CHAR(a1.TKNDAT + 1000000), 8, 2)) AS Order_Taken_Date,
    DATE(SUBSTR(CHAR(a1.FRZDAT + 1000000), 2, 4) || '-' ||
         SUBSTR(CHAR(a1.FRZDAT + 1000000), 6, 2) || '-' ||
         SUBSTR(CHAR(a1.FRZDAT + 1000000), 8, 2)) AS Original_Request_Date,
    DATE(SUBSTR(CHAR(a1.RQSDAT + 1000000), 2, 4) || '-' ||
         SUBSTR(CHAR(a1.RQSDAT + 1000000), 6, 2) || '-' ||
         SUBSTR(CHAR(a1.RQSDAT + 1000000), 8, 2)) AS CRD,
    DATE(SUBSTR(CHAR(a1.RQIDT + 1000000), 2, 4) || '-' ||
         SUBSTR(CHAR(a1.RQIDT + 1000000), 6, 2) || '-' ||
         SUBSTR(CHAR(a1.RQIDT + 1000000), 8, 2)) AS CPD,
    DATE(SUBSTR(CHAR(a1.MFIDT + 1000000), 2, 4) || '-' ||
         SUBSTR(CHAR(a1.MFIDT + 1000000), 6, 2) || '-' ||
         SUBSTR(CHAR(a1.MFIDT + 1000000), 8, 2)) AS LoadDate,
    a1.ORDUSR,
    a1.COQTY,
    a1.QTYSH,
    a1.QTYBO,
    a1.OPEN_CO_QTY,
    a1.ALC,
    a1.Product,
    x1.BDTRP#,
    x1.BDISEQ,
    x1.Trip_Qty,
    x1.BDITCT,
    x1.BDITWT,
    x1.BDREF#,
    x1.BHCDAT,
    x1.BHCTIM,
    x1.BHRDAT,
    x1.BHLDAT,
    x1.BHLTIM
FROM open_orders a1
    LEFT JOIN trip_data x1 ON a1.join_key = x1.join_key
ORDER BY a1.MFIDT, x1.BDTRP#, a1.ITNBR, x1.BDISEQ;

-- 推荐创建以下索引以提升性能：
/*
-- 主要表的复合索引
CREATE INDEX IDX_CODATAN_HOUSE_ORDNO ON AFILELIB.CODATAN (HOUSE, ORDNO, CCUSNO, COQTY, QTYSH);
CREATE INDEX IDX_EXTORD_XORDNO ON AFILELIB.EXTORD (XORDNO);
CREATE INDEX IDX_ACUSMASJ_CUSNO ON AFILELIB.ACUSMASJ (CUSNO);
CREATE INDEX IDX_COMAST_ORDNO ON AFILELIB.COMAST (ORDNO);

-- Trip 表的复合索引
CREATE INDEX IDX_BTTRIPH_BHWHS_BHLDAT ON DISTLIB.BTTRIPH (BHWHS#, BHLDAT, BHTRPS, BHTRP#);
CREATE INDEX IDX_BTTRIPD_BDTRP ON DISTLIB.BTTRIPD (BDTRP#, BDORD#, BDISEQ, BDITM#, BDCUS#);

-- 排序相关索引
CREATE INDEX IDX_CODATAN_MFIDT ON AFILELIB.CODATAN (MFIDT);
*/