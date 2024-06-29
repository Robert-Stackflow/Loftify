enum CreateTableSql {
  rssItems(
    "rssItems",
    '''
      CREATE TABLE rssItems (
        iid TEXT NOT NULL,
        feedId INTEGER NOT NULL,
        feedFid TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        date INTEGER NOT NULL,
        content TEXT NOT NULL,
        snippet TEXT NOT NULL,
        creator TEXT,
        thumb TEXT,
        hasRead INTEGER NOT NULL,
        starred INTEGER NOT NULL,
        readTime INTEGER,
        starTime INTEGER,
        params TEXT,
        PRIMARY KEY(feedId,url)
      );
    ''',
  );

  const CreateTableSql(this.tableName, this.sql);

  final String tableName;
  final String sql;
}
