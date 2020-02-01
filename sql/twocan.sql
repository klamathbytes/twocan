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
DROP TYPE IF EXISTS idtype;
CREATE TYPE idtype AS ENUM ('bio_id', 'senate_id', 'committee_id');

DROP TABLE IF EXISTS "public"."document";
CREATE TABLE "public"."document" (
  "doc_id" varchar(256) NOT NULL PRIMARY KEY,
  "committees" jsonb,
  "chamber_of_origin" chamber,
  "doc_type" varchar(64), --NOT NULL,
  "action_date" timestamp --,
);

DROP TABLE IF EXISTS "public"."endorsement";
CREATE TABLE "public"."endorsement" (
  "id_type" idtype,
  "id" varchar(512),
  "sponsor" sponsor,
	"raw_id" int REFERENCES "public"."raw"("raw_id")	
);

CREATE INDEX idx_endorsement_raws ON "public"."endorsement"(raw_id);
CREATE INDEX idx_id ON "public"."endorsement" (id);
CREATE INDEX idx_id_type ON "public"."endorsement" (id_type);

DROP TABLE IF EXISTS "public"."document_history";
CREATE TABLE "public"."document_history" (
  "raw_id" int PRIMARY KEY,
  "doc_id" varchar(256) REFERENCES "public"."document" ("doc_id"),
  "doc_type" varchar(64), --NOT NULL,
  "data" jsonb,
  "action_date" timestamp
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
  "committee_id" varchar(256) PRIMARY KEY,
  "parent_committee_id" integer,
  "name" varchar(256) NOT NULL,
	"type" varchar(256)
);

DROP TABLE IF EXISTS "public"."congress_roster";
CREATE TABLE "public"."congress_roster" (
  "bio_id" varchar(256) NOT NULL REFERENCES "public"."individual" ("bio_id"),
  "committee_id" varchar(256) NOT NULL REFERENCES "public"."committee" ("committee_id"),
	"congress_id" varchar(256) NOT NULL REFERENCES "public"."congress" ("congress_id"),
  "start_at" timestamp NOT NULL,
	"end_at" timestamp
);
ALTER TABLE "public"."congress_roster" ADD CONSTRAINT "congress_roster_id" PRIMARY KEY ("bio_id", "committee_id", "congress_id","start_at");


