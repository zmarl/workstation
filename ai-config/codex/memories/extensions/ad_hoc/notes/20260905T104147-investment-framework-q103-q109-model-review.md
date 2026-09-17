# Investment framework Q103-Q109 and operating-profit model review

- Date: 2026-09-05
- Workspace: `D:\Dev\Investment`
- Dialogue record: `D:\Dev\Investment-investment-framework-owner-dialogue\docs\worklogs\20260905-investment-framework-owner-dialogue.md`

## Owner decisions

- Adopt all recommendations in Q103-Q109.
- Analyze every fundamental factor that can reasonably be read from disclosed data, at the same fine granularity as the current question rounds.
- Do not invent undisclosed values or force every qualitative factor into a number.
- Preserve company disclosures, deterministic calculations, company qualitative explanations, external-context hypotheses, and unresolved items as distinct evidence states.

## Re-review conclusion

- The current `operating-profit-forecast-model.md` and `OperatingProfitScenarioCompiler` are valid as an auditable conditional reference scenario, not as a finished earnings forecast model.
- The all-rates-held case algebraically reduces to conditional revenue multiplied by the origin quarter's operating margin. It is a useful baseline but does not model fixed-cost absorption, incremental profitability, or acceleration.
- Keep its cutoff, provenance, fact identity, unit/scope/period checks, accounting identity, and fail-closed behavior.
- Extend the formal model to independently handle YoY, comparable QoQ, company KPIs, gross margin, SGA amount/growth and step costs, recurring/one-off/unresolved operating residuals, multiple periods, company-plan seasonality, segment drivers, the operating-profit-to-EPS bridge, PER valuation ranges, and market-leading revaluation.
- Keep any P10/P50/P90 statistical future-actual model separate from conditional reference scenarios and from stock-price win probabilities.

## Legacy-path warning

- `tools/decision_support/story_builder/impact_calculator.py` contains a separate simplified path with default zeros, 30% tax, current operating margin as fallback incremental margin, and fixed bull/base/bear defaults.
- It does not preserve the new model's point-in-time and source/data-comparability contract and must not become the formal model by accident.
- When formal implementation is approved, inspect existing saved/UI usage and either quarantine it as historical output or migrate it explicitly.

## Recording status

- Earlier model decisions exist in ODR-0033, the Current design, and the earlier worklog.
- Q96-Q109 and the owner's latest clarification are now recorded in the owner-dialogue worklog.
- They are not yet integrated into the Current investment-framework authority, the Current operating-profit design, Qwen runtime workflow, or Desktop app.
- Next discussion frontier is Q110-Q117: disclosure coverage, revenue/gross-profit/SGA/segment decomposition, leading KPIs, balance-sheet/cash-flow quality, and complete evidence ledger versus concise human display.
