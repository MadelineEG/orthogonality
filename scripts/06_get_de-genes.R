# 1. Load required libraries
library(DESeq2)

# 2. Define master directories
counts_dir <- "./output/counts" # Adjusted to match your actual counts folder path
output_dir <- "./output/de-genes"
meta_file  <- "data/metadata.tsv"
comps_file <- "data/comparisons.tsv"

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 3. Load architecture tables
meta  <- read.delim(meta_file, colClasses = "character")
comps <- read.delim(comps_file, colClasses = "character")

comps$group <- as.character(comps$group)

unique_studies <- unique(comps$study)

for (current_study in unique_studies) {
  
  message("Processing study: ", current_study)
  
  study_meta  <- subset(meta, study == current_study)
  study_comps <- subset(comps, study == current_study)
  
  # --- STEP 4: DYNAMIC MATRIX COMPILER ---
  # Read all files individually into a list to handle mismatched rows/genes
  gene_list <- list()
  
  for (j in 1:nrow(study_meta)) {
    file_name <- paste0(study_meta$study[j], "_", study_meta$accession[j], "_counts.txt")
    file_path <- file.path(counts_dir, file_name)
    
    # Read the individual HTSeq file
    sample_counts <- read.delim(file_path, header = FALSE, col.names = c("GeneID", study_meta$accession[j]))
    
    # Strip out standard HTSeq summary stats (lines starting with "__") so they don't break stats
    sample_counts <- sample_counts[!grepl("^__", sample_counts$GeneID), ]
    
    gene_list[[study_meta$accession[j]]] <- sample_counts
  }
  
  # Use an outer join approach to merge them. This keeps ALL unique genes (host + all plasmids)
  master_df <- Reduce(function(x, y) merge(x, y, by = "GeneID", all = TRUE), gene_list)
  
  # Set Gene IDs as row names and convert to a pure numeric matrix
  rownames(master_df) <- master_df$GeneID
  count_matrix <- as.matrix(master_df[, -1])
  
  # CRITICAL: Replace all missing data (NAs) with 0. 
  # This ensures untransminded samples get a '0' count for plasmid genes instead of breaking.
  count_matrix[is.na(count_matrix)] <- 0
  
  # Ensure counts are integers
  count_matrix <- round(count_matrix)
  
  # --- STEP 5: RUN DESeq2 FROM MATRIX ---
  # Set up colData matching the matrix column order
  sTable <- data.frame(condition = study_meta$condition)
  rownames(sTable) <- study_meta$accession
  
  dds <- DESeqDataSetFromMatrix(countData = count_matrix,
                                colData   = sTable,
                                design    = ~ condition)
  
  dds <- DESeq(dds)
  
  # --- STEP 6: INNER LOOP FOR COMPARISONS ---
  for (i in 1:nrow(study_comps)) {
    treat <- study_comps$treat_condition[i]
    ctrl  <- study_comps$ctrl_condition[i]
    
    message("  -> Running contrast: ", treat, " vs ", ctrl)
    
    res <- results(dds, contrast = c("condition", treat, ctrl))
    res_df <- as.data.frame(res)
    
    # Filter by padj < 0.05 (dropping NAs)
    res_filtered <- res_df[!is.na(res_df$padj) & res_df$padj < 0.05, ]
    res_ordered  <- res_filtered[order(res_filtered$padj), ]
    
    # Filename assembly
    grp  <- study_comps$group[i]
    c_nm <- study_comps$comp_name[i]
    out_filename <- paste0(current_study, "_", grp, "_", c_nm, ".csv")
    out_path     <- file.path(output_dir, out_filename)
    
    write.csv(res_ordered, file = out_path)
    message("     Saved ", nrow(res_ordered), " significant DE genes to: ", out_filename)
  }
}
