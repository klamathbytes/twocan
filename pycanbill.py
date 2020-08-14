import xmltodict
import json
import requests as req
from bs4 import BeautifulSoup
from sqlalchemy import Table, Column, MetaData, types, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import ForeignKey
import configparser



# config = configparser.ConfigParser()
# config.read(".env")
# pg_user = config["postgres"]["PGUSER"]
# pg_password = config["postgres"]["PGPASSWORD"]
# pg_database = "twocanpy"
# db_string = f"postgresql://{pg_user}:{pg_password}/@127.0.0.53:5432/{pg_database}"
# print(db_string)
# postgres_engine = create_engine(db_string)
# base = declarative_base()
# databaseMetaDAta = MetaData(postgres_engine)
# psql_session = (sessionmaker(postgres_engine))()
# base.metadata.create_all(postgres_engine)


congress_queue = [114,115,116]
sessions_queue = [1,2]

congress = None
session = None

roll_call_menues = []

for congress in congress_queue:
    for session in sessions_queue:
        try:
            roll_call_menu = f"https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_{congress}_{session}.xml"
            response = req.get(roll_call_menu)
            soup = BeautifulSoup(response.text, 'lxml')
            #print(response.text)
            json_data = json.dumps(xmltodict.parse(response.text))
            print(json_data)
            json_data = json.loads(json_data)
            roll_call_menues.append(json_data)
        except TypeError:
            print("error with",roll_call_menu)

print(roll_call_menues)        