SELECT * FROM developer
SELECT * FROM HeaderTransaction
SELECT * FROM Company
SELECT * FROM DetailTransaction
SELECT * FROM Project

-- 1. Display CompanyID (obtained FROM CompanyID by replacing "C" with "Company"), CompanyName, CompanyAddress (obtained by combining CompanyAddress that followed by "No." and the last digit of CompanyID), StartDate and EndDate for every company which name contains "Ironworks".
--(replace, right, like)
SELECT 'companyID'= REPLACE(c.companyID, 'c', 'Company '), c.CompanyName,
CompanyAddress + 'No.' + RIGHT(c.companyID,1), StartDate, EndDate
FROM Company c JOIN HeaderTransaction ht ON c.CompanyID=ht.CompanyID
WHERE CompanyName LIKE '%Ironworks%'

--2. Display Transaction Code (obtained by adding "TR-" in front of the last digit of TransactionID), ProjectID, ProjectName, Revenue, ProjectBudget, and Profit (obtained FROM subtraction between Revenue and ProjectBudget) for every transaction which revenue is between 100000000 and 200000000.
--(right, JOIN, between)
SELECT 'Transaction Code' = 'TR-' + RIGHT(ht.TransactionID, 1), 
	p.ProjectID,
	p.projectName, 
	dt.Revenue, 
	p.ProjectBudget, 
	'Profit' = Revenue-ProjectBudget
FROM HeaderTransaction ht 
	JOIN DetailTransaction dt ON ht.TransactionID=dt.TransactionID
	JOIN Project p ON dt.ProjectID=p.ProjectID
WHERE dt.Revenue BETWEEN 10000000 AND 200000000

--3. Display CompanyID, DeveloperID, and Tax Revenue (obtained FROM average of 10% of Revenue with integer format) for every transaction which started between 1st and 4th day.
--(cast, avg, JOIN, day, between, group by)
SELECT CompanyID, DeveloperID, 'Tax Revenue' = CAST(AVG(revenue)*0.1 AS INT)
FROM HeaderTransaction ht 
	JOIN DetailTransaction dt ON dt.TransactionID=ht.TransactionID
WHERE DAY(startdate) BETWEEN 1 AND 4
GROUP BY CompanyID, DeveloperID

