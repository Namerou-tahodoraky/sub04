from .Exceptions import DLSettingFileError


class RefinedetSettingFileError(DLSettingFileError):
    """
    設定ファイルの記述内容に関してのエラー
    RefineDet専用のUniqueSettingsに関するもの
    """
    def __str__(self):
        pass


class RefinedetClassDefineError(DLSettingFileError):
    """
    設定ファイルの記述内容に関してのエラー
    RefineDet専用のUniqueSettingsに関するもの
    """
    def __init__(self, setting_classnum, detect_classnum):
        self.setting_classnum = setting_classnum
        self.detect_classnum = detect_classnum

    def __str__(self):
        return "設定ファイルのクラス数とモデルのクラス数が合っていません。\n" + \
            f"設定ファイル={self.setting_classnum}, 検出クラス={self.detect_classnum}"
