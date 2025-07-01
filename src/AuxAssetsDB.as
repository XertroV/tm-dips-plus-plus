bool _AuxAssetDB_SingletonLoaded = false;

AuxAssetsDBImpl@ AuxAssetsDB = AuxAssetsDBImpl();

class AuxAssetsDBImpl {
    SQLite::Database@ db;

    AuxAssetsDBImpl() {
        if (_AuxAssetDB_SingletonLoaded) {
            throw("AuxAssetsDB is a singleton and can only be created once.");
        }
        _AuxAssetDB_SingletonLoaded = true;

        // Open the database
        @db = SQLite::Database(IO::FromStorageFolder("aux_assets.db"));

        RunMigrations();
        auto tables = ListTables();
        if (tables.Length == 0) {
            warn("AuxAssetsDB: No tables found in the database after migrations.");
        } else {
            dev_trace("AuxAssetsDB: Tables in the database: " + string::Join(tables, ", "));
        }
    }

    void RunMigrations() {
        // todo: actual migrations
        // Create the table if it doesn't exist
        db.Execute("CREATE TABLE IF NOT EXISTS test_assets (specHash VARCHAR(16), name TEXT PRIMARY KEY, url TEXT, type TEXT, local_path TEXT)");
        // db.Execute("CREATE TABLE IF NOT EXISTS aux_assets (specUrlHash VARCHAR(16), name TEXT PRIMARY KEY, url TEXT, type TEXT, local_path TEXT)");
    }

    string[]@ ListTables() {
        SQLite::Statement@ stmt = db.Prepare("SELECT name FROM sqlite_master WHERE type='table'");
        string[]@ tables = {};
        stmt.Execute();
        int rowCount = 0;
        stmt.NextRow();
        while (stmt.NextRow()) {
            tables.InsertLast(stmt.GetColumnString("name"));
            rowCount++;
        }
        if (rowCount == 0) {
            warn("AuxAssetsDB: No tables found in the database.");
        }
        return tables;
    }
}
