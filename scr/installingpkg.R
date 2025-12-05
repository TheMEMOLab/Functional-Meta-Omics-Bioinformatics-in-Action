# ============================================================
#   COMPLETE PACKAGE INSTALLER: CRAN + BIOCONDUCTOR + GITHUB
# ============================================================

# ---- 1. CRAN PACKAGES ----
cran_packages <- c(
  "tidyverse",
  "ggplot2",
  "RColorBrewer",
  "gt",
  "DT",
  "gtools",
  "patchwork",
  "ggpubr",
  "pheatmap",
  "viridis",
  "Polychrome",
  "ggplotify",
  "gridExtra",
  "devtools"    # needed for GitHub installs
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("📦 Installing CRAN package:", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    message(paste("✔ CRAN package already installed:", pkg))
  }
}

# Install CRAN packages
invisible(lapply(cran_packages, install_if_missing))


# ---- 2. BIOCONDUCTOR PACKAGES ----
bioc_packages <- c("MSstats", "pcaMethods")

# Install BiocManager if missing
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Install Bioconductor packages (with fallback for pcaMethods)
for (pkg in bioc_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("🧬 Installing Bioconductor package:", pkg))
    tryCatch(
      BiocManager::install(pkg, ask = FALSE),
      error = function(e) {
        message(paste("⚠️ Bioconductor install failed for", pkg,
                      "— trying r-universe fallback"))
        install.packages(pkg,
                         repos = c("https://bioc.r-universe.dev",
                                   "https://cloud.r-project.org"))
      }
    )
  } else {
    message(paste("✔ Bioconductor package already installed:", pkg))
  }
}


# ---- 3. GITHUB PACKAGES ----
# distillR from anttonalberdi
if (!requireNamespace("distillR", quietly = TRUE)) {
  message("🐙 Installing GitHub package: anttonalberdi/distillR")
  devtools::install_github("anttonalberdi/distillR")
} else {
  message("✔ GitHub package already installed: distillR")
}


# ---- 4. LOAD ALL PACKAGES ----
all_packages <- c(
  cran_packages,
  bioc_packages,
  "distillR"
)

invisible(lapply(all_packages, library, character.only = TRUE))

message("🎉 All packages installed and loaded successfully!")