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

def get_data(session,url,query,headers=None):
    try:
        response = (session.get(url+query,headers=headers)).json()
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

def upload_file(url_file,folder_up,viz_id2,url=url_api,gis=get_gis(),session=get_session(),headers=None):
    try:
        # Get metadata from api
        query = '?viz_id2=eq."' + viz_id2 + '"'
        data = get_data(session,url,query,headers)
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

def publish_file(id,url=url_api,gis=get_gis(),session=get_session()):
    try:
        # Get metadata from api
        query = '?shp_id=eq.' + id
        data = get_data(session,url,query,headers)
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

def create_view(id,folder,url=url_api,gis=get_gis(),session=get_session()):
    try:
        # Get metadata from api
        query = '?pub_id=eq.' + id
        data = get_data(session,url,query,headers)
        metadata = data[0]

        # Get item/layer
        feature_item = gis.content.get(id)

        source_flc = FeatureLayerCollection.fromitem(feature_item)

        new_view = source_flc.manager.create_view(name='WrOnRnYpNWBRfhErxvQF')

        new_view.move(folder)

        new_view_id = new_view.id

        view_search = gis.content.get(new_view_id)

        view_search.update(metadata['properties_flw'])

        view_flc = FeatureLayerCollection.fromitem(view_search)

        service_layer = view_flc.layers[0]

        ## Atualiza metadata do layer
        # update_dict = {"viewDefinitionQuery" : "error = ''"}
        # service_layer.manager.update_definition(update_dict)
        service_layer.manager.update_definition(metadata['properties_l'])

        ## Categoriza o feature service
        gis.content.categories.assign_to_items(items = [{new_view_id : {"categories" : metadata['categories']}}])

        new_view.share(org = True, everyone = True)
    except Exception as error:
        print('1')
    else:
        print(f"{new_view_id}")

def tr_fields(id,idvw=None,url=url_api,gis=get_gis(),session=get_session()):
    try:
        # Get metadata from api
        # query = '?pub_id=eq.' + id
        query = '?or=(pub_id.eq.' + id + ',view_id.eq.' + id + ')'
        data = get_data(session,url,query,headers)
        metadata = data[0]

        if metadata['pub_id'] == id:
            print(f"Update fields Feature layer hosted: {id} {metadata['class_ftname']}")

        if metadata['view_id'] == id:
            print(f"Update fields Feature layer hosted view: {id} {metadata['class_ftname']}")

        # Get item/layer
        feature_item = gis.content.get(id)
        feature_layer = feature_item.layers[0]

        #  Drop fields
        delete_fields = [{"name": field["name"]} for field in feature_layer.properties.fields if (field["type"] not in ('esriFieldTypeOID','esriFieldTypeGlobalID') and field["name"] not in ('Shape__Area','Shape__Length') and  field["name"] not in (metadata['nodel_fields']) )]

        if delete_fields:
            print(f"Delete fields: {delete_fields}")
            feature_layer.manager.delete_from_definition({"fields": delete_fields })
            feature_layer._refresh()
        else:
            print(f"No fields to delete.")

        # Inicializa listas/dict auxiliares
        old_fields = [dict(field) for field in feature_layer.properties.fields if (field["name"] in (metadata['tr_dict']).keys() and field["alias"] != metadata['tr_dict'][field["name"]]) ]
        new_fields = []

        if old_fields:
            # Append listas/dict
            for idx, old_field in enumerate(old_fields):
                print(f"Update alias: {old_field['alias']} -> {metadata['tr_dict'][old_field['name']]}")
                new_field = deepcopy(old_field)
                new_field['alias'] = metadata['tr_dict'][old_field["name"]]
                new_fields.append(new_field)

            # Update campos
            new_fields_add = feature_layer.manager.update_definition({"fields": new_fields})
        else:
            print(f"No aliases to update.")

        update_metadata(id,url,gis,session,headers)

        feature_item.share(org = True, everyone = True, groups = ["82b5c771d36f47a6939b95f1a8ae8f81"])

        # Add building=yes se não existir class ou building
        if metadata['class_ftname'] == 'building' and 'class' not in [field["name"] for field in feature_layer.properties.fields] and 'building' not in [field["name"] for field in feature_layer.properties.fields]:
            print('Add building=yes.')
            add_field = [
            {
            "name": "building",
            "type": "esriFieldTypeString",
            "actualType": "nvarchar",
            "alias": "building",
            "sqlType": "sqlTypeNVarchar",
            "length": 3,
            "nullable": True,
            "editable": True,
            "defaultValue": 'yes'
            }]
            feature_layer.manager.add_to_definition({"fields": add_field})

            ## building=yes
            expressions = []
            expressions.append({"field": "building","value": "yes",})
            feature_layer.calculate(where="1=1", calc_expression=expressions)
        else:
            print(f"Not added building=yes.")

    except Exception as error:
        print('1 ', error)
    else:
        print(f"Update completed.")

