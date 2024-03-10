import math
import re
import struct
import traceback
import zlib
from pattern import matches_pattern, matches_set_helper

ASSIGNMENT_PATTERN = re.compile(r'^([A-Za-z0-9_]+)\.([xyzw]+) = (.*);(?:\s*//.*)?$')
BLOCK_START_PATTERN = re.compile(r'^((?:\} else )?if|while) \((.*)\) \{(?:\s*//.*)?$')
CAST_PATTERN = re.compile(r'\(\s*([A-Za-z0-9_]+)\s*\)')
IF_VERB_PATTERN = re.compile(r'^if \((.*)\) ([A-Za-z0-9_]+);(?:\s*//.*)?$')
INT_PATTERN = re.compile(r'^-?(?:0|[1-9][0-9]*)(u)?$')
LITERAL_PATTERN = re.compile(r'-?(?:0|[1-9][0-9]*)(?:u|(?:\.[0-9]+)?(?:[Ee][+-]?[0-9]+)?)')
LOCAL_PATTERN = re.compile(r'^([A-Za-z_]+)([0-9]+)? ((?:[A-Za-z0-9_]+)(?:, ?(?:[A-Za-z0-9_]+))*);(?:\s*//.*)?$')
NAME_PATTERN = re.compile(r'[A-Za-z0-9_]+')
SWAPC_PATTERN = re.compile(r'^([A-Za-z0-9_]+)\.([xyzw]+) = ([^?:;]*) \? ([^:;]*) : ([^;]*); ([A-Za-z0-9_]+)\.([xyzw]+) = \3 \? \5 : \4;$')
SWIZZLE_PATTERN = re.compile(r'^[xyzw]{1,4}$')
OPERATORS = '+-*/%~<>&|^!='

class Context:
    def __init__(self) -> None:
        self.outs = set()
        self.name_mappings = {}

def float32(x: float) -> float:
    return struct.unpack('f', struct.pack('f', x))[0]

def simplify_float_literal(x: str) -> str:
    xf = float(x)
    xfi = float(x.replace('.', ''))
    digits = round(math.log10(xfi / xf))
    factor = math.pow(10, digits - 3)
    xfs = round(xf * factor) / factor
    if float32(xf) == float32(xfs):
        return str(xfs)
    else:
        return x

def make_vector_type(scalar_type: str, size: int) -> str:
    return ('%s%d' % (scalar_type, size)) if size > 1 else scalar_type

def parse_vector_type(vector_type: str):
    scalar_type = vector_type.rstrip('0123456789')
    size = 1 if scalar_type == vector_type else int(vector_type[len(scalar_type):])
    return (scalar_type, size)

class Node:
    def __init__(self, type: str | None) -> None:
        self.type = type
    def __str__(self) -> str:
        return "(%s) %s" % (self.type, self.value_str())
    def __repr__(self) -> str:
        return "(%s) %s" % (self.type, self.value_str())
    def matches(self, pattern, slots: dict) -> dict | None:
        return slots if self == pattern else None
    def value_str(self) -> str:
        raise NotImplementedError("value_str must be overridden by %s" % (self.__class__.__name__,))
    def member(self, member: str):
        if member == '':
            raise ValueError('cannot get empty member')
        return MemberAccessNode(None, self, member).simplify()
    def index(self, index):
        return IndexNode(None, self, index).simplify()
    def binary_op(self, op: str, right):
        return BinaryOpNode(self, op, right).simplify()
    def unary_op(self, op: str):
        return UnaryOpNode(op, self).simplify()
    def cast(self, type: str):
        return CastNode(type, self).simplify()
    def conditional(self, if_true, if_false):
        return ConditionalNode(self, if_true, if_false).simplify()
    def call(self, args: list):
        raise RuntimeError("call is not supported by %s" % (self.__class__.__name__,))
    def fn_call(self, fn: str, args: list):
        return FunctionCallNode(None, self, fn, args).simplify()
    def phi(self, name: str | None):
        return PhiNode(name, [self]).simplify()
    def copy(self, deep: bool):
        raise NotImplementedError("copy must be overridden by %s" % (self.__class__.__name__,))
    def simplify(self):
        return self
    def resolve(self, scope):
        return self.simplify()
    def inline(self):
        return self.simplify()
    def visit_children(self, visitor, acc):
        return acc
    def hash(self, init: int = 0) -> int:
        data = self.hash_data()
        if isinstance(data, bytes):
            return zlib.crc32(self.__class__.__name__.encode() + data, init)
        else:
            return zlib.crc32((self.__class__.__name__ + data).encode(), init)
    def hash_data(self) -> str | bytes:
        raise NotImplementedError("hash_data must be overridden by %s" % (self.__class__.__name__,))
    def calculate_read(self, mask: int) -> None:
        raise NotImplementedError("calculate_read must be overridden by %s" % (self.__class__.__name__,))
    def prune(self):
        return (self, False)
    def simplify_final(self):
        return self
    @property
    def innermost(self):
        return self

class UninitializedNode(Node):
    def __hash__(self) -> int:
        return hash(())
    def __eq__(self, other) -> bool:
        return self is other or isinstance(other, UninitializedNode)
    def value_str(self) -> str:
        return "<uninit>"
    def hash_data(self) -> bytes:
        return b""
    def cast(self, type: str):
        return UninitializedNode(type).simplify()
    def phi(self, name: str | None):
        return PhiNode(name, []).simplify()
    def copy(self, deep: bool):
        return UninitializedNode(self.type)
    def calculate_read(self, mask: int) -> None:
        pass

class NameNode(Node):
    def __init__(self, type: str | None, name) -> None:
        super().__init__(type)
        self._name = name
    def __hash__(self) -> int:
        return hash((self._name,))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, NameNode) and self._name == other._name)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self == pattern:
            return slots
        if isinstance(self._name, DeclarationInstruction) and self._name.value is not None and getattr(pattern, 'match_inner', True):
            return matches_pattern(self._name.value, pattern, slots)
        return None
    def canonicalize_pattern(self):
        return self.innermost
    @property
    def name(self) -> str:
        return self._name if isinstance(self._name, str) else self._name.name
    def value_str(self) -> str:
        return self.name
    def call(self, args: list):
        return FunctionCallNode(None, None, self.name, args).simplify()
    def hash_data(self) -> str:
        return self.name
    def copy(self, deep: bool):
        return NameNode(self.type, self._name)
    def simplify(self):
        if self._name == 'true' or self._name == 'false':
            return parse_literal(self._name)
        innermost = self.innermost
        if isinstance(innermost, SwizzleNode) and isinstance(innermost.receiver, NameNode):
            return innermost
        return self
    def resolve(self, scope):
        var = scope.get(self.name)
        if var is None:
            return self
        return var.value_node().simplify()
    def inline(self):
        if isinstance(self._name, DeclarationInstruction) and not self._name.is_phi:
            return self._name.value
        return self
    def calculate_read(self, mask: int) -> None:
        if isinstance(self._name, DeclarationInstruction):
            self._name.register_read(mask)
    @property
    def innermost(self):
        if isinstance(self._name, DeclarationInstruction) and self._name.value is not None:
            return self._name.value.innermost
        return self

def name(name):
    return NameNode(None, name).simplify()

def no_match_inner(node):
    node.match_inner = False
    return node

