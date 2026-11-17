# OpenAlex Philosophy of Science Bibliometrics

A Python and PostgreSQL ETL project for building a relational dataset of publications in philosophy of science and philosophy of physics. The project uses [OpenAlex](https://openalex.org/) metadata to study publication patterns, authorship, institutional affiliations, and research topics.

**Current stage:** A local, single-paper proof of concept for the extract–transform–load (ETL) pipeline. Full API retrieval and bibliometric analysis are planned, not yet implemented.

## Research scope

The intended dataset covers publications from **2025** in five journals:

- *Philosophy of Science*
- *British Journal for the Philosophy of Science*
- *Studies in History and Philosophy of Science*
- *Foundations of Physics*
- *Philosophy of Physics*

The planned publication types are articles and conference papers, subject to the records available in OpenAlex. **The current sample contains only one article from *Philosophy of Physics***; it should not be interpreted as a comprehensive extract from the five journals.

**Why select journals rather than topics?** OpenAlex assigns subjects algorithmically. Work in philosophy of physics can be classified under physics topics such as quantum mechanics, while those same topics also cover research outside philosophy. Selecting publications by journal defines a more transparent initial corpus; OpenAlex topics are retained as data to analyze rather than used as inclusion criteria.

## What the pipeline does

1. **Extract:** Read a saved OpenAlex API response from `Data/raw/one_query_from_web.json`.
2. **Transform:** Convert nested JSON into lists of dictionaries corresponding to the database tables.
3. **Validate:** Check required values, accommodate optional and missing metadata, and remove duplicate records by primary key.
4. **Load:** Insert records into PostgreSQL in foreign-key dependency order using a reusable loading function, parameterized values, and `ON CONFLICT DO NOTHING`.
5. **Verify:** Check table row counts and repeat loads to test duplicate prevention; SQL joins can be used to check the stored relationships.

The extractor currently reads a **locally saved sample**; it does not yet call the OpenAlex API automatically or handle pagination.

## Database design

The relational schema is defined in [`sql/schema.sql`](sql/schema.sql) and contains eight tables:

| Table | Contents |
|---|---|
| `paper` | Publication identifier, title, year, open-access flag, type, and source reference |
| `source` | Journal or other publication-source metadata |
| `author` | Authors and optional ORCID identifiers |
| `institution` | Institutional identifiers and names |
| `topic` | OpenAlex topic, field, subfield, and domain |
| `authorship` | Many-to-many relationship between authors and papers |
| `paper_topic` | Many-to-many relationship between papers and topics |
| `inst_auth` | An institution associated with a particular author **on a particular paper** |

The `inst_auth` table references the composite `(author_id, paper_id)` key in `authorship`. This reflects that an author's affiliation can differ from one publication to another. Papers without institutional metadata remain in the dataset; no artificial institution is created to replace a missing affiliation.

## Repository layout

```text
openalex-bibliometrics/
├── Data/
│   └── raw/
│       └── one_query_from_web.json  # Small public OpenAlex sample
├── sql/
│   └── schema.sql                   # PostgreSQL DDL
├── src/
│   ├── extract.ipynb                # Read the sample JSON
│   ├── transform.ipynb              # Transform, deduplicate, validate
│   └── load.ipynb                   # Insert and inspect PostgreSQL rows
├── .gitignore
├── requirements.txt
└── README.md
```

## Running the sample locally

**Prerequisites:** Python, Jupyter (or VS Code with the Jupyter extension), and a local PostgreSQL server.

1. Install Python dependencies from the repository root:

   ```bash
   python -m pip install -r requirements.txt
   ```

2. Create a PostgreSQL database named `openalex_philosophy` using `psql` or pgAdmin. For example, in `psql` connected to an administrative database:

   ```sql
   CREATE DATABASE openalex_philosophy;
   ```

3. Create the tables from the project root (if `psql` is on your PATH):

   ```bash
   psql -U postgres -d openalex_philosophy -f sql/schema.sql
   ```

   You can instead execute `sql/schema.sql` from the pgAdmin Query Tool while connected to the new database. Run this schema only once for a fresh database; the file is not a migration script.

4. Configure PostgreSQL connection settings for your local environment. `src/load.ipynb` uses the `PGDATABASE`, `PGUSER`, `PGHOST`, and `PGPORT` environment variables, with local defaults. PostgreSQL can obtain a password through its standard client authentication configuration (for example, `PGPASSWORD` or a password file). **Do not store database passwords in notebooks or commit them to Git.**

5. Open the `src` directory in VS Code/Jupyter and run `load.ipynb` **from that directory**. It executes `transform.ipynb`, which executes `extract.ipynb`, using relative paths to the sample data. Run the notebook's load and verification cells in order.

The sample used during development produced **1 paper, 1 author, 1 source, 3 topics, 1 authorship, and 3 paper–topic links**. The sample contains no institutional affiliations, so empty `institution` and `inst_auth` tables are expected.

## Data-quality choices and limitations

- Optional missing metadata is represented with Python `None` / SQL `NULL`, not placeholder strings.
- Invalid records missing database-required values are filtered before loading; the pipeline should log exclusions and check referential integrity more thoroughly before ingesting a larger corpus.
- Duplicate records are removed during transformation, and unique-key conflicts are skipped during loading. Existing rows are **not updated** on reruns.
- `ON CONFLICT DO NOTHING` does **not** resolve foreign-key errors. All referenced records must exist before loading relationship tables.
- The present tests use one paper. Passing them demonstrates the basic structure, not robustness at production scale.
- Citation counts and citation-network analysis are research interests but are **not currently stored** in the database schema.

## Planned analysis

Once the full 2025 corpus has been extracted, the database can support questions such as:

- Which authors and institutions have the most publications in this corpus?
- How are publications distributed across the selected journals?
- Which topics occur most frequently, and how do they differ by journal?
- What proportion of papers are single-authored versus coauthored?
- How do coauthorship and institutional affiliations relate to publication patterns?

## Next steps

- [x] Design a normalized PostgreSQL schema
- [x] Build extraction, transformation, validation, and loading notebooks for a saved sample
- [x] Run basic row-count and duplicate-prevention checks on one paper
- [ ] Test loading with diverse records, including missing metadata and multiple affiliations
- [ ] Add referential-integrity checks and exclusion logging
- [ ] Retrieve the complete intended OpenAlex corpus with pagination, retries, and API error handling
- [ ] Add SQL/Python bibliometric analysis and visualizations

## Data source

Publication metadata used for the sample comes from [OpenAlex](https://openalex.org/). OpenAlex identifiers, titles, author names, and topic classifications are preserved from its API response. This repository is an independent learning and analysis project, not an official OpenAlex product.
