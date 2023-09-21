import os
import requests
import sys
from arcgis.gis import GIS
from arcgis.features import FeatureLayerCollection
from arcgis     import features
from dotenv     import load_dotenv
from copy       import deepcopy

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

def get_gis(url=url_argis,user=username,passw=password):
    gis = GIS(url,user,passw)
    return gis

def create_folder(folder,gis):
    try:
        gis.content.create_folder(folder,owner=user)
    except Exception as error:
        print('Error.', error)
    else:
        print(f"Folder {folder} created.")

def upload_file(url_file,folder_up,viz_id2,gis=get_gis(),session = get_session(),headers=None):
    try:
        # Get metadata from api
        query = '?viz_id2=eq."' + viz_id2 + '"'
        data = get_data(session,url_api,query,headers)
        metadata = data[0]

        # Set type
        metadata['properties_fl']['type'] = "Shapefile"

        # Upload ESRI
        shp_item = gis.content.add(item_properties = metadata['properties_fl'], data=url_file, folder=folder_up)

        # Cria thumbnail
        shp_item.create_thumbnail(True)

        # Atualiza permissões
        shp_item.share(org = True, allow_members_to_edit = True)

        # ID do shapefile na ESRI
        shp_item_id = shp_item.id

        gis.content.categories.assign_to_items(items = [{shp_item_id : {"categories" : metadata['categories']}}])
    except Exception as error:
        print('1')
    else:
        print(f"{shp_item_id}")

def publish_file(id,gis=get_gis(),session = get_session()):
    try:
        # Get metadata from api
        query = '?shp_id=eq.' + id
        data = get_data(session,url_api,query,headers)
        metadata = data[0]

        # Categoriza o shapefile
        shp_item = gis.content.get(id)

        # Publicação, cria um feature service
        publish_item = shp_item.publish()

        # Atualiza permissões
        # publish_item.share(org = True, groups = ["82b5c771d36f47a6939b95f1a8ae8f81"])
        publish_item.share(org = True)

        # ID do feature service
        item_publish_id = publish_item.id

        # Categoriza o feature service
        gis.content.categories.assign_to_items(items = [{item_publish_id : {"categories" : metadata['categories']}}])

        # Atualiza metadata do layer
        feature_layer = publish_item.layers[0]
        feature_layer.manager.update_definition(metadata['properties_l'])
    except Exception as error:
        print('1')
    else:
        print(f"{item_publish_id}")

def create_view(id,folder="filtered2osm",gis=get_gis(),session = get_session()):
    try:
        # Get metadata from api
        query = '?pub_id=eq.' + id
        data = get_data(session,url_api,query,headers)
        metadata = data[0]

        # Get item/layer
        feature_item = gis.content.get(id)

        source_flc = FeatureLayerCollection.fromitem(feature_item)

        new_view = source_flc.manager.create_view(name='WrOnRnYpNWBRfhErxvQF')

        new_view.move(folder)

        new_view.share(org = True, everyone = True)

        new_view_id = new_view.id

        view_search = gis.content.get(new_view_id)

        view_search.update(metadata['properties_flw'])

        view_flc = FeatureLayerCollection.fromitem(view_search)

        service_layer = view_flc.layers[0]

        ## Atualiza metadata do layer
        # update_dict = {"viewDefinitionQuery" : "error = ''"}
        #
        # service_layer.manager.update_definition(update_dict)
        service_layer.manager.update_definition(metadata['properties_l'])

        ## Categoriza o feature service
        gis.content.categories.assign_to_items(items = [{new_view_id : {"categories" : metadata['categories']}}])

    except Exception as error:
        print('1')
    else:
        print(f"{new_view_id}")

def tr_fields(id,idvw=None,gis=get_gis(),session = get_session()):
    try:
        # Get metadata from api
        # query = '?pub_id=eq.' + id
        query = '?or=(pub_id.eq.' + id + ',view_id.eq.' + id + ')'

        data = get_data(session,url_api,query,headers)
        metadata = data[0]

        # Get item/layer
        feature_item = gis.content.get(id)
        feature_layer = feature_item.layers[0]

        # Inicializa listas/dict auxiliares
        old_fields = [dict(field) for field in feature_layer.properties.fields if field["name"] in (metadata['tr_dict']).keys()]
        new_fields = []

        # Append listas/dict
        for idx, old_field in enumerate(old_fields):
            new_field = deepcopy(old_field)
            new_field['alias'] = metadata['tr_dict'][old_field["name"]]
            new_fields.append(new_field)

        # Update campos
        new_fields_add = feature_layer.manager.update_definition({"fields": new_fields})
    except Exception as error:
        print('1 ', error)
    else:
        print('0')

def update_metadata(session,url_api,headers=None):
        print(f"Id: {layerid}")
        query = '?viz_id=eq.' + layerid
        data = get_data(session,url_api,query,headers)

        if data:
            try:
                gis = GIS(url_argis,username,password)
                get_result = gis.content.get(layerid)

                matadata = data[0]

                get_result.update(item_properties = {"title" : matadata['title'], "snippet" : matadata['snippet'], "description" : matadata['description'], "licenseInfo" : matadata['licenseinfo'], "accessInformation" : matadata['accessinformation'], "tags" : matadata['tags']})
                gis.content.categories.assign_to_items(items = [{layerid : {"categories" : matadata['categories']}}])

            except Exception as error:
                print('Error.', error)
            else:
                print(f"Updated metadata. See https://addressforall.maps.arcgis.com/home/item.html?id={layerid}")

        else:
            print('Not updated. Api without metadata.')

for layerid in sys.argv[1:]:
    update_metadata(session,url_api,headers)
# try:
#     session = get_session()
# except Exception as error:
#     print('Error. No ssession.', error)
#
# if len(sys.argv) > 1:
#     for layerid in sys.argv[1:]:
#         update_metadata(session,url_api,headers)
# else:
#     print("Error. No id!")
