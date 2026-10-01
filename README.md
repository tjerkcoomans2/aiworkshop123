# AI Workshop - OpenEdge ABL Project

Sample OpenEdge ABL (12.8) project used in the AI workshop. It runs against the `sports2000` database and demonstrates the Business Entity pattern.

## Contents

- `src/business/` - business entity classes (`CustomerEntity`, `EntityFactory`) and the shared dataset include (`CustomerDataset.i`)
- `src/CustomerWin.w` - window that reads and updates customers through the business entity
- `src/ItemWin.w` - window that still accesses the database directly
- `doc/business-entity-pattern.md` - description of the Business Entity architecture pattern
- `dump/sports2000.df` - schema of the sports2000 database (first 500 lines)
- `.windsurf/` - Windsurf rules and workflows
- `openedge-project.json`, `build.xml` - project and build configuration
