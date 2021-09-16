import os
import json
from abc import ABCMeta, abstractclassmethod
from .Exceptions import DLSettingFileError

from typing import Tuple


class AbstractDetector(metaclass=ABCMeta):

    def __init__(self, setting_file: str) -> None:
        self.info: dict = {}
        self.model_path: str = ""
        self.class_names: list[str] = []
        self.class_threshes: dict[str, float] = {}
        self.num_classes: int = 0
        self.unique_settings: dict = {}

        if not os.path.isfile(setting_file):
            raise DLSettingFileError(f"{setting_file}が存在しない.")
        try:
            with open(setting_file) as f:
                settings: dict = json.load(f)
        except Exception:
            raise DLSettingFileError("設定ファイルをJSONとして読み込めません。設定ファイルの書式を確認してください。")

        # モデル情報の必須キーの存在と型チェック
        self.info = self._read_setting_info(settings)

        # # モデルパスキーの存在と型チェック
        self.model_path = self._read_setting_modelpath(settings)

        # # クラス情報の必須キーの存在と値の型チェック
        class_names, num_classes, confidence_threshes = self._read_setting_classes(settings)
        self.class_names = class_names
        self.confidence_threshes = confidence_threshes
        self.num_classes = num_classes

        # 各モデル特有の設定情報の読み込み
        self.unique_settings = self._read_setting_uniqe(settings)

    def _read_setting_info(self, settings: dict):
        info: dict = settings.get("Info")
        if not isinstance(info, dict):
            raise DLSettingFileError("INFOキーがないか、INFOキーの値の型がdictになっていません。")
        v: str = info.get("ModelName")
        if not isinstance(v, str):
            raise DLSettingFileError("ModelNameキーがないか、ModelNameキーの値の型がstrになっていません。")
        v: str = info.get("Version")
        if not isinstance(v, str):
            raise DLSettingFileError("Versionキーがないか、Versionキーの値の型がstrになっていません。")
        v: str = info.get("Description")
        if not isinstance(v, str):
            raise DLSettingFileError("Descriptionキーがないか、Descriptionキーの値の型がstrになっていません。")
        v: str = info.get("DetectionType")
        if not isinstance(v, str):
            raise DLSettingFileError("DetectionTypeキーがないか、DetectionTypeキーの値の型がstrになっていません。")
        return info

    def _read_setting_modelpath(self, settings: dict) -> str:
        # モデルパスキーの存在と型チェック
        model_path: str = settings.get("WeightPath")
        if not isinstance(model_path, str):
            raise DLSettingFileError("WeightPathキーがないか、WeightPathキーの値の型がstrになっていません。")
        return model_path

    def _read_setting_classes(self, settings: dict) -> Tuple[list, int, dict]:
        classes: list[dict] = settings.get("Classes")
        if not isinstance(classes, list):
            raise DLSettingFileError("Classesキーがないか、Classesキーの値の型がlistになっていません。")
        num_classes: int = len(classes)
        if not num_classes:
            raise DLSettingFileError("Classesキーのlistに値が入っていません。")
        for d in classes:
            if not isinstance(d, dict):
                raise DLSettingFileError("Classesキーのlist内にdict以外が入っています。")
            v: str = d.get("ClassName")
            if not isinstance(v, str):
                raise DLSettingFileError("ClassNameキーがないか、ClassNameキーの値の型がstrになっていません。")
            v: float = d.get("ConfidenceThresh")
            if not isinstance(v, float):
                raise DLSettingFileError("ConfidenceThreshキーがないか、ConfidenceThreshキーの値の型がfloatになっていません。")
        class_names = [d["ClassName"] for d in classes]
        if (len(class_names) - len(set(class_names))):
            raise DLSettingFileError("ClassNameに重複しているものがある。")
        confidence_threshes = {d["ClassName"]: d["ConfidenceThresh"] for d in classes}
        return (class_names, num_classes, confidence_threshes)

    def _read_setting_uniqe(self, settings: dict) -> dict:
        # UniqueSettingsは使わないモデルの場合は記述しなくてもいいのでNoneを許容する
        unique_settings: dict = settings.get("UniqueSettings")
        if unique_settings is None:
            unique_settings = {}
        if not isinstance(unique_settings, dict):
            raise DLSettingFileError("UniqueSettingsキーの値の型がdictになっていません。")
        return unique_settings

    @abstractclassmethod
    def load_model(self):
        raise NotImplementedError()

    @abstractclassmethod
    def set_transformer(self):
        raise NotImplementedError()

    @abstractclassmethod
    def inference(self, image):
        raise NotImplementedError()