class MemberAccessNode(Node):
    def __init__(self, type: str | None, receiver: Node, name: str) -> None:
        super().__init__(type)
        self.receiver = receiver
        self.name = name
    def __hash__(self) -> int:
        return hash((self.receiver, self.name))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, MemberAccessNode) and self.name == other.name and self.receiver == other.receiver)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, MemberAccessNode):
            return None
        slots = matches_pattern(self.name, pattern.name, slots)
        if slots is None:
            return None
        return matches_pattern(self.receiver, pattern.receiver, slots)
    def value_str(self) -> str:
        return "%s.%s" % (self.receiver.value_str(), self.name)
    def call(self, args: list):
        return FunctionCallNode(None, self.receiver, self.name, args).simplify()
    def visit_children(self, visitor, acc):
        (self.receiver, acc) = visitor(self.receiver, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!L', self.receiver.hash()) + self.name.encode()
    def copy(self, deep: bool):
        return MemberAccessNode(self.type, self.receiver.copy(deep) if deep else self.receiver, self.name)
    def simplify(self):
        if SWIZZLE_PATTERN.fullmatch(self.name) is not None:
            return SwizzleNode(self.receiver, self.name).simplify()
        if isinstance(self.receiver, NameNode) and self.name == self.receiver._name:
            return self.receiver
        return self
    def resolve(self, scope):
        self.receiver = self.receiver.resolve(scope)
        return self.simplify()
    def inline(self):
        receiver = self.receiver.inline()
        if receiver != self.receiver:
            return MemberAccessNode(self.type, receiver, self.name).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.receiver.calculate_read(mask)
    def simplify_final(self):
        self.receiver = self.receiver.simplify_final()
        return self

class IndexNode(Node):
    def __init__(self, type: str | None, receiver: Node, index: Node) -> None:
        super().__init__(type)
        self.receiver = receiver
        self.index = index
    def __hash__(self) -> int:
        return hash((self.receiver, self.index))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, IndexNode) and self.receiver == other.receiver and self.index == other.index)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, IndexNode):
            return None
        slots = matches_pattern(self.receiver, pattern.receiver, slots)
        if slots is None:
            return None
        return matches_pattern(self.index, pattern.index, slots)
    def value_str(self) -> str:
        return "%s[%s]" % (self.receiver.value_str(), self.index.value_str())
    def visit_children(self, visitor, acc):
        (self.receiver, acc) = visitor(self.receiver, acc)
        (self.index, acc) = visitor(self.index, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!LL', self.receiver.hash(), self.index.hash())
    def copy(self, deep: bool):
        return IndexNode(self.type, self.receiver.copy(deep) if deep else self.receiver, self.index.copy(deep) if deep else self.index)
    def resolve(self, scope):
        self.receiver = self.receiver.resolve(scope)
        self.index = self.index.resolve(scope)
        return self.simplify()
    def inline(self):
        receiver = self.receiver.inline()
        index = self.index.inline()
        if receiver != self.receiver or index != self.index:
            return IndexNode(self.type, receiver, index).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.receiver.calculate_read(mask)
        self.index.calculate_read(1)
    def simplify_final(self):
        self.receiver = self.receiver.simplify_final()
        self.index = self.index.simplify_final()
        return self

class SwizzleNode(Node):
    def __init__(self, receiver: Node, swizzle: str) -> None:
        if receiver.type is None:
            type = None
        else:
            type = make_vector_type(parse_vector_type(receiver.type)[0], len(swizzle))
        super().__init__(type)
        self.receiver = receiver
        self.swizzle = swizzle
    def __hash__(self) -> int:
        return hash((self.receiver, self.swizzle))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, SwizzleNode) and self.swizzle == other.swizzle and self.receiver == other.receiver)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, SwizzleNode):
            return None
        slots = matches_pattern(self.swizzle, pattern.swizzle, slots)
        if slots is None:
            return None
        return matches_pattern(self.receiver, pattern.receiver, slots)
    def value_str(self) -> str:
        return "%s.%s" % (self.receiver.value_str(), self.swizzle)
    def visit_children(self, visitor, acc):
        (self.receiver, acc) = visitor(self.receiver, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!L', self.receiver.hash()) + self.swizzle.encode()
    def copy(self, deep: bool):
        return SwizzleNode(self.receiver.copy(deep) if deep else self.receiver, self.swizzle)
    def simplify(self):
        if isinstance(self.receiver, SwizzleNode):
            r_swizzle = self.receiver.swizzle
            s_swizzle = ''
            for c in self.swizzle:
                s_swizzle += r_swizzle[swizzle_index(c)]
            return SwizzleNode(self.receiver.receiver, s_swizzle).simplify()
        if self.receiver.type is not None:
            r_vec_type = self.receiver.type
            (r_scl_type, r_size) = parse_vector_type(r_vec_type)
            if self.swizzle == 'xyzw'[0:r_size]:
                return self.receiver
            innermost_receiver = self.receiver.innermost
            if isinstance(innermost_receiver, FunctionCallNode) and innermost_receiver.receiver is None and innermost_receiver.fn == r_vec_type:
                if len(innermost_receiver.args) == 1:
                    arg = innermost_receiver.args[0]
                    if len(self.swizzle) == 1:
                        return arg
                    result_type = make_vector_type(r_scl_type, len(self.swizzle))
                    return FunctionCallNode(result_type, None, result_type, [arg]).simplify()
                elif len(innermost_receiver.args) == r_size:
                    args = innermost_receiver.args
                    if len(self.swizzle) == 1:
                        return args[swizzle_index(self.swizzle)]
                    result_type = make_vector_type(r_scl_type, len(self.swizzle))
                    return FunctionCallNode(result_type, None, result_type, [args[swizzle_index(c)] for c in self.swizzle]).simplify()
            if isinstance(self.receiver, UninitializedNode):
                return UninitializedNode(make_vector_type(r_scl_type, len(self.swizzle)))
            if isinstance(self.receiver, NameNode) and isinstance(self.receiver._name, DeclarationInstruction) and self.receiver._name.init_mask & swizzle_mask(self.swizzle) == 0:
                return UninitializedNode(make_vector_type(r_scl_type, len(self.swizzle)))
        return self
    def resolve(self, scope):
        self.receiver = self.receiver.resolve(scope)
        return self.simplify()
    def inline(self):
        receiver = self.receiver.inline()
        if receiver != self.receiver:
            return SwizzleNode(receiver, self.swizzle).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        rcv_mask = 0
        for (i, c) in enumerate(self.swizzle):
            if mask & (1 << i) != 0:
                rcv_mask |= swizzle_mask(c)
        self.receiver.calculate_read(rcv_mask)
    def prune(self):
        if isinstance(self.receiver, NameNode) and isinstance(self.receiver._name, DeclarationInstruction):
            var = self.receiver._name
            var_size = parse_vector_type(var.type)[1]
            var_mask = (1 << var_size) - 1
            if (var_mask & var.read_mask) != var_mask:
                swizzle = ''.join(mask_swizzle(mask_inner(swizzle_mask(c), var.read_mask)) for c in self.swizzle)
                if len(swizzle) == len(mask_swizzle(var.read_mask)):
                    return (self.receiver, True)
                return (SwizzleNode(self.receiver, swizzle), True)
        return (self, False)
    def simplify_final(self):
        self.receiver = self.receiver.simplify_final()
        return self

class ExpectSwizzleNode(Node):
    def __init__(self, value: Node, swizzle: str) -> None:
        super().__init__(None)
        self.value = value
        self.swizzle = swizzle
    def __hash__(self) -> int:
        return hash((self.value, self.swizzle))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, ExpectSwizzleNode) and self.swizzle == other.swizzle and self.value == other.value)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, ExpectSwizzleNode):
            return None
        slots = matches_pattern(self.swizzle, pattern.swizzle, slots)
        if slots is None:
            return None
        return matches_pattern(self.receiver, pattern.receiver, slots)
    def member(self, member: str):
        if member == self.swizzle:
            return self.value
        raise ValueError('swizzle mismatch, expected %s, got %s' % (self.swizzle, member))
    def value_str(self) -> str:
        return "{%s:%s}" % (self.swizzle, self.value.value_str())
    def visit_children(self, visitor, acc):
        (self.value, acc) = visitor(self.value, acc)
        return acc
    def copy(self, deep: bool):
        return ExpectSwizzleNode(self.value.copy(deep) if deep else self.value, self.swizzle)

class LiteralNode(Node):
    def __init__(self, type: str | None, value: str) -> None:
        super().__init__(type)
        try:
            self.value = simplify_float_literal(value)
        except:
            self.value = value
    def __hash__(self) -> int:
        return hash((self.value,))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, LiteralNode) and self.value == other.value)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, LiteralNode):
            return None
        return matches_pattern(self.value, pattern.value, slots)
    def value_str(self) -> str:
        return self.value
    def eval(self) -> int | float:
        match self.type:
            case 'int' | 'uint':
                return int(self.value.rstrip('u'))
            case 'float':
                return float(self.value)
            case 'bool':
                match self.value:
                    case 'true':
                        return True
                    case 'false':
                        return False
                    case _:
                        raise NotImplementedError('literal of type bool not implemented: %s' % (self.value,))
            case _:
                raise NotImplementedError('literal of type %s not implemented: %s' % (self.type, self.value))
    def is_negative(self) -> bool:
        return self.value.startswith('-')
    def hash_data(self) -> bytes:
        if self.type is None:
            return self.value.encode()
        return (self.type + self.value).encode()
    def copy(self, deep: bool):
        return self
    def calculate_read(self, mask: int) -> None:
        pass

def literal(value):
    return LiteralNode(None, value).simplify()

