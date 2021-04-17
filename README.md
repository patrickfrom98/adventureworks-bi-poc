# A Modern Proof-Of-Concept Business Intelligence Solution For Organisations Using SQL Technologies

This repository contains the codebase for my final year project at the University of Huddersfield. My product idea was to develop a SQL-based business intelligence solution and to let the ecosystem run in real-time for a number of months in order to display the benefits of modern data analytics to orgranisations who might be looking to improve their BI capabilities. Additionally, this project explores the different approach to modern day BI and discusses the difficulties in implementing the IT infrastructure necessary to run ETL's.

## Database
This folder holds all of the SQL deployments to the database along with their rollbacks. The internal folder structure organises the deployments in the form date_task_description. Eg. 20210321_Create_Database

## Jobs
This folder holds all the code needed for each job step within each SQL Server Agent job. The internal folder structure organises the code by ETL process name

## Reports
This folder holds all the code for the Power BI reports that visualises the data for the management and leadership teams. The internal folder structure organises the reports by report name.

## Additional Information
This project uses the AdventureWorks SQL Server 2019 OLTP backup file as its main source of data. A fictional client brief was prepared in preparation for this project to help demonstrate the software development lifecycle more realistically.

If you would like to read my dissertation or know more about this project, please get in contact!