--4. Display Developer Lastname (obtained FROM developer's last name), DeveloperGender, ProjectName, Budget (obtained FROM ProjectBudget), Total Budget (obtained FROM amount of ProjectBudget), and Developer Count For Specific Project (obtained FROM total of transaction that had been done by developer) for every project which had been developed by male developer and the project's name is "Swift Eagle". Then, combined with Developer Lastname (obtained FROM developer's last name), DeveloperGender, ProjectName, Budget (obtained FROM ProjectBudget), Total Budget (obtained FROM amount of ProjectBudget), and Developer Count For Specific Project (obtained FROM total of transaction that had been done by developer) for every project which had been developed by female developer and the project's name is "Eastern Windshield".
--(substring, charindex, reverse, sum, count, group by, union)
SELECT REVERSE(substring(
			REVERSE(developerName), 1, CHARINDEX(' ', REVERSE(developerName))
		)) AS 'Developer Lastname',
		ProjectBudget AS 'Budget',
		SUM(ProjectBudget) AS 'Total Budget',
		COUNT(dt.transactionID) AS 'Developer Count for Specific Project'
FROM Developer d 
	JOIN HeaderTransaction ht ON d.developerID = ht.DeveloperID
	JOIN DetailTransaction dt ON dt.TransactionID = ht.TransactionID
	JOIN Project p ON p.ProjectID = dt.ProjectID
WHERE developerGender LIKE 'male' AND ProjectName LIKE 'Swift Eagle'
GROUP BY developerName, p.ProjectBudget

UNION

select REVERSE(SUBSTRING(
			REVERSE(developerName), 1, CHARINDEX(' ', REVERSE(developerName))
		)) AS 'Developer Lastname',
		ProjectBudget AS 'Budget',
		SUM(ProjectBudget) AS 'Total Budget',
		COUNT(dt.transactionID) AS 'Developer Count for Specific Project'
FROM Developer d 
	JOIN HeaderTransaction ht ON d.developerID = ht.DeveloperID
	JOIN DetailTransaction dt ON dt.TransactionID = ht.TransactionID
	JOIN Project p ON p.ProjectID = dt.ProjectID
WHERE developerGender LIKE 'female' AND ProjectName LIKE 'eastern windshield'
GROUP BY developerName, p.ProjectBudget

--5. Display ProjectID, ProjectName (obtained FROM ProjectName in uppercase format), EndDate (obtained FROM EndDate in "Mon dd, yyyy" format) for every project which want to be built by the company which address started with "Nullam" and revenue is less than 600000000.
--(upper, convert, exists, like)
SELECT p.projectID,
		upper(p.projectName) AS ProjectName,
		convert(varchar, endDate, 107) AS EndDate
FROM Project p
	JOIN DetailTransaction dt ON dt.ProjectID=p.projectID
	JOIN HeaderTransaction ht ON ht.TransactionID = dt.TransactionID
	JOIN company c ON c.companyID = ht.CompanyID
WHERE EXIST(
	SELECT *
	FROM company 
		WHERE c.CompanyAddress LIKE 'Nullam%' 
	) AND Revenue<600000000

--6. Display DeveloperName, Revenue, Day of Year (obtained FROM day of year of StartDate), and Development Year (obtained FROM the difference between StartDate and EndDate and ended with the word "Year(s)") for every project which budget is more than the average of all budgets, Development Year is more than 0 and revenue is less than 500000000.
--(datename, dayofyear, convert ,datediff, year, alias subquery, avg)
SELECT DeveloperName,
		revenue,
		'day of year' = DATENAME(dayofyear,startDate),
		'development year' = CONVERT(VARCHAR,DATEDIFF(YEAR, startdate, enddate)) + ' Year(s)'
FROM Developer d 
	JOIN HeaderTransaction ht ON d.developerid = ht.developerid
	JOIN DetailTransaction dt ON ht.TransactionID = dt.TransactionID
	JOIN project p ON dt.ProjectID=p.projectid,
	(SELECT avgBudget = AVG(projectBudget)
		FROM Project
	) AS avgBudget
WHERE DATEDIFF(YEAR, startdate, enddate)>0 
		AND Revenue<500000000 
		AND projectBudget> avgBudget.avgBudget

--7. Create a view named "View Developer" to display DeveloperID, DeveloperName, and DeveloperAddress for every transaction which started between April and July.
--(create view, month, between)
GO
CREATE view [View Developer] AS
SELECT d.DeveloperId, d.DeveloperName, d.DeveloperAddress
FROM Developer d JOIN HeaderTransaction ht ON d.DeveloperID=ht.DeveloperID
WHERE MONTH(startdate) BETWEEN 4 AND 7

select * FROM [View Developer]

--8. Create a view named "Revenue per Month" to display DeveloperName, DeveloperGender, and Revenue per Month (obtained by adding "Rp." in front of amount of Revenue that divided by 12) for every transaction which ended in 2015 and developer's address is in "Colonial Street".
--(create view, cast, sum, year, group by)
CREATE view [Revenue per Month] AS
SELECT d.DeveloperName, 
		d.DeveloperGender,
		'Revenue per Month' = 'Rp. ' + CAST(SUM(Revenue)/12 AS VARCHAR)
FROM Developer d 
		JOIN HeaderTransaction ht ON d.DeveloperID=ht.DeveloperID
		JOIN DetailTransaction dt ON ht.TransactionID=dt.TransactionID
		WHERE YEAR(EndDate) = 2015 and d.DeveloperAddress LIKE 'Colonial Street'
GROUP BY d.DeveloperName, d.DeveloperGender

--9. Add a column named "DeveloperEmail" ON Developer table with varchar(20) data type and add a constraint to check that the column must be between 5 and 30 characters. 
--(alter table, add, add constraint, len, between)
ALTER TABLE Developer
ADD DeveloperEmail VARCHAR(20)
--BEGIN TRAN
ALTER TABLE Developer
ADD CONSTRAINT chkemail CHECK(DeveloperEmail BETWEEN 5 AND 30)

--10. Remove data on Developer table for every transaction which revenue is less than 200000000 and the transaction ended in 2015. 
--(delete, year)
SELECT * FROM Developer

DELETE FROM developer 
FROM developer d 
	JOIN HeaderTransaction ht ON d.developerid=ht.DeveloperID
	JOIN DetailTransaction dt ON ht.TransactionID=dt.TransactionID
WHERE Revenue<200000000 AND YEAR(EndDate) = 2015