class UnaryOpNode(Node):
    def __init__(self, op: str, operand: Node) -> None:
        type = None
        super().__init__(type)
        self.op = op
        self.operand = operand
    def __hash__(self) -> int:
        return hash((self.op, self.operand))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, UnaryOpNode) and self.op == other.op and self.operand == other.operand)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, UnaryOpNode):
            return None
        if self.op != pattern.op:
            return None
        return matches_pattern(self.operand, pattern.operand, slots)
    def value_str(self) -> str:
        if isinstance(self.operand, BinaryOpNode):
            return "%s(%s)" % (self.op, self.operand.value_str())
        return "%s%s" % (self.op, self.operand.value_str())
    def visit_children(self, visitor, acc):
        (self.operand, acc) = visitor(self.operand, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!L', self.operand.hash()) + self.op.encode()
    def copy(self, deep: bool):
        return UnaryOpNode(self.op, self.operand.copy(deep) if deep else self.operand)
    def simplify(self):
        if isinstance(self.operand, UnaryOpNode) and self.operand.op == self.op:
            return self.operand.operand
        match self.op:
            case '-':
                if isinstance(self.operand, LiteralNode):
                    if self.operand.is_negative():
                        return parse_literal(self.operand.value[1:])
                    else:
                        return parse_literal('-' + self.operand.value)
                if isinstance(self.operand, BinaryOpNode) and self.operand.op == '-':
                    right = self.operand.left
                    self.operand.left = self.operand.right
                    self.operand.right = right
                    return self.operand.simplify()
            case '!':
                if isinstance(self.operand, BinaryOpNode):
                    match self.operand.op:
                        case '<':
                            self.operand.op = '>='
                            return self.operand
                        case '>':
                            self.operand.op = '<='
                            return self.operand
                        case '<=':
                            self.operand.op = '>'
                            return self.operand
                        case '>=':
                            self.operand.op = '<'
                            return self.operand
                        case '!=':
                            self.operand.op = '=='
                            return self.operand
                        case '==':
                            self.operand.op = '!='
                            return self.operand
        return self
    def resolve(self, scope):
        self.operand = self.operand.resolve(scope)
        return self.simplify()
    def inline(self):
        operand = self.operand.inline()
        if operand != self.operand:
            return UnaryOpNode(self.op, operand).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.operand.calculate_read(mask)
    def prune(self):
        (self.operand, changed) = self.operand.prune()
        if changed:
            return (self.simplify(), True)
        return (self, False)
    def simplify_final(self):
        self.operand = self.operand.simplify_final()
        return self

class CastNode(Node):
    def __init__(self, type: str, value: Node) -> None:
        super().__init__(type)
        self.value = value
    def __hash__(self) -> int:
        return hash((self.type, self.value))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, CastNode) and self.type == other.type and self.value == other.value)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, CastNode):
            return None
        slots = matches_pattern(self.type, pattern.type, slots)
        if slots is None:
            return None
        return matches_pattern(self.value, pattern.value, slots)
    def value_str(self) -> str:
        return "(%s)%s" % (self.type, self.value.value_str())
    def visit_children(self, visitor, acc):
        (self.value, acc) = visitor(self.value, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!L', self.value.hash()) + self.type.encode()
    def copy(self, deep: bool):
        return CastNode(self.type, self.value.copy(deep) if deep else self.value)
    def resolve(self, scope):
        self.value = self.value.resolve(scope)
        return self.simplify()
    def inline(self):
        value = self.value.inline()
        if value != self.value:
            return CastNode(self.type, value).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.value.calculate_read(mask)
    def prune(self):
        (self.value, changed) = self.value.prune()
        if changed:
            return (self.simplify(), True)
        return (self, False)
    def simplify_final(self):
        self.value = self.value.simplify_final()
        return self

class BinaryOpNode(Node):
    def __init__(self, left: Node, op: str, right: Node) -> None:
        type = None
        super().__init__(type)
        self.left = left
        self.op = op
        self.right = right
    def __hash__(self) -> int:
        return hash((self.left, self.op, self.right))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, BinaryOpNode) and self.op == other.op and self.left == other.left and self.right == other.right)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, BinaryOpNode):
            return None
        slots = matches_pattern(self.op, pattern.op, slots)
        if slots is None:
            return None
        if self.op == '+' or self.op == '*':
            sp = self.flatten()
            pp = pattern.flatten()
            if len(sp) < len(pp):
                return None
            def matches_last(sp, pattern, slots):
                node = sp[0]
                for operand in sp[1:]:
                    node = BinaryOpNode(node, self.op, operand)
                return (None, matches_pattern(node, pattern, slots))
            (_, slots) = matches_set_helper(sp, pp, matches_last, slots)
            return slots
        else:
            slots = matches_pattern(self.left, pattern.left, slots)
            if slots is None:
                return None
            return matches_pattern(self.right, pattern.right, slots)
    def value_str(self) -> str:
        return "%s %s %s" % (self.left.value_str(), self.op, self.right.value_str())
    def visit_children(self, visitor, acc):
        (self.left, acc) = visitor(self.left, acc)
        (self.right, acc) = visitor(self.right, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!LL', self.left.hash(), self.right.hash()) + self.op.encode()
    def copy(self, deep: bool):
        return BinaryOpNode(self.left.copy(deep) if deep else self.left, self.op, self.right.copy(deep) if deep else self.right)
    def simplify(self):
        match self.op:
            case '+':
                if (isinstance(self.right, UnaryOpNode) and self.right.op == '-') or (isinstance(self.right, LiteralNode) and self.right.is_negative()):
                    self.op = '-'
                    self.right = self.right.unary_op('-')
                    return self.simplify()
                if (isinstance(self.left, UnaryOpNode) and self.left.op == '-') or (isinstance(self.left, LiteralNode) and self.left.is_negative()):
                    right = self.left.unary_op('-')
                    self.op = '-'
                    self.left = self.right
                    self.right = right
                    return self.simplify()
                if self.left.hash() > self.right.hash():
                    right = self.left
                    self.left = self.right
                    self.right = right
                    return self.simplify()
            case '-':
                if (isinstance(self.right, UnaryOpNode) and self.right.op == '-') or (isinstance(self.right, LiteralNode) and self.right.is_negative()):
                    self.op = '+'
                    self.right = self.right.unary_op('-')
                    return self.simplify()
                if (isinstance(self.left, UnaryOpNode) and self.left.op == '-') or (isinstance(self.left, LiteralNode) and self.left.is_negative()):
                    self.op = '+'
                    self.left = self.left.unary_op('-')
                    return self.unary_op('-').simplify()
            case '*':
                if (isinstance(self.left, UnaryOpNode) and self.left.op == '-') or (isinstance(self.left, LiteralNode) and self.left.is_negative()):
                    self.left = self.left.unary_op('-')
                    if (isinstance(self.right, UnaryOpNode) and self.right.op == '-') or (isinstance(self.right, LiteralNode) and self.right.is_negative()):
                        self.right = self.right.unary_op('-')
                        return self.simplify()
                    return self.unary_op('-')
                if (isinstance(self.right, UnaryOpNode) and self.right.op == '-') or (isinstance(self.right, LiteralNode) and self.right.is_negative()):
                    self.right = self.right.unary_op('-')
                    return self.unary_op('-')
                if self.left.hash() > self.right.hash():
                    right = self.left
                    self.left = self.right
                    self.right = right
                    return self.simplify()
        return self
    def flatten(self):
        if self.op == '+' or self.op == '*':
            parts = []
            left_innermost = self.left.innermost
            if isinstance(left_innermost, BinaryOpNode) and left_innermost.op == self.op:
                parts.extend(left_innermost.flatten())
            else:
                parts.append(self.left)
            right_innermost = self.right.innermost
            if isinstance(right_innermost, BinaryOpNode) and right_innermost.op == self.op:
                parts.extend(right_innermost.flatten())
            else:
                parts.append(self.right)
            return parts
        else:
            return [self.left, self.right]
    def resolve(self, scope):
        self.left = self.left.resolve(scope)
        self.right = self.right.resolve(scope)
        return self.simplify()
    def inline(self):
        left = self.left.inline()
        right = self.right.inline()
        if left != self.right or right != self.right:
            return BinaryOpNode(left, self.op, right).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.left.calculate_read(mask)
        self.right.calculate_read(mask)
    def prune(self):
        (self.left, l_changed) = self.left.prune()
        (self.right, r_changed) = self.right.prune()
        if l_changed or r_changed:
            return (self.simplify(), True)
        return (self, False)
    def simplify_final(self):
        self.left = self.left.simplify_final()
        self.right = self.right.simplify_final()
        return self

class ConditionalNode(Node):
    def __init__(self, condition: Node, if_true: Node, if_false: Node) -> None:
        type = if_true.type if if_true.type == if_false.type else None
        super().__init__(type)
        self.condition = condition
        self.if_true = if_true
        self.if_false = if_false
    def __hash__(self) -> int:
        return hash((self.condition, self.if_true, self.if_false))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, ConditionalNode) and self.condition == other.condition and self.if_true == other.if_true and self.if_false == other.if_false)
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, ConditionalNode):
            return None
        slots = matches_pattern(self.condition, pattern.condition, slots)
        if slots is None:
            return None
        slots = matches_pattern(self.if_true, pattern.if_true, slots)
        if slots is None:
            return None
        return matches_pattern(self.if_false, pattern.if_false, slots)
    def value_str(self) -> str:
        return "%s ? %s : %s" % (self.condition.value_str(), self.if_true.value_str(), self.if_false.value_str())
    def visit_children(self, visitor, acc):
        (self.condition, acc) = visitor(self.condition, acc)
        (self.if_true, acc) = visitor(self.if_true, acc)
        (self.if_false, acc) = visitor(self.if_false, acc)
        return acc
    def hash_data(self) -> bytes:
        return struct.pack('!LLL', self.condition.hash(), self.if_true.hash(), self.if_false.hash())
    def copy(self, deep: bool):
        return ConditionalNode(self.condition.copy(deep) if deep else self.condition, self.if_true.copy(deep) if deep else self.if_true, self.if_false.copy(deep) if deep else self.if_false)
    def resolve(self, scope):
        self.condition = self.condition.resolve(scope)
        self.if_true = self.if_true.resolve(scope)
        self.if_false = self.if_false.resolve(scope)
        return self.simplify()
    def inline(self, scope):
        condition = self.condition.inline(scope)
        if_true = self.if_true.inline(scope)
        if_false = self.if_false.inline(scope)
        if condition != self.condition or if_true != self.if_true or if_false != self.if_false:
            return ConditionalNode(condition, if_true, if_false).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        self.condition.calculate_read(1)
        self.if_true.calculate_read(mask)
        self.if_false.calculate_read(mask)
    def prune(self):
        (self.condition, c_changed) = self.condition.prune()
        if isinstance(self.condition, BinaryOpNode) and (self.condition.op == '==' or self.condition.op == '!=') and self.condition.right == parse_literal('0'):
            left = self.condition.left.inline()
            if isinstance(left, FunctionCallNode) and left.receiver is None and left.fn == 'cmp' and len(left.args) == 1:
                self.condition = left.args[0]
                c_changed = True
        else:
            cond = self.condition.inline()
            if isinstance(cond, FunctionCallNode) and cond.receiver is None and cond.fn == 'cmp' and len(cond.args) == 1:
                self.condition = cond.args[0]
                c_changed = True
        (self.if_true, t_changed) = self.if_true.prune()
        (self.if_false, f_changed) = self.if_false.prune()
        if c_changed or t_changed or f_changed:
            return (self.simplify(), True)
        return (self, False)
    def simplify_final(self):
        self.condition = self.condition.simplify_final()
        self.if_true = self.if_true.simplify_final()
        self.if_false = self.if_false.simplify_final()
        return self

