
class DLModuleError(Exception):
    """
    DLモジュールの例外クラスの親クラス
    DLモジュールは全てこの例外クラスを継承する
    """
    pass


class DLInitializerError(DLModuleError):
    """
    DL初期化時の例外クラスの親クラス
    """
    pass


class DLSettingFileError(DLInitializerError):
    """
    設定ファイルの記述内容に関してのエラー
    """
    pass
