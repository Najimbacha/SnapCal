# USDA everyday-food import

Imported September 5, 2026 from the owner's local SR Legacy April 2018 and
Foundation April 30, 2026 JSON exports. The original downloads remain outside
the repository. Branded foods are intentionally excluded.

## Result

- 8,188 input entries; 8,096 accepted USDA records; 92 rejected entries.
- 8,381 total foods, including all 285 existing food IDs and names.
- 10,835 USDA alias keys; 1,256 keys reference multiple records.
- Existing curated aliases stay in `food_aliases.json`; candidate lists live
  in `usda_aliases.json`. A collision never overwrites a record.
- `usda_import_report.json` lists every rejected entry, collision and reviewed
  update. `usda_curated_mappings.json` records the two reviewed crosswalks.
- Roasted chicken breast retains 165 kcal and now uses the source's 3.57 g fat
  instead of 3.6 g. Generic olive oil has unchanged nutrients with provenance
  added. Other existing foods were not assigned a source based on guesswork.

## Nutrition and identity

Values are per 100 g, stored at source precision. Display/portion calculations
round downstream. Calorie priority is nutrient 2048 (specific factors), then
1008 (standard kcal), then 2047 (general factors). All three macros must be
present and valid; missing values are not zero. A complete zero-valued record
such as water is valid. Each imported row retains the FDC ID, full description,
dataset and selected calorie nutrient ID.

USDA candidates must agree with requested food words and preparation, skin and
fat qualifiers. Ambiguous candidates return no database match, allowing the
existing labeled AI estimate. Foundation supersedes SR Legacy only when the
full normalized food description is identical. Distinct IDs remain stored.
Established curated aliases retain their defaults unless the query explicitly
conflicts with the food's preparation or composition.

## Reproduction

From the repository root (PowerShell), run this as one command, substituting
the two local source paths:

```text
node backend/scripts/import-usda.js --file <SR-Legacy.json> --file <Foundation.json> --dry-run
```

To apply, remove `--dry-run` and add
`--report backend/data/usda_import_report.json`. Review the report before
committing all runtime data files together. An unchanged reimport yields the
same food and alias data and no updates to curated records.

## Verification and operation

109 backend tests passed. Repeat-import dry run remained at 8,381 foods.
All prior IDs and display names survived. Common-food source checks cover rice,
roasted chicken breast, boiled eggs and olive oil; matching tests also cover milk,
duplicate names, preparation conflicts and source selection.

Local Windows benchmark: runtime JSON files total 3.38 MiB; loaded database and
index add about 11.62 MiB heap. Initial load took 87 ms. Across 140 mixed lookups,
95% completed within 23 ms; maximum 46 ms. These are local measurements, not
Render latency guarantees. The raw 210 MB and 3.3 GB downloads are not deployed.

After deployment, `/health` reports `scan.database.foods = 8381` and
`scan.database.usdaFoods = 8096`. Scans keep their existing response format; both
tiers and the existing Play Store app use the new database. Photo identity and
portion sizes are still estimates, even when reference nutrition comes from USDA.

Rollback: revert this database-release commit and redeploy. Keep the database,
candidate index and matching code from the same release. No Firestore migration
or changes to saved meals are performed.
