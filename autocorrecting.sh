#! /usr/bin/env bash

# Counter for correct solutions
correct_count=0
total_count=0

# Create sequential reference data if it doesn't exist
if [ ! -d "data_sequential" ]; then
    echo "Generating sequential reference data..."
    mkdir -p data_sequential
    ./sequential
    cp -r ./data/* ./data_sequential/
    rm -rf ./data/*
fi

csv_file="results.csv"
if [ ! -f "$csv_file" ]; then
    echo "student_username,status,reason,compares_failed" > "$csv_file"
fi

# Find all student directories
student_dirs=$(find ./answers -maxdepth 1 -mindepth 1 -type d)

# Process each student submission
for student_dir in $student_dirs; do
    username=$(basename "$student_dir")
    echo "Processing submission for $username..."
    total_count=$((total_count + 1))
    
    # Initialize result file
    result_file_name="${username}.res"
    result_file="$student_dir/$result_file_name"

    # Continue if student already has been processed
    if [ -e "$result_file" ]; then
        echo "  Student already has a result file"
        continue
    fi

    echo "============================================" > "$result_file"
    echo "EVALUATION RESULTS FOR: $username" >> "$result_file"
    echo "STATUS: PROCESSING" >> "$result_file"
    echo "============================================" >> "$result_file"
    echo "" >> "$result_file"
    
    # Find the CUDA source file
    cuda_file=$(find "$student_dir" -maxdepth 5 -name "*.cu" -type f | head -n 1)
    
    if [ -z "$cuda_file" ]; then
        sed -i "3s/.*/STATUS: [FAILED] - No CUDA source file found/" "$result_file"
        echo "[ERROR] No CUDA source file found" >> "$result_file"
        continue
    fi
    
    # Create data directory
    mkdir -p "$student_dir/data"
    
    # Compile the CUDA program
    echo "[INFO] Compiling submission..." >> "$result_file"
    nvcc "$cuda_file" -w -O2 -fmad=false -o "$student_dir/wave_2d" 2>> "$result_file"
    
    if [ $? -ne 0 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - Compilation error/" "$result_file"
        echo "[ERROR] Compilation failed" >> "$result_file"
        echo "$username,FAILED,compilation_failed,0" >> "$csv_file"
        continue
    fi
    
    # Run the program
    echo "[INFO] Running program..." >> "$result_file"
    cd "$student_dir"
    ./wave_2d 2>> "$result_file_name"
    run_status=$?
    cd - > /dev/null
    
    if [ $run_status -ne 0 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - Runtime error/" "$result_file"
        echo "[ERROR] Program execution failed" >> "$result_file"
        echo "$username,FAILED,runtime_error,0" >> "$csv_file"
        continue
    fi
    
    # Compare results
    echo "[INFO] Comparing results..." >> "$result_file"
    differences_found=0
    last_wrong_file=""
    total_files=0
    total_error=0
    
    for ref_file in ./data_sequential/*.dat; do
        filename=$(basename "$ref_file")
        student_file="$student_dir/data/$filename"
        
        if [ ! -f "$student_file" ]; then
            echo "[ERROR] Missing output file: $filename" >> "$result_file"
            echo "$username,FAILED,missing_output_files,0" >> "$csv_file"
            differences_found=1
            break
        fi
        total_files=$((total_files + 1))
        
        if ! diff -q "$ref_file" "$student_file" >/dev/null; then
            if [ $differences_found == 0 ]; then
              echo "[ERROR] Differences found in $filename" >> "$result_file"
              differences_found=1
              total_error=1
            else
              total_error=$((total_error + 1))
              last_wrong_file="$filename"
            fi
        fi
    done
    
    if [ $differences_found -eq 0 ]; then
        sed -i "3s/.*/STATUS: [PASSED] - All tests successful/" "$result_file"
        echo "[SUCCESS] All answers correct!" >> "$result_file"
        echo "$username,PASSED,all_correct,0" >> "$csv_file"
        correct_count=$((correct_count + 1))
    else
        sed -i "3s/.*/STATUS: [FAILED] - Output mismatch, ($total_error\/$total_files failed)/" "$result_file"
        echo "[ERROR] Some differences found in the output" >> "$result_file"
        echo "[ERROR] Last wrong file was  $last_wrong_file" >> "$result_file"
        echo "$username,FAILED,output_mismatch,$total_error" >> "$csv_file"
    fi
    
    # Clean up data directory to save space
    rm -rf "$student_dir/data"
    rm -f "$student_dir/wave_2d"
done

# Create summary report
echo "============================================" > grading-summary.res
echo "EVALUATION SUMMARY" >> grading-summary.res
echo "============================================" >> grading-summary.res
echo "Total submissions: $total_count" >> grading-summary.res
echo "Correct solutions: $correct_count" >> grading-summary.res
echo "Success rate: $(( (correct_count * 100) / total_count ))%" >> grading-summary.res
echo "" >> grading-summary.res
echo "Detailed results can be found in each student's" >> grading-summary.res
echo "directory as {username}.res" >> grading-summary.res