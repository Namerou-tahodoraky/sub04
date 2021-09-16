import requests
import json

MIMETYPE = "image/png"

# <form action="/data/upload" method="post" enctype="multipart/form-data">
#   <input type="file" name="uploadFile"/>
#   <input type="submit" value="submit"/>
# </form>

# main
if __name__ == "__main__":

    fileName = 'images/000456.jpg'
    with open(fileName, 'rb') as f:
        fileDataBinary = f.read()
    # files = {'uploadFile': (fileName, fileDataBinary, XLSX_MIMETYPE)}
    # files = {'uploadFile': (fileName, fileDataBinary, MIMETYPE)}

    # url = 'http://localhost:58080'
    # response = requests.post(url, files=files)

    url = 'http://localhost:58080'
    # headers = {"Content-Type": "application/octet-stream"}
    # files = {'uploadFile': (fileName, open(fileName, 'rb'), MIMETYPE)}
    files = {'uploadFile': fileDataBinary}
    response = requests.post(url, files=files)

    print(response.status_code)
    print(response.content)

