## How to:

1. Import submissions from blackboard
2. unzip all submissions into ./bb_export
3. Run sort_bb_export_into_folders
   1. Will sort all submissions with this format: ./answers/{username}/submission
4. run unzip_student_files.sh
   1. Will unzip all submissions that are zipped. 
5. make all
6. make autocorrect


## how it works:
- Assume submissions in this format: ./answers/username/{submissionstuff}
- Looks through each folder in ./answers and gets username
  - Finds a .cu file, compiles, runs and compares with reference data
  - Generates a report in that students folder
  - exports results into a result.csv
- If a student already has a report, {username}.res file, it is skipped. Run make clean_autocorrect to delete all reports.