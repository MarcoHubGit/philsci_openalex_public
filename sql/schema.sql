
CREATE TABLE source (
   id TEXT PRIMARY KEY, 
   name TEXT NOT NULL
);

CREATE TABLE author (
   id TEXT PRIMARY KEY,
   name TEXT NOT NULL,
   orcid TEXT
);

CREATE TABLE institution (
   id TEXT PRIMARY KEY,
   name TEXT
);

CREATE TABLE topic (
   id TEXT PRIMARY KEY,
   name TEXT NOT NULL,
   field TEXT NOT NULL,
   subfield TEXT,
   domain TEXT 
);

CREATE TABLE paper (
   id TEXT PRIMARY KEY,
   title TEXT NOT NULL,
   year INT NOT NULL, 
   is_oa BOOL,
   type TEXT,
   source_id TEXT REFERENCES source(id)
);

CREATE TABLE paper_topic (
   paper_id TEXT REFERENCES paper(id),
   topic_id TEXT REFERENCES topic(id),
   PRIMARY KEY (paper_id, topic_id)
);

CREATE TABLE authorship (
   author_id TEXT REFERENCES author(id),
   paper_id TEXT REFERENCES paper(id),
   PRIMARY KEY (author_id, paper_id)
);

CREATE TABLE inst_auth (
   inst_id TEXT REFERENCES institution(id),
   author_id TEXT,
   paper_id TEXT,

   FOREIGN KEY (author_id, paper_id)
      REFERENCES authorship(author_id, paper_id),

   PRIMARY KEY (author_id, paper_id, inst_id)
);
