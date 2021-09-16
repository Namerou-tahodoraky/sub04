from flask import Flask, request, jsonify
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello world Flask"
# 
# @app.route('/', methods=['POST'])
# def post_json():
#     json = request.get_json()  # POSTされたJSONを取得
#     return jsonify(json)  # JSONをレスポンス

from src import RefineDetDetectorCpu
setting_file = "/app/src/setting.json"
detector = RefineDetDetectorCpu(setting_file)
detector.load_model()
detector.set_transformer()

@app.route("/", methods=["POST"])
def example():
    print("flask")
    print("request.data", request.data)
    # print("request.files", request.files, type(request.files))
    # print(request.files["uploadFile"].filename)
    # print(dir(request.files["uploadFile"]))
    # print(request.files["uploadFile"])
    # print(request.files["uploadFile"].stream)
    print("request.files", type(request.files))
    files = (request.files.items())
    
    for f in files:
        image_binary = f[1].read()
        det_results = detector.inference(image_binary)
        
    return jsonify(det_results)


if __name__ == "__main__":
    app.run()
