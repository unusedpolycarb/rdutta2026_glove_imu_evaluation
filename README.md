# rdutta2026_glove_imu_evaluation
Supplemental code, data, figures, and tables presented for the reproducibility of the results in the 2026 paper titled "Evaluation of a Glove-Mounted IMU Wearable Device for Pitch Count Estimation Using Frequency-Domain Features". 

## Runtime Requirements:

Below are specifications of the hardware and software that was used to complete these analyses. 

### Software
- MATLAB 2025b (MATLAB Signal Processing Toolbox)
- Python 3.13.12
- R 4.5.2
- RStudio 2026.01.0 (Build 392)

### Python Packages
- NumPy 2.4.2
- pandas 3.0.0
- scikit-learn 1.8.0
- imbalanced-learn 0.14.1
- SciPy 1.17.0
- Matplotlib 3.10.8
- Seaborn 0.13.2

### R Packages:
No additional R packages are explicitly identified in the manuscript. The statistical analyses can be implemented using base R.

### Hardware Specifications
- **CPU:** AMD Ryzen AI 7 PRO 350 (8 cores, 16 threads)
- **RAM:** 28 GB
- **GPU:** AMD Radeon 860M (Integrated Graphics)

These are not the minimum requirements.

## Execution Order
Please note that to re-run these analyses properly, some of the downstream code has dependencies on data upstream of it. That is, to run everything in order, please run the table{X} down to table{X+1}, and so on, to ensure that all dependencies are satisfied.
