#!/usr/bin/env python3
"""
sku-analysis-get-price-and-info.py
=============
By Luis Feliz
=============
Fetches Azure Virtual Machine retail pricing from the Azure Retail Prices API,
merges regional data into a single pivot table, enriches each SKU with parsed
hardware details (vCPUs, memory, features, etc.), and outputs a final CSV report.

Workflow:
  1. pull_data_from_api() – queries the API for each target region and saves per-region CSVs.
  2. merge_data()         – combines all regional CSVs into a pivoted "combined.csv".
  3. add_sku_details()    – parses SKU names and appends hardware metadata to produce
                            the final "sku-price-report-by-region.csv".
"""

import csv
import requests
import json
import time

import glob
import os
import pandas as pd

import re

# from tabulate import tabulate  # optional – uncomment for pretty-printed console tables

# ---------------------------------------------------------------------------
# Load memory and processor lookups from series-info-scraped-from-docs.csv
# ---------------------------------------------------------------------------
_MEMORY_LOOKUP: dict[str, str] = {}
_MEMORY_LOOKUP2: dict[str, str] = {}
_MEMORY_LOOKUP3: dict[str, str] = {}
_PROCESSOR_LOOKUP: dict[str, str] = {}
_VCPU_LOOKUP: dict[str, int] = {}
_series_info_path = os.path.join(os.path.dirname(__file__) or ".", "series-info-scraped-from-docs.csv")
if os.path.isfile(_series_info_path):
    _df_series = pd.read_csv(_series_info_path, usecols=["SKU", "Memory (GB)", "Processor", "Memory (GiB)", "vCPUs (Qty.)"])
    _df_series["SKU"] = _df_series["SKU"].str.strip()
    _mem = _df_series.dropna(subset=["SKU", "Memory (GB)"])
    _MEMORY_LOOKUP = dict(zip(_mem["SKU"], _mem["Memory (GB)"]))

    _mem2 = _df_series.dropna(subset=["SKU", "Memory (GiB)"])
    _MEMORY_LOOKUP2 = dict(zip(_mem2["SKU"], _mem2["Memory (GiB)"]))

    # _mem3 = _df_series.dropna(subset=["SKU", "Memory: GiB"])
    # _MEMORY_LOOKUP3 = dict(zip(_mem3["SKU"], _mem3["Memory: GiB"]))

    _proc = _df_series.dropna(subset=["SKU", "Processor"])
    _PROCESSOR_LOOKUP = dict(zip(_proc["SKU"], _proc["Processor"].str.strip()))
    _vcpu = _df_series.dropna(subset=["SKU", "vCPUs (Qty.)"])
    _VCPU_LOOKUP = dict(zip(_vcpu["SKU"], pd.to_numeric(_vcpu["vCPUs (Qty.)"], errors="coerce")))
    del _df_series, _mem, _mem2,  _proc, _vcpu


