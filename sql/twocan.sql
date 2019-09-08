CREATE DATABASE twocan;

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
  "senate_id" varchar(256) NOT NULL DEFAULT '0',
  "bio_id" varchar(256) REFERENCES "public"."individual" ("bio_id"),
  "start_at" timestamp NOT NULL,
  "end_at" timestamp
);
ALTER TABLE "public"."individual_endorsement" ADD CONSTRAINT "individual_endorsement_id" PRIMARY KEY ("senate_id", "bio_id", "start_at");

CREATE TABLE "public"."congress" (
  "congress_id" varchar(256) PRIMARY KEY,
  "meeting_id" integer NOT NULL,
  "session_id" integer NOT NULL,
  "start_at" timestamp NOT NULL,
  "end_at" timestamp NOT NULL
);

CREATE OR REPLACE FUNCTION "public"."congress_id"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
    BEGIN
      NEW.congress_id := meeting_id||'.'||session_id;
      RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

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
