CREATE DATABASE twocan;

\c twocan;

CREATE TABLE "public"."party" (
  "party_id" SERIAL PRIMARY KEY,
  "name" varchar(256) NOT NULL CHECK (name <> ''),
  "short_name" varchar(256)
);

CREATE TABLE "public"."individual" (
  "bio_id" varchar(64) NOT NULL PRIMARY KEY,
  "honorific_prefix" varchar(8),
  "given_name" varchar(64),
  "additional_name" varchar(64),
  "family_name" varchar(64),
  "honorific_suffix" varchar(64),
  "contact" jsonb,
  "bday" timestamp,
  "sex" varchar(1),
  "photo" varchar(256)
);

CREATE TABLE "public"."party_roster" (
  "party_id" int4 REFERENCES "public"."party" ("party_id"),
  "bio_id" varchar(256) REFERENCES "public"."individual" ("bio_id"),
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);
ALTER TABLE "public"."party_roster" ADD CONSTRAINT "party_roster_id" PRIMARY KEY ("party_id", "bio_id", "start_at");

CREATE TABLE "public"."individual_endorsement" (
  "bio_sen_id" varchar(512) PRIMARY KEY,
  "senate_id" varchar(256) NOT NULL DEFAULT '0',
  "bio_id" varchar(256) REFERENCES "public"."individual" ("bio_id"),
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);

CREATE OR REPLACE FUNCTION "public"."create_individual_endorsement_id"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
    BEGIN
      NEW.bio_sen_id := bio_id||'.'||senate_id;
      RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER "individual_endorsement_id" BEFORE INSERT OR UPDATE ON "public"."individual_endorsement"
FOR EACH ROW
EXECUTE PROCEDURE "public"."create_individual_endorsement_id"();

CREATE TYPE sponsor AS ENUM ('sponsor', 'cosponsor');
CREATE TYPE chamber AS ENUM ('house', 'senate');

CREATE TABLE "public"."document" (
  "doc_id" varchar(256) NOT NULL PRIMARY KEY,
  "committees" jsonb,
  "chamber_of_origin" chamber,
  "doc_type" varchar(64) NOT NULL,
  "start_at" timestamp NOT NULL
);

CREATE TABLE "public"."endorsement" (
  "bio_sen_id" varchar(512) REFERENCES "public"."individual_endorsement" ("bio_sen_id"),
  "doc_id" varchar(256) REFERENCES "public"."document" ("doc_id"),
  "sponsor" sponsor,
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);

CREATE TABLE "public"."document_history" (
  "record_id" SERIAL PRIMARY KEY,
  "doc_id" varchar(256) REFERENCES "public"."document" ("doc_id"),
  "classifier" varchar(64) NOT NULL,
  "data" jsonb,
  "start_at" timestamp
);

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

CREATE TRIGGER "congress_id" BEFORE INSERT OR UPDATE ON "public"."congress"
FOR EACH ROW
EXECUTE PROCEDURE "public"."create_congress_id"();

CREATE TABLE "public"."committee" (
  "committee_id" integer NOT NULL PRIMARY KEY,
  "parent_committee_id" integer,
	"name" varchar(256) NOT NULL,
	"type" varchar(256) NOT NULL
);

CREATE TABLE "public"."congress_roster" (
  "bio_id" varchar(256) NOT NULL REFERENCES "public"."individual" ("bio_id"),
  "committee_id" integer NOT NULL REFERENCES "public"."committee" ("committee_id"),
	"congress_id" varchar(256) NOT NULL REFERENCES "public"."congress" ("congress_id"),
  "start_at" timestamp NOT NULL,
	"end_at" timestamp
);
ALTER TABLE "public"."congress_roster" ADD CONSTRAINT "congress_roster_id" PRIMARY KEY ("bio_id", "committee_id", "congress_id","start_at");