def parse_sku(sku: str, product_name: str, meter: str) -> dict:
    """
    Parse an Azure VM SKU name and return enriched metadata.

    Extracts vCPU count, estimated memory, version, feature flags, meter type,
    OS type, CPU vendor, and retirement/burstable notes from the SKU string,
    product name, and meter name.

    Returns dict with keys: vCPUs, Memory_GB, Memory_Ratio, Version, Features, MeterType,
    OSType, Notes, CPUType.
    """
    result = {"vCPUs": "", "Memory_GB": "", "Version": "", "Features": "", "MeterType": "", "OSType": "", "Notes": "", "CPUType": "", "Memory_Ratio": ""}

    # ---------------------------------------------------------------------------
    # Memory-per-core ratio (GB) by VM family letter.
    # These are approximate base ratios used to estimate total memory from the
    # vCPU count.  Constrained-core and modifier-letter variants (m/l/t/x) are
    # handled with multipliers further below.
    # ---------------------------------------------------------------------------
    FAMILY_MEM_RATIO: dict[str, float] = {
        "A": 2.0,    # General purpose (legacy)
        "B": 4.0,    # Burstable
        "D": 4.0,    # General purpose
        "E": 8.0,    # Memory optimised
        "F": 2.0,    # Compute optimised
        "G": 8.0,    # Storage / memory (legacy)
        "H": 8.0,    # HPC
        "L": 8.0,    # Storage optimised
        "M": 16.0,   # Very-large memory
        "N": 4.0,    # GPU – memory varies widely; rough default
        "P": 4.0,    # ARM-based (Ampere)
    }

    # Legacy A-series VMs have fixed (non-formula) core/memory mappings
    LEGACY_A_SIZES: dict[str, tuple[int, float]] = {
        "A0": (1, 0.75), "A1": (1, 1.75), "A2": (2, 3.5), "A3": (4, 7),
        "A4": (8, 14),   "A5": (2, 14),    "A6": (4, 28),  "A7": (8, 56),
        "A8": (8, 56),   "A9": (16, 112),  "A10": (8, 56), "A11": (16, 112),
    }

    # Feature-letter descriptions – each lowercase letter after the core count
    # in a modern SKU name indicates a hardware or capability trait.
    FEATURE_MAP: dict[str, str] = {
        "a": "AMD processor",
        "b": "Block storage performance",
        "c": "Confidential",
        "d": "Local temp disk",
        "i": "Isolated size",
        "l": "Low memory",
        "m": "Memory intensive",
        "p": "ARM (Ampere) processor",
        "s": "Premium storage capable",
        "t": "Tiny memory",
        "x": "Extra-large memory",
    }





    # Strip tier prefix (Standard_ or Basic_) to simplify regex matching
    name = sku

    # --- Determine the SKU version suffix (e.g. "v5", "v2_Promo") ---
    if (sku.startswith("NC")):
        version = sku[-2:]  # NC-series encodes version in last 2 chars
    elif(sku.endswith("Promo") and sku.find("_v")>0):
        version = sku[-8:]  # Promotional SKUs keep the full "_vN_Promo" suffix
    elif(sku.endswith("_v32")):
        version = ""        # Special case – not a real version tag
    elif(sku.find("_v") > 0):
        version = sku[-2:]  # Standard version suffix (e.g. "v5")
    else:
        version = ""        # No version suffix present
    result["Version"] = f"{version}"

    for prefix in ("Standard_", "Basic_"):
        if name.startswith(prefix):
            name = name[len(prefix):]
            break



    # ---- Special / accelerator SKUs (NV*ads_V710, NC*_RTXPRO, PB*) ----
    # Attempt to extract cores/features even from non-standard naming.

    # Main regex for modern Azure VM SKU names.
    # Captures: Family, vCPUs, optional constrained cores, feature letters,
    # optional accelerator suffix, and optional version number.
    m = re.match(
        r"^([A-Z]{1,2})"           # 1: family (D, E, NC, NV, EC, HB …)
        r"(\d+)"                    # 2: vCPU count
        r"(?:-(\d+))?"             # 3: constrained vCPU count (optional)
        r"([a-z]*)"                # 4: feature letters (ads, ls, ms …)
        r"(?:_([a-zA-Z0-9]+))?"   # 5: accelerator or sub-variant (V710, A10, xl …)
        r"(?:_v?(\d+))?$",        # 6: version (v2, v5 …)
        name,
    )

    if not m:
        # Fallback: if the regex didn't match, try to extract at least a core count
        nums = re.findall(r"\d+", name)
        if nums:
            result["Version"] = f"{version}"
            result["vCPUs"] = int(nums[0])
    else:
        # Successful parse – extract all captured groups
        family = m.group(1)
        cores = int(m.group(2))
        constrained = int(m.group(3)) if m.group(3) else None  # e.g. E64-16s → 16 usable vCPUs
        feat_letters = m.group(4) or ""
        accel = m.group(5) or ""
        result["Version"] = f"{version}"

        # Use constrained core count if present; otherwise use advertised cores
        result["vCPUs"] = constrained if constrained else cores

        # Memory for the SKUs – look up from series-info CSV, fall back to ratio estimate
  
        # ---- Features ----
        # Translate each feature letter into a human-readable description.
        features: list[str] = []

        for ch in feat_letters:
            desc = FEATURE_MAP.get(ch)
            if desc and desc not in features:
                features.append(desc)

        # ---- CPU Type ----
        # Look up processor from series-info CSV, fall back to feature-letter heuristic.

        if "a" in feat_letters:
            result["CPUType"] = "AMD"
        elif "p" in feat_letters:
            result["CPUType"] = "ARM"
        elif "_HB" in sku or "_HX" in sku or "_NM" in sku:
            result["CPUType"] = "AMD"


        # ---- Accelerator info ----
        # Identify specific GPU/accelerator hardware from the suffix.
        if accel:
            # Known GPU accelerators
            if "A10" in accel:
                features.append("NVIDIA A10 GPU")
            elif "V710" in accel:
                features.append("AMD Radeon V710 GPU")
            elif "RTX" in accel:
                features.append("NVIDIA RTX PRO GPU")
            elif "H100" in accel.upper():
                features.append("NVIDIA H100 GPU")
            elif "H200" in accel.upper():
                features.append("NVIDIA H200 GPU")
            elif "A100" in accel.upper():
                features.append("NVIDIA A100 GPU")
            elif accel.lower() not in ("v1", "v2", "v3", "v4", "v5", "v6"):
                features.append(f"Accelerator: {accel}")

            result["Features"] = "; ".join(features)

    # Source Memory and CPU cores and Type from docs-scraped CSV lookup if available
    if "_Promo" in sku:
            base_sku = sku.replace("_Promo", "")
    else:
            base_sku = sku

    cores = _VCPU_LOOKUP.get(base_sku)
    if cores is not None:
            result["vCPUs"] = cores

    processor_str = _PROCESSOR_LOOKUP.get(base_sku)
    if processor_str is not None:
        result["CPUType"] = processor_str

    # First type of lookup
    memory_gb = _MEMORY_LOOKUP.get(base_sku)
    
    # Second type of lookup
    if memory_gb is None:
        #print ("using l2")
        memory_gb = _MEMORY_LOOKUP2.get(base_sku)
    
    # # Third type of lookup
    # if memory_gb is None:
    #     #print ("using l3")
    #     memory_gb = _MEMORY_LOOKUP3.get(base_sku)
    
    memory_gb = float(memory_gb.replace(",", "")) if isinstance(memory_gb, str) else memory_gb

    #print (f"Parsed SKU: {sku} → vCPUs: {result['vCPUs']}, Memory_GB: {memory_gb}, CPUType: {result['CPUType']}, Features: {result['Features']}")
    if memory_gb is not None :
        result["Memory_GB"] = memory_gb
        if cores is not None and cores > 0:
            result["Memory_Ratio"] = f"1:{int(memory_gb / cores)}" if cores else ""


    # ---- Meter Type ----
    # Classify the pricing tier from the meter name.
    if meter:
        if "Low Priority" in meter:
            result["MeterType"] = "Low Priority"
        elif "Spot" in meter:
            result["MeterType"] = "Spot"
        else:
            result["MeterType"] = "On Demand"

    # ---- OS Type ----
    # Derive the OS from the product name string.
    if product_name:
        if "Windows" in product_name:
            result["OSType"] = "Windows"
        elif "Linux" in product_name:
            result["OSType"] = "Linux"
        else:
            result["OSType"] = "Unspecified"

    # ---- Notes ----
    # Flag SKUs that are being retired or have special characteristics.
    notes: list[str] = []

    # Mark older generations and specific series scheduled for retirement
    if sku.endswith("_v2") or sku.endswith("_v2_Promo"):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_NP") or sku.startswith("Standard_HC"):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("NC") and sku.endswith("_v3") and not sku.endswith("T4_v3"):
        notes.append("Retiring-Avoid-Use")

    if sku.startswith("Standard_DS") and not ("_v" in sku):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_F") and not ("_v" in sku):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_G") and not ("_v" in sku):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_L") and not ("_v" in sku):
        notes.append("Retiring-Avoid-Use")


    if sku.startswith("Standard_G5") or sku.startswith("Standard_GS5"):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_E64i_v3") or sku.startswith("Standard_E64is_v3"):
        notes.append("Retiring-Avoid-Use")
    if sku.startswith("Standard_M192is_v2") or sku.startswith("Standard_M192ims_v2") or sku.startswith("Standard_M192ids_v2") or sku.startswith("Standard_M192idms_v2"):
        notes.append("Retiring-Avoid-Use")

    # Flag burstable B-series VMs (credit-based CPU model)
    if sku.startswith("Standard_B"):
        notes.append("Burstable")

    result["Notes"] = "; ".join(notes)




    # ---- Dedicated-host / type SKUs (e.g. "Dadsv5_Type1") – skip parsing ----
    
    if "Type" in sku or sku == "ARM_SKU_NAME_PLACEHOLDER":
        result["Notes"] = "Dedicated Host"

    # ---- Legacy A-series (A0-A11) without version suffix ----
    if re.match(r"^A\d+$", name):
        if name in LEGACY_A_SIZES:
            cores, mem = LEGACY_A_SIZES[name]
            result["vCPUs"] = cores
            result["Memory_GB"] = mem
            result["Notes"] = "Legacy A-series"

    # Everything else
    result["Version"] = f"{version}"
    

    return result

