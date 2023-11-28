const allocationsTable = "allocations";

const createAllocationsTableSql = "CREATE TABLE IF NOT EXISTS $allocationsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "`name` TEXT NOT NULL, "
    "`transactionKey` INTEGER NOT NULL, "
    "`categoryKey` INTEGER NOT NULL, "
    "`value` INTEGER NOT NULL, "
    "`listIndex` INTEGER NOT NULL)";

const _key = "id";
const _transaction = "transactionId";

const allocationsKey = _key;
const allocationsTransaction = _transaction;
