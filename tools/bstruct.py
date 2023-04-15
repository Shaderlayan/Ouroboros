from binary_reader import BinaryReader

class BPrimitive:
    def __init__(self, type: str, count: int | None = None) -> None:
        self.type = type
        self.count = count

    def read(self, reader: BinaryReader) -> any:
        return getattr(reader, 'read_' + self.type)(self.count)

    def write(self, writer: BinaryReader, value: any) -> None:
        getattr(writer, 'write_' + self.type)(value)

class BStruct:
    def __init__(self, members: tuple[tuple] | list[tuple]) -> None:
        self.members = members

    def read(self, reader: BinaryReader) -> dict:
        value = {}
        for (type, name) in self.members:
            value[name] = type.read(reader)
        return value

    def write(self, writer: BinaryReader, value: dict) -> None:
        for (type, name) in self.members:
            type.write(writer, value[name])

def bytes(count):
    return BPrimitive('bytes', count)

uint16 = BPrimitive('uint16')
uint32 = BPrimitive('uint32')
