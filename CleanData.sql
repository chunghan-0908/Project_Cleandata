create table SALES_DATASET_RFM_PRJ
(
  ordernumber VARCHAR,
  quantityordered VARCHAR,
  priceeach        VARCHAR,
  orderlinenumber  VARCHAR,
  sales            VARCHAR,
  orderdate        VARCHAR,
  status           VARCHAR,
  productline      VARCHAR,
  msrp             VARCHAR,
  productcode      VARCHAR,
  customername     VARCHAR,
  phone            VARCHAR,
  addressline1     VARCHAR,
  addressline2     VARCHAR,
  city             VARCHAR,
  state            VARCHAR,
  postalcode       VARCHAR,
  country          VARCHAR,
  territory        VARCHAR,
  contactfullname  VARCHAR,
  dealsize         VARCHAR
)

SELECT * FROM SALES_DATASET_RFM_PRJ

/*1. Chuyển đổi kiểu dữ liệu phù hợp cho các trường ( sử dụng câu lệnh ALTER)*/
ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN priceeach TYPE numeric USING (trim(priceeach)::numeric);

ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN quantityordered TYPE int USING (trim(quantityordered)::int);

ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN sales TYPE double precision USING (trim(sales)::double precision);

ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN orderdate TYPE TIMESTAMP USING TO_TIMESTAMP(orderdate, 'MM/DD/YYYY HH24:MI');


/*2. Check NULL/BLANK (‘’)  ở các trường: ORDERNUMBER, QUANTITYORDERED, PRICEEACH, 
ORDERLINENUMBER, SALES, ORDERDATE.*/
SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE ordernumber IS NULL

SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE quantityordered IS NULL

SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE priceeach IS NULL

SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE orderlinenumber IS NULL

SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE sales IS NULL

SELECT * 
FROM SALES_DATASET_RFM_PRJ
WHERE orderdate IS NULL

/*3. Thêm cột CONTACTLASTNAME, CONTACTFIRSTNAME được tách ra từ CONTACTFULLNAME.*/
--Thêm cột
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN contactlastname VARCHAR(50);

ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN contacfirstname VARCHAR(50); 

--Insert data
UPDATE SALES_DATASET_RFM_PRJ
SET 
    contactlastname = UPPER(LEFT(SPLIT_PART(CONTACTFULLNAME, '-', 1), 1)) 
					|| RIGHT(SPLIT_PART(CONTACTFULLNAME, '-', 1), LENGTH(SPLIT_PART(CONTACTFULLNAME, '-', 1)) - 1),
    contacfirstname = UPPER(LEFT(SPLIT_PART(CONTACTFULLNAME, '-', 2), 1)) 
					|| LOWER(RIGHT(SPLIT_PART(CONTACTFULLNAME, '-', 2), LENGTH(SPLIT_PART(CONTACTFULLNAME, '-', 2)) - 1));


/*4. Thêm cột QTR_ID, MONTH_ID, YEAR_ID lần lượt là Qúy, tháng, năm được lấy ra từ ORDERDATE */
--Tạo cột 
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN QTR_ID INTEGER,
ADD COLUMN MONTH_ID INTEGER,
ADD COLUMN YEAR_ID INTEGER;

--Insert data
UPDATE SALES_DATASET_RFM_PRJ
SET 
    QTR_ID = EXTRACT(QUARTER FROM ORDERDATE),
    MONTH_ID = EXTRACT(MONTH FROM ORDERDATE),
    YEAR_ID = EXTRACT(YEAR FROM ORDERDATE);

/*5. Hãy tìm outlier (nếu có) cho cột QUANTITYORDERED và hãy chọn cách xử lý cho bản ghi đó (2 cách) 
(Không chạy câu lệnh trước khi bài được review)*/
--Tìm outlier bằng IQR/BOX PLOT
WITH cte_min_max_value AS (
SELECT Q1-1.5*IQR AS min_value, 
	   Q3+1.5*IQR AS max_value 
	FROM
		(SELECT percentile_cont(0.25) within group (order by quantityordered) AS Q1,
			percentile_cont(0.75) within group (order by quantityordered) AS Q3,
			percentile_cont(0.75) within group (order by quantityordered) 
				- percentile_cont(0.25) within group (order by quantityordered) AS IQR
		FROM SALES_DATASET_RFM_PRJ) as temp)

---Xác định outlier
SELECT * FROM SALES_DATASET_RFM_PRJ
WHERE quantityordered < (SELECT min_value FROM cte_min_max_value)
	OR quantityordered > (SELECT max_value FROM cte_min_max_value);
	
---Các cách xử lý outlier
--Cách 1: xóa
DELETE FROM SALES_DATASET_RFM_PRJ
WHERE quantityordered > min_value OR quantityordered < max_value;

--Cách 2: thay thế bằng AVG(quantityordered)
UPDATE SALES_DATASET_RFM_PRJ
SET quantityordered = (SELECT AVG(quantityordered) FROM SALES_DATASET_RFM_PRJ)
WHERE quantityordered > min_value OR quantityordered < max_value;

/*6. Sau khi làm sạch dữ liệu, hãy lưu vào bảng mới tên là SALES_DATASET_RFM_PRJ_CLEAN*/
CREATE TABLE SALES_DATASET_RFM_PRJ_CLEAN AS SELECT * FROM SALES_DATASET_RFM_PRJ 



