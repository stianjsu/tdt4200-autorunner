#! /usr/bin/env bash

# Counter for correct solutions
correct_count=0
total_count=0

# Create sequential reference data if it doesn't exist
if [ ! -d "data_sequential" ] || [ -z "$( ls -A './data_sequential' )" ]; then
    echo "Generating sequential reference data..."
    mkdir -p data_sequential
    ./sequential
    cp -r ./data/* ./data_sequential/
    rm -rf ./data/*
fi

csv_file="results.csv"
if [ ! -f "$csv_file" ]; then
    echo "student_username,status,reason,running_time(s),compares_failed" > "$csv_file"
fi

# Find all student directories
student_dirs=$(find ./answers -maxdepth 1 -mindepth 1 -type d | sort)

# Process each student submission
for student_dir in $student_dirs; do
    username=$(basename "$student_dir")
    echo "Processing submission for $username..."
    total_count=$((total_count + 1))
    
    # Initialize result file
    result_file_name="${username}.res"
    prog_output_file_name="${username}-out.res"
    result_file="$student_dir/$result_file_name"

    # Continue if student already has been processed
    if [ -e "$result_file" ]; then
        echo "  Student already has a result file"
        continue
    fi

    echo "============================================" > "$result_file"
    echo "EVALUATION RESULTS FOR: $username" >> "$result_file"
    echo "STATUS: PROCESSING" >> "$result_file"
    echo "RUNTIME: ..." >> "$result_file"
    echo "============================================" >> "$result_file"
    echo "" >> "$result_file"
    
    # Find the CUDA source file
    cuda_files=($(find "$student_dir" -maxdepth 5 -name "*.cu" -type f))

    # Check if no files found
    if [ ${#cuda_files[@]} -eq 0 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - No CUDA source file found/" "$result_file"
        echo "[ERROR] No CUDA source file found" >> "$result_file"
        continue
    fi

    # Warn if multiple .cu files found
    if [ ${#cuda_files[@]} -gt 1 ]; then
        echo "[WARNING] Multiple CUDA source files found. Using: ${cuda_files[0]}" >> "$result_file"
        echo "      [WARNING] Multiple CUDA source files found. Using: ${cuda_files[0]}"
    fi

    cuda_file="${cuda_files[0]}"

    # Create data directory
    mkdir -p "$student_dir/data"
    
    # Compile the CUDA program
    echo "[INFO] Compiling submission... ($cuda_file)" >> "$result_file"
    nvcc "$cuda_file" -w -O2 -fmad=false -o "$student_dir/wave_2d" 2>> "$result_file"
    
    if [ $? -ne 0 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - Compilation error/" "$result_file"
        echo "[ERROR] Compilation failed" >> "$result_file"
        echo "$username,FAILED,compilation_failed,," >> "$csv_file"
        echo "      Compilation failed"      
        continue
    fi
    
    # Run the program
    echo "[INFO] Running program..." >> "$result_file"
    echo "      Running program..."
    cd "$student_dir"
    start_time=`date +%s.%4N`

    ######## handle ctrl+c while executing
    ./wave_2d 2>> "$result_file_name" 1>> "$prog_output_file_name" &
        pid=$!

        # Wait for up to 120 seconds, but allow ctrl+c
        wait_timeout=120
        (
            sleep $wait_timeout
            kill $pid 2>/dev/null
        ) &
        timer_pid=$!

        # Wait for the main process
        wait $pid
        run_status=$?

        # Clean up timer
        kill $timer_pid 2>/dev/null
        wait $timer_pid 2>/dev/null
    ################

    end_time=`date +%s.%4N`
    cd - > /dev/null

    runtime=$(echo "$end_time - $start_time" | bc)
    string_runtime=$(printf "%.3f" $runtime)
    timed_out=0
    
    if [ $run_status -eq 143 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - Exceeded 60-second time limit/" "$result_file"
        echo "[ERROR] Program execution timed out" >> "$result_file"
        echo "      Timout"
        timed_out=1
        #echo "$username,FAILED,timeout,$string_runtime,0" >> "$csv_file"
    elif [ $run_status -ne 0 ]; then
        sed -i "3s/.*/STATUS: [FAILED] - Runtime error/" "$result_file"
        echo "[ERROR] Program execution failed" >> "$result_file"
        echo "$username,FAILED,runtime_error,$string_runtime," >> "$csv_file"
        continue
    fi

    echo "[INFO] Execution time was $string_runtime." >> "$result_file"
    sed -i "4s/.*/RUNTIME: $string_runtime/" "$result_file"
    
    # Compare results
    echo "[INFO] Comparing results..." >> "$result_file"
    echo "      Comparing results..."
    differences_found=0
    last_wrong_file=""
    total_files=0
    total_error=0
    fail_reason=""
    
    for ref_file in ./data_sequential/*.dat; do
        filename=$(basename "$ref_file")
        student_file="$student_dir/data/$filename"
        
        if [ ! -f "$student_file" ]; then
            echo "[ERROR] Missing output file: $filename" >> "$result_file"
            fail_reason="missing_output_files"
            differences_found=1
            break
        fi
        total_files=$((total_files + 1))
        
        if ! diff -q "$ref_file" "$student_file" >/dev/null; then
            if [ $differences_found == 0 ]; then
              echo "[ERROR] Differences found in $filename" >> "$result_file"
              fail_reason="output_mismatch"
              differences_found=1
              total_error=1
            else
              total_error=$((total_error + 1))
              last_wrong_file="$filename"
            fi
        fi
    done
    
    if [ $timed_out -eq 1 ]; then
        echo "[ERROR] Process timed out, tried to compare result" >> "$result_file"
        echo "[ERROR] Last wrong file was  $last_wrong_file" >> "$result_file"
        echo "$username,FAILED,timeout,$string_runtime,$total_error" >> "$csv_file"
    elif [ $differences_found -eq 0 ]; then
        sed -i "3s/.*/STATUS: [PASSED] - All tests successful/" "$result_file"
        echo "[SUCCESS] All answers correct!" >> "$result_file"
        echo "$username,PASSED,all_correct,$string_runtime,0" >> "$csv_file"
        correct_count=$((correct_count + 1))
    else
        sed -i "3s/.*/STATUS: [FAILED] - Output mismatch, ($total_error\/$total_files failed)/" "$result_file"
        echo "[ERROR] Some differences found in the output" >> "$result_file"
        echo "[ERROR] Last wrong file was  $last_wrong_file" >> "$result_file"
        echo "$username,FAILED,$fail_reason,$string_runtime,$total_error" >> "$csv_file"
    fi
    
    # Clean up data directory to save space
    rm -rf "$student_dir/data"
    rm -f "$student_dir/wave_2d"
done

summary_file=./answers/grading-summary.res

# Create summary report
echo "============================================" > "$summary_file"
echo "EVALUATION SUMMARY" >> "$summary_file"
echo "============================================" >> "$summary_file"
echo "Total submissions: $total_count" >> "$summary_file"
echo "Correct solutions: $correct_count" >> "$summary_file"
echo "Success rate: $(( (correct_count * 100) / total_count ))%" >> "$summary_file"
echo "" >> "$summary_file"
echo "Detailed results can be found in each student's" >> "$summary_file"
echo "directory as {username}.res" >> "$summary_file"

cp results.csv ./answers/results.csv