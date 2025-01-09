## Bugs


## High priority features


## Medium priority features
- Redo cash flow screen, combine with categories screen. View options (vertical selector with two columns):
  - Stacked columns (double sided) (subcats as toggle in chart title instead of side bar)
  - Net income (expense/income totals as lines, with red/green columns for net. Maybe include toggle in chart title for showing lines or not instead of side bar) Maybe show income as another series (parallel bars)
  - Flows (expense) | Flows (income) (totals as bars at bottom)
  - Heatmap (expense) | Heatmap (income)
  - Move spark chart up beneath time frame
- Start screen and UX
- Choose category/account on CSV column?
- Delete account
- sort transactions by value?
- Loading scrim across full app?
- Load more transactions on reach end of transaction grid?


## Refactor
- Undo make AccountState an independent ChangeNotifier; huge hassle, need to watch the state everywhere you use an account. Alternative is to always fetch the account object from the AccountState instead of making it linked in other objects, to force the watch.
- Remove MutableAllocation


## Low priority features
- Animate bar charts?
- Day-by-day charts?
- Custom other categories
