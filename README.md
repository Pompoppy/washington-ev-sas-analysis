
# Washington State Electric Vehicle Data Analysis (SAS)

Course project for ST 445 (SAS Programming), NC State University, Fall 2026.

## Overview
Data management and reporting pipeline for 143,964 Washington State electric
vehicle registration records.

**Phase 1 – Data Management (`FP01DinhD.sas`)**
- Reads three raw files: comma/tab delimited, fixed-column multi-line, and a
  malformed export with 1,750 grouped fields per line (restructured with arrays)
- Merges with a Microsoft Access lookup database and Sashelp.ZipCode
- Produces 4 data sets matching the client's metadata

**Phase 2 – Reporting (`FP02DinhD.sas`)**
- 17-output PDF report built with PROC FREQ, MEANS, UNIVARIATE, SGPLOT, and REPORT
- Color-coded PROC REPORT tables driven by custom formats

## Data
Source data provided by the course instructor:
https://github.com/jwduggins/WashingtonStateVehicleProject

## Tools
SAS 9.4