CUSTOM_FUNCTION_MASKS = {}

class FunctionCallNode(Node):
    def __init__(self, type: str | None, receiver: Node | None, fn: str, args: list[Node]) -> None:
        super().__init__(type)
        self.receiver = receiver
        self.fn = fn
        self.args = args
    def __hash__(self) -> int:
        return hash((self.receiver, self.fn, (*self.args,) if isinstance(self.args, list) else self.args))
    def __eq__(self, other) -> bool:
        return self is other or (isinstance(other, FunctionCallNode) and self.fn == other.fn and self.receiver == other.receiver and len(self.args) == len(other.args) and all(sa == oa for (sa, oa) in zip(self.args, other.args)))
    def matches(self, pattern, slots: dict) -> dict | None:
        if self is pattern:
            return slots
        if not isinstance(pattern, FunctionCallNode):
            return None
        slots = matches_pattern(self.fn, pattern.fn, slots)
        if slots is None:
            return None
        slots = matches_pattern(self.receiver, pattern.receiver, slots)
        if slots is None:
            return None
        return matches_pattern(self.args, pattern.args, slots)
    def value_str(self) -> str:
        args_str = ", ".join((arg.value_str() for arg in self.args))
        if self.receiver is not None:
            return "%s.%s(%s)" % (self.receiver.value_str(), self.fn, args_str)
        else:
            return "%s(%s)" % (self.fn, args_str)
    def visit_children(self, visitor, acc):
        if self.receiver is not None:
            (self.receiver, acc) = visitor(self.receiver, acc)
        for i in range(len(self.args)):
            (self.args[i], acc) = visitor(self.args[i], acc)
        return acc
    def hash_data(self) -> bytes:
        data = b''
        if self.receiver is not None:
            data += struct.pack('!L', self.receiver.hash())
        for arg in self.args:
            data += struct.pack('!L', arg.hash())
        return data + self.fn.encode()
    def copy(self, deep: bool):
        return FunctionCallNode(self.type, self.receiver.copy(deep) if deep and self.receiver is not None else self.receiver, self.fn, [arg.copy(deep) if deep else arg for arg in self.args])
    def simplify(self):
        if self.receiver is None:
            match self.fn:
                case 'float2' | 'int2' | 'uint2':
                    if len(self.args) == 2:
                        if self.args[0] == self.args[1]:
                            return self.args[0]
                        if isinstance(self.args[0], SwizzleNode) and isinstance(self.args[1], SwizzleNode) and self.args[0].receiver == self.args[1].receiver:
                            return SwizzleNode(self.args[0].receiver, self.args[0].swizzle + self.args[1].swizzle).simplify()
                    if all((initialized_mask(arg) == 0 for arg in self.args)):
                        return UninitializedNode(self.fn)
                case 'float3' | 'int3' | 'uint3':
                    if len(self.args) == 3:
                        if self.args[0] == self.args[1] and self.args[0] == self.args[2]:
                            return self.args[0]
                        if isinstance(self.args[0], SwizzleNode) and isinstance(self.args[1], SwizzleNode) and isinstance(self.args[2], SwizzleNode) and self.args[0].receiver == self.args[1].receiver and self.args[0].receiver == self.args[2].receiver:
                            return SwizzleNode(self.args[0].receiver, self.args[0].swizzle + self.args[1].swizzle + self.args[2].swizzle).simplify()
                    if all((initialized_mask(arg) == 0 for arg in self.args)):
                        return UninitializedNode(self.fn)
                case 'float4' | 'int4' | 'uint4':
                    if len(self.args) == 4:
                        if self.args[0] == self.args[1] and self.args[0] == self.args[2] and self.args[0] == self.args[3]:
                            return self.args[0]
                        if isinstance(self.args[0], SwizzleNode) and isinstance(self.args[1], SwizzleNode) and isinstance(self.args[2], SwizzleNode) and isinstance(self.args[3], SwizzleNode) and self.args[0].receiver == self.args[1].receiver and self.args[0].receiver == self.args[2].receiver and self.args[0].receiver == self.args[3].receiver:
                            return SwizzleNode(self.args[0].receiver, self.args[0].swizzle + self.args[1].swizzle + self.args[2].swizzle + self.args[3].swizzle).simplify()
                    if all((initialized_mask(arg) == 0 for arg in self.args)):
                        return UninitializedNode(self.fn)
        return self
    def resolve(self, scope):
        if self.receiver is not None:
            self.receiver = self.receiver.resolve(scope)
        for i in range(len(self.args)):
            self.args[i] = self.args[i].resolve(scope)
        return self.simplify()
    def inline(self):
        receiver = None if self.receiver is None else self.receiver.inline()
        changed = receiver != self.receiver
        args = []
        for i in range(len(self.args)):
            args.append(self.args[i].inline())
            if args[i] != self.args[i]:
                changed = True
        if changed:
            return FunctionCallNode(self.type, receiver, self.fn, args).simplify()
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        if self.receiver is not None:
            self.receiver.calculate_read(mask)
            for arg in self.args:
                arg.calculate_read(15)
        else:
            match self.fn:
                case 'float2' | 'int2' | 'uint2':
                    for arg in self.args:
                        arg.calculate_read(1)
                case 'float3' | 'int3' | 'uint3':
                    for arg in self.args:
                        arg.calculate_read(1)
                case 'float4' | 'int4' | 'uint4':
                    for arg in self.args:
                        arg.calculate_read(1)
                case 'dot' | 'mul':
                    for arg in self.args:
                        arg.calculate_read(15)
                case _:
                    if self.fn in CUSTOM_FUNCTION_MASKS:
                        mask = CUSTOM_FUNCTION_MASKS[self.fn]
                    for arg in self.args:
                        arg.calculate_read(mask)
    def prune(self):
        changed = False
        if self.receiver is not None:
            (self.receiver, changed) = self.receiver.prune()
        for i in range(len(self.args)):
            (self.args[i], a_changed) = self.args[i].prune()
            changed = changed or a_changed
        return (self, False)
    def simplify_final(self):
        if self.receiver is None:
            match self.fn:
                case 'float2' | 'int2' | 'uint2' | 'float3' | 'int3' | 'uint3' | 'float4' | 'int4' | 'uint4':
                    args = []
                    for arg in self.args:
                        if len(args) > 0 and isinstance(args[-1], SwizzleNode) and isinstance(arg, SwizzleNode) and args[-1].receiver == arg.receiver:
                            args[-1] = SwizzleNode(arg.receiver, args[-1].swizzle + arg.swizzle).simplify()
                        else:
                            args.append(arg)
                    self.args = args
                    if len(args) == 1 and args[0].type == self.fn:
                        return args[0].simplify_final()
        if self.receiver is not None:
            self.receiver = self.receiver.simplify_final()
        for i in range(len(self.args)):
            self.args[i] = self.args[i].simplify_final()
        return self

def fn_call(fn: str, args: list):
    return FunctionCallNode(None, None, fn, args).simplify()

class PhiNode(Node):
    def __init__(self, name, nodes: list[Node]) -> None:
        super().__init__(None)
        self._name = name
        self.nodes = nodes
    @property
    def name(self) -> str:
        return self._name if isinstance(self._name, str) else self._name.name
    def value_str(self) -> str:
        nodes_str = ", ".join((node.value_str() for node in self.nodes))
        return "Φ(%s)" % (nodes_str,)
    def visit_children(self, visitor, acc):
        for i in range(len(self.nodes)):
            (self.nodes[i], acc) = visitor(self.nodes[i], acc)
        return acc
    def hash_data(self) -> bytes:
        data = b''
        for node in self.nodes:
            data += struct.pack('!L', node.hash())
        return data
    def copy(self, deep: bool):
        raise RuntimeError('cannot copy a Φ')
    def resolve(self, scope):
        for i in range(len(self.nodes)):
            self.nodes[i] = self.nodes[i].resolve(scope)
        return self.simplify()
    def calculate_read(self, mask: int) -> None:
        for node in self.nodes:
            node.calculate_read(mask)
    def simplify_final(self):
        raise RuntimeError('a Φ node should not be in the expression tree at this stage')

