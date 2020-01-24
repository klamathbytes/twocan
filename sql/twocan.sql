DROP DATABASE IF EXISTS twocan;
CREATE DATABASE twocan;

\c twocan;

DROP TABLE IF EXISTS "public"."raw";
CREATE TABLE "public"."raw"
(
  raw_id SERIAL PRIMARY KEY,
  raw_data jsonb,
  raw_file varchar(128),
  raw_date timestamp DEFAULT CURRENT_TIMESTAMP
);


DROP TABLE IF EXISTS "public"."party";
CREATE TABLE "public"."party" (
  "party_id" SERIAL PRIMARY KEY,
  "name" varchar(256) NOT NULL CHECK (name <> ''),
  "short_name" varchar(256)
);

DROP TABLE IF EXISTS "public"."individual";
CREATE TABLE "public"."individual" (
  "bio_id" varchar(64) NOT NULL PRIMARY KEY,
  "data" jsonb
);

DROP TABLE IF EXISTS "public"."party_roster";
CREATE TABLE "public"."party_roster" (
  "party_id" int4 REFERENCES "public"."party" ("party_id"),
  "bio_id" varchar(256) REFERENCES "public"."individual" ("bio_id"),
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);
ALTER TABLE "public"."party_roster" ADD CONSTRAINT "party_roster_id" PRIMARY KEY ("party_id", "bio_id", "start_at");

DROP TABLE IF EXISTS "public"."senate_list";
CREATE TABLE "public"."senate_list" (
  "bio_sen_id" varchar(512) PRIMARY KEY,
  "senate_id" varchar(256) NOT NULL DEFAULT '0',
  "bio_id" varchar(256) REFERENCES "public"."individual" ("bio_id"),
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);

CREATE OR REPLACE FUNCTION "public"."create_individual_senate_id"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
    BEGIN
      NEW.bio_sen_id := bio_id||'.'||senate_id;
      RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS "individual_senate_id" ON "public"."senate_list";
CREATE TRIGGER "individual_senate_id" BEFORE INSERT OR UPDATE ON "public"."senate_list"
FOR EACH ROW
EXECUTE PROCEDURE "public"."create_individual_senate_id"();

DROP TYPE IF EXISTS sponsor;
CREATE TYPE sponsor AS ENUM ('sponsor', 'cosponsor');
DROP TYPE IF EXISTS chamber;
CREATE TYPE chamber AS ENUM ('house', 'senate');

DROP TABLE IF EXISTS "public"."document";
CREATE TABLE "public"."document" (
  "doc_id" varchar(256) NOT NULL PRIMARY KEY,
  "committees" jsonb,
  "chamber_of_origin" chamber,
  "doc_type" varchar(64), --NOT NULL,
  "start_at" timestamp --,
  --raw_id" int REFERENCES "public"."raw" ("raw_id")
);

DROP TABLE IF EXISTS "public"."endorsement";
CREATE TABLE "public"."endorsement" (
  "bio_id" varchar(512) REFERENCES "public"."individual" ("bio_id"),
  "doc_id" varchar(256) REFERENCES "public"."document" ("doc_id"),
  "sponsor" sponsor,
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);

DROP TABLE IF EXISTS "public"."document_history";
CREATE TABLE "public"."document_history" (
  "record_id" SERIAL PRIMARY KEY,
  "doc_id" varchar(256) REFERENCES "public"."document" ("doc_id"),
  "doc_type" varchar(64), --NOT NULL,
  "data" jsonb,
  "start_at" timestamp
);

DROP TABLE IF EXISTS "public"."congress";
CREATE TABLE "public"."congress" (
  "congress_id" varchar(256) PRIMARY KEY,
  "meeting_id" integer NOT NULL,
  "session_id" integer NOT NULL,
  "start_at" timestamp NOT NULL,
  "end_at" timestamp NOT NULL
);

CREATE OR REPLACE FUNCTION "public"."create_congress_id"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
    BEGIN
      NEW.congress_id := meeting_id||'.'||session_id;
      RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS "congress_id" ON "public"."congress";
CREATE TRIGGER "congress_id" BEFORE INSERT OR UPDATE ON "public"."congress"
FOR EACH ROW
EXECUTE PROCEDURE "public"."create_congress_id"();

DROP TABLE IF EXISTS "public"."committee";
CREATE TABLE "public"."committee" (
  "committee_id" integer NOT NULL PRIMARY KEY,
  "parent_committee_id" integer,
	"name" varchar(256) NOT NULL,
	"type" varchar(256) NOT NULL
);

DROP TABLE IF EXISTS "public"."congress_roster";
CREATE TABLE "public"."congress_roster" (
  "bio_id" varchar(256) NOT NULL REFERENCES "public"."individual" ("bio_id"),
  "committee_id" integer NOT NULL REFERENCES "public"."committee" ("committee_id"),
	"congress_id" varchar(256) NOT NULL REFERENCES "public"."congress" ("congress_id"),
  "start_at" timestamp NOT NULL,
	"end_at" timestamp
);
ALTER TABLE "public"."congress_roster" ADD CONSTRAINT "congress_roster_id" PRIMARY KEY ("bio_id", "committee_id", "congress_id","start_at");

