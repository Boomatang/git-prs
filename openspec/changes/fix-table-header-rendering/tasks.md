## 1. Core Implementation

- [ ] 1.1 Update `formatMineOutput` header to conditionally include "URL" column when `use_inline` is true
- [ ] 1.2 Update `formatMineOutput` separator width calculation to include URL length when `use_inline` is true
- [ ] 1.3 Update `formatTeamOutput` header to conditionally include "URL" column when `use_inline` is true
- [ ] 1.4 Update `formatTeamOutput` separator width calculation to include URL length when `use_inline` is true

## 2. Testing

- [ ] 2.1 Add test for header including URL column in inline mode
- [ ] 2.2 Add test for separator extending to URL column width in inline mode
- [ ] 2.3 Run existing tests to ensure no regressions

## 3. Verification

- [ ] 3.1 Build and run with wide terminal to verify header and separator display correctly