literal_cache = {}

def parse_literal(literal: str) -> Node:
    if literal in literal_cache:
        return literal_cache[literal]
    match literal:
        case 'true':
            parsed = LiteralNode('bool', 'true')
        case 'false':
            parsed = LiteralNode('bool', 'false')
        case _:
            int_l = INT_PATTERN.fullmatch(literal)
            if int_l is not None:
                parsed = LiteralNode('uint' if int_l.group(1) is not None else 'int', literal)
            else:
                parsed = LiteralNode('float', simplify_float_literal(literal))
    parsed = parsed.simplify()
    literal_cache[literal] = parsed
    return parsed

def swizzle_index(swizzle_component: str) -> int:
    match swizzle_component:
        case 'x':
            return 0
        case 'y':
            return 1
        case 'z':
            return 2
        case 'w':
            return 3
        case _:
            raise ValueError('invalid swizzle component, must be x, y, z or w, got %s' % (swizzle_component,))

def swizzle_mask(swizzle: str) -> int:
    mask = 0
    for c in swizzle:
        mask |= 1 << swizzle_index(c)
    return mask

def mask_swizzle(mask: int) -> str:
    swizzle = ''
    for (i, c) in enumerate('xyzw'):
        if mask & (1 << i) != 0:
            swizzle += c
    return swizzle

def mask_inner(mask: int, within: int, ignore_extraneous: bool = False) -> int:
    if mask & ~within != 0 and not ignore_extraneous:
        raise ValueError('mask %d does not fit within %d' % (mask, within))
    components = [0, 0, 0, 0] if ignore_extraneous else [-1, -1, -1, -1]
    j = 0
    for i in range(4):
        if within & (1 << i) != 0:
            components[i] = 1 << j
            j += 1
    result = 0
    for (i, c) in enumerate(components):
        if mask & (1 << i) != 0:
            result |= c
    if result < 0: # should have been caught by the initial check
        raise RuntimeError('mask %d does not fit within %d' % (mask, within))
    return result

def mask_outer(mask: int, from_within: int, ignore_extraneous: bool = False) -> int:
    components = []
    orig_from_within = from_within
    while from_within != 0:
        components.append(from_within & ~(from_within - 1))
        from_within &= from_within - 1
    result = 0
    extraneous = mask
    for (i, c) in enumerate(components):
        if mask & (1 << i) != 0:
            result |= c
            extraneous &= ~(1 << i)
    if extraneous != 0 and not ignore_extraneous:
        raise ValueError('mask %d has bits overflowing %d' % (mask, orig_from_within))
    return result

class Variable:
    def __init__(self, type: str, size: int, name, value):
        self.type = type
        self.size = size
        self._name = name
        self.x = value('x') if size >= 1 else None
        self.y = value('y') if size >= 2 else None
        self.z = value('z') if size >= 3 else None
        self.w = value('w') if size >= 4 else None
    @property
    def name(self) -> str:
        return self._name if isinstance(self._name, str) else self._name.name
    @property
    def vector_type(self) -> str:
        return ("%s%d" % (self.type, self.size)) if self.size > 1 else self.type
    def component(self, component: str) -> Node:
        match swizzle_index(component):
            case 0:
                return self.x
            case 1:
                return self.y
            case 2:
                return self.z
            case 3:
                return self.w
            case _:
                raise NotImplementedError('swizzle component %s not implemented' % (component,))
    def set_component(self, component: str, value: Node) -> None:
        match swizzle_index(component):
            case 0:
                self.x = value
            case 1:
                self.y = value
            case 2:
                self.z = value
            case 3:
                self.w = value
            case _:
                raise NotImplementedError('swizzle component %s not implemented' % (component,))
    def components(self) -> list[Node]:
        if self.size >= 4:
            return [self.x, self.y, self.z, self.w]
        match self.size:
            case 3:
                return [self.x, self.y, self.z]
            case 2:
                return [self.x, self.y]
            case 1:
                return [self.x]
            case _:
                return []
    def copy(self):
        return Variable(self.type, self.size, self.name, self.component)
    def reference_node(self):
        return NameNode(self.vector_type, self)
    def value_node(self):
        vec_type = self.vector_type
        return FunctionCallNode(vec_type, None, vec_type, self.components()).simplify()
    def __str__(self) -> str:
        return self.__repr__()
    def __repr__(self) -> str:
        return "%s %s(%s)" % (self.vector_type, self.name, ', '.join((node.value_str() for node in self.components())))

class Scope:
    def __init__(self, parent) -> None:
        self.parent = parent
        self.vars = {}
    def get(self, name: str) -> dict | None:
        var = self.vars.get(name)
        if var is not None:
            return var
        if self.parent is None:
            return None
        return self.parent.get(name)
    def get_for_update(self, name: str) -> dict | None:
        var = self.vars.get(name)
        if var is not None:
            return var
        if self.parent is None:
            return None
        var = self.parent.get(name)
        if var is not None:
            var = var.copy()
            self.vars[name] = var
        return var
    def declare(self, var: Variable) -> None:
        self.vars[var.name] = var
    def copy(self):
        new_scope = Scope()
        for var in self.vars:
            new_scope.vars[var] = self.vars[var].copy()
        return new_scope

class Instruction:
    def __str__(self) -> str:
        return self.__repr__()
    def __repr__(self) -> str:
        lines = []
        self.write_to(lines, '')
        return '\n'.join((line for (_, line) in lines))
    def write_to(self, lines: list, indent: str) -> None:
        raise NotImplementedError("write_to must be overridden by %s" % (self.__class__.__name__,))
    @property
    def comment(self) -> str | None:
        return self.get_comment()
    @property
    def comment_with_marker(self) -> str:
        comment = self.get_comment()
        return (' // ' + comment) if comment is not None else ''
    def get_comment(self) -> str | None:
        return None
    @property
    def writes(self) -> dict:
        return self.get_writes()
    def get_writes(self) -> dict:
        raise NotImplementedError("get_writes must be overridden by %s" % (self.__class__.__name__,))
    def resolve(self, block, context):
        return self
    def clear_read(self) -> None:
        pass
    def calculate_read(self) -> None:
        pass
    def prune(self):
        return (True, False)
    def simplify_final(self, block):
        return self

class DeclarationInstruction(Instruction):
    def __init__(self, type: str, name: str, value: Node | None, is_phi: bool) -> None:
        super().__init__()
        self.type = type
        self.name = name
        self.value = value
        self.is_phi = is_phi
        self.init_mask = (1 << parse_vector_type(type)[1]) - 1 if value is not None else 0
        self.read_mask = 0
        self.read_count = 0
    def get_comment(self) -> str | None:
        parts = []
        if self.is_phi:
            parts.append('Φ')
        # parts.append('in:%s rd:%s #r:%d' % (mask_swizzle(self.init_mask), mask_swizzle(self.read_mask), self.read_count))
        return ' // '.join(parts) if len(parts) > 0 else None
    def write_to(self, lines: list, indent: str) -> None:
        if self.value is not None:
            lines.append((-1, '%s%s %s = %s;%s' % (indent, self.type, self.name, self.value.value_str(), self.comment_with_marker)))
        else:
            lines.append((-1, '%s%s %s;%s' % (indent, self.type, self.name, self.comment_with_marker)))
    def resolve(self, block, context):
        if self.value is not None:
            self.value = self.value.resolve(block.scope)
            block.names[self.value] = self.name
        return self
    def register_read(self, mask: int) -> None:
        if self.type is not None:
            self.read_mask |= mask & ((1 << parse_vector_type(self.type)[1]) - 1)
        else:
            self.read_mask |= mask
        self.read_count += 1
    def clear_read(self) -> None:
        self.read_mask = 0
        self.read_count = 0
    def calculate_read(self) -> None:
        if self.value is not None:
            self.value.calculate_read((1 << parse_vector_type(self.type)[1]) - 1)
    def prune(self):
        if self.read_mask == 0 or self.read_count == 0:
            return (False, False)
        if self.value is None:
            return (True, False)
        (scl_type, size) = parse_vector_type(self.type)
        var_mask = (1 << size) - 1
        if (var_mask & self.read_mask) != var_mask:
            value_mask = mask_inner(var_mask & self.read_mask, var_mask)
            swizzle = mask_swizzle(value_mask)
            self.type = make_vector_type(scl_type, len(swizzle))
            self.value = self.value.member(swizzle)
            self.init_mask = mask_inner(self.init_mask & self.read_mask, var_mask & self.read_mask)
            (self.value, _) = self.value.prune()
            return (True, True)
        (self.value, pr_changed) = self.value.prune()
        if isinstance(self.value, NameNode) and isinstance(self.value._name, DeclarationInstruction) and not self.value._name.is_phi and self.value._name.read_count == 1 and self.value._name.value is not None:
            self.value = self.value._name.value
            pr_changed = True
        return (True, pr_changed)
    def simplify_final(self, block):
        if isinstance(self.name, str) and self.name.startswith('_'):
            (scl_type, size) = parse_vector_type(self.type)
            prefix = 'sdtq'[size - 1]
            if scl_type != 'float':
                prefix += scl_type[0]
            new_name = prefix + self.name[1:]
            if new_name not in block.declarations:
                block.declarations[new_name] = self
                self.name = new_name
        if self.value is not None:
            self.value = self.value.simplify_final()
        return self

