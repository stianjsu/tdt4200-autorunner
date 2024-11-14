## How to:

1. Import submissions from blackboard
2. Run unzip_and_sort.py
3. make all
4. make autocorrect


## how it works:
- Submissions in this format: ./answers/username/{submissionstuff} after running unzip_and_sort.py
- Looks through each folder in ./answers and gets username
  - Finds a .cu file, compiles, runs and compares with reference data
  - Generates a report in that students folder
  - exports results into a result.csv
- If a student already has a report, {username}.res file, it is skipped. Run make clean_autocorrect to delete all reports.