import os
import zipfile
import shutil
from pathlib import Path

def clean_macos_files(directory):
    """Remove macOS-specific files and directories."""
    # Remove __MACOSX directories
    macosx_dirs = Path(directory).glob("**/__MACOSX")
    for macosx_dir in macosx_dirs:
        if macosx_dir.is_dir():
            shutil.rmtree(macosx_dir)

    # Remove .DS_Store files
    ds_store_files = Path(directory).glob("**/.DS_Store")
    for ds_file in ds_store_files:
        if ds_file.is_file():
            ds_file.unlink()

    # Remove ._ files
    dot_underscore_files = Path(directory).glob("**/._*")
    for dot_file in dot_underscore_files:
        if dot_file.is_file():
            dot_file.unlink()


def clean_dirs():
    bb_export_exists = Path("./bb_export").exists()
    answers_exists = Path("./answers").exists()

    if (bb_export_exists and len(os.listdir("./bb_export")) > 0) or (
        answers_exists and len(os.listdir("answers")) > 0
    ):
        delete_prev_data = input(
            "There are already content in ./bb_export or ./answers. \n"
            "Do you want to delete them and extract new files (Y/n)? "
        ).strip()
        if delete_prev_data not in "yY":
            print("[INFO] exiting")
            exit()

    dir_path = Path("./bb_export")
    if dir_path.exists():
        shutil.rmtree(dir_path)
        print(f"[INFO] Deleted directory: ./bb_export")

    dir_path = Path("./answers")
    if dir_path.exists():
        shutil.rmtree(dir_path)
        print(f"[INFO] Deleted directory: ./answers")


def extract_gradebook_into_answers_folder():
    bb_export_name = (
        input("Write identifiable name of blackboard export: >>>").strip()
        or "gradebook"
    )
    bb_export = list(Path("./").glob(bb_export_name + "*.zip"))

    if len(bb_export) != 1 or not bb_export[0].is_file():
        print("[ERROR] Could not identify gradebook to unzip")
        return

    with zipfile.ZipFile(bb_export[0]) as gradebook_zip:
        print("[INFO] unzipping gradebook into ./bb_export")
        os.mkdir("./bb_export")
        gradebook_zip.extractall("./bb_export")

    for filename in os.listdir("./bb_export"):
        # besvarelser på formen "Exercise 6_username_navnpåfila_dato.zip/.cu/.txt/etc"
        username = filename.split(" ", 1)[1].split("_")[1]
        path = f"./answers/{username}"
        if not os.path.exists(path):
            os.makedirs(path)

        pathen = Path(path)
        shutil.copy(
            "./bb_export/" + filename,
            pathen / filename.split(" ", 1)[1].replace(" ", ""),
        )
    print("[INFO] unzipped gradebook and sorted by student into ./answers")
    
    
def unzip_student_submisssions():
    # Find all student directories
    answers_dir = Path("./answers")
    student_dirs = [d for d in answers_dir.iterdir() if d.is_dir()]

    for student_dir in student_dirs:
        print(f"Checking directory: {student_dir}")

        # Find all zip files in the student directory
        zip_files = list(student_dir.glob("*.zip"))

        for zip_file in zip_files:
            print(f">>>> Found zip file: {zip_file}")

            try:
                # Unzip the file into the same directory
                with zipfile.ZipFile(zip_file, "r") as zip_ref:
                    zip_ref.extractall(student_dir)
                print(f">>>> Successfully unzipped {zip_file}")

                # Clean up macOS files
                clean_macos_files(student_dir)

                # Remove the zip file
                zip_file.unlink()
                print(f">>>> Deleted {zip_file}")

            except Exception as e:
                print(f">>>> [ERROR] error unzipping {zip_file}: {str(e)}")
                
        flatten_directory(student_dir)
        print(">>>> [INFO] flattened dir")
        
    print("Finished processing all directories")
    
    
def flatten_directory(directory: Path) -> None:
    """
    Flatten a directory by moving all files to the root level,
    handling duplicates with counters.
    
    Args:
        directory (Path): Path to the directory to flatten
    """
    seen_files = set()
    
    # First collect all files to move
    to_move = []
    for root, _, files in os.walk(directory):
        if Path(root) == directory:  # Skip root directory
            seen_files.update(files)
            continue
            
        for file in files:
            current_path = Path(root) / file
            to_move.append((current_path, file))
    
    # Move files with duplicate handling
    for current_path, filename in to_move:
        new_path = directory / filename
        
        # Handle duplicates with counter
        if filename in seen_files:
            name = Path(filename).stem
            suffix = Path(filename).suffix
            counter = 1
            
            while f"{name}_{counter}{suffix}" in seen_files:
                counter += 1
                
            new_filename = f"{name}_{counter}{suffix}"
            new_path = directory / new_filename
            seen_files.add(new_filename)
            print(f"[WARNING] duplicate file found {new_path}\n\n")
        else:
            seen_files.add(filename)
        
        shutil.move(str(current_path), str(new_path))
    
    # Clean up empty directories
    for root, dirs, _ in os.walk(directory, topdown=False):
        for dir in dirs:
            try:
                os.rmdir(os.path.join(root, dir))
            except OSError:
                # Directory not empty, skip it
                pass

def main():
    # Remove existing folders
    clean_dirs()
    # extract gradebook and sort submissions into ./answers/{username}/..submission...
    extract_gradebook_into_answers_folder()
    # unzip ./answers/{username}/submission.zip if student delivered a zip file
    unzip_student_submisssions()
    

if __name__ == "__main__":
    main()
