#!/usr/bin/env python3

# ---------------------------------------------
# Python script building a sliding window 
# feature vector table from the windowed Fst
# calculated by VCFtools:
# - Groups 11 subwindows per window
# - Instead of consecutive windows only, 
#   windows overlap in a sliding window 
#   fashion. This is implemented by having a 
#   window step which is a multiple of a 
#   subwindow size. As such, a new overlapping
#   window starts every n subwindows.
# - Assigns the S (selected) or (non-selected)
#   label to all windows
# - Normalizes Fst values per window
# ---------------------------------------------

# ---------------------------------------------
# 1. Import required libraries:
# ---------------------------------------------
import argparse         # Command-line arguments
import numpy as np      # Numerical operations with arrays
import pandas as pd     # Handling dataframes
import ast              # Safely parsing strings and lists

# ---------------------------------------------
# 2. Parsing command line arguments:
# ---------------------------------------------
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fst", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--subwindow_size", type=int, required=True)
    parser.add_argument("--selected", required=True,
                        help="Selected sites, e.g. '[10000,20000]'")
    parser.add_argument("--subwindow_overlap", type=int, required=True,
                        help="Overlap between windows (number of subwindows overlapping). E.g., 3 means the third subwindow of the next window is the first subwindow.")
    return parser.parse_args()

def main():
    # Call parse_args function to get the command line arguments:
    args = parse_args()
    # Process selected sites:
    selected_sites = ast.literal_eval(args.selected)    # Turn the selected sites from a string representation of a list into an actual list
    selected_sites = sorted(selected_sites)             # Sort selected sites in acending order

    # ---------------------------------------------
    # 3. Load and clean Fst data:
    # ---------------------------------------------
    df = pd.read_csv(args.fst, sep="\t")
    # Clean Fst values by replacing -nan and nan with 0
    df["WEIGHTED_FST"].replace(["nan", "-nan"], 0, inplace=True)
    # Sort by position to ensure correct ordering
    df.sort_values(by="BIN_START", inplace=True)

    # ---------------------------------------------
    # 4. Create the feature vector dataframe
    #    by grouping 11 subwindows into a window
    #    and labeling each window as S or N:
    # ---------------------------------------------
    # Extract subwindow size from arguments and calculate window size:
    subwindow_size = args.subwindow_size
    window_size = subwindow_size * 11
    # Extract window overlap from arguments, i.e. number of subwindows without overlap
    overlap = args.subwindow_overlap

    rows = []       # Initialize temporary storage for the data of each window
    # Loop over all subwindows from 1st to last-11 subwindows, with a step of "overlap". This results in a new overlapping window starting every "overlap" subwindows:
    for i in range(0, len(df) - 11 + 1, overlap):
        # Get the relevant subset of subwindows:
        subdf = df.iloc[i:i + 11]

        # Extract Fst values for all subwindows in this window:
        fst_vals = list(subdf["WEIGHTED_FST"].values)

        # Pad last window with 0, if it contains less than 11 subwindows:
        if len(fst_vals) < 11:
            fst_vals += [0] * (11 - len(fst_vals))

        # Assign S/N label depending on selected_site in range:
        start = subdf.iloc[0]["BIN_START"]          # Starting position of window
        end = start + window_size                   # End position of window
        label = "S" if any(start <= pos < end for pos in selected_sites) else "N"

        # Append a new window to the list:
        rows.append([start] + fst_vals + [label])   # Creates a list of lists

    # Build the complete dataframe:
    colnames = ["window_start"] + [f"Fst_subwin{i}" for i in range(1, 12)] + ["label"]
    table = pd.DataFrame(rows, columns=colnames)

    # ---------------------------------------------
    # 5. Normalize subwindow Fst across the window:
    # ---------------------------------------------
    def normalize(vals):
        vals = np.array(vals, dtype=float)  # Convert input values to a numpy array of floats
        total_sum = np.sum(vals)            # Calculates sum of subwindows
        if total_sum == 0:                  # Edge case division by zero
            return np.zeros_like(vals)      # Create array of zeros
        return vals / total_sum             # Normalize the subwindows by the sum across window

    # Create a list of the subwindow column names to extract them from the dataframe for normalization:
    fst_cols = [f"Fst_subwin{i}" for i in range(1, 12)]
    # Extract the subwindow values from the dataframe only, then normalize along each row (window).
    table[fst_cols] = table[fst_cols].apply(lambda row: normalize(row), axis=1, result_type="expand")   # result_type="expand" turns the array of values back into separate columns of a  dataframe.

    # ---------------------------------------------
    # 6. Save table to csv:
    # ---------------------------------------------
    table.to_csv(args.output, index=False)

if __name__ == "__main__":
    main()