class AssignmentInstruction(Instruction):
    def __init__(self, name, mask: str | None, value: Node, is_init: bool) -> None:
        super().__init__()
        self._name = name
        self.mask = mask
        self.value = value
        self.is_init = is_init
    @property
    def name(self) -> str:
        return self._name if isinstance(self._name, str) else self._name.name
    def write_to(self, lines: list, indent: str) -> None:
        if self.mask is not None:
            lines.append((-1, '%s%s.%s = %s;%s' % (indent, self.name, self.mask, self.value.value_str(), self.comment_with_marker)))
        else:
            lines.append((-1, '%s%s = %s;%s' % (indent, self.name, self.value.value_str(), self.comment_with_marker)))
    def get_writes(self) -> dict:
        return {self.name, swizzle_mask(self.mask) if self.mask is not None else -1}
    def resolve(self, block, context):
        self.value = self.value.resolve(block.scope)
        if isinstance(self.value, LiteralNode):
            var = block.scope.get_for_update(self.name)
            for (i, c) in enumerate(self.mask):
                var.set_component(c, self.value)
            if self.name in context.outs:
                return self
            else:
                return []
        var = block.scope.get(self.name)
        type = var.reference_node().member(self.mask).type
        (name, already_decl) = block.name(self.value, False, context)
        if already_decl:
            decl = block.declarations[name]
            usage = NameNode(type, decl).simplify()
            for (i, c) in enumerate(self.mask):
                var.set_component(c, usage.member('xyzw'[i]))
            if self.name in context.outs:
                return AssignmentInstruction(self.name, self.mask, NameNode(type, block.declarations[name]), False)
            else:
                return None
        decl = DeclarationInstruction(type, name, self.value, False)
        block.declarations[name] = decl
        var = block.scope.get_for_update(self.name)
        usage = NameNode(type, decl).simplify()
        for (i, c) in enumerate(self.mask):
            var.set_component(c, usage.member('xyzw'[i]))
        if self.name in context.outs:
            return [decl, AssignmentInstruction(self.name, self.mask, usage, False)]
        else:
            return decl
    def calculate_read(self) -> None:
        if self.mask is not None:
            vector_size = len(self.mask)
        elif self._name is not None and not isinstance(self._name, str) and self._name.type is not None:
            vector_size = parse_vector_type(self._name.type)[1]
        else:
            vector_size = 4
        self.value.calculate_read((1 << vector_size) - 1)
    def prune(self):
        if isinstance(self._name, DeclarationInstruction):
            if self._name.read_mask == 0:
                return (False, False)
            var_size = parse_vector_type(self._name.type)[1]
            var_mask = (1 << var_size) - 1
            mask_before = swizzle_mask(self.mask) if self.mask is not None else var_mask
            changed = False
            mask_after = mask_inner(mask_before, self._name.read_mask, True)
            value_mask = mask_inner(mask_before & self._name.read_mask, mask_before)
            if mask_after != mask_before:
                self.mask = mask_swizzle(mask_after)
                changed = True
            if self.mask is not None and len(self.mask) == len(mask_swizzle(self._name.read_mask)):
                self.mask = None
                changed = True
            if value_mask != var_mask:
                self.value = self.value.member(mask_swizzle(value_mask))
                changed = True
            if self.is_init and self._name.read_mask == mask_before & self._name.read_mask:
                decl_init = self.value
                exp_swizzle = mask_swizzle(mask_inner(var_mask & self._name.read_mask, var_mask))
                if len(exp_swizzle) < var_size:
                    decl_init = ExpectSwizzleNode(decl_init, exp_swizzle)
                self._name.value = decl_init
                return (False, True)
            (self.value, pr_changed) = self.value.prune()
            if isinstance(self.value, NameNode) and isinstance(self.value._name, DeclarationInstruction) and not self.value._name.is_phi and self.value._name.read_count == 1 and self.value._name.value is not None:
                self.value = self.value._name.value
                pr_changed = True
            return (True, changed or pr_changed)
        (self.value, pr_changed) = self.value.prune()
        if isinstance(self.value, NameNode) and isinstance(self.value._name, DeclarationInstruction) and not self.value._name.is_phi and self.value._name.read_count == 1 and self.value._name.value is not None:
            self.value = self.value._name.value
            pr_changed = True
        return (True, pr_changed)
    def simplify_final(self, block):
        self.value = self.value.simplify_final()
        return self

class SwapCInstruction(Instruction):
    def __init__(self, var1: str, mask1: str, var2: str, mask2: str, condition: Node, value1: Node, value2: Node) -> None:
        super().__init__()
        self.var1 = var1
        self.mask1 = mask1
        self.var2 = var2
        self.mask2 = mask2
        self.condition = condition
        self.value1 = value1
        self.value2 = value2
    def resolve(self, block, context):
        self.condition = self.condition.resolve(block.scope)
        self.value1 = self.value1.resolve(block.scope)
        self.value2 = self.value2.resolve(block.scope)
        cond1 = ConditionalNode(self.condition, self.value1, self.value2)
        cond2 = ConditionalNode(self.condition.copy(True), self.value2.copy(True), self.value1.copy(True))
        var1 = block.scope.get_for_update(self.var1)
        var2 = block.scope.get_for_update(self.var2)
        type1 = var1.reference_node().member(self.mask1).type
        type2 = var2.reference_node().member(self.mask2).type
        if type1 != type2:
            raise RuntimeError('type mismatch between output vectors of swapc: %s %s.%s != %s %s.%s' % (type1, self.var1, self.mask1, type2, self.var2, self.mask2))
        (name1, already_decl1) = block.name(cond1, False, context)
        (name2, already_decl2) = block.name(cond2, False, context)
        if already_decl1 or already_decl2:
            raise RuntimeError('new cond should not already be declared')
        decl1 = DeclarationInstruction(type1, name1, cond1, False)
        decl2 = DeclarationInstruction(type2, name2, cond2, False)
        block.declarations[name1] = decl1
        block.declarations[name2] = decl2
        usage1 = NameNode(type1, decl1).simplify()
        usage2 = NameNode(type2, decl2).simplify()
        for (i, c) in enumerate(self.mask1):
            var1.set_component(c, usage1.member('xyzw'[i]))
        for (i, c) in enumerate(self.mask2):
            var2.set_component(c, usage2.member('xyzw'[i]))
        resolved = [decl1]
        if self.var1 in context.outs:
            resolved.append(AssignmentInstruction(self.var1, self.mask1, usage1, False))
        resolved.append(decl2)
        if self.var2 in context.outs:
            resolved.append(AssignmentInstruction(self.var2, self.mask2, usage2, False))
        return resolved

class ConditionalVerbInstruction(Instruction):
    def __init__(self, condition: Node, verb: str) -> None:
        super().__init__()
        self.condition = condition
        self.verb = verb
    def write_to(self, lines: list, indent: str) -> None:
        lines.append((-1, '%sif (%s) %s;%s' % (indent, self.condition.value_str(), self.verb, self.comment_with_marker)))
    def get_writes(self) -> dict:
        return {}
    def resolve(self, block, context):
        self.condition = self.condition.resolve(block.scope)
        return self
    def calculate_read(self) -> None:
        self.condition.calculate_read(1)
    def prune(self):
        (self.condition, changed) = self.condition.prune()
        if isinstance(self.condition, BinaryOpNode) and (self.condition.op == '==' or self.condition.op == '!=') and self.condition.right == parse_literal('0'):
            left = self.condition.left.inline()
            if isinstance(left, FunctionCallNode) and left.receiver is None and left.fn == 'cmp' and len(left.args) == 1:
                self.condition = left.args[0]
                changed = True
        return (True, changed)
    def simplify_final(self, block):
        self.condition = self.condition.simplify_final()
        return self

