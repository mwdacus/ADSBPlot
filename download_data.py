# =============================================================================
#  USGS/EROS Inventory Service Example
#  Python - JSON API
# 
#  Script Last Modified: 6/17/2020
#  Note: This example does not include any error handling!
#        Any request can throw an error, which can be found in the errorCode proprty of
#        the response (errorCode, errorMessage, and data properies are included in all responses).
#        These types of checks could be done by writing a wrapper similiar to the sendRequest function below
#  Usage: python download_data.py
# =============================================================================

import json
import requests
import sys
import time

# send http request
def sendRequest(url, data, apiKey = None):  
    json_data = json.dumps(data)
    
    if apiKey == None:
        response = requests.post(url, json_data)
    else:
        headers = {'X-Auth-Token': apiKey}              
        response = requests.post(url, json_data, headers = headers)    
    
    try:
      httpStatusCode = response.status_code 
      if response == None:
          print("No output from service")
          sys.exit()
      output = json.loads(response.text)	
      if output['errorCode'] != None:
          print(output['errorCode'], "- ", output['errorMessage'])
          sys.exit()
      if  httpStatusCode == 404:
          print("404 Not Found")
          sys.exit()
      elif httpStatusCode == 401: 
          print("401 Unauthorized")
          sys.exit()
      elif httpStatusCode == 400:
          print("Error Code", httpStatusCode)
          sys.exit()
    except Exception as e: 
          response.close()
          print(e)
          sys.exit()
    response.close()
    
    return output['data']

def DownloadData(downloadIds,download,filenames):
    downloadIds.append(download['downloadId'])
    r=requests.get(download['url'])
    filename=str(download['displayId'])+'.tif'
    filenames.append(filename)
    open('geotif/'+filename,'wb').write(r.content)
    print("DOWNLOAD: " + download['url'])
    return downloadIds, filename

def main(boxlat,boxlon,username,password):
    print("\nRunning Scripts...\n")
    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"
    # login
    payload = {'username' : username, 'password' : password} 
    apiKey = sendRequest(serviceUrl + "login", payload)
    print("API Key: " + apiKey + "\n")
    #define search area
    payload={
        "datasetName": "SRTM 1 Arc-Second Global",
        "spatialFilter": {
            "filterType": "mbr",
            "lowerLeft": {
                    "latitude": boxlat[0],
                    "longitude": boxlon[0]
            },
            "upperRight": {
                    "latitude": boxlat[1],
                    "longitude": boxlon[1]
            }
        }
    }               
    print("Searching datasets...\n")
    srtm = sendRequest(serviceUrl + "dataset-search", payload, apiKey)[0]
        
    payload = {'datasetName' : srtm['datasetAlias'], 
        'startingNumber' : 1, 
        'sceneFilter' : {
                        'spatialFilter' : payload['spatialFilter']
                        }}
    # Now I need to run a scene search to find data to download
    print("Searching scenes...\n\n")          
    scenes = sendRequest(serviceUrl + "scene-search", payload, apiKey)
    # Did we find anything?
    if scenes['recordsReturned'] > 0:
        # Aggregate a list of scene ids
        sceneIds = []
        for result in scenes['results']:
            # Add this scene to the list I would like to download
            sceneIds.append(result['entityId'])
        
        # Find the download options for these scenes
        # NOTE :: Remember the scene list cannot exceed 50,000 items!
        payload = {'datasetName' : srtm['datasetAlias'], 'entityIds' : sceneIds}
        downloadOptions = sendRequest(serviceUrl + "download-options", payload, apiKey)
        #Filter data to only include Geotiff data

        # Aggregate a list of available products
        downloads = []
        for product in downloadOptions:
                # Make sure the product is available for this scene
                if product['available'] == True and product['productName']=='GeoTIFF 1 Arc-second':
                        downloads.append({'entityId' : product['entityId'],
                                        'productId' : product['id']})
                        
        # Did we find products?
        if downloads:
            requestedDownloadsCount = len(downloads)
            # set a label for the download request
            label = "download-sample"
            payload = {'downloads' : downloads,
                                            'label' : label}
            # Call the download to get the direct download urls
            requestResults = sendRequest(serviceUrl + "download-request", payload, apiKey)                      
            # PreparingDownloads has a valid link that can be used but data may not be immediately available
            # Call the download-retrieve method to get download that is available for immediate download
            if requestResults['preparingDownloads'] != None and len(requestResults['preparingDownloads']) > 0:
                payload = {'label' : label}
                moreDownloadUrls = sendRequest(serviceUrl + "download-retrieve", payload, apiKey)
                downloadIds = []  
                filenames=[]
                for download in moreDownloadUrls['available']:
                    if str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']:
                        DownloadData(downloadIds,download,filenames)
                    
                for download in moreDownloadUrls['requested']:
                    if str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']:
                       DownloadData(downloadIds,download,filenames)
                    
                # Didn't get all of the reuested downloads, call the download-retrieve method again probably after 30 seconds
                while len(downloadIds) < (requestedDownloadsCount - len(requestResults['failed'])): 
                    preparingDownloads = requestedDownloadsCount - len(downloadIds) - len(requestResults['failed'])
                    print("\n", preparingDownloads, "downloads are not available. Waiting for 30 seconds.\n")
                    time.sleep(30)
                    print("Trying to retrieve data\n")
                    moreDownloadUrls = sendRequest(serviceUrl + "download-retrieve", payload, apiKey)
                    for download in moreDownloadUrls['available']:                            
                        if download['downloadId'] not in downloadIds and (str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']):
                            DownloadData(downloadIds,download,filenames)          
            else:
                # Download geotiff files 
                for download in requestResults['availableDownloads']:
                    DownloadData(downloadIds,download,filenames)
                print("\nAll downloads are available to download.\n")

        #return geotiff filenames
        return filenames
    else:
        print("Search found no results.\n")
                
    # Logout so the API Key cannot be used anymore
    endpoint = "logout"  
    if sendRequest(serviceUrl + endpoint, None, apiKey) == None:        
        print("Logged Out\n\n")
    else:
        print("Logout Failed\n\n")            

if __name__ == '__main__': 
    #sample problem (denver area)
    boxlat=[39.5, 40.5]
    boxlon=[-105.5, -104.5]
    username="username" #enter username and password here
    password="password" 
    filenames=main(boxlat,boxlon,username,password)