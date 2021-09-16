import os
from .BaseDetecter import AbstractDetector
from .RefinedetExceptions import RefinedetSettingFileError, RefinedetClassDefineError

# import argparse
# import os
# import sys
# import matplotlib.pyplot as plt
# import skimage.io as io


# from google.protobuf import text_format
# from caffe.proto import caffe_pb2

import numpy as np
import caffe
import skimage

class RefineDetDetectorCpu(AbstractDetector):
    def __init__(self, setting_file: str) -> None:
        super().__init__(setting_file)
        self.net_def_filepath: str = ""
        self.input_image_size: int = 0
        self.net = None
        self.transformer = None

        # caffeはモデル読み込みにdeploy.prototxtが必要
        net_def_filepath = self.unique_settings.get("NetworkDefineFile")
        if not isinstance(net_def_filepath, str):
            raise RefineDetSettingFileError("UniqueSettings内にNetworkDefineFileキーがないか、NetworkDefineFileキーの値の型がstrになっていません。")
        self.net_def_filepath = net_def_filepath

        # RefineDetの入力解像度は320か512のどちらかのみ
        input_image_size = self.unique_settings.get("InputImageSize")
        if not isinstance(input_image_size, int):
            raise RefineDetSettingFileError("UniqueSettings内にInputImageSizeキーがないか、InputImageSizeキーの値の型がintになっていません。")
        if input_image_size != 512 and input_image_size != 320:
            raise RefineDetSettingFileError("InputImageSizeキーの値に512と320以外の値が設定されています。")
        self.input_image_size = input_image_size

    def load_model(self) -> None:
        if not os.path.isfile(self.model_path):
            raise RefineDetSettingFileError(f"{self.model_path}が存在しない.")
        if not os.path.isfile(self.net_def_filepath):
            raise RefineDetSettingFileError(f"{self.net_def_filepath}が存在しない.")
        net = caffe.Net(self.net_def_filepath, self.model_path, caffe.TEST)
        net.blobs['data'].reshape(1, 3, self.input_image_size, self.input_image_size)
        self.net = net

    def set_transformer(self) -> None:
        transformer = caffe.io.Transformer({'data': self.net.blobs['data'].data.shape})
        transformer.set_transpose('data', (2, 0, 1))
        transformer.set_mean('data', np.array([104, 117, 123]))  # mean pixel
        transformer.set_raw_scale('data', 255)  # the reference model operates on images in [0,255] range instead of [0,1]
        transformer.set_channel_swap('data', (2, 1, 0))  # the reference model has channels in BGR order instead of RGB
        self.transformer = transformer

    # def inference(self, image_file):
    #     image = caffe.io.load_image(image_file)
    # def inference(self, image, out_path):
    #     # image = image[[2, 1, 0], :, :]
    #     # image = image.astype(np.float32) / 255.0
    #     image = skimage.img_as_float(image).astype(np.float32)
    #     print(image.max(), image.min())
    # def inference(self, image: bytes, out_path: str) -> list[dict]:
    #     # image = caffe.io.load_image(image_file)
    def inference(self, image: bytes) -> list[dict]:
        image = skimage.img_as_float(skimage.io.imread(image, plugin='imageio')).astype(np.float32)



        transformed_image = self.transformer.preprocess('data', image)
        self.net.blobs['data'].data[...] = transformed_image

        detections = self.net.forward()['detection_out']
        det_label = detections[0, 0, :, 1]
        det_conf = detections[0, 0, :, 2]
        det_xmin = detections[0, 0, :, 3] * image.shape[1]
        det_ymin = detections[0, 0, :, 4] * image.shape[0]
        det_xmax = detections[0, 0, :, 5] * image.shape[1]
        det_ymax = detections[0, 0, :, 6] * image.shape[0]
        result = np.column_stack([det_xmin, det_ymin, det_xmax, det_ymax, det_conf, det_label])
        print(result.astype(np.int8))
        det_list: list[dict] = []
        for xmin, ymin, xmax, ymax, conf, label in result:
            try:
                class_name = self.class_names[int(label)]
            except Exception:
                raise RefinedetClassDefineError(self.num_classes, int(label))
            if conf < self.confidence_threshes[class_name]:
                continue
            print(xmin, ymin, xmax, ymax, conf, class_name)
            det_list.append(
                {
                    "LeftTopX": int(xmin),
                    "LeftTopY": int(ymin),
                    "RightBottomX": int(xmax),
                    "RightBottomY": int(ymax),
                    "ClassName": class_name,
                    "Confidence": conf,
                }
            )
        ShowResults(image, "000456.jpg", result, self.num_classes, save_fig=True)
        return det_list
            

import matplotlib.pyplot as plt

def ShowResults(img, image_name, results, num_classes, threshold=0.6, save_fig=False):
    plt.clf()
    plt.imshow(img)
    plt.axis('off')
    ax = plt.gca()

    # num_classes = len(labelmap.item) - 1
    colors = plt.cm.hsv(np.linspace(0, 1, num_classes)).tolist()

    for i in range(0, results.shape[0]):
        score = results[i, -2]
        if threshold and score < threshold:
            continue

        label = int(results[i, -1])
        # name = get_labelname(labelmap, label)[0]
        name = f"{label:03}"
        color = colors[label % num_classes]

        xmin = int(round(results[i, 0]))
        ymin = int(round(results[i, 1]))
        xmax = int(round(results[i, 2]))
        ymax = int(round(results[i, 3]))
        coords = (xmin, ymin), xmax - xmin, ymax - ymin
        ax.add_patch(plt.Rectangle(*coords, fill=False, edgecolor=color, linewidth=3))
        display_text = '%s: %.2f' % (name, score)
        ax.text(xmin, ymin, display_text, bbox={'facecolor':color, 'alpha':0.5})
    if save_fig:
        plt.savefig(os.path.join("/RefineDet/examples/request/",image_name), bbox_inches="tight")
        print('Saved: ' + out_path)
    plt.show()



if __name__ == "__main__":
    setting_file = "./src/setting.json"
    detector = RefineDetDetectorCpu(setting_file)
    detector.load_model()
    detector.set_transformer()

    image_paths = [
        "/RefineDet/examples/images/000456.jpg",
        "/RefineDet/examples/images/000542.jpg",
        "/RefineDet/examples/images/001150.jpg",
        "/RefineDet/examples/images/001763.jpg",
        "/RefineDet/examples/images/004545.jpg",
    ]
    out_dirpath = "/RefineDet/examples/request/"
    if not os.path.exists(out_dirpath):
        os.makedirs(out_dirpath)
    # for image_path in image_paths:
    #     try:
    #         image = cv2.imread(image_path, 1)
    #         image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    #         out_path = os.path.join(out_dirpath, os.path.basename(image_path))
    #         detector.inference(image, out_path)
    #     except RefinedetClassDefineError as e:
    #         print(e)
    for image_path in image_paths:
        try:
            out_path = os.path.join(out_dirpath, os.path.basename(image_path))
            # detector.inference(image_path, out_path)
            with open(image_path, "rb") as f:
                image_byte = f.read()
            detector.inference(image_byte, out_path)
        except RefinedetClassDefineError as e:
            print(e)


    print("CONPLETE")