class BlockInstruction(Instruction):
    def prepare_phis(self, block, writes: dict, update_vars: bool, context):
        resolved = []
        phis = {}
        for var_name in writes:
            swizzle = mask_swizzle(writes[var_name])
            var = block.scope.get_for_update(var_name)
            value_before = var.value_node().member(swizzle)
            type = var.reference_node().member(swizzle).type
            phi = value_before.phi(None)
            (name, already_decl) = block.name(phi, False, context)
            if already_decl:
                raise RuntimeError('new Φ should not already be declared')
            phis[var_name] = phi
            v_mask = (1 << parse_vector_type(type)[1]) - 1
            init_mask = initialized_mask(value_before)
            decl = DeclarationInstruction(value_before.type, name, value_before if init_mask == v_mask else None, True)
            phi._name = decl
            block.declarations[name] = decl
            resolved.append(decl)
            if init_mask != 0 and init_mask != v_mask:
                decl.init_mask |= init_mask
                init_swizzle = mask_swizzle(init_mask)
                resolved.append(AssignmentInstruction(decl, init_swizzle, value_before.member(init_swizzle), True))
            if update_vars:
                usage = NameNode(type, decl).simplify()
                for (i, c) in enumerate(swizzle):
                    var.set_component(c, usage.member('xyzw'[i]))
        return (resolved, phis)
    def add_phis(self, resolved_block, writes: dict, phis: dict) -> None:
        block_writes = resolved_block.writes
        for var_name in block_writes:
            in_value = resolved_block.scope.get(var_name).value_node().member(mask_swizzle(block_writes[var_name]))
            init_mask_in_bw = initialized_mask(in_value)
            if init_mask_in_bw == 0:
                continue
            init_mask_in_var = mask_outer(init_mask_in_bw, block_writes[var_name])
            out_swizzle = mask_swizzle(mask_inner(init_mask_in_var, writes[var_name])) if init_mask_in_var != writes[var_name] else None
            resolved_block.instructions.append(AssignmentInstruction(phis[var_name]._name, out_swizzle, in_value.member(mask_swizzle(init_mask_in_bw)), False))
            phis[var_name].nodes.append(in_value)
    def update_vars(self, block, writes: dict, phis: dict) -> None:
        for var_name in writes:
            swizzle = mask_swizzle(writes[var_name])
            var = block.scope.get_for_update(var_name)
            type = var.reference_node().member(swizzle).type
            usage = NameNode(type, phis[var_name]._name).simplify()
            for (i, c) in enumerate(swizzle):
                var.set_component(c, usage.member('xyzw'[i]))
    def child_blocks(self):
        return ()

class IfBlockInstruction(BlockInstruction):
    def __init__(self, conditions_and_blocks: list, else_block) -> None:
        super().__init__()
        self.conditions_and_blocks = conditions_and_blocks
        self.else_block = else_block
    def write_to(self, lines: list, indent: str) -> None:
        first = True
        for (condition, block) in self.conditions_and_blocks:
            if first:
                lines.append((-1, '%sif (%s) {%s' % (indent, condition.value_str(), self.comment_with_marker)))
                first = False
            else:
                lines.append((-1, '%s} else if (%s) {' % (indent, condition.value_str())))
            block.write_to(lines, indent + '  ')
        if self.else_block is not None:
            lines.append((-1, '%s} else {' % (indent,)))
            self.else_block.write_to(lines, indent + '  ')
        lines.append((-1, '%s}' % (indent,)))
    def get_writes(self) -> dict:
        writes = {}
        for (_, block) in self.conditions_and_blocks:
            union_writes(writes, block.writes)
        if self.else_block is not None:
            union_writes(writes, self.else_block.writes)
        return writes
    def resolve(self, block, context):
        writes = self.writes
        (resolved, phis) = self.prepare_phis(block, writes, False, context)
        resolved_cb = []
        for (condition, inner_block) in self.conditions_and_blocks:
            resolved_condition = condition.resolve(inner_block.scope)
            resolved_block = inner_block.resolve(context)
            self.add_phis(resolved_block, writes, phis)
            resolved_cb.append((resolved_condition, resolved_block))
        self.conditions_and_blocks = resolved_cb
        if self.else_block is not None:
            self.else_block = self.else_block.resolve(context)
            self.add_phis(self.else_block, writes, phis)
        resolved.append(self)
        self.update_vars(block, writes, phis)
        return resolved
    def clear_read(self) -> None:
        for (_, block) in self.conditions_and_blocks:
            block.clear_read()
        if self.else_block is not None:
            self.else_block.clear_read()
    def calculate_read(self) -> None:
        for (condition, block) in self.conditions_and_blocks:
            condition.calculate_read(1)
            block.calculate_read()
        if self.else_block is not None:
            self.else_block.calculate_read()
    def prune(self):
        changed = False
        for i in range(len(self.conditions_and_blocks)):
            (condition, block) = self.conditions_and_blocks[i]
            if block.prune():
                changed = True
            if isinstance(condition, BinaryOpNode) and (condition.op == '==' or condition.op == '!=') and condition.right == parse_literal('0'):
                left = condition.left.inline()
                if isinstance(left, FunctionCallNode) and left.receiver is None and left.fn == 'cmp' and len(left.args) == 1:
                    condition = left.args[0]
                    self.conditions_and_blocks[i] = (condition, block)
                    changed = True
        if self.else_block is not None:
            if self.else_block.prune():
                changed = True
        return (True, changed)
    def simplify_final(self, block):
        for i in range(len(self.conditions_and_blocks)):
            (condition, inner_block) = self.conditions_and_blocks[i]
            condition = condition.simplify_final()
            inner_block.simplify_final()
            self.conditions_and_blocks[i] = (condition, inner_block)
        if self.else_block is not None:
            self.else_block.simplify_final()
        return self
    def child_blocks(self):
        for (_, inner_block) in self.conditions_and_blocks:
            yield inner_block
        if self.else_block is not None:
            yield self.else_block

class WhileBlockInstruction(BlockInstruction):
    def __init__(self, condition: Node, block) -> None:
        super().__init__()
        self.condition = condition
        self.block = block
    def write_to(self, lines: list, indent: str) -> None:
        lines.append((-1, '%swhile (%s) {%s' % (indent, self.condition.value_str(), self.comment_with_marker)))
        self.block.write_to(lines, indent + '  ')
        lines.append((-1, '%s}' % (indent,)))
    def get_writes(self) -> dict:
        return self.block.writes
    def resolve(self, block, context):
        writes = self.writes
        (resolved, phis) = self.prepare_phis(block, writes, True, context)
        self.condition = self.condition.resolve(block.scope)
        self.block = self.block.resolve(context)
        self.add_phis(self.block, writes, phis)
        resolved.append(self)
        return resolved
    def clear_read(self) -> None:
        self.block.clear_read()
    def calculate_read(self) -> None:
        self.condition.calculate_read(1)
        self.block.calculate_read()
    def prune(self):
        changed = self.block.prune()
        if self.condition == parse_literal('true') and isinstance(self.block.instructions[0], ConditionalVerbInstruction) and self.block.instructions[0].verb == 'break':
            self.condition = self.block.instructions.pop(0).condition.unary_op('!')
            changed = True
        return (True, changed)
    def simplify_final(self, block):
        self.condition = self.condition.simplify_final()
        self.block.simplify_final()
        return self
    def child_blocks(self):
        return (self.block,)

def initialized_mask(expr: Node) -> int:
    if isinstance(expr, UninitializedNode):
        return 0
    elif isinstance(expr, PhiNode):
        mask = 0
        for node in expr.nodes:
            mask |= initialized_mask(node)
        return mask
    elif isinstance(expr, NameNode):
        if isinstance(expr._name, DeclarationInstruction):
            return expr._name.init_mask
    mask = 15
    if expr.type is not None:
        mask &= (1 << parse_vector_type(expr.type)[1]) - 1
    if isinstance(expr, FunctionCallNode) and expr.receiver is None:
        match expr.fn:
            case 'float2' | 'int2' | 'uint2':
                if len(expr.args) == 1:
                    if isinstance(expr.args[0], UninitializedNode):
                        return 0
                elif len(expr.args) == 2:
                    for (i, arg) in enumerate(expr.args):
                        if isinstance(arg, UninitializedNode):
                            mask &= ~(1 << i)
            case 'float3' | 'int3' | 'uint3':
                if len(expr.args) == 1:
                    if isinstance(expr.args[0], UninitializedNode):
                        return 0
                elif len(expr.args) == 3:
                    for (i, arg) in enumerate(expr.args):
                        if isinstance(arg, UninitializedNode):
                            mask &= ~(1 << i)
            case 'float4' | 'int4' | 'uint4':
                if len(expr.args) == 1:
                    if isinstance(expr.args[0], UninitializedNode):
                        return 0
                elif len(expr.args) == 4:
                    for (i, arg) in enumerate(expr.args):
                        if isinstance(arg, UninitializedNode):
                            mask &= ~(1 << i)
    return mask

def union_writes(target: dict, source: dict) -> None:
    for var in source:
        target[var] = target.get(var, 0) | source[var]

