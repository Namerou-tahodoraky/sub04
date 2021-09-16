import requests

MIMYTYPE = "image/png"

# <form action="/data/upload" method="post" enctype="multipart/form-data">
#   <input type="file" name="uploadFile"/>
#   <input type="submit" value="submit"/>
# </form>

# main
if __name__ == "__main__":

    fileName = 'images/000456.jpg'
    fileDataBinary = open(fileName, 'rb').read()
    # files = {'uploadFile': (fileName, fileDataBinary, XLSX_MIMETYPE)}
    files = {'uploadFile': (fileName, fileDataBinary, MIMETYPE)}

    # url = 'http://localhost:3000/data/upload'
    url = 'http://localhost'
    response = requests.post(url, files=files)

    print(response.status_code)
    print(response.content)
