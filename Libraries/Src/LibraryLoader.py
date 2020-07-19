
from robot.libraries.BuiltIn import BuiltIn

class LibraryLoader:
    __instance = None
    def __init__(self):
        if self.__class__.__instance is not None:
            raise AssertionError("LibraryLoader is a singleton. Call LibraryLoader.get_instance() to get the instance")
        self.__class__.__instance = self
        self.builtin = BuiltIn()

    @classmethod
    def get_instance(cls):
        if cls.__instance is not None:
            return cls.__instance
        return cls()


if __name__ == '__main__':  # python -m LibraryLoader
    ll_one = LibraryLoader.get_instance()
    ll_two = LibraryLoader.get_instance()
    if ll_one is not ll_two:
        raise AssertionError('Error: LibraryLoader is not a singleton!')
    print(dir(ll_one))




