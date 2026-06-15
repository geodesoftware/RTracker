# Work History

## 2026-06-14

- Updated the country filter label in `index.html` so it opens a fullscreen country summary dialog.
- Added country aggregation logic that totals made counts per country, sorts by total times descending, and uses the most recent `lastMade` date per country.
- Applied the fallback rule that treats a recipe as made once when `madeTimes` is `0` or missing but `lastMade` is populated.
- Added summary UI, close controls, and supporting styles for the new country summary view.
- Added explicit accessibility labels for the country summary trigger and country filter select after replacing the original label element.
- Removed the explanatory summary note from the country summary header and restored the summary modal's themed background treatment.
- Made country names in the summary clickable so they close the modal, switch to the `All` tab, and apply the selected country filter.
- Fixed the mobile breakpoint so the country summary table stays visible on small screens instead of inheriting the recipe-table hide rule.