--[01.31.2020]_unwrap_data_function
CREATE OR REPLACE FUNCTION unwrap_bills() RETURNS void 
AS $$
		BEGIN
					RAISE NOTICE 'TRUNCATING TABLES...';
					RAISE NOTICE '...endorsement...:';
					TRUNCATE TABLE "public"."endorsement" CASCADE;
					
					RAISE NOTICE '...committee...:';
					TRUNCATE TABLE "public"."committee" CASCADE;
					
					RAISE NOTICE '...document_history...:';
					TRUNCATE TABLE "public"."document_history" CASCADE;
					
					RAISE NOTICE '...document...:';
					TRUNCATE TABLE "public"."document" CASCADE;
					
					RAISE NOTICE 'POPULATING document...';
					INSERT INTO "public"."document"
					(doc_id, action_date)

					SELECT doc_id, MIN(start_at)
					FROM 
					(
							SELECT raw_id, 
								doc_type, 
								MIN(start_at) as start_at, 
								raw_data,
								doc_id
							FROM
							(
								SELECT  raw_id, raw_data,
									replace(
										replace(
											replace(COALESCE(prefix1,prefix2) || COALESCE(suffix1, suffix2), '"',''), 
											'CONGRESS', ''),
										'One Hundred Sixteenth Congress of the United States of America', '116th ') 
									as doc_id, 
									doc_type, COALESCE(start_at,start_at_2) as start_at 
								FROM 
								(
									SELECT raw_id,
										jsonb_path_query(raw_data, '$.**.congress.\#text')::text as prefix1,
										jsonb_path_query(raw_data, '$.**.congress')::text as prefix2,
										jsonb_path_query(raw_data, '$.**.legis\-num.\#text')::text as suffix1,
										jsonb_path_query(raw_data, '$.**.legis\-num')::text as suffix2,
										jsonb_path_query(raw_data, '$.**.legis\-type')::text as doc_type,
										raw_data,
										jsonb_path_query(raw_data, '$.**[*].action[0].*.\@date')::text::DATE as "start_at",
										jsonb_path_query(raw_data, '$.**[*].attestation\-group.*.\@date')::text::DATE as "start_at_2"
									FROM raw 
								) as temp
							) as form
							GROUP BY raw_id, raw_data,doc_id,doc_type
					) as docs
					GROUP BY doc_id;
				
				RAISE NOTICE 'POPULATING document_history...';
				
				INSERT INTO "public"."document_history"
				(raw_id, doc_id, doc_type, data, action_date)

				SELECT raw_id, doc_id, doc_type, raw_data, action_date
				FROM 
				(
						SELECT raw_id, 
						doc_type, 
						MIN(start_at) as action_date, 
						raw_data,
						doc_id
						FROM
						(
							SELECT  raw_id, raw_data,
								replace(
									replace(
										replace(COALESCE(prefix1,prefix2) || COALESCE(suffix1, suffix2), '"',''), 
										'CONGRESS', ''),
									'One Hundred Sixteenth Congress of the United States of America', '116th ') 
								as doc_id, 
								doc_type, 
								COALESCE(start_at,start_at_2) as start_at
							FROM 
							(
								SELECT raw_id,
									jsonb_path_query(raw_data, '$.**.congress.\#text')::text as prefix1,
									jsonb_path_query(raw_data, '$.**.congress')::text as prefix2,
									jsonb_path_query(raw_data, '$.**.legis\-num.\#text')::text as suffix1,
									jsonb_path_query(raw_data, '$.**.legis\-num')::text as suffix2,
									jsonb_path_query(raw_data, '$.**.legis\-type')::text as doc_type,
									raw_data,
									jsonb_path_query(raw_data, '$.**[*].action[0].*.\@date')::text::DATE as "start_at",
									jsonb_path_query(raw_data, '$.**[*].attestation\-group.*.\@date')::text::DATE as "start_at_2"
								FROM raw 
							) as temp
						) as form
						GROUP BY raw_id, raw_data, doc_id, doc_type
				) as docs;

			RAISE NOTICE 'POPULATING endorsement...';
			RAISE NOTICE '...senate_id, sponsors...';
			
			INSERT INTO "public"."endorsement"
			( "id_type","id", "sponsor", "raw_id")

			SELECT 'senate_id'::idtype, sponsor as "id", 'sponsor'::sponsor , raw_id
			FROM 
			(
					SELECT raw_id, 
					sponsor
					FROM
					(
						SELECT  raw_id, 
						 replace(sponsor::text,'"','') as sponsor
						FROM 
						(
							SELECT raw_id,
								raw_data,
								jsonb_path_query(raw_data, '$.**[*].action[*].action\-desc.sponsor.\@name\-id') as sponsor
							FROM raw 
						) as raw_data
					) as individual
					WHERE sponsor IS NOT NULL
					GROUP BY sponsor, raw_id
			) as docs
			WHERE  sponsor SIMILAR TO 'S(1|2|3|4|5|6|7|8|9)%';
				
			RAISE NOTICE '...bio_id, sponsors...';
			
			INSERT INTO "public"."endorsement"
			( "id_type","id", "sponsor", "raw_id")

			SELECT 'bio_id'::idtype ,sponsor as "id", 'sponsor'::sponsor, raw_id
			FROM 
			(
					SELECT raw_id, 
					sponsor
					FROM
					(
						SELECT  raw_id, replace(sponsor::text,'"','') as sponsor
						FROM 
						(
							SELECT raw_id,
								jsonb_path_query(raw_data, '$.**[*].action[*].action\-desc.sponsor.\@name\-id') as sponsor
							FROM raw 
						) as temp
					) as form
					GROUP BY sponsor, raw_id
			) as docs
			WHERE sponsor ilike '_0%';

			RAISE NOTICE '...senate_id, cosponsors...';
			
			INSERT INTO "public"."endorsement"
			( "id_type","id", "sponsor", "raw_id")

			SELECT 'senate_id'::idtype ,sponsor as "id", 'cosponsor'::sponsor , raw_id
			FROM 
			(
					SELECT raw_id, 
					sponsor
					FROM
					(
						SELECT  raw_id, 
						 replace(sponsor::text,'"','') as sponsor
						FROM 
						(
							SELECT raw_id,
								raw_data,
								jsonb_path_query(raw_data, '$.**[*].action[*].action\-desc.cosponsor.\@name\-id') as sponsor
							FROM raw 
						) as raw_data
					) as individual
					WHERE sponsor IS NOT NULL
					GROUP BY sponsor, raw_id
			) as docs
			WHERE sponsor SIMILAR TO 'S(1|2|3|4|5|6|7|8|9)%';

			RAISE NOTICE '...bio_id, cosponsors...';
			
			INSERT INTO "public"."endorsement"
			( "id_type","id", "sponsor", "raw_id")

			SELECT 'bio_id'::idtype ,sponsor as "id", 'cosponsor'::sponsor , raw_id
			FROM 
			(
					SELECT raw_id, 
					sponsor
					FROM
					(
						SELECT  raw_id, 
						 replace(sponsor::text,'"','') as sponsor
						FROM 
						(
							SELECT raw_id,
								jsonb_path_query(raw_data, '$.**[*].action[*].action\-desc.cosponsor.\@name\-id') as sponsor
							FROM raw 
						) as raw_data
					) as individual
					WHERE sponsor IS NOT NULL
					GROUP BY sponsor, raw_id
			) as docs
			WHERE sponsor ilike '_0%';

			RAISE NOTICE '...committeee, sponsors...';
			
			INSERT INTO "public"."endorsement"
			( "id_type","id", "sponsor", "raw_id")

			SELECT 'committee_id'::idtype ,sponsor as "id", 'sponsor'::sponsor , raw_id
			FROM 
			(
					SELECT raw_id, 
					sponsor
					FROM
					(
						SELECT  raw_id, 
						 replace(sponsor::text,'"','') as sponsor
						FROM 
						(
							SELECT raw_id,
								replace(
									jsonb_path_query(raw_data, '$.**[*].action[*].*.*.\@committee\-id')::text, 
									'"','') as "sponsor"	
							FROM raw 
						) as raw_data
					) as committees
					WHERE sponsor IS NOT NULL
					GROUP BY sponsor, raw_id
			) as docs;
			
			RAISE NOTICE 'BUILDING committee_data CTE...';
			RAISE NOTICE 'AND POPULATING comittee with committee_data CTE...';

			WITH committee_data AS (
					SELECT committee_id, replace(replace(committee,'Committee on ', ''), 'Committees on ', '') as committee, raw_id
						FROM 
						(
								SELECT raw_id, 
								committee_id,
								committee
								FROM
								(
									SELECT  raw_id, 
									 replace(replace(committee::text,'"',''), '\n                    ',' ') as committee,
									 replace(committee_id::text,'"','') as committee_id
									FROM 
									(
										SELECT raw_id,
											replace(
												jsonb_path_query(raw_data, '$.**[*].action[*].*.committee\-name.\@committee\-id')::text, 
												'"','') as "committee_id",
											replace(
												jsonb_path_query(raw_data, '$.**[*].action[*].*.committee\-name.\#text')::text,
												'"','') as "committee"		
										FROM raw 
									) as raw_data
								) as committees
						) as docs
			)
			
			
			
			INSERT INTO "public"."committee"
			( "committee_id","name")

			SELECT committees_list.committee_id, committees_list.committee
			FROM (
						SELECT committee_id, MAX(footprint) as weighted_footprint
						FROM (
									SELECT  committee_id, committee, count(raw_id) as footprint
									FROM committee_data
									GROUP BY committee_id, committee
									) as weighted_data
						GROUP BY committee_id
						) weighted_committees
			JOIN (
						SELECT  committee_id, committee, count(raw_id) as footprint
						FROM committee_data
						GROUP BY committee_id, committee
						) as committees_list
			ON weighted_committees.committee_id = committees_list.committee_id
			AND weighted_committees.weighted_footprint = committees_list.footprint;

			RAISE NOTICE 'DONE';
			
		END;
$$ LANGUAGE plpgsql;