def build_pricing_table(json_data, table_data):
    """Append rows from a single API response page to the pricing table list."""
    for item in json_data['Items']:
        meter = item['meterName']
        table_data.append([item['armSkuName'], item['retailPrice'],  item['armRegionName'], meter, item['productName']])
        
def requests_get_with_retry(url, max_retries=5, initial_delay=1, **kwargs):
    """Perform a GET request with exponential backoff on failure."""
    delay = initial_delay
    for attempt in range(max_retries):
        try:
            response = requests.get(url, **kwargs)
            response.raise_for_status()
            return response
        except (requests.exceptions.RequestException) as e:
            if attempt == max_retries - 1:
                raise
            print(f"  Request failed ({e}), retrying in {delay}s...")
            time.sleep(delay)
            delay *= 2

def pull_data_from_api():
    """
    Query the Azure Retail Prices API for VM pricing in each target region.
    Handles pagination automatically and writes one CSV per region.
    """

    # Target regions to fetch pricing for
    regions = ("eastus2","eastus","centralus")

    for region in regions:

        # For every region, build the OData filter and make the initial request
        print ("Downloading price data for region",region)

        # Initialize table with header row
        table_data = []
        table_data.append(['SKU', 'Retail Price', 'Region', 'Meter', 'Product Name'])
        
        # Azure Retail Prices REST endpoint
        api_url = "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview"
        
        # OData filter: restrict to VM service in the target region
        query = "armRegionName eq '" + region +"' and serviceName eq 'Virtual Machines'"
        response = requests_get_with_retry(api_url, params={'$filter': query})
        json_data = json.loads(response.text)
        
        build_pricing_table(json_data, table_data)
        nextPage = json_data['NextPageLink']
        
        # Follow pagination links until all pages are consumed
        while(nextPage):
            response = requests_get_with_retry(nextPage)
            json_data = json.loads(response.text)
            nextPage = json_data['NextPageLink']
            build_pricing_table(json_data, table_data)
            print("  Getting next page...")

        # Write the collected pricing data to a CSV file for this region
        fileName = region + '_pricing_data.csv'

        with open(fileName, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            #writer.writerow("armSkuName,retailPrice,unitOfMeasure,armRegionName,meter,productName")
            writer.writerows(table_data)
        print ("Wrote",fileName)

def merge_data():
    """
    Read all per-region pricing CSVs, concatenate them, and create a pivoted
    "combined.csv" with one row per (SKU, Meter, Product Name) and one column
    per region containing the retail price.
    """
    # Find all CSV files with "pricing_data" in the name (one per region)
    csv_files = glob.glob(os.path.join(os.path.dirname(__file__) or ".", "*pricing_data*.csv"))

    if not csv_files:
        print("No CSV files with 'pricing_data' in the name found.")
        exit(1)

    print(f"Found {len(csv_files)} file(s): {[os.path.basename(f) for f in csv_files]}")

    # Load all regional files and merge into a single DataFrame
    frames = [pd.read_csv(f) for f in csv_files]
    df = pd.concat(frames, ignore_index=True)

    # Normalize column names (strip leading/trailing whitespace)
    df.columns = df.columns.str.strip()

    # Pivot: one row per unique (SKU, Meter, Product Name) combination,
    # one column per Region containing the retail price.
    # Where duplicates exist in the same region, keep the first occurrence.
    pivoted = df.pivot_table(
        index=["SKU",  "Meter", "Product Name"],
        columns="Region",
        values="Retail Price",
        aggfunc="first",
    )

    # Flatten the multi-level column index and reset
    pivoted.columns = [col for col in pivoted.columns]
    pivoted.reset_index(inplace=True)

    output = os.path.join(os.path.dirname(__file__) or ".", "combined.csv")
    pivoted.to_csv(output, index=False)
    print(f"Written {len(pivoted)} rows to {output}")


def add_sku_details():
    """
    Read combined.csv, parse each SKU to extract hardware metadata, apply
    exclusion filters, and write the final enriched report to
    "sku-price-report-by-region.csv".
    """
    script_dir = os.path.dirname(__file__) or "."
    input_path = os.path.join(script_dir, "combined.csv")
    output_path = os.path.join(script_dir, "sku-price-report-by-region.csv")

    with open(input_path, newline="", encoding="utf-8") as fin:
        reader = csv.DictReader(fin)
        fieldnames = list(reader.fieldnames or [])

        # Insert enrichment columns immediately after the SKU column
        sku_idx = fieldnames.index("SKU") + 1
        new_cols = ["vCPUs", "Memory_GB", "Memory_Ratio", "Version", "MeterType", "OSType",  "CPUType","Notes", "Features"]
        for i, col in enumerate(new_cols):
            fieldnames.insert(sku_idx + i, col)

        # Parse each row and apply exclusion filters
        rows: list[dict] = []
        for row in reader:
            details = parse_sku(row.get("SKU", ""), row.get("Product Name", ""),row.get("Meter", ""))
            row.update(details)

            # Apply exclusion filters based on configuration flags
            if exclude_basic_or_legacy and ("Legacy A-series" in row.get("Notes", "") or row.get("SKU", "").startswith("Standard_A")):
                continue
            if exclude_retiring and "Retiring-Avoid-Use" in row.get("Notes", ""):
                continue
            if exclude_dedicated_host and "Dedicated Host" in row.get("Notes", ""):
                continue
            if exclude_dedicated_host and "Isolated" in row.get("Features", ""):
                continue
            if exclude_spot and (row.get("MeterType", "") == "Spot" or row.get("MeterType", "") == "Low Priority"):
                continue
            if exclude_on_demand and row.get("MeterType", "") == "On Demand":
                continue

            rows.append(row)

    with open(output_path, "w", newline="", encoding="utf-8") as fout:
        writer = csv.DictWriter(fout, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Written {len(rows)} rows to {output_path}")


if __name__ == "__main__":

    # --- Exclusion filters ---
    # Set to True to omit the corresponding category from the final report.
    exclude_basic_or_legacy = True   # Filter legacy A-series / Basic tier SKUs
    exclude_retiring        = True   # Filter SKUs flagged as retiring
    exclude_dedicated_host  = True   # Filter dedicated and isolated host type SKUs

    exclude_spot            = False  # Filter Spot / Low Priority pricing
    exclude_on_demand       = False  # Filter On Demand pricing

    # --- Execute the three-step pipeline ---
    pull_data_from_api()   # Step 1: Fetch per-region pricing from the API
    merge_data()           # Step 2: Combine regional CSVs into pivoted table
    add_sku_details()      # Step 3: Enrich with parsed SKU metadata & export

    