class Block:
    def __init__(self, parent, scope: Scope) -> None:
        self.parent = parent
        self.scope = scope
        self.instructions = []
        self.names = {}
        self.names_rev = {}
        self.declarations = {}
        self.writes = {}
    @property
    def root(self):
        return self.parent.root if self.parent is not None else self
    def register_write(self, name: str, mask: int) -> None:
        self.writes[name] = self.writes.get(name, 0) | mask
        if self.parent is not None:
            self.parent.register_write(name, mask)
    def write_to(self, lines: list, indent: str) -> None:
        for instruction in self.instructions:
            instruction.write_to(lines, indent)
    def name(self, value: Node, force: bool, context):
        if value in self.names and not force:
            return (self.names[value], True)
        hash = value.hash()
        hex_hash = struct.pack('!H', (hash >> 16) ^ (hash & 0xFFFF)).hex().upper()
        name_base = '_%s' % (hex_hash,)
        name = name_base
        i = 1
        while self.is_name_used(name):
            i += 1
            name = '%s_%d' % (name_base, i)
        if name[1:] in context.name_mappings:
            name = context.name_mappings[name[1:]]
        self.names[value] = name
        self.root.names_rev[name] = None
        self.names_rev[name] = value
        return (name, False)
    def is_name_used(self, name: str) -> bool:
        if name in self.names_rev:
            return True
        if self.parent is None:
            return False
        return self.parent.is_name_used(name)
    def resolve(self, context) -> None:
        instructions = []
        for instruction in self.instructions:
            resolved = instruction.resolve(self, context)
            if isinstance(resolved, list):
                instructions.extend(resolved)
            elif resolved is not None:
                instructions.append(resolved)
        self.instructions = instructions
        return self
    def clear_read(self) -> None:
        for name in self.declarations:
            self.declarations[name].clear_read()
        for instr in self.instructions:
            instr.clear_read()
    def calculate_read(self) -> None:
        for instruction in reversed(self.instructions):
            instruction.calculate_read()
    def prune(self) -> bool:
        instructions = []
        changed = False
        for instruction in reversed(self.instructions):
            (keep, instr_changed) = instruction.prune()
            if keep:
                instructions.append(instruction)
            changed = changed or not keep or instr_changed
        if changed:
            instructions.reverse()
            self.instructions = instructions
        return changed
    def simplify_final(self) -> None:
        for i in range(len(self.instructions)):
            self.instructions[i] = self.instructions[i].simplify_final(self)

class BlockStack:
    def __init__(self) -> None:
        self.root = Block(None, Scope(None))
        self.current = self.root
    def push(self) -> None:
        self.current = Block(self.current, Scope(self.current.scope))
    def pop(self) -> Block:
        current = self.current
        self.current = current.parent
        return current
    def full_prune(self) -> None:
        while True:
            self.root.clear_read()
            self.root.calculate_read()
            if not self.root.prune():
                break
    def parse_line(self, line) -> bool:
        local = LOCAL_PATTERN.fullmatch(line)
        if local is not None:
            loc_t = local.group(1)
            loc_n = local.group(2)
            loc_n = 1 if loc_n is None else int(loc_n)
            for loc in local.group(3).split(','):
                self.current.scope.declare(Variable(loc_t, loc_n, loc.strip(), lambda _: UninitializedNode(loc_t).simplify()))
            return True
        swapc = SWAPC_PATTERN.fullmatch(line)
        if swapc is not None:
            var1 = swapc.group(1)
            mask1 = swapc.group(2)
            condition = parse_expression(swapc.group(3))
            value1 = parse_expression(swapc.group(4))
            value2 = parse_expression(swapc.group(5))
            var2 = swapc.group(6)
            mask2 = swapc.group(7)
            block = self.current
            block.instructions.append(SwapCInstruction(var1, mask1, var2, mask2, condition, value1, value2))
            block.register_write(var1, swizzle_mask(mask1))
            block.register_write(var2, swizzle_mask(mask2))
            return True
        assignment = ASSIGNMENT_PATTERN.fullmatch(line)
        if assignment is not None:
            var = assignment.group(1)
            mask = assignment.group(2)
            expr = parse_expression(assignment.group(3))
            block = self.current
            block.instructions.append(AssignmentInstruction(var, mask, expr, False))
            block.register_write(var, swizzle_mask(mask))
            return True
        if_verb = IF_VERB_PATTERN.fullmatch(line)
        if if_verb is not None:
            condition = parse_expression(if_verb.group(1))
            verb = if_verb.group(2)
            self.current.instructions.append(ConditionalVerbInstruction(condition, verb))
            return True
        block_start = BLOCK_START_PATTERN.fullmatch(line)
        if block_start is not None:
            block_type = block_start.group(1)
            condition = parse_expression(block_start.group(2))
            if block_type.startswith('}'):
                self.pop()
            block = self.current
            self.push()
            sub_block = self.current
            match block_type:
                case 'if':
                    block.instructions.append(IfBlockInstruction([(condition, sub_block)], None))
                case 'while':
                    block.instructions.append(WhileBlockInstruction(condition, sub_block))
                case '} else if':
                    block.instructions[-1].conditions_and_blocks.append((condition, sub_block))
                case _:
                    raise NotImplementedError('unrecognized block type "%s"' % (block_type,))
            return True
        if line == '} else {':
            self.pop()
            block = self.current
            self.push()
            block.instructions[-1].else_block = self.current
            return True
        if line == '}':
            self.pop()
            return True
        return False

class ExpressionParser:
    def __init__(self, input: str) -> None:
        self.input = input
        self.cursor = 0
        self.skip_whitespace()
    def match(self, pattern: re.Pattern, consume: bool = True) -> re.Match | None:
        match = pattern.match(self.input, self.cursor)
        if consume and match is not None:
            self.cursor = match.end()
        return match
    def take(self, condition, max: int | None = None, consume: bool = True) -> str | None:
        cursor = self.cursor
        limit = len(self.input)
        if max is not None and max < limit - cursor:
            limit = cursor + max
        while cursor < limit and condition(self.input[cursor]):
            cursor += 1
        if cursor == self.cursor:
            return None
        substr = self.input[self.cursor:cursor]
        if consume:
            self.cursor = cursor
        return substr
    def span(self, chars: str, max: int | None = None, consume: bool = True) -> str | None:
        return self.take(lambda c: c in chars, max, consume)
    def complement_span(self, chars: str, max: int | None = None, consume: bool = True) -> str | None:
        return self.take(lambda c: c not in chars, max, consume)
    def skip_whitespace(self) -> None:
        length = len(self.input)
        while self.cursor < length and self.input[self.cursor].isspace():
            self.cursor += 1
    def rest(self) -> str:
        return self.input[self.cursor:]
    def assert_end(self) -> None:
        if self.cursor < len(self.input):
            raise RuntimeError('expected end of string, got "%s"' % (self.rest(),))
    def parse(self) -> Node:
        return self.parse_conditional()
    def parse_conditional(self) -> Node:
        expr = self.parse_binary()
        if self.span('?', 1) is None:
            return expr
        self.skip_whitespace()
        if_true = self.parse_conditional()
        if self.span(':', 1) is None:
            raise RuntimeError('expected ":", got "%s"' % (self.rest(),))
        self.skip_whitespace()
        if_false = self.parse_conditional()
        return expr.conditional(if_true, if_false)
    def parse_binary(self) -> Node:
        # No proper handling of priorities because, as we're looking at a pseudo-disassembly,
        # the only nested binary we have is the fused multiply-add: a * b + c
        expr = self.parse_primary()
        while True:
            op = self.span(OPERATORS)
            if op is None:
                return expr
            self.skip_whitespace()
            second = self.parse_primary()
            expr = expr.binary_op(op, second)
    def parse_primary(self) -> Node:
        literal = self.match(LITERAL_PATTERN)
        if literal is not None:
            self.skip_whitespace()
            return parse_literal(literal.group())
        unary = self.span('-~!', 1)
        if unary is not None:
            self.skip_whitespace()
            return self.parse_primary().unary_op(unary)
        cast = self.match(CAST_PATTERN)
        if cast is not None:
            self.skip_whitespace()
            return self.parse_primary().cast(cast.group(1))
        name = self.match(NAME_PATTERN)
        if name is None:
            raise RuntimeError('expected literal or name, got "%s"' % (self.rest(),))
        self.skip_whitespace()
        node = NameNode(None, name.group()).simplify()
        while True:
            if self.span('.', 1) is not None:
                self.skip_whitespace()
                m_name = self.match(NAME_PATTERN)
                if m_name is None:
                    raise RuntimeError('expected name, got "%s"' % (self.rest(),))
                self.skip_whitespace()
                node = node.member(m_name.group())
            elif self.span('[', 1) is not None:
                self.skip_whitespace()
                index = self.parse()
                if self.span(']', 1) is None:
                    raise RuntimeError('expected "]", got "%s"' % (self.rest(),))
                self.skip_whitespace()
                node = node.index(index)
            elif self.span('(', 1) is not None:
                self.skip_whitespace()
                args = []
                if self.span(')', 1) is None:
                    while True:
                        args.append(self.parse())
                        if self.span(')', 1) is not None:
                            break
                        if self.span(',', 1) is None:
                            raise RuntimeError('expected "," or ")", got "%s"' % (self.rest(),))
                        self.skip_whitespace()
                self.skip_whitespace()
                node = node.call(args)
            else:
                return node

def parse_expression(expr: str) -> Node:
    parser = ExpressionParser(expr)
    node = parser.parse()
    parser.assert_end()
    return node