def update_metadata(id,url=url_api,gis=get_gis(),session=get_session(),headers=None):
    try:
        query = '?or=(shp_id.eq.' + id + ',pub_id.eq.' + id + ')'
        data = get_data(session,url,query,headers)
        metadata = data[0]
        feature_item = gis.content.get(id)

        if metadata['shp_id'] == id:
            print(f"Update metadata Shapefile: {id}")
            feature_item.update(item_properties = metadata['properties_fl'])

        if metadata['pub_id'] == id:
            print(f"Update metadata hosted Feature layer: {id}")
            feature_item.update(item_properties = metadata['properties_flw'])

            print(f"Update metadata hosted Feature layer sublayer")
            # Atualiza metadata do layer
            feature_layer = feature_item.layers[0]
            feature_layer.manager.update_definition(metadata['properties_l'])

        print(f"Update categories.")
        # Categoriza o feature service
        gis.content.categories.assign_to_items(items = [{id : {"categories" : metadata['categories']}}])
    except Exception as error:
        print('Error.', error)
    else:
        print(f"Update completed. See https://addressforall.maps.arcgis.com/home/item.html?id={id}")

def update_share(id,org = True, everyone = False, groups = ["82b5c771d36f47a6939b95f1a8ae8f81"],gis=get_gis()):
    try:
        feature_item = gis.content.get(id)
        feature_item.share(org = org, everyone = everyone, groups = groups)
    except Exception as error:
        print('Error.', error)
    else:
        print(f"Update completed. See https://addressforall.maps.arcgis.com/home/item.html?id={id}")

def add_value_building(id,chunk=1000,addfield=False,url=url_api,gis=get_gis(),session=get_session()):
    try:
        # Get metadata from api
        query = '?pub_id=eq.' + id
        data = get_data(session,url,query,headers)
        metadata = data[0]
        # Get item/layer
        feature_item = gis.content.get(id)
        feature_layer = feature_item.layers[0]
        features = feature_layer.query()


        # Add building=yes se não existir class ou building
        if addfield and metadata['class_ftname'] == 'building' and 'class' not in [field["name"] for field in feature_layer.properties.fields] and 'building' not in [field["name"] for field in feature_layer.properties.fields]:
            print('Add building=yes.')
            add_field = [
            {
            "name": "building",
            "type": "esriFieldTypeString",
            "actualType": "nvarchar",
            "alias": "building",
            "sqlType": "sqlTypeNVarchar",
            "length": 3,
            "nullable": True,
            "editable": True,
            "defaultValue": 'yes'
            }]
            feature_layer.manager.add_to_definition({"fields": add_field})

            ## building=yes
            # expressions = []
            # expressions.append({"field": "building","value": "yes",})
            # feature_layer.calculate(where="1=1", calc_expression=expressions)
        else:
            print(f"Not added building=yes.")

        # Add building=yes se não existir class ou building
        if metadata['class_ftname'] == 'building':
            print(f'Add building=yes in {len(features)}')
            fs = features.to_dict()
            fss = fs["features"]
            edits = []
            for f in fss:
                f["attributes"].update({"building" : "yes"})
                edits.append(f)
            chunked_list = list()
            chunk_size = chunk
            for i in range(0, len(edits), chunk_size):
                chunked_list.append(edits[i:i+chunk_size])
            for i in range(0, len(chunked_list)):
                print(f'Update chunk {i} of {len(chunked_list)}.')
                feature_layer.edit_features(updates=chunked_list[i])
        else:
            print(f"Not building layer.")
    except Exception as error:
        print('1 ', error)
    else:
        print(f"Completed.")
