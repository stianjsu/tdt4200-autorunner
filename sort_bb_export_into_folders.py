import os
from pathlib import Path
import shutil

for filename in os.listdir('./bb_export'):
    # besvarelser på formen "Exercise 6_username_navnpåfila_dato.zip/.cu/.txt/etc"
    username = filename.split(" ", 1)[1].split("_")[1]
    path = f"./answers/{username}"
    if not os.path.exists(path):
      os.makedirs(path)

    pathen = Path(path)
    shutil.copy("./bb_export/" + filename, pathen / filename.split(" ", 1)[1].replace(" ", ""))
    
