#!/bin/bash

# Find all student directories
student_dirs=$(find ./answers -maxdepth 1 -mindepth 1 -type d)

for student_dir in $student_dirs; do
    echo "Checking directory: $student_dir"
    
    # Find all zip files in the student directory
    zip_files=$(find "$student_dir" -maxdepth 1 -name "*.zip" -type f)
    
    for zip_file in $zip_files; do
        echo ">>>> Found zip file: $zip_file"
        
        # Unzip the file into the same directory
        unzip -o "$zip_file" -d "$student_dir"
        
        # Check if unzip was successful
        if [ $? -eq 0 ]; then
            echo ">>>> Successfully unzipped $zip_file"
            # Remove the zip file
            rm "$zip_file"
            echo ">>>> Deleted $zip_file"
        else
            echo ">>>> [ERROR] error unzipping $zip_file"
        fi
    done
done

echo "Finished processing all directories"