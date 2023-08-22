import os
import requests
import sys
from arcgis.gis import GIS
from arcgis     import features
from dotenv     import load_dotenv

load_dotenv()

username = os.getenv("ARCGIS_USERNAME")
password = os.getenv("ARCGIS_PASSWORD")
url_argis = os.getenv("ARCGIS_URL")
url_api = os.getenv("API_URL")
headers = {'Accept': 'application/json'}

def get_session():
    session = requests.session()

    return session

def get_data(session,url_api,query,headers=None):
    try:
        response = (session.get(url_api+query,headers=headers)).json()
    except Exception as error:
        response = []
        print ('Error.', error)

    return response

try:
    session = get_session()
except Exception as error:
    print('Error. Api offline.', error)

if len(sys.argv) > 1:
    for layerid in sys.argv[1:]:
        print(f"Id: {layerid}")
        query = '?viz_id=eq.' + layerid
        data = get_data(session,url_api,query,headers)

        if data:
            # print(f"API metadata: {data}")

            try:
                gis = GIS(url_argis,username,password)
                get_result = gis.content.get(layerid)

                matadata = data[0]

                get_result.update(item_properties = {"title" : matadata['title'], "snippet" : matadata['snippet'], "description" : matadata['description'], "licenseInfo" : matadata['licenseinfo'], "accessInformation" : matadata['accessinformation'], "tags" : matadata['tags']})
                gis.content.categories.assign_to_items(items = [{layerid : {"categories" : matadata['categories']}}])

            except Exception as error:
                print('Error.', error)
            else:
                print('Update metadata of ', layerid)

        else:
            print(f"Error. No API data for id: {layerid}")
else:
    print("Error. No id!")
