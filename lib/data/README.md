# Data Processing Info

## Objects

We have several main objects which correspond to respective tables in the database. These are mapped to one another in the following ways:
    - `Account`: no links
    - `Category`: self-links to child categories
    - `CategoryRule`: link to single category
    - `Tag`: no links
    - `Transaction`: single links to `Account` and `Category`, and one-to-many links to `Tag`, `Allocation` and `Reimbursement`
    - `Allocation`: unique pairings between a category and a transaction
    - `Reimbursement`: unique pairings between two transactions
The respective mappings are stored and respected in memory, with the only exception being the transactions. Therefore, other than the transactions, objects in memory must always have one unique instance per value. For example, never create two `Category` objects representing the same category. On the other hand, transactions should never be persisted in memory outside of UI state. For example, `Reimbursement.target` should only be used for UI and obtaining the `id` of the target transaction.  