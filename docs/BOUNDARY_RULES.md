**Migration Platform – Boundary Rules**



**Purpose**



**This document defines the separation between:**



**The Migration Engine (reusable system)**

**The Client Workspace (client-specific runtime environment)**



**This separation ensures:**



**Data security**

**Audit integrity**

**Reusability**

**Controlled versioning**

**No cross-client contamination**



**1. Migration Engine (Reusable Repository)**



**Location:**

**C:\\migration\\engine\\**



**Source:**

**GitHub – migrate-engine repository**



**Contains:**

**Database schemas (DDL)**

**Transformation and validation scripts**

**Load utilities**

**Template documentation**

**Metabase template exports**

**Example configuration files (no secrets)**



**Does NOT contain:**

**Raw client extracts**

**Logs**

**Output files**

**Credentials**

**Client-specific configuration**

**Sensitive data**



**The engine is version-controlled and tagged at release.**



**Each client implementation references a specific engine version.**



**2. Client Workspace (Client-Specific Runtime)**



**Location:**

**C:\\migration\\workspace<client>\\**



**Contains:**



**Raw data extracts (immutable once captured)**

**Logs from execution runs**

**Validation reports and row counts**

**Client-specific configuration (.env)**

**Final handover documentation**

**Evidence packs**



**The workspace is NOT reusable.**

**It is client-specific and environment-specific.**



**No client data is committed to GitHub.**



**3. Configuration Boundary**



**The engine reads configuration from:**

**workspace<client>.env**



**The .env file may contain:**

**File paths**

**Database connection strings**

**Client identifiers**



**The .env file must never be committed to source control.**



**4. Version Control Rules**



**Engine:**

**Maintained in GitHub**

**Tagged at release**

**Changes documented in CHANGELOG**



**Workspace:**

**Not committed to public repositories**

**Archived with final deliverables**

**Stored according to client retention policy**



**5. Security Principles**



**Principle of least privilege for database roles**

**Read-only extraction where possible**

**No production writes to source systems**

**No credentials in documentation**

**No raw extracts in Git repositories**



**6. Audit Integrity**



**For each client:**

**Engine version used is recorded**

**Extract manifests are stored**

**Row count validations are preserved**

**Run logs are timestamped**



**Handover documentation is archived**



**This ensures reproducibility and audit defensibility.**



**This document establishes the architectural boundary between reusable system components and client-specific data environments.**

